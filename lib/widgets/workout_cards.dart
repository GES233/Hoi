import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';
import 'set_stopwatch.dart';
import 'workout_dialogs.dart';

/// 关联方案的实时进度卡：按方案快照对当前已记录内容实时评估；
/// 达到最低时整卡变为成功态，并弹出一次「最低方案已完成」反馈
/// （是否已反馈由外层经 minDoneNotified / onMinDone 维护，避免重复弹 SnackBar）
class PlanProgressCard extends StatelessWidget {
  const PlanProgressCard({
    super.key,
    required this.workout,
    required this.exercises,
    required this.sets,
    required this.minDoneNotified,
    required this.onMinDone,
  });

  final Workout workout;
  final List<WorkoutExercise> exercises;
  final List<WorkoutSet> sets;

  /// 本次进入页面后是否已反馈过「最低方案完成」
  final bool minDoneNotified;

  /// 最低方案首次完成时回调（外层据此标记已反馈）
  final VoidCallback onMinDone;

  @override
  Widget build(BuildContext context) {
    final ev = AppDatabase.evaluateWorkout(workout, exercises, sets);
    final isDuration = workout.planMetric == PlanMetric.duration;
    final min = workout.planMin ?? 0;
    final regular = workout.planRegular ?? 0;
    String fmt(int v) => isDuration ? '${v ~/ 60} 分钟' : '$v 组';
    final minDone =
        ev.tier == PlanTier.min || ev.tier == PlanTier.regular;
    final regularDone = ev.tier == PlanTier.regular;

    if (minDone && !minDoneNotified) {
      onMinDone();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('今天的最低方案已完成')),
          );
        }
      });
    }

    final scheme = Theme.of(context).colorScheme;
    Widget statusLine(String label, int target, bool done) {
      // 进度按指标单位显示：时长换算为分钟，组数直接显示
      final progress = isDuration
          ? '${ev.actual ~/ 60} / ${target ~/ 60} 分钟'
          : '${ev.actual} / $target 组';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ${fmt(target)}'),
          const SizedBox(width: 8),
          if (done)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check, size: 16, color: scheme.primary),
              const SizedBox(width: 2),
              const Text('已完成'),
            ])
          else
            Text(
              progress,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
        ],
      );
    }

    return Card(
      color: minDone ? scheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('关联方案：${workout.planName ?? ''}',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            statusLine('最低', min, minDone),
            statusLine('常规', regular, regularDone),
          ],
        ),
      ),
    );
  }
}

