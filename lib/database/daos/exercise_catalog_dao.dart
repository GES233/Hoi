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
            ..orderBy([
              (e) => OrderingTerm.asc(e.sortOrder),
              (e) => OrderingTerm.asc(e.id),
            ]))
          .watch();

  Future<List<Exercise>> getExercises({bool includeArchived = false}) =>
      (select(exercises)
            ..where(
              (e) => includeArchived
                  ? const Constant(true)
                  : e.archivedAt.isNull(),
            )
            ..orderBy([
              (e) => OrderingTerm.asc(e.sortOrder),
              (e) => OrderingTerm.asc(e.id),
            ]))
          .get();

  Future<Exercise?> getExercise(int id) =>
      (select(exercises)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<int> _nextCatalogExerciseOrder() async {
    final maxExpr = exercises.sortOrder.max();
    final row = await (selectOnly(exercises)..addColumns([maxExpr])).getSingle();
    return (row.read(maxExpr) ?? -1) + 1;
  }

  Future<int> insertExercise({
    String? builtinKey,
    required String name,
    required ExerciseCategory category,
    required TrackingType trackingType,
    LoadConvention loadConvention = LoadConvention.none,
    RepsConvention repsConvention = RepsConvention.total,
    DateTime? now,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError.value(name, 'name', '动作名称不能为空');
    final nextOrder = await _nextCatalogExerciseOrder();
    return into(exercises).insert(
      ExercisesCompanion.insert(
        builtinKey: Value(builtinKey),
        name: cleanName,
        category: category,
        trackingType: trackingType,
        loadConvention: loadConvention,
        repsConvention: repsConvention,
        sortOrder: Value(nextOrder),
        createdAt: now ?? DateTime.now(),
      ),
    );
  }

  /// 按传入的动作 ID 顺序重排；仅替换 [orderedIds] 所占的槽位，
  /// 因此既支持「全部」列表拖拽，也支持在单个分类筛选下局部拖拽。
  Future<void> reorderExercises(List<int> orderedIds) async {
    final uniqueOrdered = <int>[];
    final seen = <int>{};
    for (final id in orderedIds) {
      if (seen.add(id)) uniqueOrdered.add(id);
    }
    if (uniqueOrdered.length < 2) return;

    await transaction(() async {
      final all =
          await (select(exercises)..orderBy([
                (e) => OrderingTerm.asc(e.sortOrder),
                (e) => OrderingTerm.asc(e.id),
              ]))
              .get();
      final byId = {for (final item in all) item.id: item};
      final validOrdered = [
        for (final id in uniqueOrdered)
          if (byId.containsKey(id)) id,
      ];
      if (validOrdered.length < 2) return;

      final targetSet = validOrdered.toSet();
      var cursor = 0;
      final merged = <Exercise>[
        for (final item in all)
          if (targetSet.contains(item.id))
            byId[validOrdered[cursor++]]!
          else
            item,
      ];

      for (var i = 0; i < merged.length; i++) {
        final item = merged[i];
        if (item.sortOrder != i) {
          await (update(exercises)..where((e) => e.id.equals(item.id))).write(
            ExercisesCompanion(sortOrder: Value(i)),
          );
        }
      }
    });
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
