import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// 餐次类型
enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeLabel on MealType {
  String get label => switch (this) {
    MealType.breakfast => '早餐',
    MealType.lunch => '午餐',
    MealType.dinner => '晚餐',
    MealType.snack => '加餐',
  };
}

/// 运动类别
enum ExerciseCategory { cardio, resistance, core, functional }

extension ExerciseCategoryLabel on ExerciseCategory {
  String get label => switch (this) {
    ExerciseCategory.cardio => '心肺',
    ExerciseCategory.resistance => '抗阻',
    ExerciseCategory.core => '核心',
    ExerciseCategory.functional => '功能',
  };
}

/// 训练状态：进行中 / 已完成
enum WorkoutStatus { inProgress, completed }

/// 方案指标：持续时长 / 有效组数（阶段 2 使用）
enum PlanMetric { duration, sets }

/// 单次训练按方案快照评估出的达标档位；none 表示未关联方案
enum PlanTier { none, belowMin, min, regular }

/// 达标评估结果：档位 + 实际累计值（duration 指标为秒，sets 指标为有效组数）
class PlanEvaluation {
  const PlanEvaluation(this.tier, this.actual);

  final PlanTier tier;
  final int actual;
}

/// 每日状态：未设方案 / 无记录 / 休息 / 已记录未达最低 / 达最低 / 达常规
enum DailyStatus { noPlan, none, rest, recorded, minDone, regularDone }

/// 饮食记录
class FoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 只存日期部分（本地时间午夜）
  DateTimeColumn get date => dateTime()();
  IntColumn get mealType => intEnum<MealType>()();
  TextColumn get name => text()();
  IntColumn get calories => integer()();
}

/// 常用食物收藏
class FavoriteFoods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  IntColumn get calories => integer()();
}

/// 每周运动目标（次数 + 分钟），全表仅一行；空表时使用 [AppDatabase.defaultWeeklyGoals]
class WeeklyExerciseGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get targetSessions => integer()();
  IntColumn get targetMinutes => integer()();
}

/// 一次训练（容器）：一次训练可含多个动作与多组，统计时只计一次
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 归属日期（只存日期部分）；实时训练取开始当天，跨午夜不拆分
  DateTimeColumn get date => dateTime()();
  IntColumn get status => intEnum<WorkoutStatus>()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();

  /// 暂停中标记；非空表示当前处于暂停
  DateTimeColumn get pausedAt => dateTime().nullable()();

  /// 已累计的暂停秒数（恢复时累加）
  IntColumn get pausedSeconds => integer().withDefault(const Constant(0))();

  /// 训练总用时（秒）；未知即为 null，绝不推算
  IntColumn get totalSeconds => integer().nullable()();
  TextColumn get feeling => text().nullable()();

  /// 方案快照（阶段 2 使用，先建好列）
  IntColumn get planId => integer().nullable()();
  TextColumn get planName => text().nullable()();
  TextColumn get planExerciseName => text().nullable()();
  IntColumn get planMetric => intEnum<PlanMetric>().nullable()();
  IntColumn get planMin => integer().nullable()();
  IntColumn get planRegular => integer().nullable()();
}

/// 训练中的一个动作
class WorkoutExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId =>
      integer().references(Workouts, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get category => intEnum<ExerciseCategory>()();
  TextColumn get note => text().nullable()();
  IntColumn get sortOrder => integer()();
}

/// 一组动作记录；有效组定义：reps > 0 或 durationSeconds > 0
class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId =>
      integer().references(WorkoutExercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get reps => integer().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  RealColumn get weightKg => real().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get sortOrder => integer()();
}

/// 最低／常规运动方案（阶段 2 才写查询，本阶段只建表）
class ExercisePlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get exerciseName => text()();
  IntColumn get category => intEnum<ExerciseCategory>()();
  IntColumn get metric => intEnum<PlanMetric>()();
  IntColumn get minThreshold => integer()();
  IntColumn get regularThreshold => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// 休息标记（阶段 2 使用）
class RestMarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime().unique()();
  TextColumn get note => text().nullable()();
}

