import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../widgets/home_cards.dart';
import '../widgets/home_workout_cards.dart';
import '../widgets/week_strip.dart';
import 'plans_screen.dart';
import 'rules_screen.dart';

/// 首页：行动入口优先，不使用悬浮按钮。
/// 顺序：周条（选日期 + 本周落实点阵，非今天可回今天）→ 今日方案 →
/// 开始/补记入口 → 进行中的训练（与选中日期无关）→ 当日运动记录 →
/// 饮食入口与摘要 → 本周概览（次数/时长进度 + 点阵图例）
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static String formatDate(DateTime date) => formatWeekDate(date);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final foodAsync = ref.watch(foodEntriesProvider);
    final workoutsAsync = ref.watch(completedWorkoutsProvider);
    final ongoingAsync = ref.watch(ongoingWorkoutProvider);
    final ongoing = ongoingAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoi'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const RulesScreen())),
            child: const Text('目标'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const PlansScreen())),
            child: const Text('方案'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WeekStrip(date: date),
          const SizedBox(height: 12),
          const TodayPlanCard(),
          const SizedBox(height: 12),
          const RuleGoalsCard(),
          const SizedBox(height: 12),
          WorkoutEntryButtons(ongoing: ongoing, selectedDate: date),
          if (ongoingAsync.hasError)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('进行中训练状态加载失败'),
            )
          else if (ongoing != null) ...[
            const SizedBox(height: 12),
            OngoingWorkoutCard(workout: ongoing),
          ],
          const SizedBox(height: 12),
          WorkoutSection(workoutsAsync: workoutsAsync),
          const SizedBox(height: 12),
          FoodSection(entriesAsync: foodAsync),
          const SizedBox(height: 12),
          const WeeklyExerciseCard(),
        ],
      ),
    );
  }
}
