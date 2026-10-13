import 'metric.dart';

enum ComparisonOperator {
  greaterOrEqual('>='),
  greaterThan('>'),
  equal('='),
  lessOrEqual('<='),
  lessThan('<');

  const ComparisonOperator(this.symbol);

  final String symbol;

  static ComparisonOperator fromSymbol(String symbol) => values.firstWhere(
    (operator) => operator.symbol == symbol,
    orElse: () => throw FormatException('未知比较运算符：$symbol'),
  );
}

sealed class RuleNode {
  const RuleNode();

  Map<String, Object?> toJson();

  factory RuleNode.fromJson(Map<String, Object?> json) {
    final type = json['type'];
    switch (type) {
      case 'comparison':
        final metric = json['metric'];
        final operator = json['operator'];
        final target = json['target'];
        if (metric is! String || operator is! String || target is! num) {
          throw const FormatException('ComparisonRule 字段不完整');
        }
        final filtersJson = json['filters'];
        return ComparisonRule(
          metricId: metric,
          metricVersion: json['metricVersion'] as int? ?? 1,
          filters: filtersJson is Map
              ? MetricFilters.fromJson(Map<String, Object?>.from(filtersJson))
              : const MetricFilters(),
          operator: ComparisonOperator.fromSymbol(operator),
          target: target,
        );
      case 'all':
        return AllRule(_childrenFromJson(json));
      case 'any':
        return AnyRule(_childrenFromJson(json));
      default:
        throw FormatException('未知规则节点：$type');
    }
  }

  static List<RuleNode> _childrenFromJson(Map<String, Object?> json) {
    final children = json['children'];
    if (children is! List || children.isEmpty) {
      throw const FormatException('组合规则至少需要一个子规则');
    }
    return children
        .map(
          (child) => RuleNode.fromJson(Map<String, Object?>.from(child as Map)),
        )
        .toList(growable: false);
  }
}

class ComparisonRule extends RuleNode {
  const ComparisonRule({
    required this.metricId,
    this.metricVersion = 1,
    this.filters = const MetricFilters(),
    required this.operator,
    required this.target,
  });

  final String metricId;
  final int metricVersion;
  final MetricFilters filters;
  final ComparisonOperator operator;
  final num target;

  @override
  Map<String, Object?> toJson() => {
    'type': 'comparison',
    'metric': metricId,
    'metricVersion': metricVersion,
    'filters': filters.toJson(),
    'operator': operator.symbol,
    'target': target,
  };
}

class AllRule extends RuleNode {
  factory AllRule(List<RuleNode> children) {
    if (children.isEmpty) {
      throw ArgumentError.value(children, 'children', 'ALL 至少需要一个子规则');
    }
    return AllRule._(List.unmodifiable(children));
  }

  const AllRule._(this.children);

  final List<RuleNode> children;

  @override
  Map<String, Object?> toJson() => {
    'type': 'all',
    'children': children.map((child) => child.toJson()).toList(),
  };
}

class AnyRule extends RuleNode {
  factory AnyRule(List<RuleNode> children) {
    if (children.isEmpty) {
      throw ArgumentError.value(children, 'children', 'ANY 至少需要一个子规则');
    }
    return AnyRule._(List.unmodifiable(children));
  }

  const AnyRule._(this.children);

  final List<RuleNode> children;

  @override
  Map<String, Object?> toJson() => {
    'type': 'any',
    'children': children.map((child) => child.toJson()).toList(),
  };
}
