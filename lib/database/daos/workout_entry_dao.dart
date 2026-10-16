part of '../database.dart';

extension WorkoutEntryDao on AppDatabase {
  // ---- 动作与组 ----

  Future<int> _nextExerciseOrder(int workoutId) async {
    final maxExpr = workoutExercises.sortOrder.max();
    final row =
        await (selectOnly(workoutExercises)
              ..addColumns([maxExpr])
              ..where(workoutExercises.workoutId.equals(workoutId)))
            .getSingle();
    return (row.read(maxExpr) ?? -1) + 1;
  }

  Future<int> addWorkoutExercise(
    int workoutId, {
    required String name,
    required ExerciseCategory category,
    int? catalogExerciseId,
    TrackingType trackingType = TrackingType.reps,
    LoadConvention loadConvention = LoadConvention.none,
    RepsConvention repsConvention = RepsConvention.total,
    int? templateExerciseId,
    String? note,
  }) async {
    return into(workoutExercises).insert(
      WorkoutExercisesCompanion(
        workoutId: Value(workoutId),
        catalogExerciseId: Value(catalogExerciseId),
        name: Value(name),
        category: Value(category),
        trackingTypeSnapshot: Value(trackingType),
        loadConventionSnapshot: Value(loadConvention),
        repsConventionSnapshot: Value(repsConvention),
        templateExerciseId: Value(templateExerciseId),
        note: Value(note),
        sortOrder: Value(await _nextExerciseOrder(workoutId)),
      ),
    );
  }

  Future<void> deleteWorkoutExercise(int id) async {
    // 显式级联删除组，不依赖 sqlite 外键开关
    await transaction(() async {
      await (delete(workoutSets)..where((t) => t.exerciseId.equals(id))).go();
      await (delete(workoutExercises)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<int> _nextSetOrder(int exerciseId) async {
    final maxExpr = workoutSets.sortOrder.max();
    final row =
        await (selectOnly(workoutSets)
              ..addColumns([maxExpr])
              ..where(workoutSets.exerciseId.equals(exerciseId)))
            .getSingle();
    return (row.read(maxExpr) ?? -1) + 1;
  }

  Future<int> addWorkoutSet(
    int exerciseId, {
    int? templateSetId,
    SetRole? setRole,
    SetStatus setStatus = SetStatus.completed,
    int? reps,
    int? durationSeconds,
    double? distanceMeters,
    double? weightKg,
    double? assistanceKg,
    double? rpe,
    double? rir,
    String? note,
  }) async {
    var resolvedTemplateSetId = templateSetId;
    TemplateSet? planned;
    if (resolvedTemplateSetId == null) {
      final actualExercise = await (select(
        workoutExercises,
      )..where((e) => e.id.equals(exerciseId))).getSingleOrNull();
      final plannedExerciseId = actualExercise?.templateExerciseId;
      if (plannedExerciseId != null) {
        final candidates =
            await (select(templateSets)
                  ..where((s) => s.templateExerciseId.equals(plannedExerciseId))
                  ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
                .get();
        final used =
            await (selectOnly(workoutSets)
                  ..addColumns([workoutSets.templateSetId])
                  ..where(workoutSets.exerciseId.equals(exerciseId))
                  ..where(workoutSets.templateSetId.isNotNull()))
                .map((row) => row.read(workoutSets.templateSetId))
                .get();
        planned = candidates.cast<TemplateSet?>().firstWhere(
          (candidate) => !used.contains(candidate!.id),
          orElse: () => null,
        );
        resolvedTemplateSetId = planned?.id;
      }
    } else {
      planned = await (select(
        templateSets,
      )..where((s) => s.id.equals(resolvedTemplateSetId!))).getSingleOrNull();
    }
    return into(workoutSets).insert(
      WorkoutSetsCompanion(
        exerciseId: Value(exerciseId),
        templateSetId: Value(resolvedTemplateSetId),
        setRole: Value(setRole ?? planned?.setRole ?? SetRole.work),
        setStatus: Value(setStatus),
        reps: Value(reps),
        durationSeconds: Value(durationSeconds),
        distanceMeters: Value(distanceMeters),
        weightKg: Value(weightKg),
        assistanceKg: Value(assistanceKg),
        rpe: Value(rpe),
        rir: Value(rir),
        note: Value(note),
        sortOrder: Value(await _nextSetOrder(exerciseId)),
      ),
    );
  }

  /// 编辑组；用 [Value] 语义区分「不修改」与「清空」
  Future<void> updateWorkoutSet(
    int id, {
    Value<SetRole>? setRole,
    Value<SetStatus>? setStatus,
    Value<int?>? reps,
    Value<int?>? durationSeconds,
    Value<double?>? distanceMeters,
    Value<double?>? weightKg,
    Value<double?>? assistanceKg,
    Value<double?>? rpe,
    Value<double?>? rir,
    Value<String?>? note,
  }) {
    return (update(workoutSets)..where((t) => t.id.equals(id))).write(
      WorkoutSetsCompanion(
        setRole: setRole ?? const Value.absent(),
        setStatus: setStatus ?? const Value.absent(),
        reps: reps ?? const Value.absent(),
        durationSeconds: durationSeconds ?? const Value.absent(),
        distanceMeters: distanceMeters ?? const Value.absent(),
        weightKg: weightKg ?? const Value.absent(),
        assistanceKg: assistanceKg ?? const Value.absent(),
        rpe: rpe ?? const Value.absent(),
        rir: rir ?? const Value.absent(),
        note: note ?? const Value.absent(),
      ),
    );
  }

  Future<void> deleteWorkoutSet(int id) =>
      (delete(workoutSets)..where((t) => t.id.equals(id))).go();

  /// 监听一场训练的动作列表（按添加顺序）
  Stream<List<WorkoutExercise>> watchWorkoutExercises(int workoutId) =>
      (select(workoutExercises)
            ..where((t) => t.workoutId.equals(workoutId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  /// 监听一场训练的全部组（按动作顺序、组顺序排列）
  Stream<List<WorkoutSet>> watchWorkoutSets(int workoutId) {
    final query =
        select(workoutSets).join([
            innerJoin(
              workoutExercises,
              workoutExercises.id.equalsExp(workoutSets.exerciseId),
            ),
          ])
          ..where(workoutExercises.workoutId.equals(workoutId))
          ..orderBy([
            OrderingTerm.asc(workoutExercises.sortOrder),
            OrderingTerm.asc(workoutSets.sortOrder),
          ]);
    return query.map((row) => row.readTable(workoutSets)).watch();
  }

  /// 一次性读取一场训练的动作列表（按添加顺序）
  Future<List<WorkoutExercise>> getWorkoutExercises(int workoutId) =>
      (select(workoutExercises)
            ..where((t) => t.workoutId.equals(workoutId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  /// 一次性读取一场训练的全部组
  Future<List<WorkoutSet>> getWorkoutSets(int workoutId) {
    final query = select(workoutSets).join([
      innerJoin(
        workoutExercises,
        workoutExercises.id.equalsExp(workoutSets.exerciseId),
      ),
    ])..where(workoutExercises.workoutId.equals(workoutId));
    return query.map((row) => row.readTable(workoutSets)).get();
  }

  Future<List<TemplateSet>> getTemplateSetsForExercise(
    int templateExerciseId,
  ) =>
      (select(templateSets)
            ..where((set) => set.templateExerciseId.equals(templateExerciseId))
            ..orderBy([(set) => OrderingTerm.asc(set.sortOrder)]))
          .get();
}
