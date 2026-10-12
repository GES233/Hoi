import 'dart:async';

import 'package:drift/drift.dart' show Value;
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
    final draft = await showAddWorkoutExerciseDialog(context);
    if (draft == null) return;
    await ref.read(databaseProvider).addWorkoutExercise(
          workout.id,
          name: draft.name,
          category: draft.category,
          note: draft.note,
        );
  }

  /// 添加组：预填该动作上一组的数值，便于抗阻训练快速录入
  Future<void> _addSet(WorkoutExercise exercise, List<WorkoutSet> sets) async {
    final exerciseSets = sets.where((s) => s.exerciseId == exercise.id);
    final draft = await showAddWorkoutSetDialog(
      context,
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
  Future<void> _repeatLastSet(
      WorkoutExercise exercise, WorkoutSet last) async {
    await ref.read(databaseProvider).addWorkoutSet(
          exercise.id,
          reps: last.reps,
          durationSeconds: last.durationSeconds,
          weightKg: last.weightKg,
        );
  }

  /// 滑动删除一组，SnackBar 提供撤销；撤销会追加到末尾，不恢复原顺序
  Future<void> _deleteSetWithUndo(WorkoutSet set) async {
    final db = ref.read(databaseProvider);
    await db.deleteWorkoutSet(set.id);
    if (!mounted) return;
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

  /// 删除动作需确认：会级联删除该动作已记录的全部组
  Future<void> _confirmDeleteExercise(
      WorkoutExercise exercise, int setCount) async {
    final confirmed = await showDialog<bool>(
      context: context,
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
    final db = ref.read(databaseProvider);

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
                  fontFeatures: const [FontFeature.tabularFigures()]),
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
        if (workout.planMetric != null) ...[
          const SizedBox(height: 12),
          _planProgressCard(workout, exercises, sets),
        ],
        const SizedBox(height: 12),
        for (final exercise in exercises)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _exerciseCard(context, exercise, sets, db),
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('添加动作'),
          onPressed: () => _addExercise(workout),
        ),
      ],
    );
  }

  /// 关联方案的实时进度卡：按方案快照对当前已记录内容实时评估；
  /// 达到最低时整卡变为成功态，并弹出一次「最低方案已完成」反馈
  Widget _planProgressCard(
    Workout workout,
    List<WorkoutExercise> exercises,
    List<WorkoutSet> sets,
  ) {
    final ev = AppDatabase.evaluateWorkout(workout, exercises, sets);
    final isDuration = workout.planMetric == PlanMetric.duration;
    final min = workout.planMin ?? 0;
    final regular = workout.planRegular ?? 0;
    String fmt(int v) => isDuration ? '${v ~/ 60} 分钟' : '$v 组';
    final minDone =
        ev.tier == PlanTier.min || ev.tier == PlanTier.regular;
    final regularDone = ev.tier == PlanTier.regular;

    if (minDone && !_minDoneNotified) {
      _minDoneNotified = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
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

  /// 单个动作卡：组序号 + 汇总 + 组级小秒表
  /// （全场至多一个组在计时，其他动作的「开始一组」此时禁用）
  Widget _exerciseCard(
    BuildContext context,
    WorkoutExercise exercise,
    List<WorkoutSet> sets,
    AppDatabase db,
  ) {
    final isTimingThis = _timingExerciseId == exercise.id;
    final isTimingOther = _timingExerciseId != null && !isTimingThis;
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
                      _confirmDeleteExercise(exercise, exerciseSets.length);
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
              _setRow(exerciseSets[i], i),
            // 计时的组变成高亮条，计时期间隐藏「添加组」避免一行挤四个控件
            if (isTimingThis)
              _timingBar(exercise, exerciseSets.length + 1)
            else
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('添加组'),
                    onPressed: () => _addSet(exercise, sets),
                  ),
                  if (exerciseSets.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.repeat, size: 18),
                      label: const Text('再来一组'),
                      onPressed: () =>
                          _repeatLastSet(exercise, exerciseSets.last),
                    ),
                  const Spacer(),
                  Tooltip(
                    message: isTimingOther ? '请先完成正在计时的组' : '计时并保存为一组时长',
                    child: TextButton.icon(
                      icon: const Icon(Icons.timer_outlined, size: 18),
                      label: const Text('开始一组'),
                      onPressed: isTimingOther
                          ? null
                          : () => _startSetTiming(exercise),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// 编辑已保存的组：次数 / 时长 / 重量 / 备注均可修改，
  /// 例如一组内先做完整版再做退阶，可事后在备注里补充
  Future<void> _editSet(WorkoutSet set) async {
    final draft = await showEditWorkoutSetDialog(context, set);
    if (draft == null) return;
    await ref.read(databaseProvider).updateWorkoutSet(
          set.id,
          reps: Value(draft.reps),
          durationSeconds: Value(draft.durationSeconds),
          weightKg: Value(draft.weightKg),
          note: Value(draft.note),
        );
  }

  /// 单组行：带序号，点按编辑，左滑删除并在 SnackBar 中提供撤销
  Widget _setRow(WorkoutSet set, int index) {
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
      onDismissed: (_) => _deleteSetWithUndo(set),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text('第 ${index + 1} 组　${describeSet(set)}'),
        trailing: Icon(Icons.edit_outlined,
            size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        onTap: () => _editSet(set),
      ),
    );
  }

  /// 组级秒表计时中的高亮条：组序号 + 大读数（等宽数字）+ 暂停本组 / 完成本组
  Widget _timingBar(WorkoutExercise exercise, int setIndex) {
    final stopwatch = _stopwatch!;
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
            onPressed: _toggleSetPause,
            child: Text(stopwatch.isPaused ? '继续本组' : '暂停本组'),
          ),
          FilledButton.tonal(
            onPressed: () => _finishSetTiming(exercise),
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
