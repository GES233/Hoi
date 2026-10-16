import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';

PlanMetric _metricForTracking(TrackingType tracking) => switch (tracking) {
  TrackingType.duration => PlanMetric.duration,
  TrackingType.reps => PlanMetric.sets,
  TrackingType.distance => PlanMetric.distance,
};

TrackingType _trackingForMetric(PlanMetric metric) => switch (metric) {
  PlanMetric.duration => TrackingType.duration,
  PlanMetric.sets => TrackingType.reps,
  PlanMetric.distance => TrackingType.distance,
};

/// 单个模板动作的最低／常规描述。
String describeExerciseThresholds(
  TemplateExercise exercise,
  List<TemplateSet> sets,
) {
  final metric = _metricForTracking(exercise.trackingTypeSnapshot);
  switch (metric) {
    case PlanMetric.duration:
      final hasMin = sets.any(
        (s) => s.minimumDurationSeconds != null && s.minimumDurationSeconds! > 0,
      );
      final minimum = hasMin
          ? sets.fold<int>(0, (sum, s) => sum + (s.minimumDurationSeconds ?? 0))
          : null;
      final regular = sets.fold<int>(
        0,
        (sum, s) => sum + (s.durationSeconds ?? 0),
      );
      String format(int value) => '${value ~/ 60} 分钟';
      final minimumText = minimum == null || minimum == 0
          ? '未设置最低量'
          : '最低 ${format(minimum)}';
      return '$minimumText / 常规 ${format(regular)}';
    case PlanMetric.distance:
      final hasMin = sets.any(
        (s) => s.minimumDistanceMeters != null && s.minimumDistanceMeters! > 0,
      );
      final minimum = hasMin
          ? sets
                .fold<double>(
                  0,
                  (sum, s) => sum + (s.minimumDistanceMeters ?? 0),
                )
                .round()
          : null;
      final regular = sets
          .fold<double>(0, (sum, s) => sum + (s.distanceMeters ?? 0))
          .round();
      String format(int value) => '$value 米';
      final minimumText = minimum == null || minimum == 0
          ? '未设置最低量'
          : '最低 ${format(minimum)}';
      return '$minimumText / 常规 ${format(regular)}';
    case PlanMetric.sets:
      final minimum = sets
          .where((set) => set.minimumReps != null && set.minimumReps! > 0)
          .length;
      final regular = sets.length;
      final minimumText = minimum == 0 ? '未设置最低量' : '最低 $minimum 组';
      final repsPerSet = sets.isEmpty ? 1 : (sets.first.reps ?? 1);
      final allSameReps = sets.every((s) => (s.reps ?? 1) == repsPerSet);
      final regularText = allSameReps && repsPerSet > 1
          ? '$regular 组 × $repsPerSet 次'
          : '$regular 组';
      return '$minimumText / 常规 $regularText';
  }
}

/// 模板的最低／常规描述（兼容单动作与多动作模板）。
String describeTemplateThresholds(WorkoutTemplateDefinition definition) {
  if (definition.exercises.isEmpty) return '';
  if (definition.exercises.length == 1) {
    return describeExerciseThresholds(
      definition.exercises.single,
      definition.sets,
    );
  }
  return [
    for (final ex in definition.exercises)
      '${ex.exerciseNameSnapshot}（${describeExerciseThresholds(ex, definition.sets.where((s) => s.templateExerciseId == ex.id).toList())}）',
  ].join(' · ');
}

/// 方案管理页：支持单动作与多动作模板、以及按时长/组数/距离三种口径编辑。
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  Future<void> _confirmArchive(
    BuildContext context,
    WidgetRef ref,
    WorkoutTemplateSummary summary,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('归档方案'),
        content: Text('归档「${summary.version.name}」？历史训练和旧版本会继续保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('归档'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(databaseProvider)
          .archiveWorkoutTemplate(summary.template.id);
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    WorkoutTemplateSummary summary,
  ) async {
    final definition = await ref
        .read(databaseProvider)
        .getTemplateDefinition(summary.template.id);
    if (!context.mounted || definition == null) return;
    await showTemplateFormDialog(context, editing: definition);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(workoutTemplatesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('运动方案')),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('方案加载失败')),
        data: (templates) => templates.isEmpty
            ? const Center(child: Text('尚未设置最低／常规方案'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final summary in templates)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: _TemplateListTile(
                          summary: summary,
                          onTap: () => _edit(context, ref, summary),
                          onArchive: () =>
                              _confirmArchive(context, ref, summary),
                        ),
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_plan',
        icon: const Icon(Icons.add),
        label: const Text('新建方案'),
        onPressed: () => showTemplateFormDialog(context),
      ),
    );
  }
}

