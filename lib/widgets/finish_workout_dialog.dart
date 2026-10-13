import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';

/// 结束训练对话框：可编辑总用时（分钟，预填计时值）与感受；
/// 单一空动作训练提供「将计时记为该动作时长」勾选项
class FinishWorkoutDialog extends ConsumerStatefulWidget {
  const FinishWorkoutDialog({
    super.key,
    required this.elapsedSeconds,
    required this.creditExerciseName,
  });

  final int elapsedSeconds;

  /// 非空表示可勾选把计时补记为该动作的一条时长组
  final String? creditExerciseName;

  @override
  ConsumerState<FinishWorkoutDialog> createState() =>
      _FinishWorkoutDialogState();
}

class _FinishWorkoutDialogState
    extends ConsumerState<FinishWorkoutDialog> {
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