@DriftDatabase(tables: [
  FoodEntries,
  FavoriteFoods,
  WeeklyExerciseGoals,
  Workouts,
  WorkoutExercises,
  WorkoutSets,
  ExercisePlans,
  RestMarks,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  static QueryExecutor _openConnection() => driftDatabase(name: 'hoi_tracker');

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(weeklyExerciseGoals);
          }
          if (from < 3) {
            // 旧运动记录表被实际训练模型取代，经确认直接丢弃旧数据
            await m.deleteTable('exercise_entries');
            await m.createTable(workouts);
            await m.createTable(workoutExercises);
            await m.createTable(workoutSets);
            await m.createTable(exercisePlans);
            await m.createTable(restMarks);
          }
        },
      );

  /// 只保留日期部分，保证按天查询的一致性
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 所在周的周一（周一为一周起点）
  static DateTime weekStart(DateTime d) {
    final day = dateOnly(d);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  /// 未设置目标时的默认值：每周 3 次、90 分钟
  static const defaultWeeklyGoals = WeeklyExerciseGoal(
    id: 1,
    targetSessions: 3,
    targetMinutes: 90,
  );

  // ---- 饮食 ----

  Stream<List<FoodEntry>> watchFoodEntries(DateTime date) =>
      (select(foodEntries)..where((t) => t.date.equals(dateOnly(date))))
          .watch();

  Future<int> insertFoodEntry(FoodEntriesCompanion entry) =>
      into(foodEntries).insert(entry);

  Future<int> deleteFoodEntry(int id) =>
      (delete(foodEntries)..where((t) => t.id.equals(id))).go();

  Stream<List<FavoriteFood>> watchFavoriteFoods() =>
      (select(favoriteFoods)
        ..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  /// 按名称 upsert 常用食物
  Future<void> upsertFavoriteFood(String name, int calories) {
    return into(favoriteFoods).insert(
      FavoriteFoodsCompanion(name: Value(name), calories: Value(calories)),
      onConflict: DoUpdate(
        (_) => FavoriteFoodsCompanion(calories: Value(calories)),
        target: [favoriteFoods.name],
      ),
    );
  }

  /// 监听每周运动目标；空表时返回 [defaultWeeklyGoals]
  Stream<WeeklyExerciseGoal> watchWeeklyGoals() =>
      (select(weeklyExerciseGoals)..limit(1))
          .watchSingleOrNull()
          .map((goal) => goal ?? defaultWeeklyGoals);

  /// 更新每周运动目标；空表时插入首行
  Future<void> updateWeeklyGoals({
    required int targetSessions,
    required int targetMinutes,
  }) async {
    final existing =
        await (select(weeklyExerciseGoals)..limit(1)).getSingleOrNull();
    if (existing == null) {
      await into(weeklyExerciseGoals).insert(
        WeeklyExerciseGoalsCompanion(
          targetSessions: Value(targetSessions),
          targetMinutes: Value(targetMinutes),
        ),
      );
    } else {
      await (update(weeklyExerciseGoals)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        WeeklyExerciseGoalsCompanion(
          targetSessions: Value(targetSessions),
          targetMinutes: Value(targetMinutes),
        ),
      );
    }
  }

  // ---- 训练 ----

  /// 有效组定义：次数 > 0 或持续时间 > 0
  static bool isValidSet(WorkoutSet s) =>
      (s.reps ?? 0) > 0 || (s.durationSeconds ?? 0) > 0;

  Future<Workout?> getWorkout(int id) =>
      (select(workouts)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 监听当前进行中的训练（全场至多一场）
  Stream<Workout?> watchOngoingWorkout() => (select(workouts)
        ..where((t) => t.status.equalsValue(WorkoutStatus.inProgress))
        ..limit(1))
      .watchSingleOrNull();

  Future<Workout?> getOngoingWorkout() => (select(workouts)
        ..where((t) => t.status.equalsValue(WorkoutStatus.inProgress))
        ..limit(1))
      .getSingleOrNull();

  /// 开始训练；已有进行中训练时直接返回它，不创建第二场（也不关联新方案）。
  /// 传入 [plan] 时把方案快照写入训练，并预添加绑定动作（用户可删除该动作）
  Future<Workout> startWorkout({DateTime? now, ExercisePlan? plan}) async {
    final existing = await getOngoingWorkout();
    if (existing != null) return existing;
    final t = now ?? DateTime.now();
    final id = await into(workouts).insert(
      WorkoutsCompanion(
        date: Value(dateOnly(t)),
        status: const Value(WorkoutStatus.inProgress),
        startedAt: Value(t),
        planId: Value(plan?.id),
        planName: Value(plan?.name),
        planExerciseName: Value(plan?.exerciseName),
        planMetric: Value(plan?.metric),
        planMin: Value(plan?.minThreshold),
        planRegular: Value(plan?.regularThreshold),
      ),
    );
    if (plan != null) {
      await addWorkoutExercise(id,
          name: plan.exerciseName, category: plan.category);
    }
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
        pausedSeconds:
            Value(w.pausedSeconds + t.difference(pausedAt).inSeconds),
        pausedAt: const Value(null),
      ),
    );
  }

  /// 当前已计时的秒数：now - startedAt - 已暂停秒数 - 正在暂停的这一段；
  /// startedAt 为空（补记）时返回 0。权威数据在数据库，UI 只负责显示
  static int elapsedSeconds(Workout w, {DateTime? now}) {
    final startedAt = w.startedAt;
    if (startedAt == null) return 0;
    final t = now ?? DateTime.now();
    var elapsed = t.difference(startedAt).inSeconds - w.pausedSeconds;
    final pausedAt = w.pausedAt;
    if (pausedAt != null) elapsed -= t.difference(pausedAt).inSeconds;
    return elapsed < 0 ? 0 : elapsed;
  }

  /// 该训练是否至少有一条有效组
  Future<bool> hasValidSet(int workoutId) async {
    final query = select(workoutSets).join([
      innerJoin(workoutExercises,
          workoutExercises.id.equalsExp(workoutSets.exerciseId)),
    ])
      ..where(workoutExercises.workoutId.equals(workoutId))
      ..where(workoutSets.reps.isBiggerThanValue(0) |
          workoutSets.durationSeconds.isBiggerThanValue(0))
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
      throw StateError('结束训练至少需要一条有效组（次数或持续时间大于 0）');
    }
    final t = now ?? DateTime.now();
    var total = totalSeconds;
    if (total == null && w.startedAt != null) {
      total = elapsedSeconds(w, now: t);
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
      final exerciseIds = await (selectOnly(workoutExercises)
            ..addColumns([workoutExercises.id])
            ..where(workoutExercises.workoutId.equals(id)))
          .map((row) => row.read(workoutExercises.id)!)
          .get();
      if (exerciseIds.isNotEmpty) {
        await (delete(workoutSets)
              ..where((t) => t.exerciseId.isIn(exerciseIds)))
            .go();
      }
      await (delete(workoutExercises)
            ..where((t) => t.workoutId.equals(id)))
          .go();
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
        date: Value(dateOnly(date)),
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
            ..where((t) =>
                t.status.equalsValue(WorkoutStatus.completed) &
                t.date.equals(dateOnly(date)))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch();

  /// 监听所在周（周一至周日）的已完成训练
  Stream<List<Workout>> watchCompletedWorkoutsInWeek(DateTime date) {
    final start = weekStart(date);
    final end = start.add(const Duration(days: 7));
    return (select(workouts)
          ..where((t) =>
              t.status.equalsValue(WorkoutStatus.completed) &
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch();
  }

  // ---- 动作与组 ----

  Future<int> _nextExerciseOrder(int workoutId) async {
    final maxExpr = workoutExercises.sortOrder.max();
    final row = await (selectOnly(workoutExercises)
          ..addColumns([maxExpr])
          ..where(workoutExercises.workoutId.equals(workoutId)))
        .getSingle();
    return (row.read(maxExpr) ?? -1) + 1;
  }

  Future<int> addWorkoutExercise(
    int workoutId, {
    required String name,
    required ExerciseCategory category,
    String? note,
  }) async {
    return into(workoutExercises).insert(
      WorkoutExercisesCompanion(
        workoutId: Value(workoutId),
        name: Value(name),
        category: Value(category),
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
    final row = await (selectOnly(workoutSets)
          ..addColumns([maxExpr])
          ..where(workoutSets.exerciseId.equals(exerciseId)))
        .getSingle();
    return (row.read(maxExpr) ?? -1) + 1;
  }

  Future<int> addWorkoutSet(
    int exerciseId, {
    int? reps,
    int? durationSeconds,
    double? weightKg,
    String? note,
  }) async {
    return into(workoutSets).insert(
      WorkoutSetsCompanion(
        exerciseId: Value(exerciseId),
        reps: Value(reps),
        durationSeconds: Value(durationSeconds),
        weightKg: Value(weightKg),
        note: Value(note),
        sortOrder: Value(await _nextSetOrder(exerciseId)),
      ),
    );
  }

  /// 编辑组；用 [Value] 语义区分「不修改」与「清空」
  Future<void> updateWorkoutSet(
    int id, {
    Value<int?>? reps,
    Value<int?>? durationSeconds,
    Value<double?>? weightKg,
    Value<String?>? note,
  }) {
    return (update(workoutSets)..where((t) => t.id.equals(id))).write(
      WorkoutSetsCompanion(
        reps: reps ?? const Value.absent(),
        durationSeconds: durationSeconds ?? const Value.absent(),
        weightKg: weightKg ?? const Value.absent(),
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
    final query = select(workoutSets).join([
      innerJoin(workoutExercises,
          workoutExercises.id.equalsExp(workoutSets.exerciseId)),
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
      innerJoin(workoutExercises,
          workoutExercises.id.equalsExp(workoutSets.exerciseId)),
    ])
      ..where(workoutExercises.workoutId.equals(workoutId));
    return query.map((row) => row.readTable(workoutSets)).get();
  }

  // ---- 方案 ----

  /// 校验阈值：最低需大于 0，常规不得低于最低
  static void _validateThresholds(int minThreshold, int regularThreshold) {
    if (minThreshold <= 0) {
      throw ArgumentError.value(minThreshold, 'minThreshold', '最低阈值需大于 0');
    }
    if (regularThreshold < minThreshold) {
      throw ArgumentError.value(
          regularThreshold, 'regularThreshold', '常规阈值不能低于最低阈值');
    }
  }

  Stream<List<ExercisePlan>> watchExercisePlans() => (select(exercisePlans)
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .watch();

  Future<ExercisePlan?> getExercisePlan(int id) =>
      (select(exercisePlans)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 新建方案；duration 指标的阈值存秒，sets 指标存组数
  Future<int> insertExercisePlan({
    required String name,
    required String exerciseName,
    required ExerciseCategory category,
    required PlanMetric metric,
    required int minThreshold,
    required int regularThreshold,
    String? note,
  }) {
    _validateThresholds(minThreshold, regularThreshold);
    return into(exercisePlans).insert(
      ExercisePlansCompanion(
        name: Value(name),
        exerciseName: Value(exerciseName),
        category: Value(category),
        metric: Value(metric),
        minThreshold: Value(minThreshold),
        regularThreshold: Value(regularThreshold),
        note: Value(note),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  /// 编辑方案；只影响之后关联的训练，已关联训练按快照判定不受影响
  Future<void> updateExercisePlan(
    int id, {
    required String name,
    required String exerciseName,
    required ExerciseCategory category,
    required PlanMetric metric,
    required int minThreshold,
    required int regularThreshold,
    String? note,
  }) {
    _validateThresholds(minThreshold, regularThreshold);
    return (update(exercisePlans)..where((t) => t.id.equals(id))).write(
      ExercisePlansCompanion(
        name: Value(name),
        exerciseName: Value(exerciseName),
        category: Value(category),
        metric: Value(metric),
        minThreshold: Value(minThreshold),
        regularThreshold: Value(regularThreshold),
        note: Value(note),
      ),
    );
  }

  /// 删除方案；绝不动任何已有训练（训练靠快照判定）
  Future<int> deleteExercisePlan(int id) =>
      (delete(exercisePlans)..where((t) => t.id.equals(id))).go();

  /// 把方案 id 与判定所需快照写入训练
  Future<void> linkPlanToWorkout(int workoutId, ExercisePlan plan) {
    return (update(workouts)..where((t) => t.id.equals(workoutId))).write(
      WorkoutsCompanion(
        planId: Value(plan.id),
        planName: Value(plan.name),
        planExerciseName: Value(plan.exerciseName),
        planMetric: Value(plan.metric),
        planMin: Value(plan.minThreshold),
        planRegular: Value(plan.regularThreshold),
      ),
    );
  }

  /// 取消关联：planId 与快照列全部清空
  Future<void> clearPlanLink(int workoutId) {
    return (update(workouts)..where((t) => t.id.equals(workoutId))).write(
      const WorkoutsCompanion(
        planId: Value(null),
        planName: Value(null),
        planExerciseName: Value(null),
        planMetric: Value(null),
        planMin: Value(null),
        planRegular: Value(null),
      ),
    );
  }

  /// 按训练上的方案快照实时评估达标档位。
  /// 只累计与快照动作同名的动作：duration 累计有效时长组的秒数，
  /// sets 计有效组数量；无快照返回 [PlanTier.none]
  static PlanEvaluation evaluateWorkout(
    Workout w,
    List<WorkoutExercise> exercises,
    List<WorkoutSet> sets,
  ) {
    final metric = w.planMetric;
    final min = w.planMin;
    final regular = w.planRegular;
    final exerciseName = w.planExerciseName;
    if (metric == null || min == null || regular == null || exerciseName == null) {
      return const PlanEvaluation(PlanTier.none, 0);
    }
    final targetIds = {
      for (final e in exercises)
        if (e.name == exerciseName) e.id,
    };
    var actual = 0;
    for (final s in sets) {
      if (!targetIds.contains(s.exerciseId)) continue;
      if (metric == PlanMetric.duration) {
        final d = s.durationSeconds ?? 0;
        if (d > 0) actual += d;
      } else if (isValidSet(s)) {
        actual += 1;
      }
    }
    final tier = actual >= regular
        ? PlanTier.regular
        : actual >= min
            ? PlanTier.min
            : PlanTier.belowMin;
    return PlanEvaluation(tier, actual);
  }

  // ---- 休息标记 ----

  /// 监听某天的休息标记（dateOnly 归一化）
  Stream<RestMark?> watchRestMark(DateTime date) => (select(restMarks)
        ..where((t) => t.date.equals(dateOnly(date))))
      .watchSingleOrNull();

  /// 标记某天休息（按 date upsert，可改备注）；不增删任何训练数据
  Future<void> setRestMark(DateTime date, {String? note}) {
    final day = dateOnly(date);
    return into(restMarks).insert(
      RestMarksCompanion(date: Value(day), note: Value(note)),
      onConflict: DoUpdate(
        (_) => RestMarksCompanion(note: Value(note)),
        target: [restMarks.date],
      ),
    );
  }

  /// 取消某天的休息标记
  Future<void> removeRestMark(DateTime date) =>
      (delete(restMarks)..where((t) => t.date.equals(dateOnly(date)))).go();

  // ---- 每日状态 ----

  /// 任一源流变化都发出一次事件（监听时立即发一次），供组合查询重算
  static Stream<void> _watchAny(List<Stream<Object?>> sources) {
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
      innerJoin(workoutExercises,
          workoutExercises.id.equalsExp(workoutSets.exerciseId)),
      innerJoin(workouts, workouts.id.equalsExp(workoutExercises.workoutId)),
    ])
      ..where(workouts.date.equals(day));
    return query.map((row) => row.readTable(workoutSets)).watch();
  }

  /// 计算某天的每日状态（当天数据量小，直接按快照逐场评估）
  Future<DailyStatus> computeDailyStatus(DateTime date) async {
    final day = dateOnly(date);
    final plans = await select(exercisePlans).get();
    if (plans.isEmpty) return DailyStatus.noPlan;
    final done = await (select(workouts)
          ..where((t) =>
              t.status.equalsValue(WorkoutStatus.completed) &
              t.date.equals(day)))
        .get();
    if (done.isEmpty) {
      final rest = await (select(restMarks)
            ..where((t) => t.date.equals(day)))
          .getSingleOrNull();
      return rest != null ? DailyStatus.rest : DailyStatus.none;
    }
    // 取当天已完成训练中的最高档：regular > min > recorded
    var hasMin = false;
    for (final w in done) {
      final ev = evaluateWorkout(
          w, await getWorkoutExercises(w.id), await getWorkoutSets(w.id));
      if (ev.tier == PlanTier.regular) return DailyStatus.regularDone;
      if (ev.tier == PlanTier.min) hasMin = true;
    }
    return hasMin ? DailyStatus.minDone : DailyStatus.recorded;
  }

  /// 监听某天的每日状态；方案 / 休息标记 / 当天训练与组任一变化都重算
  Stream<DailyStatus> watchDailyStatus(DateTime date) {
    final day = dateOnly(date);
    return _watchAny([
      watchExercisePlans(),
      watchRestMark(day),
      watchCompletedWorkouts(day),
      _watchSetsForDate(day),
    ]).asyncMap((_) => computeDailyStatus(day));
  }

  /// 当天各方案的达标情况：key 为方案 id，值为当日关联训练的最高档评估；
  /// 当天无关联完成训练的方案不出现在结果中（UI 显示「未开始」）
  Stream<Map<int, PlanEvaluation>> watchDailyPlanEvaluations(DateTime date) {
    final day = dateOnly(date);
    return _watchAny([
      watchExercisePlans(),
      watchCompletedWorkouts(day),
      _watchSetsForDate(day),
    ]).asyncMap((_) async {
      final done = await (select(workouts)
            ..where((t) =>
                t.status.equalsValue(WorkoutStatus.completed) &
                t.date.equals(day)))
          .get();
      final result = <int, PlanEvaluation>{};
      for (final w in done) {
        final planId = w.planId;
        if (planId == null) continue;
        final ev = evaluateWorkout(
            w, await getWorkoutExercises(w.id), await getWorkoutSets(w.id));
        final prev = result[planId];
        if (prev == null || _tierRank(ev.tier) > _tierRank(prev.tier)) {
          result[planId] = ev;
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
