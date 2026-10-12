import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';
import '../screens/plans_screen.dart';
import 'add_entry_dialogs.dart';
import 'week_strip.dart';

/// 「今日方案」卡片：各方案阈值与选中日期状态、休息标记入口
class TodayPlanCard extends ConsumerWidget {
  const TodayPlanCard({super.key});

  /// 标记休息：可选备注；返回 null 表示取消
  Future<void> _markRest(
      BuildContext context, WidgetRef ref, DateTime date) async {
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

  /// 单个方案的今日状态行：未开始 / 未达最低 / 最低完成 / 常规完成
  Widget _planRow(BuildContext context, ExercisePlan p, PlanEvaluation? ev) {
    final scheme = Theme.of(context).colorScheme;
    final isDuration = p.metric == PlanMetric.duration;
    String fmt(int v) => isDuration ? '${v ~/ 60} 分钟' : '$v 组';
    final Widget status;
    switch (ev?.tier) {
      case null:
        status = Text('未开始',
            style: TextStyle(color: scheme.onSurfaceVariant));
      case PlanTier.belowMin:
        status = Text(
          '未达最低（${fmt(ev!.actual)}/${fmt(p.minThreshold)}）',
          style: TextStyle(color: scheme.onSurfaceVariant),
        );
      case PlanTier.min:
        status = Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check, size: 16, color: scheme.primary),
          const SizedBox(width: 4),
          const Text('最低完成'),
        ]);
      case PlanTier.regular:
        status = Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, size: 16, color: scheme.primary),
          const SizedBox(width: 4),
          const Text('常规完成'),
        ]);
      case PlanTier.none:
        status = const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  '${p.exerciseName} · ${describePlanThresholds(p)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          status,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final plansAsync = ref.watch(exercisePlansProvider);
    final evalsAsync = ref.watch(dailyPlanEvaluationsProvider);
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
            if (plansAsync.hasError || evalsAsync.hasError)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('方案状态加载失败'),
              )
            else if (!plansAsync.hasValue)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('加载中…'),
              )
            else if (plansAsync.value!.isEmpty)
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
              for (final p in plansAsync.value!)
                _planRow(context, p, evalsAsync.value?[p.id]),
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
      Text(
        '当日摄入 $total kcal',
        style: Theme.of(context).textTheme.labelSmall,
      ),
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
    final group =
        entries.where((e) => e.mealType == mealType).toList();
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
            onPressed: () =>
                ref.read(databaseProvider).deleteFoodEntry(e.id),
          ),
        ),
    ];
  }
}

/// 本周运动卡片：次数/时长目标进度 + 点阵图例（点阵本身在顶部周条）。
/// 次数按已完成训练计；时长只累计已记录总用时的训练，未知用时不推算
class WeeklyExerciseCard extends ConsumerWidget {
  const WeeklyExerciseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final goalsAsync = ref.watch(weeklyGoalsProvider);
    final weekAsync = ref.watch(weekWorkoutsProvider);
    final goals = goalsAsync.value ?? AppDatabase.defaultWeeklyGoals;

    final weekStart = AppDatabase.weekStart(date);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekWorkouts = weekAsync.value ?? [];
    final totalSeconds = weekWorkouts.fold<int>(
        0, (sum, w) => sum + (w.totalSeconds ?? 0));
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
                const Spacer(),
                TextButton(
                  onPressed: () => showEditWeeklyGoalsDialog(context),
                  child: const Text('调整目标'),
                ),
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
              GoalProgress(
                label: '运动次数',
                current: weekWorkouts.length,
                target: goals.targetSessions,
                unit: '次',
              ),
              const SizedBox(height: 12),
              GoalProgress(
                label: '运动时长',
                current: totalMinutes,
                target: goals.targetMinutes,
                unit: '分钟',
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
          BuildContext context, DailyStatus status, String label) =>
      Row(
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

/// 单项目标进度条（自动封顶到 100%）
class GoalProgress extends StatelessWidget {
  const GoalProgress({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
  });

  final String label;
  final int current;
  final int target;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final value =
        target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            Text(
              '$current / $target $unit',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}
