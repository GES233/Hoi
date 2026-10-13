import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';
import '../widgets/workout_dialogs.dart';

/// 补记 / 编辑已完成训练。
/// 补记模式：动作与组先在本地暂存，保存时一次性写入；
/// 编辑模式：动作与组实时写库，总用时与感受点保存时更新。
class LogWorkoutScreen extends ConsumerStatefulWidget {
  const LogWorkoutScreen({super.key, required this.initialDate})
    : editing = null;

  const LogWorkoutScreen.editing({super.key, required Workout workout})
    : editing = workout,
      initialDate = null;

  /// 补记模式的初始日期（通常为首页选中日期）
  final DateTime? initialDate;

  /// 编辑模式下被编辑的已完成训练
  final Workout? editing;

  @override
  ConsumerState<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

/// 补记模式本地暂存的组
class _DraftSet {
  _DraftSet({
    this.reps,
    this.durationSeconds,
    this.distanceMeters,
    this.weightKg,
    this.setRole = SetRole.work,
    this.setStatus = SetStatus.completed,
    this.note,
  });

  int? reps;
  int? durationSeconds;
  double? distanceMeters;
  double? weightKg;
  SetRole setRole;
  SetStatus setStatus;
  String? note;

  bool get isValid =>
      setStatus == SetStatus.completed &&
      ((reps ?? 0) > 0 ||
          (durationSeconds ?? 0) > 0 ||
          (distanceMeters ?? 0) > 0);
}

/// 补记模式本地暂存的动作
class _DraftExercise {
  _DraftExercise({
    required this.name,
    required this.category,
    required this.trackingType,
    this.note,
  });

  String name;
  ExerciseCategory category;
  TrackingType trackingType;
  String? note;
  final List<_DraftSet> sets = [];
}

class _LogWorkoutScreenState extends ConsumerState<LogWorkoutScreen> {
  final _minutesController = TextEditingController();
  final _feelingController = TextEditingController();
  final List<_DraftExercise> _drafts = [];
  late DateTime _date;

  /// 关联的模板版本 id；null 表示不关联
  int? _selectedTemplateVersionId;
  bool _saving = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _date = AppDatabase.dateOnly(editing?.date ?? widget.initialDate!);
    _selectedTemplateVersionId = editing?.templateVersionId;
    final total = editing?.totalSeconds;
    if (total != null) {
      // 预填分钟，保留一位小数以尽量不损失精度
      final minutes = total / 60;
      _minutesController.text = minutes == minutes.roundToDouble()
          ? minutes.round().toString()
          : minutes.toStringAsFixed(1);
    }
    _feelingController.text = editing?.feeling ?? '';
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _feelingController.dispose();
    super.dispose();
  }

