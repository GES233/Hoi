import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../screens/week_progress_screen.dart';

/// 已记录时长口径：非零但不足 1 分钟时显示「不足 1 分钟」，
/// 避免周摘要出现「已记录 0 分钟」这种看不出有没有记录的说法。
String formatRecordedMinutes(int seconds) {
  if (seconds <= 0) return '0 分钟';
  if (seconds < 60) return '不足 1 分钟';
  return '${(seconds / 60).toStringAsFixed(seconds % 60 == 0 ? 0 : 1)} 分钟';
}

/// 首页的周进度入口：只显示本周次数与已记录时长，
/// 落实点阵、运动时段与周期目标都在周进度页里。
class WeekProgressEntry extends ConsumerWidget {
  const WeekProgressEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        : '${workouts.length} 次 · 已记录 ${formatRecordedMinutes(totalSeconds)}';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.insights_outlined),
        title: const Text('周进度'),
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
