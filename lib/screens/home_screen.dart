import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';
import '../widgets/add_entry_dialogs.dart';
import 'log_workout_screen.dart';
import 'plans_screen.dart';
import 'workout_screen.dart';

/// 首页：行动入口优先，不使用悬浮按钮。
/// 顺序：周条（选日期 + 本周落实点阵，非今天可回今天）→ 今日方案 →
/// 开始/补记入口 → 进行中的训练（与选中日期无关）→ 当日运动记录 →
/// 饮食入口与摘要 → 本周概览（次数/时长进度 + 点阵图例）
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  static String formatDate(DateTime date) =>
      '${DateFormat('yyyy年M月d日').format(date)} ${_weekdays[date.weekday - 1]}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final foodAsync = ref.watch(foodEntriesProvider);
    final workoutsAsync = ref.watch(completedWorkoutsProvider);
    final ongoingAsync = ref.watch(ongoingWorkoutProvider);
    final ongoing = ongoingAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('饮食运动记录'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlansScreen()),
            ),
            child: const Text('方案'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WeekStrip(date: date),
          const SizedBox(height: 12),
          const _TodayPlanCard(),
          const SizedBox(height: 12),
          _WorkoutEntryButtons(ongoing: ongoing, selectedDate: date),
          if (ongoingAsync.hasError)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('进行中训练状态加载失败'),
            )
          else if (ongoing != null) ...[
            const SizedBox(height: 12),
            _OngoingWorkoutCard(workout: ongoing),
          ],
          const SizedBox(height: 12),
          _WorkoutSection(workoutsAsync: workoutsAsync),
          const SizedBox(height: 12),
          _FoodSection(entriesAsync: foodAsync),
          const SizedBox(height: 12),
          const _WeeklyExerciseCard(),
        ],
      ),
    );
  }
}

/// 周条：一行同时承担「选日期」与「看本周落实」。
/// 左右箭头或横向滑动按周切换；点击日期文本弹 DatePicker；
/// 未来日期不可选，也不允许切到本周之后
class _WeekStrip extends ConsumerWidget {
  const _WeekStrip({required this.date});

  final DateTime date;

  static const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final today = AppDatabase.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: date.isAfter(today) ? today : date,
      firstDate: DateTime(2020),
      lastDate: today,
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).select(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = ref.watch(weekDailyStatusProvider).value ?? {};
    final today = AppDatabase.dateOnly(DateTime.now());
    final weekStart = AppDatabase.weekStart(date);
    final isToday = date == today;
    // 不允许切到本周之后
    final canGoNext = !weekStart
        .add(const Duration(days: 7))
        .isAfter(AppDatabase.weekStart(today));
    final notifier = ref.read(selectedDateProvider.notifier);

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: '上一周',
              visualDensity: VisualDensity.compact,
              onPressed: () => notifier.shift(-7),
            ),
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(context, ref),
                child: Center(
                  child: Text(
                    HomeScreen.formatDate(date),
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            if (!isToday)
              TextButton(
                onPressed: notifier.goToday,
                child: const Text('回到今天'),
              ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: '下一周',
              visualDensity: VisualDensity.compact,
              onPressed: canGoNext ? () => notifier.shift(7) : null,
            ),
          ],
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v < -150) {
              if (canGoNext) notifier.shift(7);
            } else if (v > 150) {
              notifier.shift(-7);
            }
          },
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                _dayCell(
                  context,
                  ref,
                  weekStart.add(Duration(days: i)),
                  statuses[weekStart.add(Duration(days: i))] ??
                      DailyStatus.none,
                  today,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 单日格子：星期标签 + 日期数字（选中为实心圆、今天加下划线）+ 状态点
  Widget _dayCell(BuildContext context, WidgetRef ref, DateTime day,
      DailyStatus status, DateTime today) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = day == date;
    final isToday = day == today;
    final isFuture = day.isAfter(today);
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    return Expanded(
      child: InkWell(
        onTap: isFuture
            ? null
            : () => ref.read(selectedDateProvider.notifier).select(day),
        child: Column(
          children: [
            Text(_weekdayLabels[day.weekday - 1], style: labelStyle),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? scheme.primary : null,
              ),
              child: Center(
                child: Container(
                  decoration: isToday && !isSelected
                      ? BoxDecoration(
                          border: Border(
                            bottom:
                                BorderSide(color: scheme.primary, width: 2),
                          ),
                        )
                      : null,
                  child: Text(
                    '${day.day}',
                    style: labelStyle?.copyWith(
                      color: isFuture
                          ? scheme.outline
                          : isSelected
                              ? scheme.onPrimary
                              : null,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 14,
              child: Center(child: _StatusDot(status: status)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 周条与图例共用的状态点：无记录（空心灰）/ 有记录未达最低（浅绿描边）/
/// 最低达标（实心绿）/ 常规达标（实心绿 + 外圈）/ 休息（小月亮）。
/// 不使用红色或叉号，未达标不表达为失败
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final DailyStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case DailyStatus.rest:
        return Icon(Icons.bedtime_outlined, size: 12, color: scheme.secondary);
      case DailyStatus.minDone:
        return _circle(color: scheme.primary);
      case DailyStatus.regularDone:
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: scheme.primary, width: 1.5),
          ),
          child: Center(child: _circle(size: 8, color: scheme.primary)),
        );
      case DailyStatus.recorded:
        return _circle(border: scheme.primary);
      case DailyStatus.noPlan:
      case DailyStatus.none:
        return _circle(border: scheme.outlineVariant);
    }
  }

  static Widget _circle({double size = 10, Color? color, Color? border}) =>
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: border != null ? Border.all(color: border, width: 1.5) : null,
        ),
      );
}

/// 「开始运动」与「补记运动」入口。
/// 选中今天时「开始运动」为主按钮；查看历史日期时「补记运动」为主按钮，
/// 「开始运动」仍代表从现在开始计时（归属今天，数据层已保证）。
/// 已有进行中训练时隐藏「开始运动」，由进行中训练卡提供继续入口
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
    final isToday = selectedDate == AppDatabase.dateOnly(DateTime.now());
    final startButton = isToday
        ? FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('开始运动'),
            onPressed: () => _startWorkout(context, ref),
          )
        : OutlinedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('开始运动'),
            onPressed: () => _startWorkout(context, ref),
          );
    final logButton = isToday
        ? OutlinedButton.icon(
            icon: const Icon(Icons.edit_note),
            label: const Text('补记运动'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LogWorkoutScreen(initialDate: selectedDate),
              ),
            ),
          )
        : FilledButton.icon(
            icon: const Icon(Icons.edit_note),
            label: const Text('补记运动'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LogWorkoutScreen(initialDate: selectedDate),
              ),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (ongoing == null) ...[
              Expanded(child: startButton),
              const SizedBox(width: 12),
            ],
            Expanded(child: logButton),
          ],
        ),
        if (!isToday && ongoing == null)
          Text(
            '「开始运动」从现在开始计时；补记归属选中日期',
            style: Theme.of(context).textTheme.labelSmall,
          ),
      ],
    );
  }
}

