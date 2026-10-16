import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/daily_checkin_card.dart';
import '../widgets/home_cards.dart';
import '../widgets/home_workout_cards.dart';
import '../widgets/week_progress_entry.dart';
import '../widgets/week_strip.dart';
import 'exercises_screen.dart';
import 'plans_screen.dart';
import 'rules_screen.dart';

/// 首页：行动入口优先，不使用悬浮按钮。
/// 顺序：周条（选日期 + 本周落实点阵，非今天可回今天）→ 每日状态 → 今日方案 →
/// 开始/补记/单项入口 → 进行中的训练（与选中日期无关）→ 当日运动记录 →
/// 饮食入口与摘要 → 紧凑周进度入口
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
    final scheme = Theme.of(context).colorScheme;
    final themePref = ref.watch(themePreferenceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.bolt_rounded,
                size: 18,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Hoi'),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.fitness_center_outlined, size: 16),
            label: const Text('动作'),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ExercisesScreen())),
          ),
          TextButton.icon(
            icon: const Icon(Icons.flag_outlined, size: 16),
            label: const Text('目标'),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const RulesScreen())),
          ),
          TextButton.icon(
            icon: const Icon(Icons.assignment_outlined, size: 16),
            label: const Text('方案'),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PlansScreen())),
          ),
          PopupMenuButton<HoiThemePreference>(
            tooltip: '切换外观与对比度',
            icon: Icon(themePref.icon, size: 20),
            initialValue: themePref,
            onSelected: (value) =>
                ref.read(themePreferenceProvider.notifier).select(value),
            itemBuilder: (context) => [
              for (final option in HoiThemePreference.values)
                PopupMenuItem(
                  value: option,
                  child: Row(
                    children: [
                      Icon(
                        option.icon,
                        size: 18,
                        color: option == themePref ? scheme.primary : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        option.label,
                        style: TextStyle(
                          fontWeight: option == themePref
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: option == themePref ? scheme.primary : null,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  WeekStrip(date: date),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  const DailyCheckinCard(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (ongoingAsync.hasError)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('进行中训练状态加载失败'),
            )
          else if (ongoing != null) ...[
            OngoingWorkoutCard(workout: ongoing),
            const SizedBox(height: 14),
          ],
          WorkoutEntryButtons(ongoing: ongoing, selectedDate: date),
          const SizedBox(height: 14),
          const TodayPlanCard(),
          const SizedBox(height: 14),
          WorkoutSection(workoutsAsync: workoutsAsync),
          const SizedBox(height: 14),
          FoodSection(entriesAsync: foodAsync),
          const SizedBox(height: 14),
          const WeekProgressEntry(),
        ],
      ),
    );
  }
}
