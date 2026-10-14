import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../widgets/home_cards.dart';
import '../widgets/week_strip.dart';
import '../widgets/workout_timeline_card.dart';

class WeeklyReviewScreen extends ConsumerWidget {
  const WeeklyReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('本周回顾')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WeekStrip(date: date),
          const SizedBox(height: 12),
          const WorkoutTimelineCard(),
          const SizedBox(height: 12),
          const RuleGoalsCard(),
        ],
      ),
    );
  }
}
