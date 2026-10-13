part of '../database.dart';

extension WorkoutDao on AppDatabase {
  // ---- 训练 ----

  Future<Workout?> getWorkout(int id) =>
      (select(workouts)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 监听当前进行中的训练（全场至多一场）
  Stream<Workout?> watchOngoingWorkout() =>
      (select(workouts)
            ..where((t) => t.status.equalsValue(WorkoutStatus.inProgress))
            ..limit(1))
          .watchSingleOrNull();

  Future<Workout?> getOngoingWorkout() =>
      (select(workouts)
            ..where((t) => t.status.equalsValue(WorkoutStatus.inProgress))
            ..limit(1))
          .getSingleOrNull();

  /// 开始训练；已有进行中训练时直接返回它，不创建第二场。
  /// 选择模板版本时复制动作口径快照，实际组仍由用户记录。
  Future<Workout> startWorkout({
    DateTime? now,
    TemplateVersion? templateVersion,
  }) async {
    final existing = await getOngoingWorkout();
    if (existing != null) return existing;
    final t = now ?? DateTime.now();
    final id = await transaction(() async {
      final workoutId = await into(workouts).insert(
        WorkoutsCompanion(
          date: Value(AppDatabase.dateOnly(t)),
          status: const Value(WorkoutStatus.inProgress),
          startedAt: Value(t),
          templateVersionId: Value(templateVersion?.id),
          templateNameSnapshot: Value(templateVersion?.name),
          templateEvaluationPolicyVersion: Value(
            templateVersion == null ? null : 1,
          ),
        ),
      );
      if (templateVersion != null) {
        final plannedExercises =
            await (select(templateExercises)
                  ..where((e) => e.templateVersionId.equals(templateVersion.id))
                  ..orderBy([(e) => OrderingTerm.asc(e.sortOrder)]))
                .get();
        for (final planned in plannedExercises) {
          await addWorkoutExercise(
            workoutId,
            name: planned.exerciseNameSnapshot,
            category: planned.categorySnapshot,
            catalogExerciseId: planned.exerciseId,
            trackingType: planned.trackingTypeSnapshot,
            loadConvention: planned.loadConventionSnapshot,
            repsConvention: planned.repsConventionSnapshot,
            templateExerciseId: planned.id,
            note: planned.note,
          );
        }
      }
      return workoutId;
    });
    return (await getWorkout(id))!;
  }

  /// 暂停；仅当未暂停时记录暂停起点
  Future<void> pauseWorkout(int id, {DateTime? now}) async {
    final w = await getWorkout(id);
    if (w == null || w.status != WorkoutStatus.inProgress) return;
    if (w.pausedAt != null) return;
    await (update(workouts)..where((t) => t.id.equals(id))).write(
      WorkoutsCompanion(pausedAt: Value(now ?? DateTime.now())),
    );
  }

  /// 恢复；把这一段暂停累加进 pausedSeconds，并清除暂停标记
  Future<void> resumeWorkout(int id, {DateTime? now}) async {
    final w = await getWorkout(id);
    final pausedAt = w?.pausedAt;
    if (w == null || pausedAt == null) return;
    final t = now ?? DateTime.now();
    await (update(workouts)..where((t2) => t2.id.equals(id))).write(
      WorkoutsCompanion(
        pausedSeconds: Value(
          w.pausedSeconds + t.difference(pausedAt).inSeconds,
        ),
        pausedAt: const Value(null),
      ),
    );
  }

  /// 该训练是否至少有一条有效组
  Future<bool> hasValidSet(int workoutId) async {
    final query =
        select(workoutSets).join([
            innerJoin(
              workoutExercises,
              workoutExercises.id.equalsExp(workoutSets.exerciseId),
            ),
          ])
          ..where(workoutExercises.workoutId.equals(workoutId))
          ..where(workoutSets.setStatus.equalsValue(SetStatus.completed))
          ..where(
            workoutSets.reps.isBiggerThanValue(0) |
                workoutSets.durationSeconds.isBiggerThanValue(0) |
                workoutSets.distanceMeters.isBiggerThanValue(0),
          )
          ..limit(1);
    return (await query.get()).isNotEmpty;
  }

  /// 结束训练：至少一条有效组，否则抛 [StateError]。
  /// totalSeconds 未传且 startedAt 非空时按计时计算（暂停段不计）
  Future<void> finishWorkout(
    int id, {
    int? totalSeconds,
    String? feeling,
    DateTime? now,
  }) async {
    final w = await getWorkout(id);
    if (w == null) return;
    if (!await hasValidSet(id)) {
      throw StateError('结束训练至少需要一条未跳过的有效组');
    }
    final t = now ?? DateTime.now();
    var total = totalSeconds;
    if (total == null && w.startedAt != null) {
      total = AppDatabase.elapsedSeconds(w, now: t);
    }
    await (update(workouts)..where((t2) => t2.id.equals(id))).write(
      WorkoutsCompanion(
        status: const Value(WorkoutStatus.completed),
        endedAt: Value(t),
        pausedAt: const Value(null),
        totalSeconds: Value(total),
        feeling: Value(feeling),
      ),
    );
  }

  /// 丢弃训练（动作与组一并删除；显式级联，不依赖 sqlite 外键开关）
  Future<void> discardWorkout(int id) async {
    await transaction(() async {
      final exerciseIds =
          await (selectOnly(workoutExercises)
                ..addColumns([workoutExercises.id])
                ..where(workoutExercises.workoutId.equals(id)))
              .map((row) => row.read(workoutExercises.id)!)
              .get();
      if (exerciseIds.isNotEmpty) {
        await (delete(
          workoutSets,
        )..where((t) => t.exerciseId.isIn(exerciseIds))).go();
      }
      await (delete(
        workoutExercises,
      )..where((t) => t.workoutId.equals(id))).go();
      await (delete(workouts)..where((t) => t.id.equals(id))).go();
    });
  }

  /// 补记：直接插入一场已完成训练（无开始/结束时间，date 归一化）
  Future<int> insertCompletedWorkout({
    required DateTime date,
    int? totalSeconds,
    String? feeling,
  }) {
    return into(workouts).insert(
      WorkoutsCompanion(
        date: Value(AppDatabase.dateOnly(date)),
        status: const Value(WorkoutStatus.completed),
        totalSeconds: Value(totalSeconds),
        feeling: Value(feeling),
      ),
    );
  }

  /// 编辑已完成训练的元信息；用 [Value] 语义区分「不修改」与「清空」
  Future<void> updateWorkoutMeta(
    int id, {
    Value<int?>? totalSeconds,
    Value<String?>? feeling,
  }) {
    return (update(workouts)..where((t) => t.id.equals(id))).write(
      WorkoutsCompanion(
        totalSeconds: totalSeconds ?? const Value.absent(),
        feeling: feeling ?? const Value.absent(),
      ),
    );
  }

  /// 按归属日期监听已完成训练
  Stream<List<Workout>> watchCompletedWorkouts(DateTime date) =>
      (select(workouts)
            ..where(
              (t) =>
                  t.status.equalsValue(WorkoutStatus.completed) &
                  t.date.equals(AppDatabase.dateOnly(date)),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch();

  /// 监听所在周（周一至周日）的已完成训练
  Stream<List<Workout>> watchCompletedWorkoutsInWeek(DateTime date) {
    final start = AppDatabase.weekStart(date);
    final end = start.add(const Duration(days: 7));
    return (select(workouts)
          ..where(
            (t) =>
                t.status.equalsValue(WorkoutStatus.completed) &
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch();
  }

  /// 把持久化记录转换为规则引擎的稳定事实 DTO；规则计算不直接读取 Drift 表。
  Future<MetricContext> buildMetricContext({
    required DateTime periodStart,
    required DateTime periodEndExclusive,
  }) async {
    final start = AppDatabase.dateOnly(periodStart);
    final end = AppDatabase.dateOnly(periodEndExclusive);
    final completed =
        await (select(workouts)
              ..where(
                (workout) =>
                    workout.status.equalsValue(WorkoutStatus.completed) &
                    workout.date.isBiggerOrEqualValue(start) &
                    workout.date.isSmallerThanValue(end),
              )
              ..orderBy([(workout) => OrderingTerm.asc(workout.date)]))
            .get();
    final sessions = <MetricSessionFact>[];
    for (final workout in completed) {
      final actualExercises = await getWorkoutExercises(workout.id);
      final actualSets = await getWorkoutSets(workout.id);
      sessions.add(
        MetricSessionFact(
          workoutId: workout.id,
          date: workout.date,
          completed: true,
          totalSeconds: workout.totalSeconds,
          exercises: [
            for (final exercise in actualExercises)
              MetricExerciseFact(
                exerciseId: exercise.catalogExerciseId,
                category: exercise.category.name,
                trackingType: exercise.trackingTypeSnapshot.name,
                sets: [
                  for (final set in actualSets.where(
                    (set) => set.exerciseId == exercise.id,
                  ))
                    MetricSetFact(
                      setRole: set.setRole.name,
                      setStatus: set.setStatus.name,
                      reps: set.reps,
                      durationSeconds: set.durationSeconds,
                      distanceMeters: set.distanceMeters,
                    ),
                ],
              ),
          ],
        ),
      );
    }
    return MetricContext(
      periodStart: start,
      periodEndExclusive: end,
      sessions: sessions,
    );
  }
}
