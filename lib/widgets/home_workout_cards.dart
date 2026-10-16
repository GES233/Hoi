import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';
import '../screens/log_workout_screen.dart';
import '../screens/workout_screen.dart';
import 'workout_dialogs.dart';

/// 「开始运动」、「补记运动」与单项运动入口。
/// 选中今天时「开始运动」为主按钮；查看历史日期时「补记运动」为主按钮，
/// 「开始运动」仍代表从现在开始计时（归属今天，数据层已保证）。
/// 已有进行中训练时隐藏「开始运动」，由进行中训练卡提供继续入口
class WorkoutEntryButtons extends ConsumerWidget {
  const WorkoutEntryButtons({
    super.key,
    required this.ongoing,
    required this.selectedDate,
  });

  final Workout? ongoing;
  final DateTime selectedDate;

  /// 开始训练：有模板时先选择「自由训练 / 各模板」。
  Future<void> _startWorkout(BuildContext context, WidgetRef ref) async {
    final templates = ref.read(workoutTemplatesProvider).value ?? [];
    TemplateVersion? templateVersion;
    if (templates.isNotEmpty) {
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
            for (final summary in templates)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(summary.version),
                child: Text(summary.version.name),
              ),
          ],
        ),
      );
      if (choice == null) return; // 用户取消
      if (choice is TemplateVersion) templateVersion = choice;
    }
    await ref
        .read(databaseProvider)
        .startWorkout(
          now: ref.read(appClockProvider)(),
          templateVersion: templateVersion,
        );
    if (context.mounted) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const WorkoutScreen()));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isToday =
        selectedDate == AppDatabase.dateOnly(ref.watch(appClockProvider)());
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
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('记录单项运动'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    LogWorkoutScreen.singleExercise(initialDate: selectedDate),
              ),
            ),
          ),
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
class OngoingWorkoutCard extends StatelessWidget {
  const OngoingWorkoutCard({super.key, required this.workout});

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
                  Text('训练进行中', style: Theme.of(context).textTheme.titleSmall),
                  Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('继续训练'),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const WorkoutScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

/// 当天已完成训练列表
class WorkoutSection extends ConsumerWidget {
  const WorkoutSection({super.key, required this.workoutsAsync});

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
              for (final w in workoutsAsync.value!) WorkoutTile(workout: w),
          ],
        ),
      ),
    );
  }
}

class WorkoutTile extends ConsumerWidget {
  const WorkoutTile({super.key, required this.workout});

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
        total != null ? '总用时 ${formatRecordedSeconds(total)}' : '用时未记录',
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
