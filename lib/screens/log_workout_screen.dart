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
  _DraftSet({this.reps, this.durationSeconds, this.weightKg, this.note});

  int? reps;
  int? durationSeconds;
  double? weightKg;
  String? note;

  bool get isValid => (reps ?? 0) > 0 || (durationSeconds ?? 0) > 0;
}

/// 补记模式本地暂存的动作
class _DraftExercise {
  _DraftExercise({required this.name, required this.category, this.note});

  String name;
  ExerciseCategory category;
  String? note;
  final List<_DraftSet> sets = [];
}

class _LogWorkoutScreenState extends ConsumerState<LogWorkoutScreen> {
  final _minutesController = TextEditingController();
  final _feelingController = TextEditingController();
  final List<_DraftExercise> _drafts = [];
  late DateTime _date;

  /// 关联的方案 id；null 表示不关联
  int? _selectedPlanId;
  bool _saving = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _date = AppDatabase.dateOnly(editing?.date ?? widget.initialDate!);
    _selectedPlanId = editing?.planId;
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
        note: draft.note,
      );
    } else {
      setState(() => _drafts.add(
          _DraftExercise(name: draft.name, category: draft.category, note: draft.note)));
    }
  }

  Future<void> _addSet(int index, WorkoutExercise? live) async {
    final draft = await showAddWorkoutSetDialog(context);
    if (draft == null) return;
    if (live != null) {
      await ref.read(databaseProvider).addWorkoutSet(
            live.id,
            reps: draft.reps,
            durationSeconds: draft.durationSeconds,
            weightKg: draft.weightKg,
            note: draft.note,
          );
    } else {
      setState(() => _drafts[index].sets.add(_DraftSet(
            reps: draft.reps,
            durationSeconds: draft.durationSeconds,
            weightKg: draft.weightKg,
            note: draft.note,
          )));
    }
  }

  /// 编辑已保存的组（编辑模式，实时写库）
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

  String _describeDraftSet(_DraftSet s) {
    final parts = <String>[];
    if ((s.reps ?? 0) > 0) parts.add('${s.reps} 次');
    final d = s.durationSeconds;
    if (d != null && d > 0) {
      parts.add(d >= 60
          ? '${(d / 60).toStringAsFixed(d % 60 == 0 ? 0 : 1)} 分钟'
          : '$d 秒');
    }
    if ((s.weightKg ?? 0) > 0) parts.add('${s.weightKg} kg');
    if (parts.isEmpty) parts.add('（无效组）');
    if (s.note != null && s.note!.isNotEmpty) parts.add(s.note!);
    return parts.join(' · ');
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final messenger = ScaffoldMessenger.of(context);
    final feeling = _feelingController.text.trim();
    // 选中的方案对象（方案可能已被删除，找不到则视为不关联）
    final plans = ref.read(exercisePlansProvider).value ?? [];
    final linked =
        plans.where((p) => p.id == _selectedPlanId).firstOrNull;
    int? savedId;
    try {
      if (_isEditing) {
        savedId = widget.editing!.id;
        await db.updateWorkoutMeta(
          savedId,
          totalSeconds: Value(_parsedTotalSeconds),
          feeling: Value(feeling.isEmpty ? null : feeling),
        );
        if (linked != null) {
          await db.linkPlanToWorkout(savedId, linked);
        } else if (widget.editing!.planId != null) {
          await db.clearPlanLink(savedId);
        }
      } else {
        final hasValid =
            _drafts.any((e) => e.sets.any((s) => s.isValid));
        if (!hasValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('至少需要一条有效组（次数或持续时间大于 0）才能保存')),
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
            note: exercise.note,
          );
          for (final set in exercise.sets) {
            await db.addWorkoutSet(
              exerciseId,
              reps: set.reps,
              durationSeconds: set.durationSeconds,
              weightKg: set.weightKg,
              note: set.note,
            );
          }
        }
        if (linked != null) await db.linkPlanToWorkout(savedId, linked);
      }
      // 关联了方案时按保存后的实际记录给出达标反馈
      if (linked != null) {
        final w = await db.getWorkout(savedId);
        if (w != null) {
          final ev = AppDatabase.evaluateWorkout(
            w,
            await db.getWorkoutExercises(savedId),
            await db.getWorkoutSets(savedId),
          );
          messenger.showSnackBar(
            SnackBar(content: Text(describePlanEvaluation(ev, w))),
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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

  /// 关联方案下拉：无 / 各方案；选中的方案已被删除时回退为「无」
  Widget _buildPlanDropdown() {
    final plans = ref.watch(exercisePlansProvider).value ?? [];
    final effectiveId =
        plans.any((p) => p.id == _selectedPlanId) ? _selectedPlanId : null;
    return DropdownButtonFormField<int?>(
      initialValue: effectiveId,
      decoration: const InputDecoration(labelText: '关联方案（可选）'),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('无')),
        for (final p in plans)
          DropdownMenuItem<int?>(value: p.id, child: Text(p.name)),
      ],
      onChanged: (v) => setState(() => _selectedPlanId = v),
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
            for (final set
                in sets.where((s) => s.exerciseId == exercise.id))
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
                  onPressed: () =>
                      setState(() => _drafts[i].sets.removeAt(j)),
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
                    child: Text(title,
                        style: Theme.of(context).textTheme.titleSmall),
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
