part of '../database.dart';

extension RuleDao on AppDatabase {
  // ---- 休息标记 ----

  /// 监听某天的休息标记（dateOnly 归一化）
  Stream<RestMark?> watchRestMark(DateTime date) =>
      (select(restMarks)
            ..where((t) => t.date.equals(AppDatabase.dateOnly(date))))
          .watchSingleOrNull();

  /// 标记某天休息（按 date upsert，可改备注）；不增删任何训练数据
  Future<void> setRestMark(DateTime date, {String? note}) {
    final day = AppDatabase.dateOnly(date);
    return into(restMarks).insert(
      RestMarksCompanion(date: Value(day), note: Value(note)),
      onConflict: DoUpdate(
        (_) => RestMarksCompanion(note: Value(note)),
        target: [restMarks.date],
      ),
    );
  }

  /// 取消某天的休息标记
  Future<void> removeRestMark(DateTime date) => (delete(
    restMarks,
  )..where((t) => t.date.equals(AppDatabase.dateOnly(date)))).go();

  // ---- 周期目标规则 ----

  Stream<List<RuleSet>> watchRuleSets({bool includeArchived = false}) =>
      (select(ruleSets)
            ..where(
              (rule) => includeArchived
                  ? const Constant(true)
                  : rule.archivedAt.isNull(),
            )
            ..orderBy([(rule) => OrderingTerm.asc(rule.createdAt)]))
          .watch();

  Future<RuleSet?> getRuleSet(int id) =>
      (select(ruleSets)..where((rule) => rule.id.equals(id))).getSingleOrNull();

  Future<int> createRuleSet({
    String? presetKey,
    required String name,
    required RulePeriod period,
    required DateTime effectiveFromDate,
    DateTime? effectiveUntilDate,
    required RuleCombineMode combineMode,
    required RuleNode expression,
    int evaluationPolicyVersion = 1,
    DateTime? now,
  }) {
    _validateRuleSet(
      name,
      effectiveFromDate,
      effectiveUntilDate,
      combineMode,
      expression,
      evaluationPolicyVersion,
    );
    return into(ruleSets).insert(
      RuleSetsCompanion.insert(
        presetKey: Value(presetKey),
        name: name.trim(),
        period: period,
        effectiveFromDate: AppDatabase.dateOnly(effectiveFromDate),
        effectiveUntilDate: Value(
          effectiveUntilDate == null
              ? null
              : AppDatabase.dateOnly(effectiveUntilDate),
        ),
        combineMode: combineMode,
        expressionJson: jsonEncode(expression.toJson()),
        evaluationPolicyVersion: evaluationPolicyVersion,
        createdAt: now ?? DateTime.now(),
      ),
    );
  }

  Future<void> updateRuleSetDefinition(
    int id, {
    required String name,
    required RulePeriod period,
    required DateTime effectiveFromDate,
    DateTime? effectiveUntilDate,
    required RuleCombineMode combineMode,
    required RuleNode expression,
    int evaluationPolicyVersion = 1,
  }) {
    _validateRuleSet(
      name,
      effectiveFromDate,
      effectiveUntilDate,
      combineMode,
      expression,
      evaluationPolicyVersion,
    );
    return (update(ruleSets)..where((rule) => rule.id.equals(id))).write(
      RuleSetsCompanion(
        name: Value(name.trim()),
        period: Value(period),
        effectiveFromDate: Value(AppDatabase.dateOnly(effectiveFromDate)),
        effectiveUntilDate: Value(
          effectiveUntilDate == null
              ? null
              : AppDatabase.dateOnly(effectiveUntilDate),
        ),
        combineMode: Value(combineMode),
        expressionJson: Value(jsonEncode(expression.toJson())),
        evaluationPolicyVersion: Value(evaluationPolicyVersion),
      ),
    );
  }

  Future<void> archiveRuleSet(int id, {DateTime? now}) =>
      (update(ruleSets)..where((rule) => rule.id.equals(id))).write(
        RuleSetsCompanion(archivedAt: Value(now ?? DateTime.now())),
      );

