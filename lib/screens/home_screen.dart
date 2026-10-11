import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';
import '../widgets/add_entry_dialogs.dart';
import 'log_workout_screen.dart';
import 'plans_screen.dart';
import 'workout_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  static String formatDate(DateTime date) =>
      '${DateFormat('yyyy年M月d日').format(date)} ${_weekdays[date.weekday - 1]}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final foodEntries = ref.watch(foodEntriesProvider).value ?? [];
    final workouts = ref.watch(completedWorkoutsProvider).value ?? [];
    final ongoing = ref.watch(ongoingWorkoutProvider).value;

    final totalIntake =
        foodEntries.fold<int>(0, (sum, e) => sum + e.calories);

    return Scaffold(
      appBar: AppBar(
        title: const Text('饮食运动记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: '运动方案',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlansScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DateSwitcher(date: date),
          const SizedBox(height: 12),
          _WorkoutEntryButtons(ongoing: ongoing, selectedDate: date),
          const SizedBox(height: 12),
          const _TodayPlanCard(),
          const SizedBox(height: 12),
          _SummaryCard(totalIntake: totalIntake),
          const SizedBox(height: 16),
          const _WeeklyExerciseCard(),
          const SizedBox(height: 16),
          _FoodSection(entries: foodEntries),
          const SizedBox(height: 16),
          _WorkoutSection(workouts: workouts),
          // 给底部悬浮按钮留出空间
          const SizedBox(height: 120),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_food',
        icon: const Icon(Icons.add),
        label: const Text('添加饮食'),
        onPressed: () => showAddFoodEntryDialog(context),
      ),
    );
  }
}

/// 「开始运动」/「继续训练」与「补记运动」入口。
/// 查看历史日期时「开始运动」仍表示现在开始（归属今天），补记归属选中日期
class _WorkoutEntryButtons extends ConsumerWidget {
  const _WorkoutEntryButtons({required this.ongoing, required this.selectedDate});

  final Workout? ongoing;
  final DateTime selectedDate;

  /// 开始训练：有方案时先选择「自由训练 / 各方案」，选方案则写入快照
  Future<void> _startWorkout(BuildContext context, WidgetRef ref) async {
    final plans = ref.read(exercisePlansProvider).value ?? [];
    ExercisePlan? plan;
    if (plans.isNotEmpty) {
      const free = Object(); // 哨兵：区分「自由训练」与「取消」
      final choice = await showDialog<Object?>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('选择运动方案'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(free),
              child: const Text('自由训练（不关联方案）'),
            ),
            for (final p in plans)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(p),
                child: Text('${p.name}（${p.exerciseName}）'),
              ),
          ],
        ),
      );
      if (choice == null) return; // 用户取消
      if (choice is ExercisePlan) plan = choice;
    }
    await ref.read(databaseProvider).startWorkout(plan: plan);
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WorkoutScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            icon: Icon(ongoing == null ? Icons.play_arrow : Icons.directions_run),
            label: Text(ongoing == null ? '开始运动' : '继续训练'),
            onPressed: () {
              if (ongoing == null) {
                _startWorkout(context, ref);
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WorkoutScreen()),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.edit_note),
            label: const Text('补记运动'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LogWorkoutScreen(initialDate: selectedDate),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 「今日方案」卡片：各方案阈值与今日状态、休息标记入口（布局阶段 3 再重排）
class _TodayPlanCard extends ConsumerWidget {
  const _TodayPlanCard();

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
    final plans = ref.watch(exercisePlansProvider).value ?? [];
    final evals = ref.watch(dailyPlanEvaluationsProvider).value ?? {};
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
            if (plans.isEmpty)
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
              for (final p in plans) _planRow(context, p, evals[p.id]),
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

class _DateSwitcher extends ConsumerWidget {  const _DateSwitcher({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: '前一天',
          onPressed: () =>
              ref.read(selectedDateProvider.notifier).shift(-1),
        ),
        Text(
          HomeScreen.formatDate(date),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: '后一天',
          onPressed: () => ref.read(selectedDateProvider.notifier).shift(1),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totalIntake});

  final int totalIntake;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text('总摄入', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text('$totalIntake',
                style: Theme.of(context).textTheme.headlineSmall),
            Text('kcal', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _FoodSection extends ConsumerWidget {
  const _FoodSection({required this.entries});

  final List<FoodEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('饮食记录', style: Theme.of(context).textTheme.titleMedium),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('暂无记录'),
              )
            else
              for (final mealType in MealType.values)
                ..._buildMealGroup(context, ref, mealType),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMealGroup(
    BuildContext context,
    WidgetRef ref,
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

/// 当天已完成训练列表
class _WorkoutSection extends ConsumerWidget {
  const _WorkoutSection({required this.workouts});

  final List<Workout> workouts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('运动记录', style: Theme.of(context).textTheme.titleMedium),
            if (workouts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('暂无记录'),
              )
            else
              for (final w in workouts) _WorkoutTile(workout: w),
          ],
        ),
      ),
    );
  }
}

class _WorkoutTile extends ConsumerWidget {
  const _WorkoutTile({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises =
        ref.watch(workoutExercisesProvider(workout.id)).value ?? [];
    final names = exercises.map((e) => e.name).join('、');
    final total = workout.totalSeconds;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(names.isEmpty ? '（无动作记录）' : names),
      subtitle: Text(
        total != null ? '总用时 ${(total / 60).round()} 分钟' : '用时未记录',
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LogWorkoutScreen.editing(workout: workout),
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: '删除',
        onPressed: () => ref.read(databaseProvider).discardWorkout(workout.id),
      ),
    );
  }
}

/// 本周运动卡片：落实点阵 + 次数/时长目标进度
/// 次数按已完成训练计；时长只累计已记录总用时的训练，未知用时不推算
class _WeeklyExerciseCard extends ConsumerWidget {
  const _WeeklyExerciseCard();

  static const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final goals = ref.watch(weeklyGoalsProvider).value ??
        AppDatabase.defaultWeeklyGoals;
    final weekWorkouts = ref.watch(weekWorkoutsProvider).value ?? [];

    final weekStart = AppDatabase.weekStart(date);
    final weekEnd = weekStart.add(const Duration(days: 6));
    // 有已完成训练的日期集合，用于点亮落实点阵
    final activeDays =
        weekWorkouts.map((w) => AppDatabase.dateOnly(w.date)).toSet();
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
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: '编辑目标',
                  onPressed: () => showEditWeeklyGoalsDialog(context),
                ),
              ],
            ),
            Text(
              '${DateFormat('M月d日').format(weekStart)} – '
              '${DateFormat('M月d日').format(weekEnd)}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < 7; i++)
                  _WeekDayDot(
                    label: _weekdayLabels[i],
                    active: activeDays
                        .contains(weekStart.add(Duration(days: i))),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _GoalProgress(
              label: '运动次数',
              current: weekWorkouts.length,
              target: goals.targetSessions,
              unit: '次',
            ),
            const SizedBox(height: 12),
            _GoalProgress(
              label: '运动时长',
              current: totalMinutes,
              target: goals.targetMinutes,
              unit: '分钟',
            ),
          ],
        ),
      ),
    );
  }
}

/// 周内某一天的落实情况：有记录点亮，否则灰色
class _WeekDayDot extends StatelessWidget {
  const _WeekDayDot({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? scheme.primary : scheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

/// 单项目标进度条（自动封顶到 100%）
class _GoalProgress extends StatelessWidget {
  const _GoalProgress({
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
