import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../domain/rules/metric.dart';
import '../domain/rules/rule_ast.dart';
import '../providers/app_providers.dart';

extension on RulePeriod {
  String get label => this == RulePeriod.day ? '每日' : '每周';
}

extension on RuleCombineMode {
  String get label => this == RuleCombineMode.all ? '全部满足' : '任一满足';
}

String _operatorLabel(ComparisonOperator operator) => switch (operator) {
  ComparisonOperator.greaterOrEqual => '不少于',
  ComparisonOperator.greaterThan => '大于',
  ComparisonOperator.equal => '等于',
  ComparisonOperator.lessOrEqual => '不多于',
  ComparisonOperator.lessThan => '小于',
};

class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  Future<void> _showPresets(
    BuildContext context,
    WidgetRef ref,
    List<RuleSet> activeRules,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('周期目标预设'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final preset in AppDatabase.ruleSetPresets)
                Builder(
                  builder: (context) {
                    final active = activeRules.any(
                      (rule) => rule.presetKey == preset.key,
                    );
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(preset.name),
                      subtitle: Text(preset.description),
                      trailing: active
                          ? const Icon(Icons.check_circle_outline)
                          : FilledButton.tonal(
                              onPressed: () async {
                                await ref
                                    .read(databaseProvider)
                                    .activateRuleSetPreset(preset.key);
                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }
                              },
                              child: const Text('启用'),
                            ),
                    );
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    RuleSet ruleSet,
  ) async {
    final expression = ref.read(databaseProvider).decodeRuleExpression(ruleSet);
    await showRuleSetFormDialog(
      context,
      editing: ruleSet,
      expression: expression,
    );
  }

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    RuleSet ruleSet,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('归档目标'),
        content: Text('归档「${ruleSet.name}」？已记录的训练事实不会改变。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('归档'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(databaseProvider).archiveRuleSet(ruleSet.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(ruleSetsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('周期目标'),
        actions: [
          IconButton(
            tooltip: '使用预设',
            icon: const Icon(Icons.playlist_add),
            onPressed: () =>
                _showPresets(context, ref, rulesAsync.value ?? const []),
          ),
        ],
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('目标加载失败')),
        data: (rules) => rules.isEmpty
            ? const Center(child: Text('尚未设置每日或每周目标'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rules.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final rule = rules[index];
                  final until = rule.effectiveUntilDate;
                  final dateRange = until == null
                      ? '${DateFormat('yyyy-MM-dd').format(rule.effectiveFromDate)} 起'
                      : '${DateFormat('yyyy-MM-dd').format(rule.effectiveFromDate)} 至 '
                            '${DateFormat('yyyy-MM-dd').format(until)}';
                  return Card(
                    child: ListTile(
                      title: Text(rule.name),
                      subtitle: Text(
                        '${rule.period.label} · ${rule.combineMode.label}\n$dateRange',
                      ),
                      isThreeLine: true,
                      onTap: () => _edit(context, ref, rule),
                      trailing: IconButton(
                        icon: const Icon(Icons.archive_outlined),
                        tooltip: '归档目标',
                        onPressed: () => _archive(context, ref, rule),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_rule_set',
        icon: const Icon(Icons.add),
        label: const Text('新建目标'),
        onPressed: () => showRuleSetFormDialog(context),
      ),
    );
  }
}

Future<void> showRuleSetFormDialog(
  BuildContext context, {
  RuleSet? editing,
  RuleNode? expression,
}) => showDialog<void>(
  context: context,
  builder: (_) => RuleSetFormDialog(editing: editing, expression: expression),
);

class RuleSetFormDialog extends ConsumerStatefulWidget {
  const RuleSetFormDialog({super.key, this.editing, this.expression});

  final RuleSet? editing;
  final RuleNode? expression;

  @override
  ConsumerState<RuleSetFormDialog> createState() => _RuleSetFormDialogState();
}

class _ConditionDraft {
  _ConditionDraft({
    this.metricId = 'session_count',
    this.exerciseId,
    this.category,
    this.setRole,
    this.operator = ComparisonOperator.greaterOrEqual,
    String target = '',
  }) : targetController = TextEditingController(text: target);

  factory _ConditionDraft.fromRule(ComparisonRule rule) => _ConditionDraft(
    metricId: rule.metricId,
    exerciseId: rule.filters.exerciseId,
    category: rule.filters.category,
    setRole: rule.filters.setRole,
    operator: rule.operator,
    target: rule.metricId == 'session_duration'
        ? _formatNumber(rule.target / 60)
        : _formatNumber(rule.target),
  );

  static String _formatNumber(num value) =>
      value == value.roundToDouble() ? '${value.round()}' : value.toString();

  String metricId;
  int? exerciseId;
  String? category;
  String? setRole;
  ComparisonOperator operator;
  final TextEditingController targetController;

  void dispose() => targetController.dispose();
}

class _RuleSetFormDialogState extends ConsumerState<RuleSetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late RulePeriod _period;
  late RuleCombineMode _combineMode;
  late DateTime _effectiveFrom;
  DateTime? _effectiveUntil;
  final List<_ConditionDraft> _conditions = [];
  String? _formError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _nameController = TextEditingController(text: editing?.name ?? '');
    _period = editing?.period ?? RulePeriod.week;
    _combineMode = editing?.combineMode ?? RuleCombineMode.all;
    _effectiveFrom =
        editing?.effectiveFromDate ??
        AppDatabase.dateOnly(ref.read(appClockProvider)());
    _effectiveUntil = editing?.effectiveUntilDate;
    final expression = widget.expression;
    final children = switch (expression) {
      AllRule all => all.children,
      AnyRule any => any.children,
      ComparisonRule comparison => <RuleNode>[comparison],
      null => const <RuleNode>[],
    };
    _conditions.addAll(
      children.whereType<ComparisonRule>().map(_ConditionDraft.fromRule),
    );
    if (_conditions.isEmpty) _conditions.add(_ConditionDraft());
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final condition in _conditions) {
      condition.dispose();
    }
    super.dispose();
  }

  Future<void> _pickEffectiveFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveFrom,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _effectiveFrom = picked);
  }

  Future<void> _pickEffectiveUntil() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveUntil ?? _effectiveFrom,
      firstDate: _effectiveFrom,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _effectiveUntil = picked);
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_conditions.isEmpty) {
      setState(() => _formError = '至少添加一条规则');
      return;
    }
    setState(() => _saving = true);
    final comparisons = [
      for (final condition in _conditions)
        ComparisonRule(
          metricId: condition.metricId,
          filters: MetricFilters(
            exerciseId: condition.exerciseId,
            category: condition.category,
            setRole: condition.setRole,
          ),
          operator: condition.operator,
          target: condition.metricId == 'session_duration'
              ? num.parse(condition.targetController.text.trim()) * 60
              : num.parse(condition.targetController.text.trim()),
        ),
    ];
    final expression = _combineMode == RuleCombineMode.all
        ? AllRule(comparisons)
        : AnyRule(comparisons);
    final db = ref.read(databaseProvider);
    try {
      final editing = widget.editing;
      if (editing == null) {
        await db.createRuleSet(
          name: _nameController.text,
          period: _period,
          effectiveFromDate: _effectiveFrom,
          effectiveUntilDate: _effectiveUntil,
          combineMode: _combineMode,
          expression: expression,
        );
      } else {
        await db.updateRuleSetDefinition(
          editing.id,
          name: _nameController.text,
          period: _period,
          effectiveFromDate: _effectiveFrom,
          effectiveUntilDate: _effectiveUntil,
          combineMode: _combineMode,
          expression: expression,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on ArgumentError catch (error) {
      if (mounted) setState(() => _formError = error.message?.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exercisesProvider).value ?? [];
    final metrics = MetricRegistry.builtIn().definitions;
    return AlertDialog(
      title: Text(widget.editing == null ? '新建周期目标' : '编辑周期目标'),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '目标名称'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入目标名称' : null,
                ),
                const SizedBox(height: 12),
                SegmentedButton<RulePeriod>(
                  segments: [
                    for (final period in RulePeriod.values)
                      ButtonSegment(value: period, label: Text(period.label)),
                  ],
                  selected: {_period},
                  onSelectionChanged: (value) =>
                      setState(() => _period = value.single),
                ),
                const SizedBox(height: 12),
                SegmentedButton<RuleCombineMode>(
                  segments: [
                    for (final mode in RuleCombineMode.values)
                      ButtonSegment(value: mode, label: Text(mode.label)),
                  ],
                  selected: {_combineMode},
                  onSelectionChanged: (value) =>
                      setState(() => _combineMode = value.single),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(
                        '生效 ${DateFormat('yyyy-MM-dd').format(_effectiveFrom)}',
                      ),
                      onPressed: _pickEffectiveFrom,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.event_available, size: 18),
                      label: Text(
                        _effectiveUntil == null
                            ? '长期有效'
                            : '至 ${DateFormat('yyyy-MM-dd').format(_effectiveUntil!)}',
                      ),
                      onPressed: _pickEffectiveUntil,
                    ),
                    if (_effectiveUntil != null)
                      IconButton(
                        tooltip: '清除结束日期',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _effectiveUntil = null),
                      ),
                  ],
                ),
                const Divider(height: 28),
                for (var i = 0; i < _conditions.length; i++) ...[
                  _ConditionEditor(
                    key: ValueKey(_conditions[i]),
                    index: i,
                    draft: _conditions[i],
                    metrics: metrics,
                    exercises: exercises,
                    onChanged: () => setState(() {}),
                    onRemove: _conditions.length == 1
                        ? null
                        : () => setState(() {
                            _conditions.removeAt(i).dispose();
                          }),
                  ),
                  if (i != _conditions.length - 1) const SizedBox(height: 12),
                ],
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('添加规则'),
                  onPressed: () =>
                      setState(() => _conditions.add(_ConditionDraft())),
                ),
                if (_formError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _formError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _ConditionEditor extends StatelessWidget {
  const _ConditionEditor({
    super.key,
    required this.index,
    required this.draft,
    required this.metrics,
    required this.exercises,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final _ConditionDraft draft;
  final List<MetricDefinition> metrics;
  final List<Exercise> exercises;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final selectedExerciseExists = exercises.any(
      (exercise) => exercise.id == draft.exerciseId,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '规则 ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                IconButton(
                  tooltip: '移除规则',
                  icon: const Icon(Icons.close),
                  onPressed: onRemove,
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: draft.metricId,
              decoration: const InputDecoration(labelText: '指标'),
              items: [
                for (final metric in metrics)
                  DropdownMenuItem(
                    value: metric.metricId,
                    child: Text(
                      metric.metricId == 'session_duration'
                          ? '${metric.name}（分钟）'
                          : '${metric.name}（${metric.unit}）',
                    ),
                  ),
              ],
              onChanged: (value) {
                draft.metricId = value ?? 'session_count';
                onChanged();
              },
            ),
            DropdownButtonFormField<int?>(
              initialValue: draft.exerciseId,
              decoration: const InputDecoration(labelText: '动作过滤（可选）'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('全部动作')),
                if (draft.exerciseId != null && !selectedExerciseExists)
                  DropdownMenuItem<int?>(
                    value: draft.exerciseId,
                    child: Text('历史动作 #${draft.exerciseId}'),
                  ),
                for (final exercise in exercises)
                  DropdownMenuItem<int?>(
                    value: exercise.id,
                    child: Text(exercise.name),
                  ),
              ],
              onChanged: (value) {
                draft.exerciseId = value;
                onChanged();
              },
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: draft.category,
                    decoration: const InputDecoration(labelText: '类别（可选）'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('全部类别'),
                      ),
                      for (final category in ExerciseCategory.values)
                        DropdownMenuItem<String?>(
                          value: category.name,
                          child: Text(category.label),
                        ),
                    ],
                    onChanged: (value) {
                      draft.category = value;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: draft.setRole,
                    decoration: const InputDecoration(labelText: '组角色（可选）'),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('全部组'),
                      ),
                      DropdownMenuItem(value: 'warmup', child: Text('热身组')),
                      DropdownMenuItem(value: 'work', child: Text('工作组')),
                      DropdownMenuItem(value: 'cooldown', child: Text('放松组')),
                    ],
                    onChanged: (value) {
                      draft.setRole = value;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ComparisonOperator>(
                    initialValue: draft.operator,
                    decoration: const InputDecoration(labelText: '比较'),
                    items: [
                      for (final operator in ComparisonOperator.values)
                        DropdownMenuItem(
                          value: operator,
                          child: Text(_operatorLabel(operator)),
                        ),
                    ],
                    onChanged: (value) {
                      draft.operator =
                          value ?? ComparisonOperator.greaterOrEqual;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: draft.targetController,
                    decoration: InputDecoration(
                      labelText: draft.metricId == 'session_duration'
                          ? '目标值（分钟）'
                          : '目标值',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final target = num.tryParse(value?.trim() ?? '');
                      if (target == null || !target.isFinite) return '请输入有效数字';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
