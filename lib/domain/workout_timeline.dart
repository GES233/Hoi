class WorkoutTimelineEntry {
  const WorkoutTimelineEntry({
    required this.workoutId,
    required this.startedAt,
    required this.endedAt,
    required this.totalSeconds,
    required this.label,
  });

  final int workoutId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? totalSeconds;
  final String label;
}

class WorkoutTimelineSegment {
  const WorkoutTimelineSegment({
    required this.entry,
    required this.dayIndex,
    required this.startMinute,
    required this.endMinute,
    required this.lane,
    required this.laneCount,
  });

  final WorkoutTimelineEntry entry;
  final int dayIndex;
  final double startMinute;
  final double endMinute;
  final int lane;
  final int laneCount;
}

/// 将训练的现实时间跨度裁切到连续日期列，并为同日重叠区间分配 lane。
List<WorkoutTimelineSegment> buildWorkoutTimeline({
  required List<WorkoutTimelineEntry> entries,
  required DateTime rangeStart,
  required DateTime now,
  int dayCount = 7,
}) {
  if (dayCount <= 0) throw ArgumentError.value(dayCount, 'dayCount');
  final start = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
  final rangeEnd = start.add(Duration(days: dayCount));
  final byDay = <int, List<_MutableSegment>>{};

  for (final entry in entries) {
    final effectiveEnd = entry.endedAt ?? now;
    if (!effectiveEnd.isAfter(entry.startedAt)) continue;
    if (!entry.startedAt.isBefore(rangeEnd) || !effectiveEnd.isAfter(start)) {
      continue;
    }

    for (var dayIndex = 0; dayIndex < dayCount; dayIndex++) {
      final dayStart = start.add(Duration(days: dayIndex));
      final dayEnd = dayStart.add(const Duration(days: 1));
      final clippedStart = entry.startedAt.isAfter(dayStart)
          ? entry.startedAt
          : dayStart;
      final clippedEnd = effectiveEnd.isBefore(dayEnd) ? effectiveEnd : dayEnd;
      if (!clippedEnd.isAfter(clippedStart)) continue;
      (byDay[dayIndex] ??= []).add(
        _MutableSegment(
          entry: entry,
          dayIndex: dayIndex,
          startMinute: clippedStart.difference(dayStart).inMilliseconds / 60000,
          endMinute: clippedEnd.difference(dayStart).inMilliseconds / 60000,
        ),
      );
    }
  }

  final result = <WorkoutTimelineSegment>[];
  for (final dayIndex in byDay.keys.toList()..sort()) {
    final segments = byDay[dayIndex]!
      ..sort((a, b) {
        final byStart = a.startMinute.compareTo(b.startMinute);
        return byStart != 0 ? byStart : a.endMinute.compareTo(b.endMinute);
      });
    final laneEnds = <double>[];
    for (final segment in segments) {
      var lane = laneEnds.indexWhere((end) => end <= segment.startMinute);
      if (lane == -1) {
        lane = laneEnds.length;
        laneEnds.add(segment.endMinute);
      } else {
        laneEnds[lane] = segment.endMinute;
      }
      segment.lane = lane;
    }
    final laneCount = laneEnds.length;
    result.addAll(
      segments.map(
        (segment) => WorkoutTimelineSegment(
          entry: segment.entry,
          dayIndex: segment.dayIndex,
          startMinute: segment.startMinute,
          endMinute: segment.endMinute,
          lane: segment.lane,
          laneCount: laneCount,
        ),
      ),
    );
  }
  return result;
}

class _MutableSegment {
  _MutableSegment({
    required this.entry,
    required this.dayIndex,
    required this.startMinute,
    required this.endMinute,
  });

  final WorkoutTimelineEntry entry;
  final int dayIndex;
  final double startMinute;
  final double endMinute;
  int lane = 0;
}
