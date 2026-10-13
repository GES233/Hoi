import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:hoi/domain/rules/metric.dart';
import 'package:hoi/domain/rules/rule_ast.dart';
import 'package:hoi/domain/rules/rule_evaluator.dart';

void main() {
  final start = DateTime(2026, 10, 5);
  late MetricRegistry metrics;
  late RuleEvaluator evaluator;
  late MetricContext context;

  MetricSetFact set({
    String role = 'work',
    String status = 'completed',
    int? reps,
    int? duration,
    double? distance,
  }) => MetricSetFact(
    setRole: role,
    setStatus: status,
    reps: reps,
    durationSeconds: duration,
    distanceMeters: distance,
  );

  MetricExerciseFact exercise({
    required int id,
    required String category,
    required String tracking,
    required List<MetricSetFact> sets,
  }) => MetricExerciseFact(
    exerciseId: id,
    category: category,
    trackingType: tracking,
    sets: sets,
  );

  setUp(() {
    metrics = MetricRegistry.builtIn();
    evaluator = RuleEvaluator(metrics: metrics);
    context = MetricContext(
      periodStart: start,
      periodEndExclusive: start.add(const Duration(days: 7)),
      sessions: [
        MetricSessionFact(
          workoutId: 1,
          date: start,
          completed: true,
          totalSeconds: 1800,
          exercises: [
            exercise(
              id: 1,
              category: 'resistance',
              tracking: 'reps',
              sets: [
                set(reps: 10),
                set(reps: 10, status: 'skipped'),
                set(reps: 0),
              ],
            ),
            exercise(
              id: 2,
              category: 'cardio',
              tracking: 'duration',
              sets: [set(duration: 600)],
            ),
          ],
        ),
        MetricSessionFact(
          workoutId: 2,
          date: start.add(const Duration(days: 2)),
          completed: true,
          totalSeconds: 3600,
          exercises: [
            exercise(
              id: 1,
              category: 'resistance',
              tracking: 'reps',
              sets: [set(reps: 20)],
            ),
            exercise(
              id: 2,
              category: 'cardio',
              tracking: 'duration',
              sets: [set(duration: 1200)],
            ),
          ],
        ),
        MetricSessionFact(
          workoutId: 3,
          date: start.add(const Duration(days: 4)),
          completed: true,
          totalSeconds: null,
          exercises: const [],
        ),
        MetricSessionFact(
          workoutId: 4,
          date: start.subtract(const Duration(days: 1)),
          completed: true,
          totalSeconds: null,
          exercises: const [],
        ),
      ],
    );
  });

  test('内置指标声明稳定 ID、单位、聚合和缺失策略', () {
    expect(metrics.definitions.map((definition) => definition.metricId), [
      'session_count',
      'session_duration',
      'valid_set_count',
      'reps',
      'duration',
      'distance',
    ]);
    final duration = metrics.definition('duration', 1);
    expect(duration.unit, 'second');
    expect(duration.aggregation, MetricAggregation.sum);
    expect(
      duration.missingDataPolicy,
      MissingDataPolicy.insufficientWhenMatchedFactMissing,
    );
    expect(() => metrics.definition('duration', 2), throwsStateError);
  });

  test('session_count 按训练 ID 计数，多动作多组不重复', () {
    final value = metrics.evaluate(
      'session_count',
      1,
      context,
      const MetricFilters(),
    );
    expect(value.value, 3);
    expect(value.unit, 'session');
  });

  test('session_duration 读取整场用时，未知时不从动作组推算', () {
    final knownContext = MetricContext(
      periodStart: context.periodStart,
      periodEndExclusive: context.periodEndExclusive,
      sessions: context.sessions.take(2).toList(),
    );
    final known = metrics.evaluate(
      'session_duration',
      1,
      knownContext,
      const MetricFilters(),
    );
    expect(known.value, 5400);

    final missing = metrics.evaluate(
      'session_duration',
      1,
      context,
      const MetricFilters(),
    );
    expect(missing.insufficientData, isTrue);
    expect(missing.missingFields, ['total_seconds']);
  });

  test('指标按 exerciseId 过滤，跳过组与零值组不算有效组', () {
    final validSets = metrics.evaluate(
      'valid_set_count',
      1,
      context,
      const MetricFilters(exerciseId: 1),
    );
    final reps = metrics.evaluate(
      'reps',
      1,
      context,
      const MetricFilters(exerciseId: 1),
    );
    final duration = metrics.evaluate(
      'duration',
      1,
      context,
      const MetricFilters(exerciseId: 2),
    );
    expect(validSets.value, 2);
    expect(reps.value, 30);
    expect(duration.value, 1800);
  });

  test('距离使用米并支持类别过滤', () {
    final distanceContext = MetricContext(
      periodStart: start,
      periodEndExclusive: start.add(const Duration(days: 7)),
      sessions: [
        MetricSessionFact(
          workoutId: 1,
          date: start,
          completed: true,
          totalSeconds: 900,
          exercises: [
            exercise(
              id: 3,
              category: 'cardio',
              tracking: 'distance',
              sets: [set(distance: 3200), set(distance: 1800)],
            ),
          ],
        ),
      ],
    );
    final value = metrics.evaluate(
      'distance',
      1,
      distanceContext,
      const MetricFilters(category: 'cardio'),
    );
    expect(value.value, 5000);
    expect(value.unit, 'meter');
  });

  test('ComparisonRule 输出 passed、partial 与 failed', () {
    RuleEvaluation evaluate(num target) => evaluator.evaluate(
      ComparisonRule(
        metricId: 'reps',
        filters: const MetricFilters(exerciseId: 1),
        operator: ComparisonOperator.greaterOrEqual,
        target: target,
      ),
      context,
    );

    expect(evaluate(30).status, RuleResultStatus.passed);
    expect(evaluate(50).status, RuleResultStatus.partial);
    expect(
      evaluator
          .evaluate(
            const ComparisonRule(
              metricId: 'reps',
              filters: MetricFilters(exerciseId: 99),
              operator: ComparisonOperator.greaterOrEqual,
              target: 10,
            ),
            context,
          )
          .status,
      RuleResultStatus.failed,
    );
  });

  test('ALL 与 ANY 按既定优先级合成子结果', () {
    const sessionRule = ComparisonRule(
      metricId: 'session_count',
      operator: ComparisonOperator.greaterOrEqual,
      target: 3,
    );
    const repsRule = ComparisonRule(
      metricId: 'reps',
      filters: MetricFilters(exerciseId: 1),
      operator: ComparisonOperator.greaterOrEqual,
      target: 50,
    );
    final all = evaluator.evaluate(AllRule([sessionRule, repsRule]), context);
    final any = evaluator.evaluate(AnyRule([sessionRule, repsRule]), context);
    expect(all.status, RuleResultStatus.partial);
    expect(any.status, RuleResultStatus.passed);
    expect(all.children, hasLength(2));
  });

  test('匹配记录缺少必需字段时返回 insufficient_data', () {
    final missingContext = MetricContext(
      periodStart: start,
      periodEndExclusive: start.add(const Duration(days: 1)),
      sessions: [
        MetricSessionFact(
          workoutId: 1,
          date: start,
          completed: true,
          totalSeconds: null,
          exercises: [
            exercise(
              id: 2,
              category: 'cardio',
              tracking: 'duration',
              sets: [set()],
            ),
          ],
        ),
      ],
    );
    final result = evaluator.evaluate(
      const ComparisonRule(
        metricId: 'duration',
        filters: MetricFilters(exerciseId: 2),
        operator: ComparisonOperator.greaterOrEqual,
        target: 600,
      ),
      missingContext,
    );
    expect(result.status, RuleResultStatus.insufficientData);
    expect(result.actual, isNull);
    expect(result.missingFields, ['duration_seconds']);
    expect(result.policyVersion, 1);
  });

  test('Rule AST JSON 可往返，并拒绝未知节点和空组合', () {
    final rule = AllRule([
      const ComparisonRule(
        metricId: 'session_count',
        operator: ComparisonOperator.greaterOrEqual,
        target: 3,
      ),
      AnyRule([
        const ComparisonRule(
          metricId: 'duration',
          filters: MetricFilters(exerciseId: 2, setRole: 'work'),
          operator: ComparisonOperator.greaterThan,
          target: 1200,
        ),
      ]),
    ]);
    final encoded = jsonEncode(rule.toJson());
    final decoded = RuleNode.fromJson(
      Map<String, Object?>.from(jsonDecode(encoded) as Map),
    );
    expect(jsonEncode(decoded.toJson()), encoded);
    expect(
      () => RuleNode.fromJson(const {'type': 'unknown'}),
      throwsFormatException,
    );
    expect(
      () => RuleNode.fromJson(const {'type': 'all', 'children': []}),
      throwsFormatException,
    );
  });
}
