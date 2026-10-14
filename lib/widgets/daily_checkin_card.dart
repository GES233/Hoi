import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';

String _sleepLabel(int value) => switch (value) {
  1 => '很差',
  2 => '较差',
  3 => '一般',
  4 => '较好',
  _ => '很好',
};

String _stressLabel(int value) => switch (value) {
  1 => '很低',
  2 => '较低',
  3 => '一般',
  4 => '较高',
  _ => '很高',
};

class DailyCheckinCard extends ConsumerWidget {
  const DailyCheckinCard({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    DailyCheckin? current,
  ) async {
    var sleep = current?.sleepRating;
    var stress = current?.stressRating;
    final noteController = TextEditingController(text: current?.note ?? '');
    final result = await showDialog<({int? sleep, int? stress, String note})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('每日状态'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int?>(
                  initialValue: sleep,
                  decoration: const InputDecoration(
                    labelText: '睡眠感受',
                    prefixIcon: Icon(Icons.bedtime_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('未记录'),
                    ),
                    for (var value = 1; value <= 5; value++)
                      DropdownMenuItem(
                        value: value,
                        child: Text(_sleepLabel(value)),
                      ),
                  ],
                  onChanged: (value) => setDialogState(() => sleep = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: stress,
                  decoration: const InputDecoration(
                    labelText: '压力',
                    prefixIcon: Icon(Icons.psychology_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('未记录'),
                    ),
                    for (var value = 1; value <= 5; value++)
                      DropdownMenuItem(
                        value: value,
                        child: Text(_stressLabel(value)),
                      ),
                  ],
                  onChanged: (value) => setDialogState(() => stress = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: '今日备注（可选）',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop((sleep: sleep, stress: stress, note: noteController.text)),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    noteController.dispose();
    if (result == null) return;
    await ref
        .read(databaseProvider)
        .saveDailyCheckin(
          date,
          sleepRating: result.sleep,
          stressRating: result.stress,
          note: result.note,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final checkinAsync = ref.watch(dailyCheckinProvider);
    final checkin = checkinAsync.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('每日状态', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: checkin == null ? '记录每日状态' : '编辑每日状态',
                  icon: Icon(checkin == null ? Icons.add : Icons.edit_outlined),
                  onPressed: checkinAsync.hasError
                      ? null
                      : () => _edit(context, ref, date, checkin),
                ),
              ],
            ),
            if (checkinAsync.hasError)
              const Text('每日状态加载失败')
            else if (!checkinAsync.hasValue)
              const Text('加载中…')
            else if (checkin == null)
              Text(
                '尚未记录',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (checkin.sleepRating != null)
                    _Fact(
                      icon: Icons.bedtime_outlined,
                      label: '睡眠 ${_sleepLabel(checkin.sleepRating!)}',
                    ),
                  if (checkin.stressRating != null)
                    _Fact(
                      icon: Icons.psychology_outlined,
                      label: '压力 ${_stressLabel(checkin.stressRating!)}',
                    ),
                ],
              ),
              if (checkin.note != null) ...[
                const SizedBox(height: 8),
                Text(checkin.note!),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(label)],
  );
}
