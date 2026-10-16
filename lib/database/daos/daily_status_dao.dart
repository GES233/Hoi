part of '../database.dart';

extension DailyStatusDao on AppDatabase {
  // ---- 每日状态 ----

  /// 任一源流变化都发出一次事件（监听时立即发一次），
  /// 同一微任务轮次内多个源流同时发射时合并为一次重算（不使用 Timer，兼容测试 FakeAsync）
  Stream<void> _watchAny(List<Stream<Object?>> sources) {
    return Stream.multi((multi) {
      var pending = false;
      void trigger() {
        if (pending || multi.isClosed) return;
        pending = true;
        scheduleMicrotask(() {
          pending = false;
          if (!multi.isClosed) multi.add(null);
        });
      }

      final subs = <StreamSubscription<dynamic>>[
        for (final s in sources) s.listen((_) => trigger()),
      ];
      trigger(); // 首次立即触发
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
  Stream<List<WorkoutSet>> _watchSetsForDate(DateTime day) =>
      _watchSetsInDateRange(day, day.add(const Duration(days: 1)));

  /// 监听日期区间 [start, endExclusive) 内训练相关的组
  Stream<List<WorkoutSet>> _watchSetsInDateRange(
    DateTime start,
    DateTime endExclusive,
  ) {
    final query =
        select(workoutSets).join([
          innerJoin(
            workoutExercises,
            workoutExercises.id.equalsExp(workoutSets.exerciseId),
          ),
          innerJoin(
            workouts,
            workouts.id.equalsExp(workoutExercises.workoutId),
          ),
        ])..where(
          workouts.date.isBiggerOrEqualValue(start) &
              workouts.date.isSmallerThanValue(endExclusive),
        );
    return query.map((row) => row.readTable(workoutSets)).watch();
  }

  /// 监听日期区间 [start, endExclusive) 内训练相关的动作
  Stream<List<WorkoutExercise>> _watchExercisesInDateRange(
    DateTime start,
    DateTime endExclusive,
  ) {
    final query =
        select(workoutExercises).join([
          innerJoin(
            workouts,
            workouts.id.equalsExp(workoutExercises.workoutId),
          ),
        ])..where(
          workouts.date.isBiggerOrEqualValue(start) &
              workouts.date.isSmallerThanValue(endExclusive),
        );
    return query.map((row) => row.readTable(workoutExercises)).watch();
  }

  /// 监听日期区间 [start, endExclusive) 内的休息标记
  Stream<List<RestMark>> _watchRestMarksInRange(
    DateTime start,
    DateTime endExclusive,
  ) =>
      (select(restMarks)..where(
            (r) =>
                r.date.isBiggerOrEqualValue(start) &
                r.date.isSmallerThanValue(endExclusive),
          ))
          .watch();

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
  /// 仅监听当周相关的休息标记、训练、动作与组，并批量计算整周状态以消除 N+1 查询。
  Stream<Map<DateTime, DailyStatus>> watchWeekDailyStatus(DateTime date) {
    final start = AppDatabase.weekStart(date);
    final end = start.add(const Duration(days: 7));
    return _watchAny([
      watchWorkoutTemplates(),
      _watchRestMarksInRange(start, end),
      watchCompletedWorkoutsInWeek(date),
      _watchExercisesInDateRange(start, end),
      _watchSetsInDateRange(start, end),
    ]).asyncMap((_) => computeWeekDailyStatus(date));
  }

  /// 批量计算所在周（周一至周日）每天的每日状态
  Future<Map<DateTime, DailyStatus>> computeWeekDailyStatus(
    DateTime date,
  ) async {
    final start = AppDatabase.weekStart(date);
    final end = start.add(const Duration(days: 7));
    final hasPlan =
        (await (select(workoutTemplates)
                  ..where((t) => t.archivedAt.isNull())
                  ..limit(1))
                .get())
            .isNotEmpty;
    final completed =
        await (select(workouts)..where(
              (t) =>
                  t.status.equalsValue(WorkoutStatus.completed) &
                  t.date.isBiggerOrEqualValue(start) &
                  t.date.isSmallerThanValue(end),
            ))
            .get();
    final rests = hasPlan
        ? await (select(restMarks)..where(
                (r) =>
                    r.date.isBiggerOrEqualValue(start) &
                    r.date.isSmallerThanValue(end),
              ))
              .get()
        : const <RestMark>[];
    final restDays = {for (final r in rests) AppDatabase.dateOnly(r.date)};
    final workoutsByDay = <DateTime, List<Workout>>{};
    for (final w in completed) {
      (workoutsByDay[AppDatabase.dateOnly(w.date)] ??= []).add(w);
    }

    // 批量预加载本周已完成训练所引用的模板版本计划组与实际组
    final versionIds = completed
        .map((w) => w.templateVersionId)
        .whereType<int>()
        .toSet();
    final plannedSetsByVersion = <int, List<TemplateSet>>{};
    final actualSetsByWorkout = <int, List<WorkoutSet>>{};
    if (hasPlan && versionIds.isNotEmpty) {
      final plannedExercises =
          await (select(templateExercises)
                ..where((e) => e.templateVersionId.isIn(versionIds))
                ..orderBy([(e) => OrderingTerm.asc(e.sortOrder)]))
              .get();
      final plannedExerciseIds = [for (final e in plannedExercises) e.id];
      final versionByPlannedExercise = {
        for (final e in plannedExercises) e.id: e.templateVersionId,
      };
      final plannedSets = plannedExerciseIds.isEmpty
          ? const <TemplateSet>[]
          : await (select(templateSets)
                  ..where((s) => s.templateExerciseId.isIn(plannedExerciseIds))
                  ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
                .get();
      for (final vId in versionIds) {
        plannedSetsByVersion[vId] = [];
      }
      for (final s in plannedSets) {
        final vId = versionByPlannedExercise[s.templateExerciseId];
        if (vId != null) {
          (plannedSetsByVersion[vId] ??= []).add(s);
        }
      }

      final linkedWorkoutIds = [
        for (final w in completed)
          if (w.templateVersionId != null) w.id,
      ];
      if (linkedWorkoutIds.isNotEmpty) {
        final joinedRows =
            await (select(workoutSets).join([
              innerJoin(
                workoutExercises,
                workoutExercises.id.equalsExp(workoutSets.exerciseId),
              ),
            ])..where(workoutExercises.workoutId.isIn(linkedWorkoutIds))).get();
        for (final row in joinedRows) {
          final set = row.readTable(workoutSets);
          final exercise = row.readTable(workoutExercises);
          (actualSetsByWorkout[exercise.workoutId] ??= []).add(set);
        }
      }
    }

    final result = <DateTime, DailyStatus>{};
    for (var i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final dayWorkouts = workoutsByDay[day] ?? const <Workout>[];
      if (!hasPlan) {
        // 未设方案时点阵仍区分「有记录 / 无记录」
        result[day] = dayWorkouts.isNotEmpty
            ? DailyStatus.recorded
            : DailyStatus.none;
        continue;
      }
      if (dayWorkouts.isEmpty) {
        result[day] = restDays.contains(day)
            ? DailyStatus.rest
            : DailyStatus.none;
        continue;
      }
      var hasMin = false;
      var hasRegular = false;
      for (final w in dayWorkouts) {
        final vId = w.templateVersionId;
        if (vId == null) continue;
        final plannedSets = plannedSetsByVersion[vId];
        if (plannedSets == null) continue;
        final actualSets = actualSetsByWorkout[w.id] ?? const <WorkoutSet>[];
        final ev = TemplateDao._evaluateSetsAgainstPlanned(
          plannedSets,
          actualSets,
        );
        if (ev.tier == PlanTier.regular) {
          hasRegular = true;
          break;
        }
        if (ev.tier == PlanTier.min) hasMin = true;
      }
      result[day] = hasRegular
          ? DailyStatus.regularDone
          : hasMin
          ? DailyStatus.minDone
          : DailyStatus.recorded;
    }
    return result;
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
