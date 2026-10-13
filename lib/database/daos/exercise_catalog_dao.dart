part of '../database.dart';

extension ExerciseCatalogDao on AppDatabase {
  // ---- 动作目录 ----

  Stream<List<Exercise>> watchExercises({bool includeArchived = false}) =>
      (select(exercises)
            ..where(
              (e) => includeArchived
                  ? const Constant(true)
                  : e.archivedAt.isNull(),
            )
            ..orderBy([(e) => OrderingTerm.asc(e.name)]))
          .watch();

  Future<List<Exercise>> getExercises({bool includeArchived = false}) =>
      (select(exercises)
            ..where(
              (e) => includeArchived
                  ? const Constant(true)
                  : e.archivedAt.isNull(),
            )
            ..orderBy([(e) => OrderingTerm.asc(e.name)]))
          .get();

  Future<Exercise?> getExercise(int id) =>
      (select(exercises)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<int> insertExercise({
    String? builtinKey,
    required String name,
    required ExerciseCategory category,
    required TrackingType trackingType,
    LoadConvention loadConvention = LoadConvention.none,
    RepsConvention repsConvention = RepsConvention.total,
    DateTime? now,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError.value(name, 'name', '动作名称不能为空');
    return into(exercises).insert(
      ExercisesCompanion.insert(
        builtinKey: Value(builtinKey),
        name: cleanName,
        category: category,
        trackingType: trackingType,
        loadConvention: loadConvention,
        repsConvention: repsConvention,
        createdAt: now ?? DateTime.now(),
      ),
    );
  }

  Future<void> archiveExercise(int id, {DateTime? now}) =>
      (update(exercises)..where((e) => e.id.equals(id))).write(
        ExercisesCompanion(archivedAt: Value(now ?? DateTime.now())),
      );

  /// 更新动作目录的当前定义；历史模板与训练使用各自快照，不受影响。
  Future<void> updateExercise(
    int id, {
    required String name,
    required ExerciseCategory category,
    required TrackingType trackingType,
    LoadConvention loadConvention = LoadConvention.none,
    RepsConvention repsConvention = RepsConvention.total,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError.value(name, 'name', '动作名称不能为空');
    return (update(exercises)..where((e) => e.id.equals(id))).write(
      ExercisesCompanion(
        name: Value(cleanName),
        category: Value(category),
        trackingType: Value(trackingType),
        loadConvention: Value(loadConvention),
        repsConvention: Value(repsConvention),
      ),
    );
  }
}
