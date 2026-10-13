import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';

PlanMetric _shortcutMetric(WorkoutTemplateDefinition definition) =>
    definition.exercises.single.trackingTypeSnapshot == TrackingType.duration
    ? PlanMetric.duration
    : PlanMetric.sets;

bool _isShortcutTemplate(WorkoutTemplateDefinition definition) {
  if (definition.exercises.length != 1 || definition.sets.isEmpty) return false;
  final tracking = definition.exercises.single.trackingTypeSnapshot;
  if (tracking == TrackingType.duration) {
    return definition.sets.length == 1 &&
        definition.sets.single.durationSeconds != null;
  }
  if (tracking == TrackingType.reps) {
    return definition.sets.every((set) => set.reps == 1);
  }
  return false;
}

/// 单动作快捷模板的最低／常规描述。
String describeTemplateThresholds(WorkoutTemplateDefinition definition) {
  final metric = _shortcutMetric(definition);
  final minimum = metric == PlanMetric.duration
      ? definition.sets.single.minimumDurationSeconds
      : definition.sets.where((set) => set.minimumReps != null).length;
  final regular = metric == PlanMetric.duration
      ? definition.sets.single.durationSeconds!
      : definition.sets.length;
  String format(int value) =>
      metric == PlanMetric.duration ? '${value ~/ 60} 分钟' : '$value 组';
  final minimumText = minimum == null || minimum == 0
      ? '未设置最低量'
      : '最低 ${format(minimum)}';
  return '$minimumText / 常规 ${format(regular)}';
}

/// 方案管理页目前提供单动作模板快捷编辑；底层模型支持多动作、多计划组。
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
    if (!_isShortcutTemplate(definition)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('多动作模板将在完整模板编辑器中开放编辑')));
      return;
    }
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
      if (_isShortcutTemplate(definition)) {
        final note = definition.version.note;
        subtitle =
            '${definition.exercises.single.exerciseNameSnapshot}（${definition.exercises.single.categorySnapshot.label}） · '
            '${_shortcutMetric(definition) == PlanMetric.duration ? '时长' : '有效组数'} · '
            '${describeTemplateThresholds(definition)}'
            '${note != null && note.isNotEmpty ? '\n$note' : ''}';
      } else {
        subtitle =
            '${definition.exercises.length} 个动作 · ${definition.sets.length} 个计划组';
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

class TemplateFormDialog extends ConsumerStatefulWidget {
  const TemplateFormDialog({super.key, this.editing});

  final WorkoutTemplateDefinition? editing;

  @override
  ConsumerState<TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends ConsumerState<TemplateFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _exerciseController;
  late final TextEditingController _minimumController;
  late final TextEditingController _regularController;
  late final TextEditingController _noteController;
  late ExerciseCategory _category;
  late PlanMetric _metric;
  bool _saving = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final definition = widget.editing;
    final exercise = definition?.exercises.single;
    _metric = definition == null
        ? PlanMetric.duration
        : _shortcutMetric(definition);
    _nameController = TextEditingController(
      text: definition?.version.name ?? '',
    );
    _exerciseController = TextEditingController(
      text: exercise?.exerciseNameSnapshot ?? '',
    );
    _category = exercise?.categorySnapshot ?? ExerciseCategory.cardio;
    final minimum = definition == null
        ? null
        : _metric == PlanMetric.duration
        ? definition.sets.single.minimumDurationSeconds
        : definition.sets.where((set) => set.minimumReps != null).length;
    final regular = definition == null
        ? null
        : _metric == PlanMetric.duration
        ? definition.sets.single.durationSeconds
        : definition.sets.length;
    String inputValue(int? value) {
      if (value == null) return '';
      return _metric == PlanMetric.duration ? '${value ~/ 60}' : '$value';
    }

    _minimumController = TextEditingController(text: inputValue(minimum));
    _regularController = TextEditingController(text: inputValue(regular));
    _noteController = TextEditingController(
      text: definition?.version.note ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _exerciseController.dispose();
    _minimumController.dispose();
    _regularController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String get _unitLabel => _metric == PlanMetric.duration ? '分钟' : '组数';

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final minimumText = _minimumController.text.trim();
    final minimumInput = minimumText.isEmpty ? null : int.parse(minimumText);
    final regularInput = int.parse(_regularController.text.trim());
    final tracking = _metric == PlanMetric.duration
        ? TrackingType.duration
        : TrackingType.reps;
    final note = _noteController.text.trim();
    try {
      final int catalogId;
      final editing = widget.editing;
      if (editing == null) {
        catalogId = await db.insertExercise(
          name: _exerciseController.text,
          category: _category,
          trackingType: tracking,
        );
      } else {
        catalogId = editing.exercises.single.exerciseId;
        await db.updateExercise(
          catalogId,
          name: _exerciseController.text,
          category: _category,
          trackingType: tracking,
        );
      }
      final sets = _metric == PlanMetric.duration
          ? [
              TemplateSetInput(
                durationSeconds: regularInput * 60,
                minimumDurationSeconds: minimumInput == null
                    ? null
                    : minimumInput * 60,
              ),
            ]
          : [
              for (var i = 0; i < regularInput; i++)
                TemplateSetInput(
                  reps: 1,
                  minimumReps: minimumInput != null && i < minimumInput
                      ? 1
                      : null,
                ),
            ];
      final exercises = [
        TemplateExerciseInput(exerciseId: catalogId, sets: sets),
      ];
      if (editing == null) {
        await db.createWorkoutTemplate(
          name: _nameController.text,
          exercises: exercises,
          note: note.isEmpty ? null : note,
        );
      } else {
        await db.reviseWorkoutTemplate(
          editing.template.id,
          name: _nameController.text,
          exercises: exercises,
          note: note.isEmpty ? null : note,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? '编辑方案' : '新建方案'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '方案名称'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? '请输入方案名称' : null,
              ),
              TextFormField(
                controller: _exerciseController,
                decoration: const InputDecoration(labelText: '动作名称'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? '请输入动作名称' : null,
              ),
              DropdownButtonFormField<ExerciseCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: '类别'),
                items: [
                  for (final category in ExerciseCategory.values)
                    DropdownMenuItem(
                      value: category,
                      child: Text(category.label),
                    ),
                ],
                onChanged: (value) => setState(
                  () => _category = value ?? ExerciseCategory.cardio,
                ),
              ),
              DropdownButtonFormField<PlanMetric>(
                initialValue: _metric,
                decoration: const InputDecoration(labelText: '指标'),
                items: const [
                  DropdownMenuItem(
                    value: PlanMetric.duration,
                    child: Text('持续时长'),
                  ),
                  DropdownMenuItem(value: PlanMetric.sets, child: Text('有效组数')),
                ],
                onChanged: (value) =>
                    setState(() => _metric = value ?? PlanMetric.duration),
              ),
              TextFormField(
                controller: _minimumController,
                decoration: InputDecoration(labelText: '最低量（$_unitLabel，可选）'),
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
                controller: _regularController,
                decoration: InputDecoration(labelText: '常规量（$_unitLabel）'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final regular = int.tryParse(value?.trim() ?? '');
                  if (regular == null || regular <= 0) return '常规量需大于 0';
                  final minimum = int.tryParse(_minimumController.text.trim());
                  if (minimum != null && regular < minimum) {
                    return '常规量不能低于最低量';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: '说明（可选）'),
              ),
            ],
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
