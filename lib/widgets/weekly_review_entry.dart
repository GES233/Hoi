import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../screens/weekly_review_screen.dart';

class WeeklyReviewEntry extends ConsumerWidget {
  const WeeklyReviewEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(weekWorkoutsProvider);
    final workouts = workoutsAsync.value ?? [];
    final totalMinutes =
        workouts.fold<int>(
          0,
          (sum, workout) => sum + (workout.totalSeconds ?? 0),
        ) ~/
        60;
    final subtitle = workoutsAsync.hasError
        ? '本周统计加载失败'
        : !workoutsAsync.hasValue
        ? '加载中…'
        : '${workouts.length} 次 · 已记录 $totalMinutes 分钟';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.insights_outlined),
        title: const Text('本周回顾'),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const WeeklyReviewScreen())),
      ),
    );
  }
}
