import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

typedef _ExerciseTypeDraft = ({
  String name,
  ExerciseCategory category,
  TrackingType trackingType,
  LoadConvention loadConvention,
  RepsConvention repsConvention,
});

/// 动作目录：新增、编辑、分类筛选、拖拽排序和归档可在训练中复用的运动类型。
class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  ExerciseCategory? _selectedCategory;

  Future<void> _openForm(
    BuildContext context, {
    Exercise? editing,
  }) async {
    final draft = await showDialog<_ExerciseTypeDraft>(
      context: context,
      builder: (_) => _ExerciseTypeDialog(
        editing: editing,
        initialCategory: _selectedCategory,
      ),
    );
    if (draft == null) return;
    final db = ref.read(databaseProvider);
    if (editing == null) {
      await db.insertExercise(
        name: draft.name,
        category: draft.category,
        trackingType: draft.trackingType,
        loadConvention: draft.loadConvention,
        repsConvention: draft.repsConvention,
      );
    } else {
      await db.updateExercise(
        editing.id,
        name: draft.name,
        category: draft.category,
        trackingType: draft.trackingType,
        loadConvention: draft.loadConvention,
        repsConvention: draft.repsConvention,
      );
    }
  }

  Future<void> _confirmArchive(
    BuildContext context,
    Exercise exercise,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('归档运动类型'),
        content: Text('归档「${exercise.name}」？已有训练记录不会受影响。'),
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
      await ref.read(databaseProvider).archiveExercise(exercise.id);
    }
  }

  Future<void> _handleReorder(
    List<Exercise> visibleExercises,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex == newIndex) return;
    final reordered = [...visibleExercises];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    await ref
        .read(databaseProvider)
        .reorderExercises([for (final e in reordered) e.id]);
  }

  String _formatSubtitle(Exercise exercise) {
    final parts = <String>[
      exercise.category.label,
      '按${exercise.trackingType.label}记录',
      if (exercise.loadConvention != LoadConvention.none)
        exercise.loadConvention.label,
      if (exercise.trackingType == TrackingType.reps &&
          exercise.repsConvention == RepsConvention.perSide)
        exercise.repsConvention.label,
    ];
    return parts.join(' · ');
  }

  Widget _buildCategoryFilterBar(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('全部'),
            selected: _selectedCategory == null,
            onSelected: (_) => setState(() => _selectedCategory = null),
          ),
          for (final category in ExerciseCategory.values) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(category.label),
              selected: _selectedCategory == category,
              onSelected: (selected) => setState(
                () => _selectedCategory = selected ? category : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('运动类型'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加运动类型',
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('运动类型加载失败')),
        data: (exercises) {
          if (exercises.isEmpty) {
            return Center(
              child: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('添加运动类型'),
                onPressed: () => _openForm(context),
              ),
            );
          }
          final filtered = _selectedCategory == null
              ? exercises
              : [
                  for (final e in exercises)
                    if (e.category == _selectedCategory) e,
                ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCategoryFilterBar(context),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '该分类下暂无运动类型',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('添加运动类型'),
                              onPressed: () => _openForm(context),
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        itemCount: filtered.length,
                        onReorderItem: (oldIndex, newIndex) =>
                            _handleReorder(filtered, oldIndex, newIndex),
                        itemBuilder: (context, index) {
                          final exercise = filtered[index];
                          final scheme = Theme.of(context).colorScheme;
                          final accent = HoiTheme.categoryColor(
                            scheme,
                            exercise.category,
                          );
                          return Padding(
                            key: ValueKey(exercise.id),
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Icon(
                                    HoiTheme.categoryIcon(exercise.category),
                                    color: accent,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  exercise.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(_formatSubtitle(exercise)),
                                onTap: () =>
                                    _openForm(context, editing: exercise),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.archive_outlined),
                                      tooltip: '归档运动类型',
                                      onPressed: () =>
                                          _confirmArchive(context, exercise),
                                    ),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 8,
                                        ),
                                        child: Icon(
                                          Icons.drag_handle_rounded,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExerciseTypeDialog extends StatefulWidget {
  const _ExerciseTypeDialog({this.editing, this.initialCategory});

  final Exercise? editing;
  final ExerciseCategory? initialCategory;

  @override
  State<_ExerciseTypeDialog> createState() => _ExerciseTypeDialogState();
}

class _ExerciseTypeDialogState extends State<_ExerciseTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late ExerciseCategory _category;
  late TrackingType _trackingType;
  late LoadConvention _loadConvention;
  late RepsConvention _repsConvention;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _nameController = TextEditingController(text: editing?.name ?? '');
    _category =
        editing?.category ?? widget.initialCategory ?? ExerciseCategory.cardio;
    _trackingType = editing?.trackingType ?? TrackingType.duration;
    _loadConvention = editing?.loadConvention ?? LoadConvention.none;
    _repsConvention = editing?.repsConvention ?? RepsConvention.total;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((
      name: _nameController.text.trim(),
      category: _category,
      trackingType: _trackingType,
      loadConvention: _loadConvention,
      repsConvention: _trackingType == TrackingType.reps
          ? _repsConvention
          : RepsConvention.total,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.editing != null;
    return AlertDialog(
      title: Text(editing ? '编辑运动类型' : '添加运动类型'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: '运动名称'),
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? '请输入运动名称' : null,
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              DropdownButtonFormField<TrackingType>(
                initialValue: _trackingType,
                decoration: const InputDecoration(labelText: '记录方式'),
                items: [
                  for (final type in TrackingType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: (value) => setState(
                  () => _trackingType = value ?? TrackingType.duration,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<LoadConvention>(
                initialValue: _loadConvention,
                decoration: const InputDecoration(labelText: '负重方式'),
                items: [
                  for (final load in LoadConvention.values)
                    DropdownMenuItem(value: load, child: Text(load.label)),
                ],
                onChanged: (value) => setState(
                  () => _loadConvention = value ?? LoadConvention.none,
                ),
              ),
              if (_trackingType == TrackingType.reps) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<RepsConvention>(
                  initialValue: _repsConvention,
                  decoration: const InputDecoration(labelText: '计数口径'),
                  items: [
                    for (final reps in RepsConvention.values)
                      DropdownMenuItem(value: reps, child: Text(reps.label)),
                  ],
                  onChanged: (value) => setState(
                    () => _repsConvention = value ?? RepsConvention.total,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: Text(editing ? '保存' : '添加')),
      ],
    );
  }
}
