import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../database/database.dart';
import '../providers/app_providers.dart';
import '../widgets/home_cards.dart';
import '../widgets/week_strip.dart';
import '../widgets/workout_timeline_card.dart';

/// 周进度：只读呈现某一自然周的落实点阵、图例、运动时段与周期目标。
///
/// 周窗口由页面自己持有（进入时等于全局选中日期所在周），翻周只影响本页，
/// 不改动首页选中的日期。日期格因此也只作展示。
class WeekProgressScreen extends ConsumerStatefulWidget {
  const WeekProgressScreen({super.key});

  @override
  ConsumerState<WeekProgressScreen> createState() => _WeekProgressScreenState();
}

class _WeekProgressScreenState extends ConsumerState<WeekProgressScreen> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = AppDatabase.weekStart(ref.read(selectedDateProvider));
  }

  /// 不允许翻到本周之后，和首页周条的规则一致
  bool get _canGoNext {
    final today = AppDatabase.dateOnly(DateTime.now());
    return !_weekStart
        .add(const Duration(days: 7))
        .isAfter(AppDatabase.weekStart(today));
  }

  void _shiftWeek(int days) =>
      setState(() => _weekStart = _weekStart.add(Duration(days: days)));

  @override
  Widget build(BuildContext context) {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final label =
        '${intl.DateFormat('M月d日').format(_weekStart)} – '
        '${intl.DateFormat('M月d日').format(weekEnd)}';
    final isThisWeek =
        _weekStart ==
        AppDatabase.weekStart(AppDatabase.dateOnly(DateTime.now()));

    return Scaffold(
      appBar: AppBar(title: const Text('周进度')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: '上一周',
                visualDensity: VisualDensity.compact,
                onPressed: () => _shiftWeek(-7),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              if (!isThisWeek)
                TextButton(
                  onPressed: () => setState(() {
                    _weekStart = AppDatabase.weekStart(
                      AppDatabase.dateOnly(DateTime.now()),
                    );
                  }),
                  child: const Text('回到本周'),
                ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: '下一周',
                visualDensity: VisualDensity.compact,
                onPressed: _canGoNext ? () => _shiftWeek(7) : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          WeekDayRow(date: _weekStart, followSelectedDate: false),
          const SizedBox(height: 8),
          const WeekStatusLegend(),
          const SizedBox(height: 12),
          WorkoutTimelineCard(date: _weekStart),
          const SizedBox(height: 12),
          RuleGoalsCard(date: _weekStart),
        ],
      ),
    );
  }
}
