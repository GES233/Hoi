import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/workout_dialogs.dart';

/// 补记 / 编辑已完成训练。
/// 补记与编辑模式均在本地草稿（_drafts）中维护动作与组：
/// - 取消返回时不会污染数据库中的已有记录；
/// - 两种模式下组行均可点按编辑；
/// - 点击保存时校验至少含一条有效组，并在单个数据库事务内原子写入与关联方案。
class LogWorkoutScreen extends ConsumerStatefulWidget {
  const LogWorkoutScreen({super.key, required this.initialDate})
    : editing = null,
      singleExercise = false;

  const LogWorkoutScreen.singleExercise({super.key, required this.initialDate})
    : editing = null,
      singleExercise = true;

  const LogWorkoutScreen.editing({super.key, required Workout workout})
    : editing = workout,
      initialDate = null,
      singleExercise = false;

  /// 补记模式的初始日期（通常为首页选中日期）
  final DateTime? initialDate;

  /// 编辑模式下被编辑的已完成训练
  final Workout? editing;

  /// 单项模式只记录一个动作，不关联训练方案。
  final bool singleExercise;

  @override
  ConsumerState<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

/// 本地暂存的组（编辑模式下保留原 id、templateSetId 及扩展字段）
class _DraftSet {
  _DraftSet({
    this.id,
    this.templateSetId,
    this.reps,
    this.durationSeconds,
    this.distanceMeters,
    this.weightKg,
    this.assistanceKg,
    this.rpe,
    this.rir,
    this.setRole = SetRole.work,
    this.setStatus = SetStatus.completed,
    this.note,
  });

  int? id;
  int? templateSetId;
  int? reps;
  int? durationSeconds;
  double? distanceMeters;
  double? weightKg;
  double? assistanceKg;
  double? rpe;
  double? rir;
  SetRole setRole;
  SetStatus setStatus;
  String? note;

  WorkoutSet toPreviewSet({int exerciseId = -1, int sortOrder = 0}) =>
      WorkoutSet(
        id: id ?? -1,
        exerciseId: exerciseId,
        templateSetId: templateSetId,
        setRole: setRole,
        setStatus: setStatus,
        reps: reps,
        durationSeconds: durationSeconds,
        distanceMeters: distanceMeters,
        weightKg: weightKg,
        assistanceKg: assistanceKg,
        rpe: rpe,
        rir: rir,
        note: note,
        sortOrder: sortOrder,
      );

  bool isValid(TrackingType trackingType) => AppDatabase.isValidSet(
    toPreviewSet(),
    trackingType: trackingType,
  );
}

/// 本地暂存的动作（编辑模式下保留原 id 与 templateExerciseId；未落库的新自定义动作 catalogExerciseId 可为空，保存时一并入库）
class _DraftExercise {
  _DraftExercise({
    this.id,
    this.catalogExerciseId,
    this.templateExerciseId,
    required this.name,
    required this.category,
    required this.trackingType,
    required this.loadConvention,
    required this.repsConvention,
    this.note,
    List<_DraftSet>? sets,
  }) : sets = sets ?? [];

  int? id;
  int? catalogExerciseId;
  int? templateExerciseId;
  String name;
  ExerciseCategory category;
  TrackingType trackingType;
  LoadConvention loadConvention;
  RepsConvention repsConvention;
  String? note;
  final List<_DraftSet> sets;
}

class _LogWorkoutScreenState extends ConsumerState<LogWorkoutScreen> {
  final _minutesController = TextEditingController();
  final _feelingController = TextEditingController();
  final List<_DraftExercise> _drafts = [];
  late DateTime _date;
  DateTime? _startedAt;
  DateTime? _endedAt;

  /// 关联的模板版本 id；null 表示不关联
  int? _selectedTemplateVersionId;
  bool _loadingEditing = false;
  bool _saving = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _date = AppDatabase.dateOnly(editing?.date ?? widget.initialDate!);
    if (editing != null) {
      _startedAt = editing.startedAt;
      _endedAt = editing.endedAt;
      _loadingEditing = true;
      _loadEditingExercises(editing.id);
    } else {
      final now = ref.read(appClockProvider)();
      _startedAt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        now.hour,
        now.minute,
      );
      _endedAt = _startedAt!.add(const Duration(hours: 1));
    }
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

