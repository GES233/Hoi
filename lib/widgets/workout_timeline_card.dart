import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../database/database.dart';
import '../domain/workout_timeline.dart';
import '../providers/app_providers.dart';

class WorkoutTimelineCard extends ConsumerStatefulWidget {
  const WorkoutTimelineCard({super.key});

  @override
  ConsumerState<WorkoutTimelineCard> createState() =>
      _WorkoutTimelineCardState();
}

class _WorkoutTimelineCardState extends ConsumerState<WorkoutTimelineCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(selectedDateProvider);
    final workoutsAsync = ref.watch(weekTimelineWorkoutsProvider);
    final workouts = workoutsAsync.value ?? const <Workout>[];
    final hasOngoing = workouts.any((workout) => workout.endedAt == null);
    final clock = ref.watch(appClockProvider);
    final now = hasOngoing
        ? (ref.watch(minuteTickProvider).value ?? clock())
        : clock();
    final weekStart = AppDatabase.weekStart(date);
    final entries = [
      for (final workout in workouts)
        if (workout.startedAt != null)
          WorkoutTimelineEntry(
            workoutId: workout.id,
            startedAt: workout.startedAt!,
            endedAt: workout.endedAt,
            totalSeconds: workout.totalSeconds,
            label: workout.templateNameSnapshot ?? '自由训练',
          ),
    ];
    final segments = buildWorkoutTimeline(
      entries: entries,
      rangeStart: weekStart,
      now: now,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('运动时段', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: _expanded ? '收起时间轴' : '展开完整时间轴',
                  icon: Icon(_expanded ? Icons.unfold_less : Icons.unfold_more),
                  onPressed: segments.isEmpty
                      ? null
                      : () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
            Text(
              '${intl.DateFormat('M月d日').format(weekStart)} – '
              '${intl.DateFormat('M月d日').format(weekStart.add(const Duration(days: 6)))}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 12),
            if (workoutsAsync.hasError)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('运动时段加载失败'),
              )
            else if (!workoutsAsync.hasValue)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('加载中…'),
              )
            else if (segments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '本周暂无带时间的训练',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              _WorkoutTimeline(
                weekStart: weekStart,
                segments: segments,
                visibleStartMinute: _expanded ? 0 : 6 * 60,
                chartHeight: _expanded ? 360 : 220,
              ),
            if (!_expanded &&
                segments.any((segment) => segment.startMinute < 6 * 60))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '有凌晨时段，展开查看完整时间轴',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutTimeline extends StatelessWidget {
  const _WorkoutTimeline({
    required this.weekStart,
    required this.segments,
    required this.visibleStartMinute,
    required this.chartHeight,
  });

  final DateTime weekStart;
  final List<WorkoutTimelineSegment> segments;
  final double visibleStartMinute;
  final double chartHeight;
  static const _gutter = 34.0;

  Color _segmentColor(ColorScheme scheme, int id) => switch (id % 3) {
    0 => scheme.primary,
    1 => scheme.tertiary,
    _ => scheme.secondary,
  };

  Future<void> _showDetails(BuildContext context, WorkoutTimelineEntry entry) =>
      showDialog<void>(
        context: context,
        builder: (context) {
          final end = entry.endedAt;
          final seconds = entry.totalSeconds;
          final duration = seconds == null ? null : Duration(seconds: seconds);
          final minutes = duration?.inMinutes;
          return AlertDialog(
            title: Text(entry.label),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '开始 ${intl.DateFormat('M月d日 HH:mm').format(entry.startedAt)}',
                ),
                Text(
                  end == null
                      ? '结束 进行中'
                      : '结束 ${intl.DateFormat('M月d日 HH:mm').format(end)}',
                ),
                if (minutes != null) Text('有效用时 $minutes 分钟'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: _gutter),
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Text(
                    '${const ['一', '二', '三', '四', '五', '六', '日'][i]}\n'
                    '${weekStart.add(Duration(days: i)).day}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: chartHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = constraints.maxWidth - _gutter;
              final dayWidth = contentWidth / 7;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TimelineGridPainter(
                        gutter: _gutter,
                        color: scheme.outlineVariant,
                        textColor: scheme.onSurfaceVariant,
                        visibleStartMinute: visibleStartMinute,
                      ),
                    ),
                  ),
                  for (final segment in segments)
                    _positionedSegment(
                      context,
                      segment,
                      dayWidth,
                      _segmentColor(scheme, segment.entry.workoutId),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _positionedSegment(
    BuildContext context,
    WorkoutTimelineSegment segment,
    double dayWidth,
    Color color,
  ) {
    const visibleEndMinute = 24 * 60.0;
    if (segment.endMinute <= visibleStartMinute ||
        segment.startMinute >= visibleEndMinute) {
      return const SizedBox.shrink();
    }
    const gap = 2.0;
    final laneWidth = (dayWidth - gap * 2) / segment.laneCount;
    final clippedStart = segment.startMinute < visibleStartMinute
        ? visibleStartMinute
        : segment.startMinute;
    final clippedEnd = segment.endMinute > visibleEndMinute
        ? visibleEndMinute
        : segment.endMinute;
    final visibleMinutes = visibleEndMinute - visibleStartMinute;
    final top =
        (clippedStart - visibleStartMinute) / visibleMinutes * chartHeight;
    final rawHeight =
        (clippedEnd - clippedStart) / visibleMinutes * chartHeight;
    final left =
        _gutter + segment.dayIndex * dayWidth + gap + segment.lane * laneWidth;
    return Positioned(
      key: ValueKey('timeline-${segment.entry.workoutId}-${segment.dayIndex}'),
      left: left,
      top: top,
      width: laneWidth - 1,
      height: rawHeight < 4 ? 4 : rawHeight,
      child: Tooltip(
        message: segment.entry.label,
        child: Semantics(
          button: true,
          label: '${segment.entry.label}运动时段',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showDetails(context, segment.entry),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineGridPainter extends CustomPainter {
  const _TimelineGridPainter({
    required this.gutter,
    required this.color,
    required this.textColor,
    required this.visibleStartMinute,
  });

  final double gutter;
  final Color color;
  final Color textColor;
  final double visibleStartMinute;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final dayWidth = (size.width - gutter) / 7;
    for (var day = 0; day <= 7; day++) {
      final x = gutter + day * dayWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    final firstHour = visibleStartMinute ~/ 60;
    for (final hour in [
      firstHour,
      for (var value = 6; value <= 24; value += 6)
        if (value > firstHour) value,
    ]) {
      final y =
          (hour * 60 - visibleStartMinute) /
          (24 * 60 - visibleStartMinute) *
          size.height;
      canvas.drawLine(Offset(gutter, y), Offset(size.width, y), paint);
      final label = hour == 24 ? '24' : hour.toString().padLeft(2, '0');
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: textColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(gutter - text.width - 5, y - text.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineGridPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.textColor != textColor ||
      oldDelegate.visibleStartMinute != visibleStartMinute;
}