/// 进行中的训练卡：只反映「现在」，与选中日期无关。
/// 显示开始时间与暂停状态而不挂秒表，避免首页常驻定时器
class _OngoingWorkoutCard extends StatelessWidget {
  const _OngoingWorkoutCard({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final startedAt = workout.startedAt;
    final subtitle = startedAt == null
        ? '计时信息缺失'
        : '开始于 ${DateFormat('HH:mm').format(startedAt)}'
            '${workout.pausedAt != null ? ' · 已暂停' : ''}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.directions_run),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('训练进行中',
                      style: Theme.of(context).textTheme.titleSmall),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('继续训练'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WorkoutScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 「今日方案」卡片：各方案阈值与选中日期状态、休息标记入口
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
class _FoodSection extends ConsumerWidget {
  const _FoodSection({required this.entriesAsync});

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

/// 当天已完成训练列表
class _WorkoutSection extends ConsumerWidget {
  const _WorkoutSection({required this.workoutsAsync});

  final AsyncValue<List<Workout>> workoutsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('运动记录', style: Theme.of(context).textTheme.titleMedium),
            // 加载 / 错误 / 空 / 数据 分开呈现
            if (workoutsAsync.hasError)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('运动记录加载失败'),
              )
            else if (!workoutsAsync.hasValue)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('加载中…'),
              )
            else if (workoutsAsync.value!.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('暂无记录'),
              )
            else
              for (final w in workoutsAsync.value!) _WorkoutTile(workout: w),
          ],
        ),
      ),
    );
  }
}

class _WorkoutTile extends ConsumerWidget {
  const _WorkoutTile({required this.workout});

  final Workout workout;

  /// 删除训练需确认：会级联删除动作与组，且不可撤销
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除训练'),
        content: const Text('将删除这次训练及其全部动作和组记录，确定删除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(databaseProvider).discardWorkout(workout.id);
    }
  }

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
        onPressed: () => _confirmDelete(context, ref),
      ),
    );
  }
}

/// 本周运动卡片：次数/时长目标进度 + 点阵图例（点阵本身在顶部周条）。
/// 次数按已完成训练计；时长只累计已记录总用时的训练，未知用时不推算
class _WeeklyExerciseCard extends ConsumerWidget {
  const _WeeklyExerciseCard();

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
            child: Center(child: _StatusDot(status: status)),
          ),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      );
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
