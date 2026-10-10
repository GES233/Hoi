import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';

/// 弹出「添加饮食」对话框
Future<void> showAddFoodEntryDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const AddFoodEntryDialog(),
  );
}

/// 弹出「添加运动」对话框
Future<void> showAddExerciseEntryDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const AddExerciseEntryDialog(),
  );
}

class AddFoodEntryDialog extends ConsumerStatefulWidget {
  const AddFoodEntryDialog({super.key});

  @override
  ConsumerState<AddFoodEntryDialog> createState() => _AddFoodEntryDialogState();
}

class _AddFoodEntryDialogState extends ConsumerState<AddFoodEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  MealType _mealType = MealType.breakfast;
  bool _saveAsFavorite = false;

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final db = ref.read(databaseProvider);
    final date = ref.read(selectedDateProvider);
    final name = _nameController.text.trim();
    final calories = int.parse(_caloriesController.text.trim());

    await db.insertFoodEntry(
      FoodEntriesCompanion(
        date: Value(date),
        mealType: Value(_mealType),
        name: Value(name),
        calories: Value(calories),
      ),
    );
    if (_saveAsFavorite) {
      await db.upsertFavoriteFood(name, calories);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoriteFoodsProvider).value ?? [];

    return AlertDialog(
      title: const Text('添加饮食'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<MealType>(
                initialValue: _mealType,
                decoration: const InputDecoration(labelText: '餐次'),
                items: [
                  for (final type in MealType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: (v) =>
                    setState(() => _mealType = v ?? MealType.breakfast),
              ),
              if (favorites.isNotEmpty)
                DropdownButtonFormField<FavoriteFood>(
                  decoration: const InputDecoration(labelText: '从常用食物选择'),
                  items: [
                    for (final f in favorites)
                      DropdownMenuItem(
                        value: f,
                        child: Text('${f.name}（${f.calories} kcal）'),
                      ),
                  ],
                  onChanged: (f) {
                    if (f == null) return;
                    setState(() {
                      _nameController.text = f.name;
                      _caloriesController.text = f.calories.toString();
                    });
                  },
                ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '食物名称'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入食物名称' : null,
              ),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: '热量 (kcal)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入热量' : null,
              ),
              CheckboxListTile(
                value: _saveAsFavorite,
                onChanged: (v) =>
                    setState(() => _saveAsFavorite = v ?? false),
                title: const Text('存为常用食物'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
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
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}

class AddExerciseEntryDialog extends ConsumerStatefulWidget {
  const AddExerciseEntryDialog({super.key});

  @override
  ConsumerState<AddExerciseEntryDialog> createState() =>
      _AddExerciseEntryDialogState();
}

class _AddExerciseEntryDialogState
    extends ConsumerState<AddExerciseEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final db = ref.read(databaseProvider);
    final date = ref.read(selectedDateProvider);

    await db.insertExerciseEntry(
      ExerciseEntriesCompanion(
        date: Value(date),
        name: Value(_nameController.text.trim()),
        durationMinutes: Value(int.parse(_durationController.text.trim())),
        caloriesBurned: Value(int.parse(_caloriesController.text.trim())),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加运动'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '运动名称'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入运动名称' : null,
              ),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: '时长 (分钟)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入时长' : null,
              ),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: '消耗热量 (kcal)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入消耗热量' : null,
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
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}
