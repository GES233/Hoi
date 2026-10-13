import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../domain/rules/rule_evaluator.dart';
import '../providers/app_providers.dart';
import '../screens/plans_screen.dart';
import '../screens/rules_screen.dart';
import 'add_entry_dialogs.dart';
import 'week_strip.dart';

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('今日方案', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (rest == null)
                  TextButton.icon(
                    icon: const Icon(Icons.bedtime_outlined, size: 18),
                    label: const Text('今天休息'),
                    onPressed: () => _markRest(context, ref, date),
                  ),
              ],
            ),
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
              Row(
                children: [
                  const Expanded(child: Text('尚未设置最低方案')),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PlansScreen()),
                    ),
                    child: const Text('去创建'),
                  ),
                ],
              )
            else
              for (final summary in templatesAsync.value!)
                _TemplateProgressRow(
                  summary: summary,
                  progress: progressAsync.value?[summary.template.id],
                ),
            if (rest != null)
              Row(
                children: [
                  const Icon(Icons.bedtime, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '已标记休息'
                      '${rest.note != null && rest.note!.isNotEmpty ? '：${rest.note}' : ''}',
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(databaseProvider).removeRestMark(date),
                    child: const Text('取消休息'),
                  ),
                ],
              ),
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
    final status = switch (progress?.tier) {
      null => Text('未开始', style: TextStyle(color: scheme.onSurfaceVariant)),
      PlanTier.belowMin => Text(
        '已记录 ${progress!.regularCompleted}/${progress!.regularTotal} 组',
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
      PlanTier.min => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 16, color: scheme.primary),
          const SizedBox(width: 4),
          const Text('最低完成'),
        ],
      ),
      PlanTier.regular => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: scheme.primary),
          const SizedBox(width: 4),
          const Text('常规完成'),
        ],
      ),
      PlanTier.none => const SizedBox.shrink(),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.version.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          status,
        ],
      ),
    );
  }
}

/// 日／周 RuleSet 进度；与上方单次训练模板完成度保持独立。
class RuleGoalsCard extends ConsumerWidget {
  const RuleGoalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(ruleSetProgressProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('周期目标', style: Theme.of(context).textTheme.titleMedium),
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
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('当前日期没有生效的周期目标'),
                    )
                  : Column(
                      children: [
                        for (final item in items)
                          _ruleProgressRow(context, item),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ruleProgressRow(BuildContext context, RuleSetProgress item) {
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
    final details = evaluation.children.map(_formatRuleValue).join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.ruleSet.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (details.isNotEmpty)
                  Text(details, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('饮食记录', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加饮食'),
                  onPressed: () => showAddFoodEntryDialog(context),
                ),
              ],
            ),
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
    final total = entries.fold<int>(0, (sum, e) => sum + e.calories);
    return [
      Text('当日摄入 $total kcal', style: Theme.of(context).textTheme.labelSmall),
      if (entries.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('暂无记录'),
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
    return [
      const Divider(),
      Text(mealType.label, style: Theme.of(context).textTheme.titleSmall),
      for (final e in group)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(e.name),
          subtitle: Text('${e.calories} kcal'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '删除',
            onPressed: () => ref.read(databaseProvider).deleteFoodEntry(e.id),
          ),
        ),
    ];
  }
}

/// 本周运动概览 + 点阵图例（目标统一由上方 RuleSet 卡片负责）。
/// 时长只累计已记录总用时的训练，未知用时不推算。
class WeeklyExerciseCard extends ConsumerWidget {
  const WeeklyExerciseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final weekAsync = ref.watch(weekWorkoutsProvider);

    final weekStart = AppDatabase.weekStart(date);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekWorkouts = weekAsync.value ?? [];
    final totalSeconds = weekWorkouts.fold<int>(
      0,
      (sum, w) => sum + (w.totalSeconds ?? 0),
    );
    final totalMinutes = totalSeconds ~/ 60;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('本周运动', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            Text(
              '${DateFormat('M月d日').format(weekStart)} – '
              '${DateFormat('M月d日').format(weekEnd)}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            // 加载 / 错误 / 数据 分开呈现
            if (weekAsync.hasError)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('本周统计加载失败'),
              )
            else if (!weekAsync.hasValue)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('加载中…'),
              )
            else ...[
              const SizedBox(height: 12),
              Text(
                '${weekWorkouts.length} 次 · 已记录 $totalMinutes 分钟',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              // 顶部周条点阵的图例
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _legendItem(context, DailyStatus.none, '无记录'),
                  _legendItem(context, DailyStatus.recorded, '有记录'),
                  _legendItem(context, DailyStatus.minDone, '最低达标'),
                  _legendItem(context, DailyStatus.regularDone, '常规达标'),
                  _legendItem(context, DailyStatus.rest, '休息'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _legendItem(
    BuildContext context,
    DailyStatus status,
    String label,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 14,
        height: 14,
        child: Center(child: StatusDot(status: status)),
      ),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}
