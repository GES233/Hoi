import 'package:flutter_test/flutter_test.dart';
import 'package:hoi/domain/workout_timeline.dart';

void main() {
  final monday = DateTime(2026, 10, 5);

  WorkoutTimelineEntry entry(int id, DateTime start, DateTime? end) =>
      WorkoutTimelineEntry(
        workoutId: id,
        startedAt: start,
        endedAt: end,
        totalSeconds: null,
        label: '训练$id',
      );

  test('跨午夜训练裁成相邻两天的条纹', () {
    final segments = buildWorkoutTimeline(
      entries: [
        entry(
          1,
          monday.add(const Duration(hours: 23, minutes: 30)),
          monday.add(const Duration(days: 1, minutes: 30)),
        ),
      ],
      rangeStart: monday,
      now: monday,
    );

    expect(segments, hasLength(2));
    expect(segments[0].dayIndex, 0);
    expect(segments[0].startMinute, 23 * 60 + 30);
    expect(segments[0].endMinute, 24 * 60);
    expect(segments[1].dayIndex, 1);
    expect(segments[1].startMinute, 0);
    expect(segments[1].endMinute, 30);
  });

  test('进行中训练以注入的 now 作为末端', () {
    final segments = buildWorkoutTimeline(
      entries: [entry(1, monday.add(const Duration(hours: 10)), null)],
      rangeStart: monday,
      now: monday.add(const Duration(hours: 11, minutes: 15)),
    );

    expect(segments.single.startMinute, 600);
    expect(segments.single.endMinute, 675);
  });

  test('同日重叠训练分配不同 lane，首尾相接可复用 lane', () {
    final segments = buildWorkoutTimeline(
      entries: [
        entry(
          1,
          monday.add(const Duration(hours: 10)),
          monday.add(const Duration(hours: 11)),
        ),
        entry(
          2,
          monday.add(const Duration(hours: 10, minutes: 30)),
          monday.add(const Duration(hours: 11, minutes: 30)),
        ),
        entry(
          3,
          monday.add(const Duration(hours: 11)),
          monday.add(const Duration(hours: 12)),
        ),
      ],
      rangeStart: monday,
      now: monday,
    );

    expect(segments.map((segment) => segment.lane), [0, 1, 0]);
    expect(segments.every((segment) => segment.laneCount == 2), isTrue);
  });

  test('周范围外和无正跨度的训练不生成条纹', () {
    final segments = buildWorkoutTimeline(
      entries: [
        entry(
          1,
          monday.subtract(const Duration(hours: 2)),
          monday.subtract(const Duration(hours: 1)),
        ),
        entry(2, monday, monday),
      ],
      rangeStart: monday,
      now: monday,
    );

    expect(segments, isEmpty);
  });
}