  /// 分钟输入解析为秒；留空为 null（未知，不显示成 0）
  int? get _parsedTotalSeconds {
    final text = _minutesController.text.trim();
    if (text.isEmpty) return null;
    final minutes = double.tryParse(text);
    return minutes == null ? null : (minutes * 60).round();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = AppDatabase.dateOnly(picked));
  }

  Future<void> _addExercise() async {
    final draft = await showAddWorkoutExerciseDialog(context);
    if (draft == null) return;
    final db = ref.read(databaseProvider);
    if (_isEditing) {
      await db.addWorkoutExercise(
        widget.editing!.id,
        name: draft.name,
        category: draft.category,
        trackingType: draft.trackingType,
        note: draft.note,
      );
    } else {
      setState(
        () => _drafts.add(
          _DraftExercise(
            name: draft.name,
            category: draft.category,
            trackingType: draft.trackingType,
            note: draft.note,
          ),
        ),
      );
    }
  }

  Future<void> _addSet(int index, WorkoutExercise? live) async {
    final draft = await showAddWorkoutSetDialog(context);
    if (draft == null) return;
    if (live != null) {
      await ref
          .read(databaseProvider)
          .addWorkoutSet(
            live.id,
            setRole: draft.setRole,
            setStatus: draft.setStatus,
            reps: draft.reps,
            durationSeconds: draft.durationSeconds,
            distanceMeters: draft.distanceMeters,
            weightKg: draft.weightKg,
            note: draft.note,
          );
    } else {
      setState(
        () => _drafts[index].sets.add(
          _DraftSet(
            reps: draft.reps,
            durationSeconds: draft.durationSeconds,
            distanceMeters: draft.distanceMeters,
            weightKg: draft.weightKg,
            setRole: draft.setRole,
            setStatus: draft.setStatus,
            note: draft.note,
          ),
        ),
      );
    }
  }

  /// 编辑已保存的组（编辑模式，实时写库）
  Future<void> _editSet(WorkoutSet set) async {
    final draft = await showEditWorkoutSetDialog(context, set);
    if (draft == null) return;
    await ref
        .read(databaseProvider)
        .updateWorkoutSet(
          set.id,
          setRole: Value(draft.setRole),
          setStatus: Value(draft.setStatus),
          reps: Value(draft.reps),
          durationSeconds: Value(draft.durationSeconds),
          distanceMeters: Value(draft.distanceMeters),
          weightKg: Value(draft.weightKg),
          note: Value(draft.note),
        );
  }

  String _describeDraftSet(_DraftSet s) {
    final parts = <String>[];
    if ((s.reps ?? 0) > 0) parts.add('${s.reps} 次');
    final d = s.durationSeconds;
    if (d != null && d > 0) {
      parts.add(
        d >= 60
            ? '${(d / 60).toStringAsFixed(d % 60 == 0 ? 0 : 1)} 分钟'
            : '$d 秒',
      );
    }
    if ((s.distanceMeters ?? 0) > 0) parts.add('${s.distanceMeters} 米');
    if ((s.weightKg ?? 0) > 0) parts.add('${s.weightKg} kg');
    if (s.setStatus == SetStatus.skipped) {
      parts.insert(0, '已跳过');
    } else if (parts.isEmpty) {
      parts.add('（无效组）');
    }
    if (s.note != null && s.note!.isNotEmpty) parts.add(s.note!);
    return parts.join(' · ');
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final messenger = ScaffoldMessenger.of(context);
    final feeling = _feelingController.text.trim();
    TemplateVersion? linkedVersion;
    int? savedId;
    try {
      linkedVersion = _selectedTemplateVersionId == null
          ? null
          : await db.getTemplateVersion(_selectedTemplateVersionId!);
      if (_isEditing) {
        savedId = widget.editing!.id;
        await db.updateWorkoutMeta(
          savedId,
          totalSeconds: Value(_parsedTotalSeconds),
          feeling: Value(feeling.isEmpty ? null : feeling),
        );
        if (linkedVersion != null) {
          await db.linkTemplateToWorkout(savedId, linkedVersion);
        } else if (widget.editing!.templateVersionId != null) {
          await db.clearTemplateLink(savedId);
        }
      } else {
        final hasValid = _drafts.any((e) => e.sets.any((s) => s.isValid));
        if (!hasValid) {
          messenger.showSnackBar(
            const SnackBar(content: Text('至少需要一条有效组（次数或持续时间大于 0）才能保存')),
          );
          return;
        }
        savedId = await db.insertCompletedWorkout(
          date: _date,
          totalSeconds: _parsedTotalSeconds,
          feeling: feeling.isEmpty ? null : feeling,
        );
        for (final exercise in _drafts) {
          final exerciseId = await db.addWorkoutExercise(
            savedId,
            name: exercise.name,
            category: exercise.category,
            trackingType: exercise.trackingType,
            note: exercise.note,
          );
          for (final set in exercise.sets) {
            await db.addWorkoutSet(
              exerciseId,
              setRole: set.setRole,
              setStatus: set.setStatus,
              reps: set.reps,
              durationSeconds: set.durationSeconds,
              distanceMeters: set.distanceMeters,
              weightKg: set.weightKg,
              note: set.note,
            );
          }
        }
        if (linkedVersion != null) {
          await db.linkTemplateToWorkout(savedId, linkedVersion);
        }
      }
      // 关联了模板时按计划组关联给出完成反馈；自由添加的动作/组仍视为计划外事实。
      if (linkedVersion != null) {
        final w = await db.getWorkout(savedId);
        if (w != null) {
          final progress = await db.evaluateWorkoutTemplate(savedId);
          messenger.showSnackBar(
            SnackBar(content: Text(describeTemplateProgress(progress, w))),
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑训练' : '补记运动')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMetaCard(),
          const SizedBox(height: 12),
          if (_isEditing) ..._buildLiveExercises() else ..._buildDrafts(),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('添加动作'),
            onPressed: _addExercise,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text('日期', style: Theme.of(context).textTheme.labelLarge),
                const Spacer(),
                if (_isEditing)
                  Text(DateFormat('yyyy年M月d日').format(_date))
                else
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(DateFormat('yyyy年M月d日').format(_date)),
                    onPressed: _pickDate,
                  ),
              ],
            ),
            TextField(
              controller: _minutesController,
              decoration: const InputDecoration(
                labelText: '训练总用时（分钟，可留空）',
                helperText: '留空表示用时未记录',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            TextField(
              controller: _feelingController,
              decoration: const InputDecoration(labelText: '感受（可选）'),
            ),
            _buildPlanDropdown(),
          ],
        ),
      ),
    );
  }

  /// 关联模板版本下拉：新选择使用当前版本，历史关联保留原版本。
  Widget _buildPlanDropdown() {
    final templates = ref.watch(workoutTemplatesProvider).value ?? [];
    final currentIds = templates.map((t) => t.version.id).toSet();
    final selected = _selectedTemplateVersionId;
    return DropdownButtonFormField<int?>(
      initialValue: selected,
      decoration: const InputDecoration(labelText: '关联方案（可选）'),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('无')),
        if (selected != null && !currentIds.contains(selected))
          DropdownMenuItem<int?>(
            value: selected,
            child: Text(widget.editing?.templateNameSnapshot ?? '历史方案版本'),
          ),
        for (final summary in templates)
          DropdownMenuItem<int?>(
            value: summary.version.id,
            child: Text(summary.version.name),
          ),
      ],
      onChanged: (value) => setState(() => _selectedTemplateVersionId = value),
    );
  }

  /// 编辑模式：动作与组实时来自数据库
  List<Widget> _buildLiveExercises() {
    final id = widget.editing!.id;
    final exercises = ref.watch(workoutExercisesProvider(id)).value ?? [];
    final sets = ref.watch(workoutSetsProvider(id)).value ?? [];
    final db = ref.read(databaseProvider);
    return [
      for (final exercise in exercises)
        _exerciseCard(
          title: '${exercise.name}（${exercise.category.label}）',
          onDelete: () => db.deleteWorkoutExercise(exercise.id),
          sets: [
            for (final set in sets.where((s) => s.exerciseId == exercise.id))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(describeSet(set)),
                onTap: () => _editSet(set),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: '删除组',
                  onPressed: () => db.deleteWorkoutSet(set.id),
                ),
              ),
          ],
          onAddSet: () => _addSet(0, exercise),
        ),
    ];
  }

  /// 补记模式：动作与组来自本地暂存
  List<Widget> _buildDrafts() {
    return [
      for (var i = 0; i < _drafts.length; i++)
        _exerciseCard(
          title: '${_drafts[i].name}（${_drafts[i].category.label}）',
          onDelete: () => setState(() => _drafts.removeAt(i)),
          sets: [
            for (var j = 0; j < _drafts[i].sets.length; j++)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_describeDraftSet(_drafts[i].sets[j])),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: '删除组',
                  onPressed: () => setState(() => _drafts[i].sets.removeAt(j)),
                ),
              ),
          ],
          onAddSet: () => _addSet(i, null),
        ),
    ];
  }

  Widget _exerciseCard({
    required String title,
    required VoidCallback onDelete,
    required List<Widget> sets,
    required VoidCallback onAddSet,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: '删除动作',
                    onPressed: onDelete,
                  ),
                ],
              ),
              ...sets,
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加组'),
                onPressed: onAddSet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
