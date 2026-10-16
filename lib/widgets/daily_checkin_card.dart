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
    final scheme = Theme.of(context).colorScheme;
    final details = <String>[
      if (checkin?.sleepRating != null)
        '睡眠 ${_sleepLabel(checkin!.sleepRating!)}',
      if (checkin?.stressRating != null)
        '压力 ${_stressLabel(checkin!.stressRating!)}',
      if (checkin?.note != null) checkin!.note!,
    ];
    final subtitle = checkinAsync.hasError
        ? '每日状态加载失败'
        : !checkinAsync.hasValue
        ? '加载中…'
        : details.isEmpty
        ? '记录睡眠、压力或备注'
        : details.join(' · ');
    return Material(
      color: details.isEmpty
          ? scheme.surfaceContainerLow
          : scheme.primaryContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: checkinAsync.hasError
            ? null
            : () => _edit(context, ref, date, checkin),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.spa_outlined,
                  size: 16,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: details.isEmpty ? null : FontWeight.w500,
                    color: details.isEmpty
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
              ),
              Icon(
                checkin == null ? Icons.add : Icons.edit_outlined,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