/// 单个动作卡：组序号 + 汇总 + 组级小秒表
/// （全场至多一个组在计时，其他动作的「开始一组」此时禁用；
/// 计时状态由外层页面经 timingExerciseId / stopwatch / 各回调传入）
class ExerciseCard extends ConsumerWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.sets,
    required this.timingExerciseId,
    required this.stopwatch,
    required this.onStartTiming,
    required this.onToggleSetPause,
    required this.onFinishSetTiming,
  });

  final WorkoutExercise exercise;

  /// 本次训练的全部组（卡内按 exerciseId 过滤）
  final List<WorkoutSet> sets;

  /// 正在计时的动作 id（全场至多一个）；null 表示无组在计时
  final int? timingExerciseId;

  /// 正在计时的组级秒表；仅 timingExerciseId 非空时有效
  final SetStopwatch? stopwatch;

  final ValueChanged<WorkoutExercise> onStartTiming;
  final VoidCallback onToggleSetPause;
  final ValueChanged<WorkoutExercise> onFinishSetTiming;

  /// 添加组：预填该动作上一组的数值，便于抗阻训练快速录入
  Future<void> _addSet(WidgetRef ref) async {
    final exerciseSets = sets.where((s) => s.exerciseId == exercise.id);
    final draft = await showAddWorkoutSetDialog(
      ref.context,
      prefill: exerciseSets.isEmpty ? null : exerciseSets.last,
    );
    if (draft == null) return;
    await ref.read(databaseProvider).addWorkoutSet(
          exercise.id,
          reps: draft.reps,
          durationSeconds: draft.durationSeconds,
          weightKg: draft.weightKg,
          note: draft.note,
        );
  }

  /// 再来一组：直接复制上一组的次数 / 时长 / 重量保存（不带备注）
  Future<void> _repeatLastSet(WidgetRef ref, WorkoutSet last) async {
    await ref.read(databaseProvider).addWorkoutSet(
          exercise.id,
          reps: last.reps,
          durationSeconds: last.durationSeconds,
          weightKg: last.weightKg,
        );
  }

  /// 编辑已保存的组：次数 / 时长 / 重量 / 备注均可修改，
  /// 例如一组内先做完整版再做退阶，可事后在备注里补充
  Future<void> _editSet(WidgetRef ref, WorkoutSet set) async {
    final draft = await showEditWorkoutSetDialog(ref.context, set);
    if (draft == null) return;
    await ref.read(databaseProvider).updateWorkoutSet(
          set.id,
          reps: Value(draft.reps),
          durationSeconds: Value(draft.durationSeconds),
          weightKg: Value(draft.weightKg),
          note: Value(draft.note),
        );
  }

  /// 滑动删除一组，SnackBar 提供撤销；撤销会追加到末尾，不恢复原顺序
  Future<void> _deleteSetWithUndo(
      BuildContext context, WidgetRef ref, WorkoutSet set) async {
    final db = ref.read(databaseProvider);
    await db.deleteWorkoutSet(set.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已删除一组'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () => db.addWorkoutSet(
            set.exerciseId,
            reps: set.reps,
            durationSeconds: set.durationSeconds,
            weightKg: set.weightKg,
            note: set.note,
          ),
        ),
      ),
    );
  }

  /// 删除动作需确认：会级联删除该动作已记录的全部组
  Future<void> _confirmDeleteExercise(WidgetRef ref, int setCount) async {
    final confirmed = await showDialog<bool>(
      context: ref.context,
      builder: (context) => AlertDialog(
        title: const Text('删除动作'),
        content: Text(
            '将删除「${exercise.name}」及其已记录的 $setCount 组，确定删除吗？'),
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
      await ref.read(databaseProvider).deleteWorkoutExercise(exercise.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTimingThis = timingExerciseId == exercise.id;
    final isTimingOther = timingExerciseId != null && !isTimingThis;
    final exerciseSets =
        sets.where((s) => s.exerciseId == exercise.id).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          exercise.name,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        exercise.category.label,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: '动作操作',
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'delete', child: Text('删除动作')),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDeleteExercise(ref, exerciseSets.length);
                    }
                  },
                ),
              ],
            ),
            if (exerciseSets.isNotEmpty)
              Text(
                _summarizeSets(exerciseSets),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            for (var i = 0; i < exerciseSets.length; i++)
              _setRow(context, ref, exerciseSets[i], i),
            // 计时的组变成高亮条，计时期间隐藏「添加组」避免一行挤四个控件
            if (isTimingThis)
              _timingBar(context, exerciseSets.length + 1)
            else
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('添加组'),
                    onPressed: () => _addSet(ref),
                  ),
                  if (exerciseSets.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.repeat, size: 18),
                      label: const Text('再来一组'),
                      onPressed: () => _repeatLastSet(ref, exerciseSets.last),
                    ),
                  const Spacer(),
                  Tooltip(
                    message: isTimingOther ? '请先完成正在计时的组' : '计时并保存为一组时长',
                    child: TextButton.icon(
                      icon: const Icon(Icons.timer_outlined, size: 18),
                      label: const Text('开始一组'),
                      onPressed: isTimingOther
                          ? null
                          : () => onStartTiming(exercise),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// 单组行：带序号，点按编辑，左滑删除并在 SnackBar 中提供撤销
  Widget _setRow(
      BuildContext context, WidgetRef ref, WorkoutSet set, int index) {
    return Dismissible(
      key: ValueKey('set-${set.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Icon(Icons.delete_outline,
            color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => _deleteSetWithUndo(context, ref, set),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text('第 ${index + 1} 组　${describeSet(set)}'),
        trailing: Icon(Icons.edit_outlined,
            size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        onTap: () => _editSet(ref, set),
      ),
    );
  }

  /// 组级秒表计时中的高亮条：组序号 + 大读数（等宽数字）+ 暂停本组 / 完成本组
  Widget _timingBar(BuildContext context, int setIndex) {
    final stopwatch = this.stopwatch!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text('第 $setIndex 组',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(width: 12),
          Text(
            formatElapsed(stopwatch.elapsedSeconds()),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: scheme.onSecondaryContainer,
                fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const Spacer(),
          TextButton(
            onPressed: onToggleSetPause,
            child: Text(stopwatch.isPaused ? '继续本组' : '暂停本组'),
          ),
          FilledButton.tonal(
            onPressed: () => onFinishSetTiming(exercise),
            child: const Text('完成本组'),
          ),
        ],
      ),
    );
  }

  /// 动作卡汇总：「N 组 · 共 X 次 · 共 Y 秒/分钟」（只显示出现过的指标）
  static String _summarizeSets(List<WorkoutSet> sets) {
    final reps = sets.fold<int>(0, (sum, s) => sum + (s.reps ?? 0));
    final seconds =
        sets.fold<int>(0, (sum, s) => sum + (s.durationSeconds ?? 0));
    final parts = <String>['${sets.length} 组'];
    if (reps > 0) parts.add('共 $reps 次');
    if (seconds > 0) {
      parts.add(seconds >= 60
          ? '共 ${(seconds / 60).toStringAsFixed(seconds % 60 == 0 ? 0 : 1)} 分钟'
          : '共 $seconds 秒');
    }
    return parts.join(' · ');
  }
}