  Future<void> _loadEditingExercises(int workoutId) async {
    final db = ref.read(databaseProvider);
    final exercises = await db.getWorkoutExercises(workoutId);
    final sets = await db.getWorkoutSets(workoutId);
    if (!mounted) return;
    setState(() {
      _drafts
        ..clear()
        ..addAll([
          for (final e in exercises)
            _DraftExercise(
              id: e.id,
              catalogExerciseId: e.catalogExerciseId,
              templateExerciseId: e.templateExerciseId,
              name: e.name,
              category: e.category,
              trackingType: e.trackingTypeSnapshot,
              loadConvention: e.loadConventionSnapshot,
              repsConvention: e.repsConventionSnapshot,
              note: e.note,
              sets: [
                for (final s in sets.where((s) => s.exerciseId == e.id))
                  _DraftSet(
                    id: s.id,
                    templateSetId: s.templateSetId,
                    reps: s.reps,
                    durationSeconds: s.durationSeconds,
                    distanceMeters: s.distanceMeters,
                    weightKg: s.weightKg,
                    assistanceKg: s.assistanceKg,
                    rpe: s.rpe,
                    rir: s.rir,
                    setRole: s.setRole,
                    setStatus: s.setStatus,
                    note: s.note,
                  ),
              ],
            ),
        ]);
      _loadingEditing = false;
    });
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

  int? get _effectiveTotalSeconds {
    final entered = _parsedTotalSeconds;
    if (entered != null) return entered;
    final start = _startedAt;
    final end = _endedAt;
    return start == null || end == null
        ? null
        : end.difference(start).inSeconds;
  }

  Future<void> _pickDate() async {
    final now = ref.read(appClockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: AppDatabase.dateOnly(now).add(const Duration(days: 1)),
    );
    if (picked == null) return;
    final newDate = AppDatabase.dateOnly(picked);
    final delta = newDate.difference(_date);
    setState(() {
      _date = newDate;
      if (_startedAt != null) _startedAt = _startedAt!.add(delta);
      if (_endedAt != null) _endedAt = _endedAt!.add(delta);
    });
  }

  Future<void> _pickStartTime() async {
    final current = _startedAt;
    final picked = await showTimePicker(
      context: context,
      initialTime: current == null
          ? const TimeOfDay(hour: 18, minute: 0)
          : TimeOfDay.fromDateTime(current),
    );
    if (picked == null) return;
    final next = DateTime(
      _date.year,
      _date.month,
      _date.day,
      picked.hour,
      picked.minute,
    );
    setState(() {
      final oldStart = _startedAt;
      final oldEnd = _endedAt;
      _startedAt = next;
      if (oldStart != null && oldEnd != null) {
        _endedAt = next.add(oldEnd.difference(oldStart));
      }
    });
  }

  Future<void> _pickEndTime() async {
    final current = _endedAt;
    final picked = await showTimePicker(
      context: context,
      initialTime: current == null
          ? const TimeOfDay(hour: 19, minute: 0)
          : TimeOfDay.fromDateTime(current),
    );
    if (picked == null) return;
    var next = DateTime(
      _date.year,
      _date.month,
      _date.day,
      picked.hour,
      picked.minute,
    );
    final start = _startedAt;
    if (start != null && !next.isAfter(start)) {
      next = next.add(const Duration(days: 1));
    }
    setState(() => _endedAt = next);
  }

  Future<void> _onTemplateChanged(int? versionId) async {
    setState(() => _selectedTemplateVersionId = versionId);
    // 补记模式下，若当前尚未添加任何动作且选择了方案，自动预填方案中的计划动作
    if (!_isEditing && versionId != null && _drafts.isEmpty) {
      final definition = await ref
          .read(databaseProvider)
          .getTemplateDefinitionByVersion(versionId);
      if (!mounted ||
          definition == null ||
          _selectedTemplateVersionId != versionId ||
          _drafts.isNotEmpty) {
        return;
      }
      setState(() {
        for (final planned in definition.exercises) {
          _drafts.add(
            _DraftExercise(
              catalogExerciseId: planned.exerciseId,
              templateExerciseId: planned.id,
              name: planned.exerciseNameSnapshot,
              category: planned.categorySnapshot,
              trackingType: planned.trackingTypeSnapshot,
              loadConvention: planned.loadConventionSnapshot,
              repsConvention: planned.repsConventionSnapshot,
              note: planned.note,
            ),
          );
        }
      });
    }
  }

  Future<void> _addExercise() async {
    final exercises = await ref.read(databaseProvider).getExercises();
    if (!mounted) return;
    final draft = await showAddWorkoutExerciseDialog(
      context,
      exercises: exercises,
    );
    if (draft == null) return;
    setState(
      () => _drafts.add(
        _DraftExercise(
          catalogExerciseId: draft.catalogExerciseId,
          name: draft.name,
          category: draft.category,
          trackingType: draft.trackingType,
          loadConvention: draft.loadConvention,
          repsConvention: draft.repsConvention,
          note: draft.note,
        ),
      ),
    );
  }

  Future<void> _addSet(int exerciseIndex) async {
    final exercise = _drafts[exerciseIndex];
    final prefill = exercise.sets.isEmpty
        ? null
        : exercise.sets.last.toPreviewSet();
    final draft = await showAddWorkoutSetDialog(
      context,
      prefill: prefill,
      trackingType: exercise.trackingType,
      loadConvention: exercise.loadConvention,
    );
    if (draft == null) return;
    setState(
      () => _drafts[exerciseIndex].sets.add(
        _DraftSet(
          reps: draft.reps,
          durationSeconds: draft.durationSeconds,
          distanceMeters: draft.distanceMeters,
          weightKg: draft.weightKg,
          assistanceKg: draft.assistanceKg,
          rpe: draft.rpe,
          rir: draft.rir,
          setRole: draft.setRole,
          setStatus: draft.setStatus,
          note: draft.note,
        ),
      ),
    );
  }

  /// 点按编辑草稿中的组（补记模式与编辑模式共用）
  Future<void> _editDraftSet(int exerciseIndex, int setIndex) async {
    final exercise = _drafts[exerciseIndex];
    final current = exercise.sets[setIndex];
    final draft = await showEditWorkoutSetDialog(
      context,
      current.toPreviewSet(),
      trackingType: exercise.trackingType,
      loadConvention: exercise.loadConvention,
    );
    if (draft == null) return;
    setState(() {
      current
        ..setRole = draft.setRole
        ..setStatus = draft.setStatus
        ..reps = draft.reps
        ..durationSeconds = draft.durationSeconds
        ..distanceMeters = draft.distanceMeters
        ..weightKg = draft.weightKg
        ..assistanceKg = draft.assistanceKg
        ..rpe = draft.rpe
        ..rir = draft.rir
        ..note = draft.note;
    });
  }

  Future<void> _save() async {
    if (_saving || _loadingEditing) return;
    final startedAt = _startedAt;
    final endedAt = _endedAt;
    if (startedAt == null || endedAt == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请选择开始和结束时间')));
      return;
    }
    if (!endedAt.isAfter(startedAt)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('结束时间必须晚于开始时间')));
      return;
    }
    final hasValid = _drafts.any(
      (e) => e.sets.any((s) => s.isValid(e.trackingType)),
    );
    if (!hasValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少需要一条有效组（次数或持续时间大于 0）才能保存')),
      );
      return;
    }

    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final messenger = ScaffoldMessenger.of(context);
    final feeling = _feelingController.text.trim();
    TemplateVersion? linkedVersion;
    late final int savedId;
    try {
      await db.transaction(() async {
        linkedVersion = _selectedTemplateVersionId == null
            ? null
            : await db.getTemplateVersion(_selectedTemplateVersionId!);

        // 先确保新建的自定义动作写入动作目录
        for (final exercise in _drafts) {
          exercise.catalogExerciseId ??= await db.insertExercise(
            name: exercise.name,
            category: exercise.category,
            trackingType: exercise.trackingType,
            loadConvention: exercise.loadConvention,
            repsConvention: exercise.repsConvention,
          );
        }

        if (_isEditing) {
          savedId = widget.editing!.id;
          await db.updateWorkoutMeta(
            savedId,
            startedAt: startedAt,
            endedAt: endedAt,
            totalSeconds: Value(_effectiveTotalSeconds),
            feeling: Value(feeling.isEmpty ? null : feeling),
          );
          final existingExercises = await db.getWorkoutExercises(savedId);
          final keptExerciseIds = _drafts
              .map((e) => e.id)
              .whereType<int>()
              .toSet();
          for (final old in existingExercises) {
            if (!keptExerciseIds.contains(old.id)) {
              await db.deleteWorkoutExercise(old.id);
            }
          }
          for (final exercise in _drafts) {
            final int exerciseId;
            if (exercise.id != null) {
              exerciseId = exercise.id!;
              final existingSets =
                  await (db.select(db.workoutSets)
                        ..where((s) => s.exerciseId.equals(exerciseId)))
                      .get();
              final keptSetIds = exercise.sets
                  .map((s) => s.id)
                  .whereType<int>()
                  .toSet();
              for (final oldSet in existingSets) {
                if (!keptSetIds.contains(oldSet.id)) {
                  await db.deleteWorkoutSet(oldSet.id);
                }
              }
            } else {
              exerciseId = await db.addWorkoutExercise(
                savedId,
                catalogExerciseId: exercise.catalogExerciseId,
                templateExerciseId: exercise.templateExerciseId,
                name: exercise.name,
                category: exercise.category,
                trackingType: exercise.trackingType,
                loadConvention: exercise.loadConvention,
                repsConvention: exercise.repsConvention,
                note: exercise.note,
              );
              exercise.id = exerciseId;
            }
            for (final set in exercise.sets) {
              if (set.id != null) {
                await db.updateWorkoutSet(
                  set.id!,
                  setRole: Value(set.setRole),
                  setStatus: Value(set.setStatus),
                  reps: Value(set.reps),
                  durationSeconds: Value(set.durationSeconds),
                  distanceMeters: Value(set.distanceMeters),
                  weightKg: Value(set.weightKg),
                  assistanceKg: Value(set.assistanceKg),
                  rpe: Value(set.rpe),
                  rir: Value(set.rir),
                  note: Value(set.note),
                );
              } else {
                await db.addWorkoutSet(
                  exerciseId,
                  templateSetId: set.templateSetId,
                  setRole: set.setRole,
                  setStatus: set.setStatus,
                  reps: set.reps,
                  durationSeconds: set.durationSeconds,
                  distanceMeters: set.distanceMeters,
                  weightKg: set.weightKg,
                  assistanceKg: set.assistanceKg,
                  rpe: set.rpe,
                  rir: set.rir,
                  note: set.note,
                );
              }
            }
          }
          if (linkedVersion != null) {
            await db.linkTemplateToWorkout(savedId, linkedVersion!);
          } else if (widget.editing!.templateVersionId != null) {
            await db.clearTemplateLink(savedId);
          }
        } else {
          savedId = await db.insertCompletedWorkout(
            startedAt: startedAt,
            endedAt: endedAt,
            totalSeconds: _effectiveTotalSeconds,
            feeling: feeling.isEmpty ? null : feeling,
          );
          for (final exercise in _drafts) {
            final exerciseId = await db.addWorkoutExercise(
              savedId,
              catalogExerciseId: exercise.catalogExerciseId,
              templateExerciseId: exercise.templateExerciseId,
              name: exercise.name,
              category: exercise.category,
              trackingType: exercise.trackingType,
              loadConvention: exercise.loadConvention,
              repsConvention: exercise.repsConvention,
              note: exercise.note,
            );
            for (final set in exercise.sets) {
              await db.addWorkoutSet(
                exerciseId,
                templateSetId: set.templateSetId,
                setRole: set.setRole,
                setStatus: set.setStatus,
                reps: set.reps,
                durationSeconds: set.durationSeconds,
                distanceMeters: set.distanceMeters,
                weightKg: set.weightKg,
                assistanceKg: set.assistanceKg,
                rpe: set.rpe,
                rir: set.rir,
                note: set.note,
              );
            }
          }
          if (linkedVersion != null) {
            await db.linkTemplateToWorkout(savedId, linkedVersion!);
          }
        }
      });

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
      appBar: AppBar(
        title: Text(
          _isEditing
              ? '编辑训练'
              : widget.singleExercise
              ? '记录单项运动'
              : '补记运动',
        ),
      ),
      body: _loadingEditing
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMetaCard(),
                const SizedBox(height: 12),
                ..._buildDrafts(),
                const SizedBox(height: 8),
                if (!widget.singleExercise || _drafts.isEmpty)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(widget.singleExercise ? '选择运动' : '添加动作'),
                    onPressed: _addExercise,
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(widget.singleExercise ? '保存记录' : '保存'),
                ),
              ],
            ),
    );
  }

  Widget _buildMetaCard() {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_note_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text('日期', style: Theme.of(context).textTheme.labelLarge),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(DateFormat('yyyy年M月d日').format(_date)),
                    onPressed: _pickDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(
                      _startedAt == null
                          ? '开始时间'
                          : DateFormat('HH:mm').format(_startedAt!),
                    ),
                    onPressed: _pickStartTime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.stop, size: 18),
                    label: Text(
                      _endedAt == null
                          ? '结束时间'
                          : '${_endedAt!.day != _date.day ? '次日 ' : ''}'
                                '${DateFormat('HH:mm').format(_endedAt!)}',
                    ),
                    onPressed: _pickEndTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _minutesController,
              decoration: const InputDecoration(
                labelText: '训练总用时（分钟，可调整）',
                helperText: '留空时使用开始至结束的时间跨度',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _feelingController,
              decoration: const InputDecoration(labelText: '感受（可选）'),
            ),
            if (!widget.singleExercise) ...[
              const SizedBox(height: 10),
              _buildPlanDropdown(),
            ],
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
      onChanged: _onTemplateChanged,
    );
  }

  /// 动作与组草稿列表（补记与编辑模式共用，均支持点按编辑组）
  List<Widget> _buildDrafts() {
    final scheme = Theme.of(context).colorScheme;
    return [
      for (var i = 0; i < _drafts.length; i++)
        _exerciseCard(
          category: _drafts[i].category,
          title: '${_drafts[i].name}（${_drafts[i].category.label}）',
          onDelete: () => setState(() => _drafts.removeAt(i)),
          sets: [
            for (var j = 0; j < _drafts[i].sets.length; j++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Material(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.only(left: 12, right: 4),
                    title: Text(describeSet(_drafts[i].sets[j].toPreviewSet())),
                    onTap: () => _editDraftSet(i, j),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: '删除组',
                      onPressed: () =>
                          setState(() => _drafts[i].sets.removeAt(j)),
                    ),
                  ),
                ),
              ),
          ],
          onAddSet: () => _addSet(i),
        ),
    ];
  }

  Widget _exerciseCard({
    required ExerciseCategory category,
    required String title,
    required VoidCallback onDelete,
    required List<Widget> sets,
    required VoidCallback onAddSet,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final accentColor = HoiTheme.categoryColor(scheme, category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      HoiTheme.categoryIcon(category),
                      size: 16,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: '删除动作',
                    onPressed: onDelete,
                  ),
                ],
              ),
              if (sets.isNotEmpty) const SizedBox(height: 6),
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