class _TemplateListTile extends ConsumerWidget {
  const _TemplateListTile({
    required this.summary,
    required this.onTap,
    required this.onArchive,
  });

  final WorkoutTemplateSummary summary;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definitionAsync = ref.watch(
      templateDefinitionProvider(summary.template.id),
    );
    final definition = definitionAsync.value;
    var subtitle = definitionAsync.hasError ? '模板详情加载失败' : '加载中…';
    if (definition != null) {
      final note = definition.version.note;
      final noteSuffix = note != null && note.isNotEmpty ? '\n$note' : '';
      if (definition.exercises.length == 1) {
        final single = definition.exercises.single;
        final metricLabel = switch (_metricForTracking(
          single.trackingTypeSnapshot,
        )) {
          PlanMetric.duration => '时长',
          PlanMetric.sets => '有效组数',
          PlanMetric.distance => '距离',
        };
        subtitle =
            '${single.exerciseNameSnapshot}（${single.categorySnapshot.label}） · '
            '$metricLabel · '
            '${describeTemplateThresholds(definition)}'
            '$noteSuffix';
      } else {
        final names = definition.exercises
            .map((e) => e.exerciseNameSnapshot)
            .join('、');
        subtitle =
            '$names · ${definition.exercises.length} 个动作 · ${definition.sets.length} 个计划组'
            '$noteSuffix';
      }
    }
    return ListTile(
      title: Text(
        '${summary.version.name} · v${summary.version.versionNumber}',
      ),
      subtitle: Text(subtitle),
      isThreeLine: subtitle.contains('\n'),
      onTap: onTap,
      trailing: IconButton(
        icon: const Icon(Icons.archive_outlined),
        tooltip: '归档方案',
        onPressed: onArchive,
      ),
    );
  }
}

Future<void> showTemplateFormDialog(
  BuildContext context, {
  WorkoutTemplateDefinition? editing,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => TemplateFormDialog(editing: editing),
  );
}

class _TemplateExerciseDraft {
  _TemplateExerciseDraft({
    this.selectedExerciseId,
    String exerciseName = '',
    this.category = ExerciseCategory.cardio,
    this.metric = PlanMetric.duration,
    String minimumText = '',
    String regularText = '',
    String repsPerSetText = '1',
  }) : exerciseController = TextEditingController(text: exerciseName),
       minimumController = TextEditingController(text: minimumText),
       regularController = TextEditingController(text: regularText),
       repsPerSetController = TextEditingController(text: repsPerSetText);

  factory _TemplateExerciseDraft.fromDefinition(
    TemplateExercise exercise,
    List<TemplateSet> sets,
  ) {
    final metric = _metricForTracking(exercise.trackingTypeSnapshot);
    int? minimum;
    late final int regular;
    var repsPerSet = 1;
    switch (metric) {
      case PlanMetric.duration:
        final hasMin = sets.any(
          (s) =>
              s.minimumDurationSeconds != null && s.minimumDurationSeconds! > 0,
        );
        final minSec = hasMin
            ? sets.fold<int>(
                0,
                (sum, s) => sum + (s.minimumDurationSeconds ?? 0),
              )
            : null;
        final regSec = sets.fold<int>(
          0,
          (sum, s) => sum + (s.durationSeconds ?? 0),
        );
        minimum = minSec == null
            ? null
            : (minSec / 60).round().clamp(1, 999999);
        regular = regSec <= 0 ? 1 : (regSec / 60).round().clamp(1, 999999);
      case PlanMetric.distance:
        final hasMin = sets.any(
          (s) =>
              s.minimumDistanceMeters != null && s.minimumDistanceMeters! > 0,
        );
        minimum = hasMin
            ? sets
                  .fold<double>(
                    0,
                    (sum, s) => sum + (s.minimumDistanceMeters ?? 0),
                  )
                  .round()
            : null;
        regular = sets
            .fold<double>(0, (sum, s) => sum + (s.distanceMeters ?? 0))
            .round();
      case PlanMetric.sets:
        final minCount = sets
            .where((set) => set.minimumReps != null && set.minimumReps! > 0)
            .length;
        minimum = minCount == 0 ? null : minCount;
        regular = sets.length;
        repsPerSet = sets.isEmpty ? 1 : (sets.first.reps ?? 1);
    }
    return _TemplateExerciseDraft(
      selectedExerciseId: exercise.exerciseId,
      exerciseName: exercise.exerciseNameSnapshot,
      category: exercise.categorySnapshot,
      metric: metric,
      minimumText: minimum == null ? '' : '$minimum',
      regularText: '$regular',
      repsPerSetText: '$repsPerSet',
    );
  }