  Future<int> activateRuleSetPreset(
    String key, {
    DateTime? effectiveFromDate,
    DateTime? now,
  }) async {
    final matches = AppDatabase.ruleSetPresets.where((item) => item.key == key);
    if (matches.isEmpty) throw ArgumentError.value(key, 'key', '未知周期目标预设');
    final preset = matches.first;
    final active =
        await (select(ruleSets)..where(
              (rule) => rule.presetKey.equals(key) & rule.archivedAt.isNull(),
            ))
            .getSingleOrNull();
    if (active != null) return active.id;
    return createRuleSet(
      presetKey: key,
      name: preset.name,
      period: preset.period,
      effectiveFromDate:
          effectiveFromDate ?? AppDatabase.dateOnly(now ?? DateTime.now()),
      combineMode: preset.combineMode,
      expression: preset.buildExpression(),
      now: now,
    );
  }

  RuleNode decodeRuleExpression(RuleSet ruleSet) => RuleNode.fromJson(
    Map<String, Object?>.from(jsonDecode(ruleSet.expressionJson) as Map),
  );

  static void _validateRuleSet(
    String name,
    DateTime effectiveFromDate,
    DateTime? effectiveUntilDate,
    RuleCombineMode combineMode,
    RuleNode expression,
    int policyVersion,
  ) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', '目标名称不能为空');
    }
    if (effectiveUntilDate != null &&
        AppDatabase.dateOnly(effectiveUntilDate)
            .isBefore(AppDatabase.dateOnly(effectiveFromDate))) {
      throw ArgumentError('结束日期不能早于开始日期');
    }
    if (policyVersion != 1) {
      throw ArgumentError('当前只支持评估策略版本 1');
    }
    if ((combineMode == RuleCombineMode.all && expression is! AllRule) ||
        (combineMode == RuleCombineMode.any && expression is! AnyRule)) {
      throw ArgumentError('组合模式与表达式根节点不一致');
    }
    void validateNode(RuleNode node) {
      switch (node) {
        case ComparisonRule comparison:
          MetricRegistry.builtIn().definition(
            comparison.metricId,
            comparison.metricVersion,
          );
          if (!comparison.target.isFinite) {
            throw ArgumentError('目标值必须是有限数字');
          }
        case AllRule all:
          for (final child in all.children) {
            validateNode(child);
          }
        case AnyRule any:
          for (final child in any.children) {
            validateNode(child);
          }
      }
    }

    validateNode(expression);
  }

  Future<List<RuleSetProgress>> evaluateRuleSets(DateTime date) async {
    final day = AppDatabase.dateOnly(date);
    final active =
        await (select(ruleSets)
              ..where(
                (rule) =>
                    rule.archivedAt.isNull() &
                    rule.effectiveFromDate.isSmallerOrEqualValue(day) &
                    (rule.effectiveUntilDate.isNull() |
                        rule.effectiveUntilDate.isBiggerOrEqualValue(day)),
              )
              ..orderBy([(rule) => OrderingTerm.asc(rule.createdAt)]))
            .get();
    final contexts = <RulePeriod, MetricContext>{};
    final results = <RuleSetProgress>[];
    for (final ruleSet in active) {
      final context = contexts[ruleSet.period] ??=
          await _metricContextForPeriod(day, ruleSet.period);
      final evaluator = RuleEvaluator(
        metrics: MetricRegistry.builtIn(),
        policyVersion: ruleSet.evaluationPolicyVersion,
      );
      results.add(
        RuleSetProgress(
          ruleSet,
          evaluator.evaluate(decodeRuleExpression(ruleSet), context),
        ),
      );
    }
    return results;
  }

  Future<MetricContext> _metricContextForPeriod(
    DateTime day,
    RulePeriod period,
  ) {
    final start = period == RulePeriod.day ? day : AppDatabase.weekStart(day);
    final end = start.add(Duration(days: period == RulePeriod.day ? 1 : 7));
    return buildMetricContext(periodStart: start, periodEndExclusive: end);
  }

  Stream<List<RuleSetProgress>> watchRuleSetProgress(DateTime date) =>
      _watchAny([
        watchRuleSets(),
        select(workouts).watch(),
        select(workoutExercises).watch(),
        select(workoutSets).watch(),
      ]).asyncMap((_) => evaluateRuleSets(date));
}
