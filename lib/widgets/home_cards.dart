import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../domain/rules/rule_ast.dart';
import '../domain/rules/rule_evaluator.dart';
import '../providers/app_providers.dart';
import '../screens/plans_screen.dart';
import '../screens/rules_screen.dart';
import '../theme/app_theme.dart';
import 'add_entry_dialogs.dart';

/// 「今日方案」卡片：各方案阈值与选中日期状态、休息标记入口
class TodayPlanCard extends ConsumerWidget {
  const TodayPlanCard({super.key});

  /// 标记休息：可选备注；返回 null 表示取消
  Future<void> _markRest(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
  ) async {
    final noteController = TextEditingController();
    final note = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('今天休息'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: '备注（可选）'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(noteController.text.trim()),
            child: const Text('标记休息'),
          ),
        ],
      ),
    );
    if (note == null) return;
    await ref
        .read(databaseProvider)
        .setRestMark(date, note: note.isEmpty ? null : note);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final templatesAsync = ref.watch(workoutTemplatesProvider);
    final progressAsync = ref.watch(dailyTemplateProgressProvider);
    final rest = ref.watch(restMarkProvider).value;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.task_alt_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '今日方案',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (rest == null)
                  TextButton.icon(
                    icon: const Icon(Icons.bedtime_outlined, size: 17),
                    label: const Text('今天休息'),
                    onPressed: () => _markRest(context, ref, date),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // 加载 / 错误 / 空 / 数据 分开呈现
            if (templatesAsync.hasError || progressAsync.hasError)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('方案状态加载失败'),
              )
            else if (!templatesAsync.hasValue)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('加载中…'),
              )
            else if (templatesAsync.value!.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('尚未设置最低方案')),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PlansScreen()),
                      ),
                      child: const Text('去创建'),
                    ),
                  ],
                ),
              )
            else
              for (final summary in templatesAsync.value!)
                _TemplateProgressRow(
                  summary: summary,
                  progress: progressAsync.value?[summary.template.id],
                ),
            if (rest != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bedtime, size: 16, color: scheme.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '已标记休息'
                        '${rest.note != null && rest.note!.isNotEmpty ? '：${rest.note}' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.read(databaseProvider).removeRestMark(date),
                      child: const Text('取消休息'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TemplateProgressRow extends ConsumerWidget {
  const _TemplateProgressRow({required this.summary, required this.progress});

  final WorkoutTemplateSummary summary;
  final TemplateProgress? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final definition = ref
        .watch(templateDefinitionProvider(summary.template.id))
        .value;
    final subtitle = definition == null
        ? '加载模板详情…'
        : definition.exercises.length == 1
        ? '${definition.exercises.single.exerciseNameSnapshot} · ${describeTemplateThresholds(definition)}'
        : '${definition.exercises.length} 个动作 · ${definition.sets.length} 个计划组';

    final tier = progress?.tier;
    final isDone = tier == PlanTier.min || tier == PlanTier.regular;

    final status = switch (tier) {
      null => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '未开始',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
      PlanTier.belowMin => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '已记录 ${progress!.regularCompleted}/${progress!.regularTotal} 组',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: scheme.onSecondaryContainer),
        ),
      ),
      PlanTier.min => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 15, color: scheme.primary),
            const SizedBox(width: 4),
            Text(
              '最低完成',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      PlanTier.regular => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 15, color: scheme.primary),
            const SizedBox(width: 4),
            Text(
              '常规完成',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      PlanTier.none => const SizedBox.shrink(),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDone
            ? scheme.primaryContainer.withValues(alpha: 0.3)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: isDone
            ? Border.all(color: scheme.primary.withValues(alpha: 0.25))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.version.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          status,
        ],
      ),
    );
  }
}

