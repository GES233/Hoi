import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../database/database.dart';
import '../providers/app_providers.dart';
import '../widgets/home_cards.dart';
import '../widgets/week_strip.dart';
import '../widgets/workout_timeline_card.dart';

/// 周进度：以当前选中日期所在自然周为窗口，只读呈现本周落实点阵、图例、
/// 运动时段与周期目标。不提供按日选择，点日期格不会改变全局选中日期。
class WeekProgressScreen extends ConsumerWidget {
  const WeekProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final weekStart = AppDatabase.weekStart(date);
    final label =
        '${intl.DateFormat('M月d日').format(weekStart)} – '
        '${intl.DateFormat('M月d日').format(weekStart.add(const Duration(days: 6)))}';

    return Scaffold(
      appBar: AppBar(title: const Text('周进度')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          WeekDayRow(date: date),
          const SizedBox(height: 8),
          const WeekStatusLegend(),
          const SizedBox(height: 12),
          const WorkoutTimelineCard(),
          const SizedBox(height: 12),
          const RuleGoalsCard(),
        ],
      ),
    );
  }
}
