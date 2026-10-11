import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';

/// 方案阈值的可读描述，如「最低 15 分钟 / 常规 30 分钟」
String describePlanThresholds(ExercisePlan p) {
  String fmt(int v) =>
      p.metric == PlanMetric.duration ? '${v ~/ 60} 分钟' : '$v 组';
  return '最低 ${fmt(p.minThreshold)} / 常规 ${fmt(p.regularThreshold)}';
}

/// 方案管理页：列表 + 新增 / 编辑 / 删除
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, ExercisePlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除方案'),
        content:
            Text('删除「${plan.name}」？不影响已有训练记录，历史训练仍按当时保存的方案条件判定。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(databaseProvider).deleteExercisePlan(plan.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(exercisePlansProvider).value ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('运动方案')),
      body: plans.isEmpty
          ? const Center(child: Text('尚未设置最低／常规方案'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final p in plans)
                  Card(
                    child: ListTile(
                      title: Text(p.name),
                      subtitle: Text(
                        '${p.exerciseName}（${p.category.label}） · '
                        '${p.metric == PlanMetric.duration ? '时长' : '有效组数'} · '
                        '${describePlanThresholds(p)}'
                        '${p.note != null && p.note!.isNotEmpty ? '\n${p.note}' : ''}',
                      ),
                      isThreeLine: p.note != null && p.note!.isNotEmpty,
                      onTap: () => showPlanFormDialog(context, editing: p),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: '删除方案',
                        onPressed: () => _confirmDelete(context, ref, p),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_plan',
        icon: const Icon(Icons.add),
        label: const Text('新建方案'),
        onPressed: () => showPlanFormDialog(context),
      ),
    );
  }
}

/// 弹出「新建 / 编辑方案」对话框
Future<void> showPlanFormDialog(BuildContext context, {ExercisePlan? editing}) {
  return showDialog<void>(
    context: context,
    builder: (_) => PlanFormDialog(editing: editing),
  );
}

class PlanFormDialog extends ConsumerStatefulWidget {
  const PlanFormDialog({super.key, this.editing});

  /// 非空表示编辑已有方案
  final ExercisePlan? editing;

  @override
  ConsumerState<PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends ConsumerState<PlanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _exerciseController;
  late final TextEditingController _minController;
  late final TextEditingController _regularController;
  late final TextEditingController _noteController;
  late ExerciseCategory _category;
  late PlanMetric _metric;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.editing;
    _nameController = TextEditingController(text: p?.name ?? '');
    _exerciseController = TextEditingController(text: p?.exerciseName ?? '');
    _category = p?.category ?? ExerciseCategory.cardio;
    _metric = p?.metric ?? PlanMetric.duration;
    // duration 指标存秒，表单以分钟输入
    String toInput(int v) =>
        _metric == PlanMetric.duration ? '${v ~/ 60}' : '$v';
    _minController =
        TextEditingController(text: p == null ? '' : toInput(p.minThreshold));
    _regularController = TextEditingController(
        text: p == null ? '' : toInput(p.regularThreshold));
    _noteController = TextEditingController(text: p?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _exerciseController.dispose();
    _minController.dispose();
    _regularController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String get _unitLabel => _metric == PlanMetric.duration ? '分钟' : '组数';

  String? _validateThreshold(String? v, String label) {
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null || n <= 0) return '$label需大于 0';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final db = ref.read(databaseProvider);
    final minInput = int.parse(_minController.text.trim());
    final regularInput = int.parse(_regularController.text.trim());
    // duration 指标：分钟换算为秒存储；sets 指标：直接存组数
    int toStore(int v) => _metric == PlanMetric.duration ? v * 60 : v;
    final note = _noteController.text.trim();
    if (_isEditing) {
      await db.updateExercisePlan(
        widget.editing!.id,
        name: _nameController.text.trim(),
        exerciseName: _exerciseController.text.trim(),
        category: _category,
        metric: _metric,
        minThreshold: toStore(minInput),
        regularThreshold: toStore(regularInput),
        note: note.isEmpty ? null : note,
      );
    } else {
      await db.insertExercisePlan(
        name: _nameController.text.trim(),
        exerciseName: _exerciseController.text.trim(),
        category: _category,
        metric: _metric,
        minThreshold: toStore(minInput),
        regularThreshold: toStore(regularInput),
        note: note.isEmpty ? null : note,
      );
    }
    if (mounted) Navigator.of(context).pop();
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
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入方案名称' : null,
              ),
              TextFormField(
                controller: _exerciseController,
                decoration: const InputDecoration(labelText: '绑定动作名'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入绑定动作名' : null,
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
              DropdownButtonFormField<PlanMetric>(
                initialValue: _metric,
                decoration: const InputDecoration(labelText: '指标'),
                items: const [
                  DropdownMenuItem(
                      value: PlanMetric.duration, child: Text('持续时长')),
                  DropdownMenuItem(
                      value: PlanMetric.sets, child: Text('有效组数')),
                ],
                onChanged: (v) =>
                    setState(() => _metric = v ?? PlanMetric.duration),
              ),
              TextFormField(
                controller: _minController,
                decoration: InputDecoration(labelText: '最低阈值（$_unitLabel）'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => _validateThreshold(v, '最低阈值'),
              ),
              TextFormField(
                controller: _regularController,
                decoration: InputDecoration(labelText: '常规阈值（$_unitLabel）'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final error = _validateThreshold(v, '常规阈值');
                  if (error != null) return error;
                  final min = int.tryParse(_minController.text.trim()) ?? 0;
                  if (int.parse(v!.trim()) < min) return '常规阈值不能低于最低阈值';
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}