  int? selectedExerciseId;
  ExerciseCategory category;
  PlanMetric metric;
  final TextEditingController exerciseController;
  final TextEditingController minimumController;
  final TextEditingController regularController;
  final TextEditingController repsPerSetController;

  String get unitLabel => switch (metric) {
    PlanMetric.duration => '分钟',
    PlanMetric.sets => '组数',
    PlanMetric.distance => '米',
  };

  void dispose() {
    exerciseController.dispose();
    minimumController.dispose();
    regularController.dispose();
    repsPerSetController.dispose();
  }
}

class TemplateFormDialog extends ConsumerStatefulWidget {
  const TemplateFormDialog({super.key, this.editing});

  final WorkoutTemplateDefinition? editing;

  @override
  ConsumerState<TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends ConsumerState<TemplateFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;
  final List<_TemplateExerciseDraft> _exercises = [];
  bool _saving = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final definition = widget.editing;
    _nameController = TextEditingController(
      text: definition?.version.name ?? '',
    );
    _noteController = TextEditingController(
      text: definition?.version.note ?? '',
    );
    if (definition == null || definition.exercises.isEmpty) {
      _exercises.add(_TemplateExerciseDraft());
    } else {
      for (final exercise in definition.exercises) {
        final exerciseSets = definition.sets
            .where((s) => s.templateExerciseId == exercise.id)
            .toList();
        _exercises.add(
          _TemplateExerciseDraft.fromDefinition(exercise, exerciseSets),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    for (final draft in _exercises) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final note = _noteController.text.trim();
    try {
      final editing = widget.editing;
      await db.transaction(() async {
        final exerciseInputs = <TemplateExerciseInput>[];
        for (final draft in _exercises) {
          final minimumText = draft.minimumController.text.trim();
          final minimumInput = minimumText.isEmpty
              ? null
              : int.parse(minimumText);
          final regularInput = int.parse(draft.regularController.text.trim());
          final repsPerSetText = draft.repsPerSetController.text.trim();
          final repsPerSet = repsPerSetText.isEmpty
              ? 1
              : int.parse(repsPerSetText);
          final tracking = _trackingForMetric(draft.metric);
          final int catalogId;
          if (draft.selectedExerciseId == null) {
            catalogId = await db.insertExercise(
              name: draft.exerciseController.text,
              category: draft.category,
              trackingType: tracking,
            );
          } else {
            catalogId = draft.selectedExerciseId!;
          }
          final sets = switch (draft.metric) {
            PlanMetric.duration => [
              TemplateSetInput(
                durationSeconds: regularInput * 60,
                minimumDurationSeconds: minimumInput == null
                    ? null
                    : minimumInput * 60,
              ),
            ],
            PlanMetric.distance => [
              TemplateSetInput(
                distanceMeters: regularInput.toDouble(),
                minimumDistanceMeters: minimumInput?.toDouble(),
              ),
            ],
            PlanMetric.sets => [
              for (var i = 0; i < regularInput; i++)
                TemplateSetInput(
                  reps: repsPerSet,
                  minimumReps: minimumInput != null && i < minimumInput
                      ? repsPerSet
                      : null,
                ),
            ],
          };
          exerciseInputs.add(
            TemplateExerciseInput(exerciseId: catalogId, sets: sets),
          );
        }
        if (editing == null) {
          await db.createWorkoutTemplate(
            name: _nameController.text,
            exercises: exerciseInputs,
            note: note.isEmpty ? null : note,
          );
        } else {
          await db.reviseWorkoutTemplate(
            editing.template.id,
            name: _nameController.text,
            exercises: exerciseInputs,
            note: note.isEmpty ? null : note,
          );
        }
      });
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildExerciseFields(
    int index,
    _TemplateExerciseDraft draft,
    List<Exercise> catalog,
  ) {
    final selectedExists = catalog.any(
      (exercise) => exercise.id == draft.selectedExerciseId,
    );
    final unitLabel = draft.unitLabel;
    final fields = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_exercises.length > 1)
          Row(
            children: [
              Text(
                '动作 ${index + 1}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              IconButton(
                tooltip: '移除动作',
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => setState(() {
                  _exercises.removeAt(index).dispose();
                }),
              ),
            ],
          ),
        DropdownButtonFormField<int>(
          key: ValueKey('exercise-$index-${draft.selectedExerciseId ?? -1}'),
          initialValue: draft.selectedExerciseId ?? -1,
          isExpanded: true,
          decoration: const InputDecoration(labelText: '动作库'),
          items: [
            const DropdownMenuItem(value: -1, child: Text('新建自定义动作')),
            if (draft.selectedExerciseId != null && !selectedExists)
              DropdownMenuItem(
                value: draft.selectedExerciseId,
                child: Text(
                  '${draft.exerciseController.text}（已归档）',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            for (final exercise in catalog)
              DropdownMenuItem(
                value: exercise.id,
                child: Text(
                  '${exercise.name} · ${exercise.trackingType.label}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) {
            final id = value == -1 ? null : value;
            setState(() {
              draft.selectedExerciseId = id;
              if (id == null) {
                draft.exerciseController.clear();
                return;
              }
              final exercise = catalog.firstWhere((item) => item.id == id);
              draft.exerciseController.text = exercise.name;
              draft.category = exercise.category;
              draft.metric = _metricForTracking(exercise.trackingType);
            });
          },
        ),
        TextFormField(
          controller: draft.exerciseController,
          enabled: draft.selectedExerciseId == null,
          decoration: const InputDecoration(labelText: '动作名称'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? '请输入动作名称' : null,
        ),
        DropdownButtonFormField<ExerciseCategory>(
          key: ValueKey(
            'template-category-$index-${draft.selectedExerciseId ?? -1}-${draft.category}',
          ),
          initialValue: draft.category,
          decoration: const InputDecoration(labelText: '类别'),
          items: [
            for (final category in ExerciseCategory.values)
              DropdownMenuItem(value: category, child: Text(category.label)),
          ],
          onChanged: draft.selectedExerciseId != null
              ? null
              : (value) => setState(
                  () => draft.category = value ?? ExerciseCategory.cardio,
                ),
        ),
        DropdownButtonFormField<PlanMetric>(
          key: ValueKey(
            'template-metric-$index-${draft.selectedExerciseId ?? -1}-${draft.metric}',
          ),
          initialValue: draft.metric,
          decoration: const InputDecoration(labelText: '指标'),
          items: const [
            DropdownMenuItem(value: PlanMetric.duration, child: Text('持续时长')),
            DropdownMenuItem(value: PlanMetric.sets, child: Text('有效组数')),
            DropdownMenuItem(value: PlanMetric.distance, child: Text('距离')),
          ],
          onChanged: draft.selectedExerciseId != null
              ? null
              : (value) => setState(
                  () => draft.metric = value ?? PlanMetric.duration,
                ),
        ),
        TextFormField(
          controller: draft.minimumController,
          decoration: InputDecoration(labelText: '最低量（$unitLabel，可选）'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return null;
            final parsed = int.tryParse(text);
            if (parsed == null || parsed <= 0) return '最低量需大于 0，或留空';
            return null;
          },
        ),
        TextFormField(
          controller: draft.regularController,
          decoration: InputDecoration(labelText: '常规量（$unitLabel）'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            final regular = int.tryParse(value?.trim() ?? '');
            if (regular == null || regular <= 0) return '常规量需大于 0';
            final minimum = int.tryParse(draft.minimumController.text.trim());
            if (minimum != null && regular < minimum) {
              return '常规量不能低于最低量';
            }
            return null;
          },
        ),
        if (draft.metric == PlanMetric.sets)
          TextFormField(
            controller: draft.repsPerSetController,
            decoration: const InputDecoration(labelText: '每组目标次数（默认 1）'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return null;
              final parsed = int.tryParse(text);
              if (parsed == null || parsed <= 0) return '每组目标次数需大于 0';
              return null;
            },
          ),
      ],
    );
    if (_exercises.length == 1) return fields;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: fields),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(exercisesProvider).value ?? const <Exercise>[];
    return AlertDialog(
      title: Text(_isEditing ? '编辑方案' : '新建方案'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '方案名称'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入方案名称' : null,
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _exercises.length; i++) ...[
                  _buildExerciseFields(i, _exercises[i], catalog),
                  if (i != _exercises.length - 1) const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('添加计划动作'),
                  onPressed: () =>
                      setState(() => _exercises.add(_TemplateExerciseDraft())),
                ),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: '说明（可选）'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
