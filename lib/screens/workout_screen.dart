import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';
import '../widgets/workout_dialogs.dart';

/// 进行中训练页：计时显示、暂停/继续、动作与组记录、结束或丢弃。
/// 计时的权威数据是数据库里的 startedAt/pausedAt/pausedSeconds，
/// 页面内的 Timer 每秒只刷新显示，不写数据库。
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _addExercise(Workout workout) async {
    final draft = await showAddWorkoutExerciseDialog(context);
    if (draft == null) return;
    await ref.read(databaseProvider).addWorkoutExercise(
          workout.id,
          name: draft.name,
          category: draft.category,
          note: draft.note,
        );
  }

  Future<void> _addSet(WorkoutExercise exercise) async {
    final draft = await showAddWorkoutSetDialog(context);
    if (draft == null) return;
    await ref.read(databaseProvider).addWorkoutSet(
          exercise.id,
          reps: draft.reps,
          durationSeconds: draft.durationSeconds,
          weightKg: draft.weightKg,
          note: draft.note,
        );
  }

  Future<void> _discard(Workout workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('丢弃训练'),
        content: const Text('将删除本场训练及已记录的动作和组，确定丢弃吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('丢弃'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(databaseProvider).discardWorkout(workout.id);
    // 进行中训练消失后由 build 里的监听自动退出本页
  }

  Future<void> _finish(
    Workout workout,
    List<WorkoutExercise> exercises,
    List<WorkoutSet> sets,
  ) async {
    final db = ref.read(databaseProvider);
    // 提前取 messenger，避免结束训练页面自动退出后跨异步间隙使用 context
    final messenger = ScaffoldMessenger.of(context);
    final hasValid = sets.any(AppDatabase.isValidSet);
    // 恰好一个动作且还没有任何组时，允许把计时记为该动作时长（需用户勾选）
    final singleEmptyExercise = exercises.length == 1 && sets.isEmpty;
    if (!hasValid && !singleEmptyExercise) {
      messenger.showSnackBar(
        const SnackBar(content: Text('至少需要一条有效组（次数或持续时间大于 0）才能结束训练')),
      );
      return;
    }
    final elapsed = AppDatabase.elapsedSeconds(workout);
    final result = await showDialog<({int? totalSeconds, String? feeling})>(
      context: context,
      builder: (_) => _FinishWorkoutDialog(
        elapsedSeconds: elapsed,
        creditExerciseName:
            singleEmptyExercise ? exercises.single.name : null,
      ),
    );
    if (result == null) return;
    try {
      await db.finishWorkout(
        workout.id,
        totalSeconds: result.totalSeconds,
        feeling: result.feeling,
      );
      // 关联了方案时按保存后的实际记录给出达标反馈
      final done = await db.getWorkout(workout.id);
      if (done != null && done.planMetric != null) {
        final ev = AppDatabase.evaluateWorkout(
          done,
          await db.getWorkoutExercises(done.id),
          await db.getWorkoutSets(done.id),
        );
        messenger.showSnackBar(
          SnackBar(content: Text(describePlanEvaluation(ev, done))),
        );
      }
    } on StateError {
      // 单一空动作但未勾选「计时记为时长」时仍无有效组
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('至少需要一条有效组（次数或持续时间大于 0）才能结束训练')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutAsync = ref.watch(ongoingWorkoutProvider);
    final workout = workoutAsync.value;

    // 训练被结束或丢弃后自动退出本页
    if (workoutAsync.hasValue && workout == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('进行中的训练'),
        actions: [
          if (workout != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '丢弃训练',
              onPressed: () => _discard(workout),
            ),
        ],
      ),
      body: workout == null
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(workout),
    );
  }

  Widget _buildBody(Workout workout) {
    final exercises =
        ref.watch(workoutExercisesProvider(workout.id)).value ?? [];
    final sets = ref.watch(workoutSetsProvider(workout.id)).value ?? [];
    final elapsed = AppDatabase.elapsedSeconds(workout);
    final paused = workout.pausedAt != null;
    final db = ref.read(databaseProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  formatElapsed(elapsed),
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                if (paused)
                  Text('已暂停', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                      label: Text(paused ? '继续' : '暂停'),
                      onPressed: () => paused
                          ? db.resumeWorkout(workout.id)
                          : db.pauseWorkout(workout.id),
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.stop),
                      label: const Text('结束训练'),
                      onPressed: () => _finish(workout, exercises, sets),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final exercise in exercises)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${exercise.name}（${exercise.category.label}）',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: '删除动作',
                        onPressed: () =>
                            db.deleteWorkoutExercise(exercise.id),
                      ),
                    ],
                  ),
                  for (final set
                      in sets.where((s) => s.exerciseId == exercise.id))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(describeSet(set)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: '删除组',
                        onPressed: () => db.deleteWorkoutSet(set.id),
                      ),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('添加组'),
                    onPressed: () => _addSet(exercise),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('添加动作'),
          onPressed: () => _addExercise(workout),
        ),
      ],
    );
  }
}

/// 结束训练对话框：可编辑总用时（分钟，预填计时值）与感受；
/// 单一空动作训练提供「将计时记为该动作时长」勾选项
class _FinishWorkoutDialog extends ConsumerStatefulWidget {
  const _FinishWorkoutDialog({
    required this.elapsedSeconds,
    required this.creditExerciseName,
  });

  final int elapsedSeconds;

  /// 非空表示可勾选把计时补记为该动作的一条时长组
  final String? creditExerciseName;

  @override
  ConsumerState<_FinishWorkoutDialog> createState() =>
      _FinishWorkoutDialogState();
}

class _FinishWorkoutDialogState
    extends ConsumerState<_FinishWorkoutDialog> {
  late final TextEditingController _minutesController;
  final _feelingController = TextEditingController();
  bool _creditToExercise = false;

  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController(
      text: (widget.elapsedSeconds / 60).round().toString(),
    );
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _feelingController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final minutesText = _minutesController.text.trim();
    final minutes = minutesText.isEmpty ? null : double.tryParse(minutesText);
    final feeling = _feelingController.text.trim();
    final workout = ref.read(ongoingWorkoutProvider).value;

    int? totalSeconds =
        minutes == null ? null : (minutes * 60).round();
    if (_creditToExercise && workout != null) {
      // 显式勾选后，把计时补为该动作的一条时长组（用完整秒数，不受分钟取整影响）
      final exercises =
          await ref.read(workoutExercisesProvider(workout.id).future);
      if (exercises.length == 1) {
        await ref.read(databaseProvider).addWorkoutSet(
              exercises.single.id,
              durationSeconds: widget.elapsedSeconds,
            );
      }
      totalSeconds ??= widget.elapsedSeconds;
    }
    if (!mounted) return;
    Navigator.of(context).pop((
      totalSeconds: totalSeconds,
      feeling: feeling.isEmpty ? null : feeling,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final creditMinutes = (widget.elapsedSeconds / 60).round();
    return AlertDialog(
      title: const Text('结束训练'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _minutesController,
            decoration: const InputDecoration(labelText: '训练总用时（分钟）'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _feelingController,
            decoration: const InputDecoration(labelText: '感受（可选）'),
          ),
          if (widget.creditExerciseName != null)
            CheckboxListTile(
              value: _creditToExercise,
              onChanged: (v) =>
                  setState(() => _creditToExercise = v ?? false),
              title: Text(
                  '将计时 $creditMinutes 分钟记为「${widget.creditExerciseName}」的时长'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('结束')),
      ],
    );
  }
}
