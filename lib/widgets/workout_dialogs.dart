import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database.dart';

/// 秒数格式化为 H:MM:SS（不足一小时为 MM:SS，分钟零填充避免歧义），仅用于显示
String formatElapsed(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

/// 训练已记录用时（秒）的统一显示口径，供首页、运动时段与周进度共用。
/// 非零但不足一分钟单独说清楚；整分钟不带小数，否则保留一位，
/// 避免同一场训练在不同页面显示成不同的数。
String formatRecordedSeconds(int seconds) {
  if (seconds <= 0) return '0 分钟';
  if (seconds < 60) return '不足 1 分钟';
  // 用十分之一分钟为单位取整，避免 61 秒显示成「1.0 分钟」
  final tenths = (seconds / 6).round();
  return tenths % 10 == 0
      ? '${tenths ~/ 10} 分钟'
      : '${(tenths / 10).toStringAsFixed(1)} 分钟';
}

String _formatCompactNum(double v) =>
    v == v.roundToDouble() ? '${v.round()}' : '$v';

/// 组的简要描述：次数 / 时长 / 距离 / 重量 / 助力 / RPE / RIR / 备注
String describeSet(WorkoutSet s) {
  final parts = <String>[];
  final reps = s.reps;
  if (reps != null && reps > 0) parts.add('$reps 次');
  final duration = s.durationSeconds;
  if (duration != null && duration > 0) {
    parts.add(
      duration >= 60
          ? '${(duration / 60).toStringAsFixed(duration % 60 == 0 ? 0 : 1)} 分钟'
          : '$duration 秒',
    );
  }
  final distance = s.distanceMeters;
  if (distance != null && distance > 0) parts.add('$distance 米');
  final weight = s.weightKg;
  if (weight != null && weight > 0) parts.add('$weight kg');
  final assistance = s.assistanceKg;
  if (assistance != null && assistance > 0) {
    parts.add('助力 ${_formatCompactNum(assistance)} kg');
  }
  final rpe = s.rpe;
  if (rpe != null && rpe > 0) {
    parts.add('RPE ${_formatCompactNum(rpe)}');
  }
  final rir = s.rir;
  if (rir != null && rir >= 0) {
    parts.add('RIR ${_formatCompactNum(rir)}');
  }
  if (s.setStatus == SetStatus.skipped) {
    parts.insert(0, '已跳过');
  } else if (parts.isEmpty) {
    parts.add('（无效组）');
  }
  final note = s.note;
  if (note != null && note.isNotEmpty) parts.add(note);
  return parts.join(' · ');
}

/// 模板完成反馈：常规/最低完成用明确的成功语气；未达最低保持中性。
String describeTemplateProgress(TemplateProgress progress, Workout workout) {
  final name = workout.templateNameSnapshot ?? '方案';
  switch (progress.tier) {
    case PlanTier.regular:
      return '常规方案完成（$name）';
    case PlanTier.min:
      return '最低方案完成（$name）';
    case PlanTier.belowMin:
      if (progress.minimumTotal == 0) {
        return '已记录，常规完成 ${progress.regularCompleted}/${progress.regularTotal} 组';
      }
      return '已记录，最低完成 ${progress.minimumCompleted}/${progress.minimumTotal} 组';
    case PlanTier.none:
      return '已记录';
  }
}

/// 添加动作的结果
typedef ExerciseDraft = ({
  int? catalogExerciseId,
  String name,
  ExerciseCategory category,
  TrackingType trackingType,
  LoadConvention loadConvention,
  RepsConvention repsConvention,
  String? note,
});

/// 添加组的结果
typedef SetDraft = ({
  int? reps,
  int? durationSeconds,
  double? distanceMeters,
  double? weightKg,
  double? assistanceKg,
  double? rpe,
  double? rir,
  SetRole setRole,
  SetStatus setStatus,
  String? note,
});

/// 从动作目录选择，或创建一个自定义动作。
Future<ExerciseDraft?> showAddWorkoutExerciseDialog(
  BuildContext context, {
  required List<Exercise> exercises,
}) {
  return showDialog<ExerciseDraft>(
    context: context,
    builder: (_) => _AddExerciseDialog(exercises: exercises),
  );
}

class _AddExerciseDialog extends StatefulWidget {
  const _AddExerciseDialog({required this.exercises});

  final List<Exercise> exercises;

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  ExerciseCategory _category = ExerciseCategory.cardio;
  TrackingType _trackingType = TrackingType.reps;
  LoadConvention _loadConvention = LoadConvention.none;
  RepsConvention _repsConvention = RepsConvention.total;
  int _selectedId = -1;

  Exercise? get _selectedExercise => _selectedId < 0
      ? null
      : widget.exercises.where((exercise) => exercise.id == _selectedId).first;

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final selected = _selectedExercise;
    final note = _noteController.text.trim();
    Navigator.of(context).pop((
      catalogExerciseId: selected?.id,
      name: selected?.name ?? _nameController.text.trim(),
      category: selected?.category ?? _category,
      trackingType: selected?.trackingType ?? _trackingType,
      loadConvention: selected?.loadConvention ?? _loadConvention,
      repsConvention: selected?.repsConvention ?? _repsConvention,
      note: note.isEmpty ? null : note,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加动作'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _selectedId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '动作库'),
                items: [
                  const DropdownMenuItem(value: -1, child: Text('新建自定义动作')),
                  for (final exercise in widget.exercises)
                    DropdownMenuItem(
                      value: exercise.id,
                      child: Text(
                        '${exercise.name} · ${exercise.trackingType.label}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  final id = value ?? -1;
                  setState(() {
                    _selectedId = id;
                    if (id < 0) {
                      _nameController.clear();
                    } else {
                      final exercise = _selectedExercise!;
                      _nameController.text = exercise.name;
                      _category = exercise.category;
                      _trackingType = exercise.trackingType;
                      _loadConvention = exercise.loadConvention;
                      _repsConvention = exercise.repsConvention;
                    }
                  });
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                enabled: _selectedId < 0,
                decoration: const InputDecoration(labelText: '动作名称'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入动作名称' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<ExerciseCategory>(
                key: ValueKey('category-$_selectedId-$_category'),
                initialValue: _category,
                decoration: const InputDecoration(labelText: '类别'),
                items: [
                  for (final c in ExerciseCategory.values)
                    DropdownMenuItem(value: c, child: Text(c.label)),
                ],
                onChanged: _selectedId >= 0
                    ? null
                    : (v) => setState(
                        () => _category = v ?? ExerciseCategory.cardio,
                      ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<TrackingType>(
                key: ValueKey('tracking-$_selectedId-$_trackingType'),
                initialValue: _trackingType,
                decoration: const InputDecoration(labelText: '记录方式'),
                items: [
                  for (final type in TrackingType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: _selectedId >= 0
                    ? null
                    : (value) => setState(
                        () => _trackingType = value ?? TrackingType.reps,
                      ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: '备注（可选）'),
              ),
            ],
          ),
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

/// 弹出「添加组」对话框；次数 / 持续秒数 / 距离 / 重量 / 进阶字段 / 备注均可选。
/// [prefill] 非空时预填上一组的次数 / 时长 / 重量等（不预填备注）
Future<SetDraft?> showAddWorkoutSetDialog(
  BuildContext context, {
  WorkoutSet? prefill,
  TrackingType? trackingType,
  LoadConvention? loadConvention,
}) {
  return showDialog<SetDraft>(
    context: context,
    builder: (_) => _AddSetDialog(
      prefill: prefill,
      trackingType: trackingType,
      loadConvention: loadConvention,
    ),
  );
}

/// 弹出「编辑组」对话框：预填该组现有全部值（含备注），返回修改后的草稿
Future<SetDraft?> showEditWorkoutSetDialog(
  BuildContext context,
  WorkoutSet set, {
  TrackingType? trackingType,
  LoadConvention? loadConvention,
}) {
  return showDialog<SetDraft>(
    context: context,
    builder: (_) => _AddSetDialog(
      prefill: set,
      editing: true,
      trackingType: trackingType,
      loadConvention: loadConvention,
    ),
  );
}

class _AddSetDialog extends StatefulWidget {
  const _AddSetDialog({
    this.prefill,
    this.editing = false,
    this.trackingType,
    this.loadConvention,
  });

  final WorkoutSet? prefill;

  /// 编辑模式：改标题与按钮文案，并预填备注（添加模式预填不带备注）
  final bool editing;

  final TrackingType? trackingType;
  final LoadConvention? loadConvention;

  @override
  State<_AddSetDialog> createState() => _AddSetDialogState();
}

class _AddSetDialogState extends State<_AddSetDialog> {
  late final TextEditingController _repsController;
  late final TextEditingController _durationController;
  late final TextEditingController _distanceController;
  late final TextEditingController _weightController;
  late final TextEditingController _assistanceController;
  late final TextEditingController _rpeController;
  late final TextEditingController _rirController;
  late final TextEditingController _noteController;
  late SetRole _setRole;
  late SetStatus _setStatus;
  late bool _showAdvanced;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    String numText(num? v) => v == null ? '' : '$v';
    _repsController = TextEditingController(text: numText(p?.reps));
    _durationController = TextEditingController(
      text: numText(p?.durationSeconds),
    );
    _distanceController = TextEditingController(
      text: numText(p?.distanceMeters),
    );
    _weightController = TextEditingController(text: numText(p?.weightKg));
    _assistanceController = TextEditingController(
      text: numText(p?.assistanceKg),
    );
    _rpeController = TextEditingController(text: numText(p?.rpe));
    _rirController = TextEditingController(text: numText(p?.rir));
    _setRole = p?.setRole ?? SetRole.work;
    _setStatus = p?.setStatus ?? SetStatus.completed;
    _noteController = TextEditingController(
      text: widget.editing ? (p?.note ?? '') : '',
    );
    _showAdvanced =
        widget.loadConvention == LoadConvention.assistance ||
        p?.assistanceKg != null ||
        p?.rpe != null ||
        p?.rir != null;
  }

  @override
  void dispose() {
    _repsController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    _weightController.dispose();
    _assistanceController.dispose();
    _rpeController.dispose();
    _rirController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? _parseInt(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : int.tryParse(t);
  }

  double? _parseDouble(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : double.tryParse(t);
  }

  void _submit() {
    final reps = _parseInt(_repsController);
    final durationSeconds = _parseInt(_durationController);
    final distanceMeters = _parseDouble(_distanceController);
    // 完成组至少需要一项核心事实；若填了动作主口径字段则需大于 0；跳过组允许不填写数值。
    if (_setStatus == SetStatus.completed) {
      final primary = switch (widget.trackingType) {
        TrackingType.reps => reps,
        TrackingType.duration => durationSeconds,
        TrackingType.distance => distanceMeters,
        null => null,
      };
      final hasAny =
          (reps != null && reps > 0) ||
          (durationSeconds != null && durationSeconds > 0) ||
          (distanceMeters != null && distanceMeters > 0);
      if ((primary != null && primary <= 0) || !hasAny) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('次数、持续秒数或距离至少填一项（需大于 0）')));
        return;
      }
    }
    final note = _noteController.text.trim();
    Navigator.of(context).pop((
      reps: reps,
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
      weightKg: _parseDouble(_weightController),
      assistanceKg: _parseDouble(_assistanceController),
      rpe: _parseDouble(_rpeController),
      rir: _parseDouble(_rirController),
      setRole: _setRole,
      setStatus: _setStatus,
      note: note.isEmpty ? null : note,
    ));
  }

  List<Widget> _buildOrderedCoreFields() {
    final repsField = Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: _repsController,
        decoration: InputDecoration(
          labelText: '次数（可选）',
          helperText:
              widget.trackingType == TrackingType.reps ? '当前动作主记录项' : null,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
    );
    final durationField = Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: _durationController,
        decoration: InputDecoration(
          labelText: '持续秒数（可选）',
          helperText:
              widget.trackingType == TrackingType.duration ? '当前动作主记录项' : null,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
    );
    final distanceField = Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: _distanceController,
        decoration: InputDecoration(
          labelText: '距离（米，可选）',
          helperText:
              widget.trackingType == TrackingType.distance ? '当前动作主记录项' : null,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
    return switch (widget.trackingType) {
      TrackingType.duration => [durationField, repsField, distanceField],
      TrackingType.distance => [distanceField, durationField, repsField],
      TrackingType.reps || null => [repsField, durationField, distanceField],
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.editing ? '编辑组' : '添加组'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<SetRole>(
                    initialValue: _setRole,
                    decoration: const InputDecoration(labelText: '组角色'),
                    items: const [
                      DropdownMenuItem(
                        value: SetRole.warmup,
                        child: Text('热身组'),
                      ),
                      DropdownMenuItem(value: SetRole.work, child: Text('工作组')),
                      DropdownMenuItem(
                        value: SetRole.cooldown,
                        child: Text('放松组'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _setRole = value ?? SetRole.work),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<SetStatus>(
                    initialValue: _setStatus,
                    decoration: const InputDecoration(labelText: '状态'),
                    items: const [
                      DropdownMenuItem(
                        value: SetStatus.completed,
                        child: Text('已完成'),
                      ),
                      DropdownMenuItem(
                        value: SetStatus.skipped,
                        child: Text('跳过'),
                      ),
                    ],
                    onChanged: (value) => setState(
                      () => _setStatus = value ?? SetStatus.completed,
                    ),
                  ),
                ),
              ],
            ),
            ..._buildOrderedCoreFields(),
            const SizedBox(height: 10),
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: '重量 kg（可选）'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: Icon(
                  _showAdvanced ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                label: Text(_showAdvanced ? '收起进阶指标' : '更多指标（助力 / RPE / RIR）'),
                onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
              ),
            ),
            if (_showAdvanced) ...[
              TextField(
                controller: _assistanceController,
                decoration: const InputDecoration(labelText: '助力 kg（可选）'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _rpeController,
                      decoration: const InputDecoration(
                        labelText: 'RPE（1-10，可选）',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _rirController,
                      decoration: const InputDecoration(
                        labelText: 'RIR（保留次数，可选）',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
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
        FilledButton(
          onPressed: _submit,
          child: Text(widget.editing ? '保存' : '添加'),
        ),
      ],
    );
  }
}
