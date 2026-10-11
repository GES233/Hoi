import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';
import '../widgets/set_stopwatch.dart';
import '../widgets/workout_dialogs.dart';

/// 进行中训练页：动作与组记录为主体；训练总用时降级为顶部紧凑一行。
/// 训练级计时的权威数据是数据库里的 startedAt/pausedAt/pausedSeconds，
/// 页面内的 Timer 每秒只刷新显示，不写数据库。
/// 组级小秒表（SetStopwatch）只存页面内存、不落库：
/// 应用被杀会丢失正在走的这一组，这是与开发者确认的既定取舍。
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  Timer? _ticker;

  /// 正在计时的组（全场至多一个）；仅页面内存，见类注释
  SetStopwatch? _stopwatch;
  int? _timingExerciseId;

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

  /// 开始一组计时；时钟来自 provider，测试可注入假时钟
  void _startSetTiming(WorkoutExercise exercise) {
    final stopwatch = SetStopwatch(now: ref.read(setStopwatchClockProvider));
    stopwatch.start();
    setState(() {
      _stopwatch = stopwatch;
      _timingExerciseId = exercise.id;
    });
  }

  /// 暂停/继续当前组计时
  void _toggleSetPause() {
    final stopwatch = _stopwatch;
    if (stopwatch == null) return;
    setState(() {
      stopwatch.isPaused ? stopwatch.resume() : stopwatch.pause();
    });
  }

  /// 结束并保存：把实际秒数直接写为一条时长组记录（可删除，不弹确认）；
  /// 不足 1 秒不构成有效组，提示且不保存
  Future<void> _finishSetTiming(WorkoutExercise exercise) async {
    final stopwatch = _stopwatch;
    if (stopwatch == null) return;
    final seconds = stopwatch.stop();
    setState(() {
      _stopwatch = null;
      _timingExerciseId = null;
    });
    if (seconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('计时不足 1 秒，未保存该组')),
      );
      return;
    }
    await ref
        .read(databaseProvider)
        .addWorkoutSet(exercise.id, durationSeconds: seconds);
  }

  /// 训练级暂停/继续；暂停训练时自动暂停进行中的组计时，
  /// 恢复训练不自动恢复组计时，由用户在动作卡上手动继续
  void _togglePause(Workout workout) {
    final db = ref.read(databaseProvider);
    if (workout.pausedAt != null) {
      db.resumeWorkout(workout.id);
    } else {
      _stopwatch?.pause();
      db.pauseWorkout(workout.id);
    }
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
        // 训练总用时降级为紧凑一行，不占视觉中心；暂停/继续/结束语义不变
        Row(
          children: [
            Text(
              '总用时 ${formatElapsed(elapsed)}${paused ? ' · 已暂停' : ''}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            TextButton.icon(
              icon: Icon(paused ? Icons.play_arrow : Icons.pause, size: 18),
              label: Text(paused ? '继续' : '暂停'),
              onPressed: () => _togglePause(workout),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.stop, size: 18),
              label: const Text('结束训练'),
              onPressed: () => _finish(workout, exercises, sets),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final exercise in exercises)
          _exerciseCard(context, exercise, sets, db),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('添加动作'),
          onPressed: () => _addExercise(workout),
        ),
      ],
    );
  }

  /// 单个动作卡：已有组列表 + 添加组 + 组级小秒表
  /// （全场至多一个组在计时，其他动作的「开始一组」此时禁用）
  Widget _exerciseCard(
    BuildContext context,
    WorkoutExercise exercise,
    List<WorkoutSet> sets,
    AppDatabase db,
  ) {
    final isTimingThis = _timingExerciseId == exercise.id;
    final isTimingOther = _timingExerciseId != null && !isTimingThis;
    return Card(
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
                  onPressed: () => db.deleteWorkoutExercise(exercise.id),
                ),
              ],
            ),
            for (final set in sets.where((s) => s.exerciseId == exercise.id))
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
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加组'),
                  onPressed: () => _addSet(exercise),
                ),
                const Spacer(),
                if (isTimingThis) ...[
                  // 小号读数，不强调；Timer 每秒刷新显示
                  Text(
                    formatElapsed(_stopwatch!.elapsedSeconds()),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  TextButton(
                    onPressed: _toggleSetPause,
                    child: Text(_stopwatch!.isPaused ? '继续' : '暂停'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _finishSetTiming(exercise),
                    child: const Text('结束并保存'),
                  ),
                ] else
                  TextButton.icon(
                    icon: const Icon(Icons.timer_outlined, size: 18),
                    label: const Text('开始一组'),
                    onPressed:
                        isTimingOther ? null : () => _startSetTiming(exercise),
                  ),
              ],
            ),
          ],
        ),
      ),
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