/// 日／周 RuleSet 进度；与上方单次训练模板完成度保持独立。
/// [date] 为空时跟随全局选中日期；周进度页翻周时传该周日期。
class RuleGoalsCard extends ConsumerWidget {
  const RuleGoalsCard({super.key, this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = date == null
        ? ref.watch(ruleSetProgressProvider)
        : ref.watch(ruleSetProgressForDateProvider(date!));
    final exercises = ref.watch(exercisesProvider).value ?? const <Exercise>[];
    final exerciseNames = {for (final e in exercises) e.id: e.name};
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.flag_rounded,
                    size: 18,
                    color: scheme.tertiary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '周期目标',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: '管理周期目标',
                  icon: const Icon(Icons.tune, size: 20),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RulesScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            progressAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('加载中…'),
              ),
              error: (_, _) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('周期目标加载失败'),
              ),
              data: (items) => items.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '当前日期没有生效的周期目标',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : Column(
                      children: [
                        for (final item in items)
                          _ruleProgressRow(context, item, exerciseNames),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ruleProgressRow(
    BuildContext context,
    RuleSetProgress item,
    Map<int, String> exerciseNames,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final evaluation = item.evaluation;
    final (icon, label, color) = switch (evaluation.status) {
      RuleResultStatus.passed => (Icons.check_circle, '已达成', scheme.primary),
      RuleResultStatus.partial => (Icons.timelapse, '进行中', scheme.secondary),
      RuleResultStatus.failed => (
        Icons.radio_button_unchecked,
        '未开始',
        scheme.onSurfaceVariant,
      ),
      RuleResultStatus.insufficientData => (
        Icons.help_outline,
        '数据不足',
        scheme.error,
      ),
    };
    RuleNode? expression;
    try {
      final raw = jsonDecode(item.ruleSet.expressionJson);
      if (raw is Map) {
        expression = RuleNode.fromJson(Map<String, Object?>.from(raw));
      }
    } catch (_) {
      expression = null;
    }
    final List<(RuleNode?, RuleEvaluation)> leaves;
    if (evaluation.children.isEmpty) {
      leaves = [
        if (evaluation.target != null ||
            evaluation.status == RuleResultStatus.insufficientData)
          (expression, evaluation),
      ];
    } else {
      final astChildren = switch (expression) {
        AllRule all => all.children,
        AnyRule any => any.children,
        _ => const <RuleNode>[],
      };
      leaves = [
        for (var i = 0; i < evaluation.children.length; i++)
          (
            i < astChildren.length ? astChildren[i] : null,
            evaluation.children[i],
          ),
      ];
    }
    final details = leaves
        .map((pair) => _formatRuleCondition(pair.$1, pair.$2, exerciseNames))
        .join(' · ');

    // 计算可视化完成度条（0..1）
    double? ratio;
    if (leaves.isNotEmpty) {
      final ratios = <double>[];
      for (final (_, leafEval) in leaves) {
        final a = leafEval.actual;
        final t = leafEval.target;
        if (a != null && t != null && t > 0) {
          ratios.add((a / t).clamp(0.0, 1.0));
        }
      }
      if (ratios.isNotEmpty) {
        ratio = ratios.reduce((a, b) => a + b) / ratios.length;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: evaluation.status == RuleResultStatus.passed
            ? scheme.primaryContainer.withValues(alpha: 0.3)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.ruleSet.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        details,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              HoiPill(label: label, color: color),
            ],
          ),
          if (ratio != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatRuleCondition(
    RuleNode? node,
    RuleEvaluation evaluation,
    Map<int, String> exerciseNames,
  ) {
    final valueText = _formatRuleValue(evaluation);
    if (node is! ComparisonRule || node.filters.isEmpty) {
      return valueText;
    }
    final filterParts = <String>[];
    final exerciseId = node.filters.exerciseId;
    final category = node.filters.category;
    final setRole = node.filters.setRole;
    if (exerciseId != null) {
      filterParts.add(exerciseNames[exerciseId] ?? '动作#$exerciseId');
    } else if (category != null) {
      final catLabel = ExerciseCategory.values
          .where((c) => c.name == category)
          .map((c) => c.label)
          .firstOrNull;
      if (catLabel != null) filterParts.add(catLabel);
    }
    if (setRole != null) {
      final roleLabel = SetRole.values
          .where((r) => r.name == setRole)
          .map((r) => r.label)
          .firstOrNull;
      if (roleLabel != null) filterParts.add(roleLabel);
    }
    if (filterParts.isEmpty) return valueText;
    return '${filterParts.join('·')} $valueText';
  }

  String _formatRuleValue(RuleEvaluation evaluation) {
    final actual = evaluation.actual;
    final target = evaluation.target;
    if (actual == null || target == null) return '数据不足';
    if (evaluation.unit == 'second') {
      final actualMinutes = actual / 60;
      final targetMinutes = target / 60;
      String minutes(num value) => value == value.roundToDouble()
          ? '${value.round()}'
          : value.toStringAsFixed(1);
      return '${minutes(actualMinutes)}/${minutes(targetMinutes)} 分钟';
    }
    final unit = switch (evaluation.unit) {
      'session' => '次',
      'set' => '组',
      'rep' => '次',
      'meter' => '米',
      _ => evaluation.unit ?? '',
    };
    return '$actual/$target $unit'.trim();
  }
}

/// 饮食分区：含「添加饮食」入口与当日摄入小字摘要（热量摘要不作主页焦点）
class FoodSection extends ConsumerWidget {
  const FoodSection({super.key, required this.entriesAsync});

  final AsyncValue<List<FoodEntry>> entriesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.restaurant_rounded,
                    size: 18,
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '饮食记录',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加饮食'),
                  onPressed: () => showAddFoodEntryDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 加载 / 错误 / 空 / 数据 分开呈现
            if (entriesAsync.hasError)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('饮食记录加载失败'),
              )
            else if (!entriesAsync.hasValue)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('加载中…'),
              )
            else
              ..._buildContent(context, ref, entriesAsync.value!),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<FoodEntry> entries,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final total = entries.fold<int>(0, (sum, e) => sum + e.calories);
    return [
      HoiPill(
        icon: Icons.local_fire_department_outlined,
        label: '当日摄入 $total kcal',
        color: scheme.secondary,
      ),
      if (entries.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '暂无记录',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        )
      else
        for (final mealType in MealType.values)
          ..._buildMealGroup(context, ref, entries, mealType),
    ];
  }

  List<Widget> _buildMealGroup(
    BuildContext context,
    WidgetRef ref,
    List<FoodEntry> entries,
    MealType mealType,
  ) {
    final group = entries.where((e) => e.mealType == mealType).toList();
    if (group.isEmpty) return const [];
    final scheme = Theme.of(context).colorScheme;
    return [
      const SizedBox(height: 10),
      Row(
        children: [
          Icon(
            HoiTheme.mealIcon(mealType),
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            mealType.label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      for (final e in group)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            child: ListTile(
              dense: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.only(left: 12, right: 4),
              title: Text(
                e.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text('${e.calories} kcal'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 19),
                tooltip: '删除',
                onPressed: () =>
                    ref.read(databaseProvider).deleteFoodEntry(e.id),
              ),
            ),
          ),
        ),
    ];
  }
}
