import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database.dart';

/// 秒数格式化为 H:MM:SS（不足一小时为 M:SS），仅用于显示
String formatElapsed(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final mm = m.toString().padLeft(h > 0 ? 2 : 1, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

/// 组的简要描述：次数 / 时长 / 重量 / 备注
String describeSet(WorkoutSet s) {
  final parts = <String>[];
  final reps = s.reps;
  if (reps != null && reps > 0) parts.add('$reps 次');
  final duration = s.durationSeconds;
  if (duration != null && duration > 0) {
    parts.add(duration >= 60
        ? '${(duration / 60).toStringAsFixed(duration % 60 == 0 ? 0 : 1)} 分钟'
        : '$duration 秒');
  }
  final weight = s.weightKg;
  if (weight != null && weight > 0) parts.add('$weight kg');
  if (parts.isEmpty) parts.add('（无效组）');
  final note = s.note;
  if (note != null && note.isNotEmpty) parts.add(note);
  return parts.join(' · ');
}

/// 达标反馈文案：常规/最低完成用明确的成功语气；
/// 未达最低用中性文案，不使用失败措辞
String describePlanEvaluation(PlanEvaluation ev, Workout w) {
  final name = w.planName ?? '方案';
  switch (ev.tier) {
    case PlanTier.regular:
      return '常规方案完成（$name）';
    case PlanTier.min:
      return '最低方案完成（$name）';
    case PlanTier.belowMin:
      final isDuration = w.planMetric == PlanMetric.duration;
      final actual =
          isDuration ? '${ev.actual ~/ 60} 分钟' : '${ev.actual} 组';
      final target = isDuration
          ? '${(w.planMin ?? 0) ~/ 60} 分钟'
          : '${w.planMin ?? 0} 组';
      return '已记录，未达最低（$actual/$target）';
    case PlanTier.none:
      return '已记录';
  }
}

/// 添加动作的结果
typedef ExerciseDraft = ({String name, ExerciseCategory category, String? note});

/// 添加组的结果
typedef SetDraft = ({
  int? reps,
  int? durationSeconds,
  double? weightKg,
  String? note,
});

/// 弹出「添加动作」对话框（名称 + 类别 + 可选备注）
Future<ExerciseDraft?> showAddWorkoutExerciseDialog(BuildContext context) {
  return showDialog<ExerciseDraft>(
    context: context,
    builder: (_) => const _AddExerciseDialog(),
  );
}

class _AddExerciseDialog extends StatefulWidget {
  const _AddExerciseDialog();

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  ExerciseCategory _category = ExerciseCategory.cardio;

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final note = _noteController.text.trim();
    Navigator.of(context).pop((
      name: _nameController.text.trim(),
      category: _category,
      note: note.isEmpty ? null : note,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加动作'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '动作名称'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入动作名称' : null,
            ),
            DropdownButtonFormField<ExerciseCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: '类别'),
              items: [
                for (final c in ExerciseCategory.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (v) =>
                  setState(() => _category = v ?? ExerciseCategory.cardio),
            ),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: '备注（可选）'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('添加')),
      ],
    );
  }
}

/// 弹出「添加组」对话框；次数 / 持续秒数 / 重量 / 备注均可选
Future<SetDraft?> showAddWorkoutSetDialog(BuildContext context) {
  return showDialog<SetDraft>(
    context: context,
    builder: (_) => const _AddSetDialog(),
  );
}

class _AddSetDialog extends StatefulWidget {
  const _AddSetDialog();

  @override
  State<_AddSetDialog> createState() => _AddSetDialogState();
}

class _AddSetDialogState extends State<_AddSetDialog> {
  final _repsController = TextEditingController();
  final _durationController = TextEditingController();
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _repsController.dispose();
    _durationController.dispose();
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? _parseInt(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : int.tryParse(t);
  }

  void _submit() {
    final reps = _parseInt(_repsController);
    final durationSeconds = _parseInt(_durationController);
    // 有效组：次数或持续秒数至少一项大于 0，全空（或只有重量/备注）不允许保存
    if ((reps == null || reps <= 0) &&
        (durationSeconds == null || durationSeconds <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('次数或持续秒数至少填一项（需大于 0）')),
      );
      return;
    }
    final note = _noteController.text.trim();
    Navigator.of(context).pop((
      reps: reps,
      durationSeconds: durationSeconds,
      weightKg: double.tryParse(_weightController.text.trim()),
      note: note.isEmpty ? null : note,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加组'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _repsController,
              decoration: const InputDecoration(labelText: '次数（可选）'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            TextField(
              controller: _durationController,
              decoration:
                  const InputDecoration(labelText: '持续秒数（可选）'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: '重量 kg（可选）'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: '备注（可选）'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('添加')),
      ],
    );
  }
}
