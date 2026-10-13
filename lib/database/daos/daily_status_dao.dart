part of '../database.dart';

extension DailyStatusDao on AppDatabase {
  // ---- 每日状态 ----

  /// 任一源流变化都发出一次事件（监听时立即发一次），供组合查询重算
  Stream<void> _watchAny(List<Stream<Object?>> sources) {
    return Stream.multi((multi) {
      final subs = <StreamSubscription<dynamic>>[
        for (final s in sources) s.listen((_) => multi.add(null)),
      ];
      multi.add(null); // 首次立即触发
      multi
        ..onPause = () {
          for (final sub in subs) {
            sub.pause();
          }
        }
        ..onResume = () {
          for (final sub in subs) {
            sub.resume();
          }
        }
        ..onCancel = () async {
          for (final sub in subs) {
            await sub.cancel();
          }
        };
    });
  }

  /// 监听指定日期内全部训练相关的组（用于触发每日状态重算）
  Stream<List<WorkoutSet>> _watchSetsForDate(DateTime day) {
    final query = select(workoutSets).join([
      innerJoin(
        workoutExercises,
        workoutExercises.id.equalsExp(workoutSets.exerciseId),
      ),
      innerJoin(workouts, workouts.id.equalsExp(workoutExercises.workoutId)),
    ])..where(workouts.date.equals(day));
    return query.map((row) => row.readTable(workoutSets)).watch();
  }

  /// 计算某天的每日状态（当天数据量小，直接按快照逐场评估）
  Future<DailyStatus> computeDailyStatus(DateTime date) async {
    final day = AppDatabase.dateOnly(date);
    final templates = await (select(
      workoutTemplates,
    )..where((t) => t.archivedAt.isNull())).get();
    if (templates.isEmpty) return DailyStatus.noPlan;
    final done =
        await (select(workouts)..where(
              (t) =>
                  t.status.equalsValue(WorkoutStatus.completed) &
                  t.date.equals(day),
            ))
            .get();
    if (done.isEmpty) {
      final rest = await (select(
        restMarks,
      )..where((t) => t.date.equals(day))).getSingleOrNull();
      return rest != null ? DailyStatus.rest : DailyStatus.none;
    }
    // 取当天已完成训练中的最高档：regular > min > recorded
    var hasMin = false;
    for (final w in done) {
      final ev = await evaluateWorkoutTemplate(w.id);
      if (ev.tier == PlanTier.regular) return DailyStatus.regularDone;
      if (ev.tier == PlanTier.min) hasMin = true;
    }
    return hasMin ? DailyStatus.minDone : DailyStatus.recorded;
  }

  /// 监听某天的每日状态；方案 / 休息标记 / 当天训练与组任一变化都重算
  Stream<DailyStatus> watchDailyStatus(DateTime date) {
    final day = AppDatabase.dateOnly(date);
    return _watchAny([
      watchWorkoutTemplates(),
      watchRestMark(day),
      watchCompletedWorkouts(day),
      _watchSetsForDate(day),
    ]).asyncMap((_) => computeDailyStatus(day));
  }

  /// 监听所在周（周一至周日）每天的每日状态，key 为归一化日期。
  /// 本地数据量小，用整表级触发 + 逐日重算换实现简单
  Stream<Map<DateTime, DailyStatus>> watchWeekDailyStatus(DateTime date) {
    final start = AppDatabase.weekStart(date);
    return _watchAny([
      watchWorkoutTemplates(),
      select(restMarks).watch(),
      watchCompletedWorkoutsInWeek(date),
      select(workoutExercises).watch(),
      select(workoutSets).watch(),
    ]).asyncMap((_) async {
      final result = <DateTime, DailyStatus>{};
      for (var i = 0; i < 7; i++) {
        final day = start.add(Duration(days: i));
        var status = await computeDailyStatus(day);
        if (status == DailyStatus.noPlan) {
          // 未设方案时点阵仍区分「有记录 / 无记录」
          final done =
              await (select(workouts)..where(
                    (t) =>
                        t.status.equalsValue(WorkoutStatus.completed) &
                        t.date.equals(day),
                  ))
                  .get();
          status = done.isNotEmpty ? DailyStatus.recorded : DailyStatus.none;
        }
        result[day] = status;
      }
      return result;
    });
  }

  /// 当天各模板的完成度：key 为模板 id，值为当日关联训练的最高档评估。
  Stream<Map<int, TemplateProgress>> watchDailyTemplateProgress(DateTime date) {
    final day = AppDatabase.dateOnly(date);
    return _watchAny([
      watchWorkoutTemplates(),
      watchCompletedWorkouts(day),
      _watchSetsForDate(day),
    ]).asyncMap((_) async {
      final done =
          await (select(workouts)..where(
                (t) =>
                    t.status.equalsValue(WorkoutStatus.completed) &
                    t.date.equals(day),
              ))
              .get();
      final result = <int, TemplateProgress>{};
      for (final w in done) {
        final versionId = w.templateVersionId;
        if (versionId == null) continue;
        final version = await getTemplateVersion(versionId);
        if (version == null) continue;
        final ev = await evaluateWorkoutTemplate(w.id);
        final prev = result[version.templateId];
        if (prev == null || _tierRank(ev.tier) > _tierRank(prev.tier)) {
          result[version.templateId] = ev;
        }
      }
      return result;
    });
  }

  static int _tierRank(PlanTier t) => switch (t) {
    PlanTier.none => 0,
    PlanTier.belowMin => 1,
    PlanTier.min => 2,
    PlanTier.regular => 3,
  };
}
