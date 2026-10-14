import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';

typedef _ExerciseTypeDraft = ({
  String name,
  ExerciseCategory category,
  TrackingType trackingType,
});

/// 动作目录：新增、编辑和归档可在训练中复用的运动类型。
class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Exercise? editing,
  }) async {
    final draft = await showDialog<_ExerciseTypeDraft>(
      context: context,
      builder: (_) => _ExerciseTypeDialog(editing: editing),
    );
    if (draft == null) return;
    final db = ref.read(databaseProvider);
    if (editing == null) {
      await db.insertExercise(
        name: draft.name,
        category: draft.category,
        trackingType: draft.trackingType,
      );
    } else {
      await db.updateExercise(
        editing.id,
        name: draft.name,
        category: draft.category,
        trackingType: draft.trackingType,
        loadConvention: editing.loadConvention,
        repsConvention: editing.repsConvention,
      );
    }
  }

  Future<void> _confirmArchive(
    BuildContext context,
    WidgetRef ref,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('运动类型'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加运动类型',
            onPressed: () => _openForm(context, ref),
          ),
        ],
      ),
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('运动类型加载失败')),
        data: (exercises) => exercises.isEmpty
            ? Center(
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('添加运动类型'),
                  onPressed: () => _openForm(context, ref),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: exercises.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  return ListTile(
                    leading: Icon(_categoryIcon(exercise.category)),
                    title: Text(exercise.name),
                    subtitle: Text(
                      '${exercise.category.label} · 按${exercise.trackingType.label}记录',
                    ),
                    onTap: () => _openForm(context, ref, editing: exercise),
                    trailing: IconButton(
                      icon: const Icon(Icons.archive_outlined),
                      tooltip: '归档运动类型',
                      onPressed: () => _confirmArchive(context, ref, exercise),
                    ),
                  );
                },
              ),
      ),
    );
  }

  IconData _categoryIcon(ExerciseCategory category) => switch (category) {
    ExerciseCategory.cardio => Icons.directions_run,
    ExerciseCategory.resistance => Icons.fitness_center,
    ExerciseCategory.core => Icons.accessibility_new,
    ExerciseCategory.functional => Icons.sports_gymnastics,
  };
}

class _ExerciseTypeDialog extends StatefulWidget {
  const _ExerciseTypeDialog({this.editing});

  final Exercise? editing;

  @override
  State<_ExerciseTypeDialog> createState() => _ExerciseTypeDialogState();
}

class _ExerciseTypeDialogState extends State<_ExerciseTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late ExerciseCategory _category;
  late TrackingType _trackingType;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _nameController = TextEditingController(text: editing?.name ?? '');
    _category = editing?.category ?? ExerciseCategory.cardio;
    _trackingType = editing?.trackingType ?? TrackingType.duration;
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
    ));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.editing != null;
    return AlertDialog(
      title: Text(editing ? '编辑运动类型' : '添加运动类型'),
      content: Form(
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
              onChanged: (value) =>
                  setState(() => _category = value ?? ExerciseCategory.cardio),
            ),
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
          ],
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
