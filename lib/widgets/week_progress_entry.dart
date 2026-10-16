import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../screens/week_progress_screen.dart';
import 'workout_dialogs.dart';

/// 首页的周进度入口：只显示本周次数与已记录时长，
/// 落实点阵、运动时段与周期目标都在周进度页里。
class WeekProgressEntry extends ConsumerWidget {
  const WeekProgressEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final workoutsAsync = ref.watch(weekWorkoutsProvider);
    final workouts = workoutsAsync.value ?? [];
    final totalSeconds = workouts.fold<int>(
      0,
      (sum, workout) => sum + (workout.totalSeconds ?? 0),
    );
    final subtitle = workoutsAsync.hasError
        ? '本周统计加载失败'
        : !workoutsAsync.hasValue
        ? '加载中…'
        : '${workouts.length} 次 · 已记录 ${formatRecordedSeconds(totalSeconds)}';
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            Icons.insights_outlined,
            size: 20,
            color: scheme.primary,
          ),
        ),
        title: const Text(
          '周进度',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        // 统计加载失败时不提供入口，避免跳到一个同样加载失败的页面
        onTap: workoutsAsync.hasError
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WeekProgressScreen()),
              ),
      ),
    );
  }
}
