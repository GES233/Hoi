import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';
import '../widgets/add_entry_dialogs.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  static String formatDate(DateTime date) =>
      '${DateFormat('yyyy年M月d日').format(date)} ${_weekdays[date.weekday - 1]}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final foodEntries = ref.watch(foodEntriesProvider).value ?? [];
    final exerciseEntries =
        ref.watch(exerciseEntriesProvider).value ?? [];

    final totalIntake =
        foodEntries.fold<int>(0, (sum, e) => sum + e.calories);
    final totalBurned =
        exerciseEntries.fold<int>(0, (sum, e) => sum + e.caloriesBurned);

    return Scaffold(
      appBar: AppBar(title: const Text('饮食运动记录')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DateSwitcher(date: date),
          const SizedBox(height: 12),
          _SummaryCard(
            totalIntake: totalIntake,
            totalBurned: totalBurned,
          ),
          const SizedBox(height: 16),
          _FoodSection(entries: foodEntries),
          const SizedBox(height: 16),
          _ExerciseSection(entries: exerciseEntries),
          // 给底部悬浮按钮留出空间
          const SizedBox(height: 120),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'add_exercise',
            tooltip: '添加运动',
            onPressed: () => showAddExerciseEntryDialog(context),
            child: const Icon(Icons.directions_run),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'add_food',
            icon: const Icon(Icons.add),
            label: const Text('添加饮食'),
            onPressed: () => showAddFoodEntryDialog(context),
          ),
        ],
      ),
    );
  }
}

class _DateSwitcher extends ConsumerWidget {
  const _DateSwitcher({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: '前一天',
          onPressed: () =>
              ref.read(selectedDateProvider.notifier).shift(-1),
        ),
        Text(
          HomeScreen.formatDate(date),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: '后一天',
          onPressed: () => ref.read(selectedDateProvider.notifier).shift(1),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totalIntake, required this.totalBurned});

  final int totalIntake;
  final int totalBurned;

  @override
  Widget build(BuildContext context) {
    final net = totalIntake - totalBurned;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SummaryItem(label: '总摄入', value: totalIntake),
            _SummaryItem(label: '总消耗', value: totalBurned),
            _SummaryItem(label: '净热量', value: net),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text('$value', style: Theme.of(context).textTheme.headlineSmall),
        Text('kcal', style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _FoodSection extends ConsumerWidget {
  const _FoodSection({required this.entries});

  final List<FoodEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('饮食记录', style: Theme.of(context).textTheme.titleMedium),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('暂无记录'),
              )
            else
              for (final mealType in MealType.values)
                ..._buildMealGroup(context, ref, mealType),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMealGroup(
    BuildContext context,
    WidgetRef ref,
    MealType mealType,
  ) {
    final group =
        entries.where((e) => e.mealType == mealType).toList();
    if (group.isEmpty) return const [];
    return [
      const Divider(),
      Text(mealType.label, style: Theme.of(context).textTheme.titleSmall),
      for (final e in group)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(e.name),
          subtitle: Text('${e.calories} kcal'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '删除',
            onPressed: () =>
                ref.read(databaseProvider).deleteFoodEntry(e.id),
          ),
        ),
    ];
  }
}

class _ExerciseSection extends ConsumerWidget {
  const _ExerciseSection({required this.entries});

  final List<ExerciseEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('运动记录', style: Theme.of(context).textTheme.titleMedium),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('暂无记录'),
              )
            else
              for (final e in entries)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.name),
                  subtitle: Text('${e.durationMinutes} 分钟 · ${e.caloriesBurned} kcal'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: '删除',
                    onPressed: () =>
                        ref.read(databaseProvider).deleteExerciseEntry(e.id),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
