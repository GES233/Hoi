import 'metric.dart';
import 'rule_ast.dart';

enum RuleResultStatus { passed, partial, failed, insufficientData }

class RuleEvaluation {
  const RuleEvaluation({
    required this.status,
    required this.policyVersion,
    required this.reasons,
    this.actual,
    this.target,
    this.unit,
    this.missingFields = const [],
    this.children = const [],
  });

  final RuleResultStatus status;
  final int policyVersion;
  final num? actual;
  final num? target;
  final String? unit;
  final List<String> reasons;
  final List<String> missingFields;
  final List<RuleEvaluation> children;
}

class RuleEvaluator {
  const RuleEvaluator({required this.metrics, this.policyVersion = 1});

  final MetricRegistry metrics;
  final int policyVersion;

  RuleEvaluation evaluate(RuleNode rule, MetricContext context) {
    if (policyVersion != 1) {
      throw StateError('不支持的规则评估策略版本：$policyVersion');
    }
    return switch (rule) {
      ComparisonRule comparison => _evaluateComparison(comparison, context),
      AllRule all => _evaluateAll(all, context),
      AnyRule any => _evaluateAny(any, context),
    };
  }

  RuleEvaluation _evaluateComparison(
    ComparisonRule rule,
    MetricContext context,
  ) {
    final value = metrics.evaluate(
      rule.metricId,
      rule.metricVersion,
      context,
      rule.filters,
    );
    if (value.insufficientData) {
      return RuleEvaluation(
        status: RuleResultStatus.insufficientData,
        policyVersion: policyVersion,
        target: rule.target,
        unit: value.unit,
        reasons: const ['匹配记录缺少指标所需字段'],
        missingFields: value.missingFields,
      );
    }
    final actual = value.value!;
    final passed = switch (rule.operator) {
      ComparisonOperator.greaterOrEqual => actual >= rule.target,
      ComparisonOperator.greaterThan => actual > rule.target,
      ComparisonOperator.equal => actual == rule.target,
      ComparisonOperator.lessOrEqual => actual <= rule.target,
      ComparisonOperator.lessThan => actual < rule.target,
    };
    final canBePartial =
        rule.operator == ComparisonOperator.greaterOrEqual ||
        rule.operator == ComparisonOperator.greaterThan ||
        rule.operator == ComparisonOperator.equal;
    final status = passed
        ? RuleResultStatus.passed
        : canBePartial && actual > 0 && rule.target > actual
        ? RuleResultStatus.partial
        : RuleResultStatus.failed;
    return RuleEvaluation(
      status: status,
      policyVersion: policyVersion,
      actual: actual,
      target: rule.target,
      unit: value.unit,
      reasons: [passed ? '指标达到目标' : '指标尚未达到目标'],
    );
  }

  RuleEvaluation _evaluateAll(AllRule rule, MetricContext context) {
    final children = rule.children
        .map((child) => evaluate(child, context))
        .toList();
    final status =
        children.any((child) => child.status == RuleResultStatus.failed)
        ? RuleResultStatus.failed
        : children.any(
            (child) => child.status == RuleResultStatus.insufficientData,
          )
        ? RuleResultStatus.insufficientData
        : children.any((child) => child.status == RuleResultStatus.partial)
        ? RuleResultStatus.partial
        : RuleResultStatus.passed;
    return RuleEvaluation(
      status: status,
      policyVersion: policyVersion,
      reasons: ['全部 ${children.length} 条规则需成立'],
      children: children,
      missingFields: _missingFields(children),
    );
  }

  RuleEvaluation _evaluateAny(AnyRule rule, MetricContext context) {
    final children = rule.children
        .map((child) => evaluate(child, context))
        .toList();
    final status =
        children.any((child) => child.status == RuleResultStatus.passed)
        ? RuleResultStatus.passed
        : children.any(
            (child) => child.status == RuleResultStatus.insufficientData,
          )
        ? RuleResultStatus.insufficientData
        : children.any((child) => child.status == RuleResultStatus.partial)
        ? RuleResultStatus.partial
        : RuleResultStatus.failed;
    return RuleEvaluation(
      status: status,
      policyVersion: policyVersion,
      reasons: ['任意 1 条规则成立即可'],
      children: children,
      missingFields: _missingFields(children),
    );
  }

  static List<String> _missingFields(List<RuleEvaluation> children) =>
      children.expand((child) => child.missingFields).toSet().toList()..sort();
}
