import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';
import '../widgets/finish_workout_dialog.dart';
import '../widgets/set_stopwatch.dart';
import '../widgets/workout_cards.dart';
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

  /// 本次进入页面后是否已反馈过「最低方案完成」，避免重复弹 SnackBar
  bool _minDoneNotified = false;

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
    final exercises = await ref.read(databaseProvider).getExercises();
    if (!mounted) return;
    final draft = await showAddWorkoutExerciseDialog(
      context,
      exercises: exercises,
    );
    if (draft == null) return;
    final db = ref.read(databaseProvider);
    final catalogId =
        draft.catalogExerciseId ??
        await db.insertExercise(
          name: draft.name,
          category: draft.category,
          trackingType: draft.trackingType,
          loadConvention: draft.loadConvention,
          repsConvention: draft.repsConvention,
        );
    await db.addWorkoutExercise(
      workout.id,
      catalogExerciseId: catalogId,
      name: draft.name,
      category: draft.category,
      trackingType: draft.trackingType,
      loadConvention: draft.loadConvention,
      repsConvention: draft.repsConvention,
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

  /// 完成本组：把实际秒数直接写为一条时长组记录（可删除，不弹确认）；
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('计时不足 1 秒，未保存该组')));
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
        title: const Text('放弃本次训练'),
        content: const Text('将删除本场训练及已记录的动作和组，确定放弃吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('放弃'),
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
      builder: (_) => FinishWorkoutDialog(
        elapsedSeconds: elapsed,
        creditExerciseName: singleEmptyExercise ? exercises.single.name : null,
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
      if (done?.templateVersionId != null) {
        final progress = await db.evaluateWorkoutTemplate(done!.id);
        messenger.showSnackBar(
          SnackBar(content: Text(describeTemplateProgress(progress, done))),
        );
      }
    } on StateError {
      // 单一空动作但未勾选「计时记为时长」时仍无有效组
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('至少需要一条有效组（次数或持续时间大于 0）才能结束训练')),
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
            PopupMenuButton<String>(
              tooltip: '更多操作',
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'discard', child: Text('放弃本次训练')),
              ],
              onSelected: (value) {
                if (value == 'discard') _discard(workout);
              },
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 训练总用时降级为紧凑一行，不占视觉中心；
        // 训练级「暂停训练 / 结束训练」与组级秒表文案明确区分
        Row(
          children: [
            Text(
              '总用时 ${formatElapsed(elapsed)}${paused ? ' · 已暂停' : ''}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              icon: Icon(paused ? Icons.play_arrow : Icons.pause, size: 18),
              label: Text(paused ? '继续训练' : '暂停训练'),
              onPressed: () => _togglePause(workout),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.stop, size: 18),
              label: const Text('结束训练'),
              onPressed: () => _finish(workout, exercises, sets),
            ),
          ],
        ),
        if (workout.templateVersionId != null) ...[
          const SizedBox(height: 12),
          PlanProgressCard(
            workout: workout,
            minDoneNotified: _minDoneNotified,
            onMinDone: () => _minDoneNotified = true,
          ),
        ],
        const SizedBox(height: 12),
        for (final exercise in exercises)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ExerciseCard(
              exercise: exercise,
              sets: sets,
              hasTemplate: workout.templateVersionId != null,
              timingExerciseId: _timingExerciseId,
              stopwatch: _stopwatch,
              onStartTiming: _startSetTiming,
              onToggleSetPause: _toggleSetPause,
              onFinishSetTiming: _finishSetTiming,
            ),
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('添加动作'),
          onPressed: () => _addExercise(workout),
        ),
      ],
    );
  }
}
