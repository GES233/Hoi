import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/rules/metric.dart';
import '../domain/rules/rule_ast.dart';
import '../domain/rules/rule_evaluator.dart';

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

/// 动作的核心记录口径；决定有效组读取哪个事实字段
enum TrackingType { reps, duration, distance }

extension TrackingTypeLabel on TrackingType {
  String get label => switch (this) {
    TrackingType.reps => '次数',
    TrackingType.duration => '时长',
    TrackingType.distance => '距离',
  };
}

/// 负重记录口径
enum LoadConvention { none, external, assistance, bodyweight }

/// 次数是总数还是每侧数量
enum RepsConvention { total, perSide }

/// 组角色与完成状态使用稳定文本持久化
enum SetRole { warmup, work, cooldown }

enum SetStatus { completed, skipped }

enum RulePeriod { day, week }

enum RuleCombineMode { all, any }

/// 训练状态：进行中 / 已完成
enum WorkoutStatus { inProgress, completed }

/// 单动作模板快捷编辑器使用的输入模式
enum PlanMetric { duration, sets }

/// 单次训练按模板版本评估出的达标档位；none 表示未关联模板
enum PlanTier { none, belowMin, min, regular }

/// 模板列表项：模板身份与当前不可变版本
class WorkoutTemplateSummary {
  const WorkoutTemplateSummary(this.template, this.version);

  final WorkoutTemplate template;
  final TemplateVersion version;
}

/// 一个模板版本的完整定义
class WorkoutTemplateDefinition {
  const WorkoutTemplateDefinition({
    required this.template,
    required this.version,
    required this.exercises,
    required this.sets,
  });

  final WorkoutTemplate template;
  final TemplateVersion version;
  final List<TemplateExercise> exercises;
  final List<TemplateSet> sets;
}

/// 创建模板版本时使用的组输入
class TemplateSetInput {
  const TemplateSetInput({
    this.role = SetRole.work,
    this.reps,
    this.minimumReps,
    this.durationSeconds,
    this.minimumDurationSeconds,
    this.distanceMeters,
    this.minimumDistanceMeters,
    this.externalLoadKg,
    this.assistanceKg,
    this.rpe,
    this.rir,
  });

  final SetRole role;
  final int? reps;
  final int? minimumReps;
  final int? durationSeconds;
  final int? minimumDurationSeconds;
  final double? distanceMeters;
  final double? minimumDistanceMeters;
  final double? externalLoadKg;
  final double? assistanceKg;
  final double? rpe;
  final double? rir;
}

/// 创建模板版本时使用的动作输入
class TemplateExerciseInput {
  const TemplateExerciseInput({
    required this.exerciseId,
    required this.sets,
    this.note,
  });

  final int exerciseId;
  final List<TemplateSetInput> sets;
  final String? note;
}

/// 单次训练相对模板版本的实时完成度
class TemplateProgress {
  const TemplateProgress({
    required this.tier,
    required this.minimumCompleted,
    required this.minimumTotal,
    required this.regularCompleted,
    required this.regularTotal,
  });

  final PlanTier tier;
  final int minimumCompleted;
  final int minimumTotal;
  final int regularCompleted;
  final int regularTotal;
}

class RuleSetProgress {
  const RuleSetProgress(this.ruleSet, this.evaluation);

  final RuleSet ruleSet;
  final RuleEvaluation evaluation;
}

class BuiltInExercisePreset {
  const BuiltInExercisePreset({
    required this.key,
    required this.name,
    required this.category,
    required this.trackingType,
    this.loadConvention = LoadConvention.none,
    this.repsConvention = RepsConvention.total,
  });

  final String key;
  final String name;
  final ExerciseCategory category;
  final TrackingType trackingType;
  final LoadConvention loadConvention;
  final RepsConvention repsConvention;
}

class RuleSetPreset {
  const RuleSetPreset({
    required this.key,
    required this.name,
    required this.description,
    required this.period,
    required this.combineMode,
  });

  final String key;
  final String name;
  final String description;
  final RulePeriod period;
  final RuleCombineMode combineMode;

  RuleNode buildExpression() => switch (key) {
    'weekly_consistency' => AllRule(const [
      ComparisonRule(
        metricId: 'session_count',
        operator: ComparisonOperator.greaterOrEqual,
        target: 3,
      ),
      ComparisonRule(
        metricId: 'session_duration',
        operator: ComparisonOperator.greaterOrEqual,
        target: 90 * 60,
      ),
    ]),
    _ => throw StateError('未知周期目标预设：$key'),
  };
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

/// 可归档的动作目录；历史引用永不随归档删除
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get builtinKey => text().nullable()();
  TextColumn get name => text()();
  TextColumn get category => textEnum<ExerciseCategory>()();
  TextColumn get trackingType => textEnum<TrackingType>()();
  TextColumn get loadConvention => textEnum<LoadConvention>()();
  TextColumn get repsConvention => textEnum<RepsConvention>()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// 模板身份；内容只存在不可变版本中
class WorkoutTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get currentVersionNumber => integer()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class TemplateVersions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().references(WorkoutTemplates, #id)();
  IntColumn get versionNumber => integer()();
  TextColumn get name => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {templateId, versionNumber},
  ];
}

class TemplateExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateVersionId =>
      integer().references(TemplateVersions, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  TextColumn get exerciseNameSnapshot => text()();
  TextColumn get categorySnapshot => textEnum<ExerciseCategory>()();
  TextColumn get trackingTypeSnapshot => textEnum<TrackingType>()();
  TextColumn get loadConventionSnapshot => textEnum<LoadConvention>()();
  TextColumn get repsConventionSnapshot => textEnum<RepsConvention>()();
  TextColumn get note => text().nullable()();
  IntColumn get sortOrder => integer()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {templateVersionId, sortOrder},
  ];
}

class TemplateSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateExerciseId =>
      integer().references(TemplateExercises, #id)();
  TextColumn get setRole => textEnum<SetRole>()();
  IntColumn get reps => integer().nullable()();
  IntColumn get minimumReps => integer().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  IntColumn get minimumDurationSeconds => integer().nullable()();
  RealColumn get distanceMeters => real().nullable()();
  RealColumn get minimumDistanceMeters => real().nullable()();
  RealColumn get externalLoadKg => real().nullable()();
  RealColumn get assistanceKg => real().nullable()();
  RealColumn get rpe => real().nullable()();
  RealColumn get rir => real().nullable()();
  IntColumn get sortOrder => integer()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {templateExerciseId, sortOrder},
  ];
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

  IntColumn get templateVersionId =>
      integer().nullable().references(TemplateVersions, #id)();
  TextColumn get templateNameSnapshot => text().nullable()();
  IntColumn get templateEvaluationPolicyVersion => integer().nullable()();
}

/// 训练中的一个动作
class WorkoutExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId =>
      integer().references(Workouts, #id, onDelete: KeyAction.cascade)();
  IntColumn get catalogExerciseId =>
      integer().nullable().references(Exercises, #id)();
  TextColumn get name => text().named('exercise_name_snapshot')();
  TextColumn get category =>
      textEnum<ExerciseCategory>().named('category_snapshot')();
  TextColumn get trackingTypeSnapshot => textEnum<TrackingType>()();
  TextColumn get loadConventionSnapshot => textEnum<LoadConvention>()();
  TextColumn get repsConventionSnapshot => textEnum<RepsConvention>()();
  IntColumn get templateExerciseId =>
      integer().nullable().references(TemplateExercises, #id)();
  TextColumn get note => text().nullable()();
  IntColumn get sortOrder => integer()();
}

/// 一组动作记录；核心事实由动作 tracking type 决定
class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId => integer().references(
    WorkoutExercises,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get templateSetId =>
      integer().nullable().references(TemplateSets, #id)();
  TextColumn get setRole => textEnum<SetRole>()();
  TextColumn get setStatus => textEnum<SetStatus>()();
  IntColumn get reps => integer().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  RealColumn get distanceMeters => real().nullable()();
  RealColumn get weightKg => real().named('external_load_kg').nullable()();
  RealColumn get assistanceKg => real().nullable()();
  RealColumn get rpe => real().nullable()();
  RealColumn get rir => real().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get sortOrder => integer()();
}

/// 休息标记（阶段 2 使用）
class RestMarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime().unique()();
  TextColumn get note => text().nullable()();
}

/// 日／周周期目标；表达式使用受控 Rule AST JSON，不执行任意代码。
class RuleSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get presetKey => text().nullable()();
  TextColumn get name => text()();
  TextColumn get period => textEnum<RulePeriod>()();
  DateTimeColumn get effectiveFromDate => dateTime()();
  DateTimeColumn get effectiveUntilDate => dateTime().nullable()();
  TextColumn get combineMode => textEnum<RuleCombineMode>()();
  TextColumn get expressionJson => text()();
  IntColumn get evaluationPolicyVersion => integer()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(
  tables: [
    FoodEntries,
    FavoriteFoods,
    Exercises,
    WorkoutTemplates,
    TemplateVersions,
    TemplateExercises,
    TemplateSets,
    Workouts,
    WorkoutExercises,
    WorkoutSets,
    RestMarks,
    RuleSets,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : seedBuiltIns = true,
      super(executor ?? _openConnection());

  AppDatabase.withOptions({QueryExecutor? executor, this.seedBuiltIns = true})
    : super(executor ?? _openConnection());

  final bool seedBuiltIns;

  static QueryExecutor _openConnection() => driftDatabase(name: 'hoi_tracker');

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 4) {
        // 发布前开发数据经确认可重置；v4 从稳定身份与模板版本重新开始。
        for (final table in const [
          'workout_sets',
          'workout_exercises',
          'workouts',
          'exercise_plans',
          'rest_marks',
          'weekly_exercise_goals',
          'favorite_foods',
          'food_entries',
        ]) {
          await m.deleteTable(table);
        }
        await m.createAll();
      } else if (from < 5) {
        await m.addColumn(exercises, exercises.builtinKey);
        await m.addColumn(ruleSets, ruleSets.presetKey);
        await m.deleteTable('weekly_exercise_goals');
      }
    },
    beforeOpen: (_) async {
      if (!seedBuiltIns) return;
      await _ensureBuiltInExercises();
      await _ensureDefaultRulePreset();
    },
  );

  /// 只保留日期部分，保证按天查询的一致性
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 所在周的周一（周一为一周起点）
  static DateTime weekStart(DateTime d) {
    final day = dateOnly(d);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static const builtInExercisePresets = [
    BuiltInExercisePreset(
      key: 'walking',
      name: '步行',
      category: ExerciseCategory.cardio,
      trackingType: TrackingType.duration,
    ),
    BuiltInExercisePreset(
      key: 'running',
      name: '跑步',
      category: ExerciseCategory.cardio,
      trackingType: TrackingType.distance,
    ),
    BuiltInExercisePreset(
      key: 'cycling',
      name: '骑行',
      category: ExerciseCategory.cardio,
      trackingType: TrackingType.distance,
    ),
    BuiltInExercisePreset(
      key: 'jump_rope',
      name: '跳绳',
      category: ExerciseCategory.cardio,
      trackingType: TrackingType.duration,
    ),
    BuiltInExercisePreset(
      key: 'push_up',
      name: '俯卧撑',
      category: ExerciseCategory.resistance,
      trackingType: TrackingType.reps,
      loadConvention: LoadConvention.bodyweight,
    ),
    BuiltInExercisePreset(
      key: 'bodyweight_squat',
      name: '自重深蹲',
      category: ExerciseCategory.resistance,
      trackingType: TrackingType.reps,
      loadConvention: LoadConvention.bodyweight,
    ),
    BuiltInExercisePreset(
      key: 'lunge',
      name: '弓步',
      category: ExerciseCategory.resistance,
      trackingType: TrackingType.reps,
      loadConvention: LoadConvention.bodyweight,
      repsConvention: RepsConvention.perSide,
    ),
    BuiltInExercisePreset(
      key: 'pull_up',
      name: '引体向上',
      category: ExerciseCategory.resistance,
      trackingType: TrackingType.reps,
      loadConvention: LoadConvention.bodyweight,
    ),
    BuiltInExercisePreset(
      key: 'plank',
      name: '平板支撑',
      category: ExerciseCategory.core,
      trackingType: TrackingType.duration,
      loadConvention: LoadConvention.bodyweight,
    ),
    BuiltInExercisePreset(
      key: 'dead_hang',
      name: '悬垂',
      category: ExerciseCategory.functional,
      trackingType: TrackingType.duration,
      loadConvention: LoadConvention.bodyweight,
    ),
    BuiltInExercisePreset(
      key: 'bench_press',
      name: '卧推',
      category: ExerciseCategory.resistance,
      trackingType: TrackingType.reps,
      loadConvention: LoadConvention.external,
    ),
    BuiltInExercisePreset(
      key: 'dumbbell_row',
      name: '哑铃划船',
      category: ExerciseCategory.resistance,
      trackingType: TrackingType.reps,
      loadConvention: LoadConvention.external,
      repsConvention: RepsConvention.perSide,
    ),
  ];

  static const ruleSetPresets = [
    RuleSetPreset(
      key: 'weekly_consistency',
      name: '每周基础运动',
      description: '每周至少训练 3 次，并累计记录 90 分钟训练用时',
      period: RulePeriod.week,
      combineMode: RuleCombineMode.all,
    ),
  ];

  Future<void> _ensureBuiltInExercises() async {
    final existing = await (select(
      exercises,
    )..where((exercise) => exercise.builtinKey.isNotNull())).get();
    final keys = existing.map((exercise) => exercise.builtinKey).toSet();
    for (final preset in builtInExercisePresets) {
      if (keys.contains(preset.key)) continue;
      await insertExercise(
        builtinKey: preset.key,
        name: preset.name,
        category: preset.category,
        trackingType: preset.trackingType,
        loadConvention: preset.loadConvention,
        repsConvention: preset.repsConvention,
      );
    }
  }

  Future<void> _ensureDefaultRulePreset() async {
    final preset = ruleSetPresets.first;
    final existing =
        await (select(ruleSets)
              ..where((rule) => rule.presetKey.equals(preset.key))
              ..limit(1))
            .getSingleOrNull();
    if (existing == null) {
      await activateRuleSetPreset(
        preset.key,
        effectiveFromDate: DateTime(2000),
      );
    }
  }

  // ---- 饮食 ----

  Stream<List<FoodEntry>> watchFoodEntries(DateTime date) => (select(
    foodEntries,
  )..where((t) => t.date.equals(dateOnly(date)))).watch();

  Future<int> insertFoodEntry(FoodEntriesCompanion entry) =>
      into(foodEntries).insert(entry);

  Future<int> deleteFoodEntry(int id) =>
      (delete(foodEntries)..where((t) => t.id.equals(id))).go();

  Stream<List<FavoriteFood>> watchFavoriteFoods() => (select(
    favoriteFoods,
  )..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

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

  // ---- 训练 ----

  /// 有效组定义：已完成，且至少一种核心事实大于 0
  static bool isValidSet(WorkoutSet s) =>
      s.setStatus == SetStatus.completed &&
      ((s.reps ?? 0) > 0 ||
          (s.durationSeconds ?? 0) > 0 ||
          (s.distanceMeters ?? 0) > 0);

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
          date: Value(dateOnly(t)),
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
            ..where(
              (t) =>
                  t.status.equalsValue(WorkoutStatus.completed) &
                  t.date.equals(dateOnly(date)),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch();

  /// 监听所在周（周一至周日）的已完成训练
  Stream<List<Workout>> watchCompletedWorkoutsInWeek(DateTime date) {
    final start = weekStart(date);
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
    final start = dateOnly(periodStart);
    final end = dateOnly(periodEndExclusive);
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

  // ---- 训练模板 ----

  Stream<List<WorkoutTemplateSummary>> watchWorkoutTemplates({
    bool includeArchived = false,
  }) {
    final query =
        select(workoutTemplates).join([
            innerJoin(
              templateVersions,
              templateVersions.templateId.equalsExp(workoutTemplates.id) &
                  templateVersions.versionNumber.equalsExp(
                    workoutTemplates.currentVersionNumber,
                  ),
            ),
          ])
          ..where(
            includeArchived
                ? const Constant(true)
                : workoutTemplates.archivedAt.isNull(),
          )
          ..orderBy([OrderingTerm.asc(workoutTemplates.createdAt)]);
    return query
        .map(
          (row) => WorkoutTemplateSummary(
            row.readTable(workoutTemplates),
            row.readTable(templateVersions),
          ),
        )
        .watch();
  }

  Future<TemplateVersion?> getTemplateVersion(int id) => (select(
    templateVersions,
  )..where((v) => v.id.equals(id))).getSingleOrNull();

  Future<WorkoutTemplateDefinition?> getTemplateDefinition(
    int templateId,
  ) async {
    final template = await (select(
      workoutTemplates,
    )..where((t) => t.id.equals(templateId))).getSingleOrNull();
    if (template == null) return null;
    final version =
        await (select(templateVersions)..where(
              (v) =>
                  v.templateId.equals(templateId) &
                  v.versionNumber.equals(template.currentVersionNumber),
            ))
            .getSingle();
    return _getTemplateDefinition(template, version);
  }

  Future<WorkoutTemplateDefinition?> getTemplateDefinitionByVersion(
    int versionId,
  ) async {
    final version = await getTemplateVersion(versionId);
    if (version == null) return null;
    final template = await (select(
      workoutTemplates,
    )..where((t) => t.id.equals(version.templateId))).getSingle();
    return _getTemplateDefinition(template, version);
  }

  Future<WorkoutTemplateDefinition> _getTemplateDefinition(
    WorkoutTemplate template,
    TemplateVersion version,
  ) async {
    final plannedExercises =
        await (select(templateExercises)
              ..where((e) => e.templateVersionId.equals(version.id))
              ..orderBy([(e) => OrderingTerm.asc(e.sortOrder)]))
            .get();
    final ids = plannedExercises.map((e) => e.id).toList();
    final plannedSets = ids.isEmpty
        ? <TemplateSet>[]
        : await (select(templateSets)
                ..where((s) => s.templateExerciseId.isIn(ids))
                ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
              .get();
    return WorkoutTemplateDefinition(
      template: template,
      version: version,
      exercises: plannedExercises,
      sets: plannedSets,
    );
  }

  Future<int> createWorkoutTemplate({
    required String name,
    required List<TemplateExerciseInput> exercises,
    String? note,
    DateTime? now,
  }) async {
    _validateTemplate(name, exercises);
    final t = now ?? DateTime.now();
    return transaction(() async {
      final templateId = await into(workoutTemplates).insert(
        WorkoutTemplatesCompanion.insert(currentVersionNumber: 1, createdAt: t),
      );
      await _insertTemplateVersion(
        templateId: templateId,
        versionNumber: 1,
        name: name.trim(),
        note: note,
        inputs: exercises,
        createdAt: t,
      );
      return templateId;
    });
  }

  Future<void> reviseWorkoutTemplate(
    int templateId, {
    required String name,
    required List<TemplateExerciseInput> exercises,
    String? note,
    DateTime? now,
  }) async {
    _validateTemplate(name, exercises);
    final template = await (select(
      workoutTemplates,
    )..where((t) => t.id.equals(templateId))).getSingle();
    final next = template.currentVersionNumber + 1;
    await transaction(() async {
      await _insertTemplateVersion(
        templateId: templateId,
        versionNumber: next,
        name: name.trim(),
        note: note,
        inputs: exercises,
        createdAt: now ?? DateTime.now(),
      );
      await (update(workoutTemplates)..where((t) => t.id.equals(templateId)))
          .write(WorkoutTemplatesCompanion(currentVersionNumber: Value(next)));
    });
  }

  static void _validateTemplate(
    String name,
    List<TemplateExerciseInput> inputs,
  ) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', '模板名称不能为空');
    }
    if (inputs.isEmpty) {
      throw ArgumentError.value(inputs, 'exercises', '模板至少需要一个动作');
    }
    if (inputs.any((e) => e.sets.isEmpty)) {
      throw ArgumentError.value(inputs, 'exercises', '每个模板动作至少需要一个计划组');
    }
  }

  Future<void> _insertTemplateVersion({
    required int templateId,
    required int versionNumber,
    required String name,
    required String? note,
    required List<TemplateExerciseInput> inputs,
    required DateTime createdAt,
  }) async {
    final versionId = await into(templateVersions).insert(
      TemplateVersionsCompanion.insert(
        templateId: templateId,
        versionNumber: versionNumber,
        name: name,
        note: Value(note),
        createdAt: createdAt,
      ),
    );
    for (
      var exerciseOrder = 0;
      exerciseOrder < inputs.length;
      exerciseOrder++
    ) {
      final input = inputs[exerciseOrder];
      final catalog = await getExercise(input.exerciseId);
      if (catalog == null || catalog.archivedAt != null) {
        throw StateError('模板动作不存在或已归档：${input.exerciseId}');
      }
      _validateTemplateSets(catalog.trackingType, input.sets);
      final templateExerciseId = await into(templateExercises).insert(
        TemplateExercisesCompanion.insert(
          templateVersionId: versionId,
          exerciseId: catalog.id,
          exerciseNameSnapshot: catalog.name,
          categorySnapshot: catalog.category,
          trackingTypeSnapshot: catalog.trackingType,
          loadConventionSnapshot: catalog.loadConvention,
          repsConventionSnapshot: catalog.repsConvention,
          note: Value(input.note),
          sortOrder: exerciseOrder,
        ),
      );
      for (var setOrder = 0; setOrder < input.sets.length; setOrder++) {
        final set = input.sets[setOrder];
        await into(templateSets).insert(
          TemplateSetsCompanion.insert(
            templateExerciseId: templateExerciseId,
            setRole: set.role,
            reps: Value(set.reps),
            minimumReps: Value(set.minimumReps),
            durationSeconds: Value(set.durationSeconds),
            minimumDurationSeconds: Value(set.minimumDurationSeconds),
            distanceMeters: Value(set.distanceMeters),
            minimumDistanceMeters: Value(set.minimumDistanceMeters),
            externalLoadKg: Value(set.externalLoadKg),
            assistanceKg: Value(set.assistanceKg),
            rpe: Value(set.rpe),
            rir: Value(set.rir),
            sortOrder: setOrder,
          ),
        );
      }
    }
  }

  static void _validateTemplateSets(
    TrackingType trackingType,
    List<TemplateSetInput> sets,
  ) {
    for (final set in sets) {
      final (num? target, num? minimum) = switch (trackingType) {
        TrackingType.reps => (set.reps, set.minimumReps),
        TrackingType.duration => (
          set.durationSeconds,
          set.minimumDurationSeconds,
        ),
        TrackingType.distance => (
          set.distanceMeters,
          set.minimumDistanceMeters,
        ),
      };
      if (target == null || target <= 0) {
        throw ArgumentError('计划组的${trackingType.label}目标需大于 0');
      }
      if (minimum != null && (minimum <= 0 || minimum > target)) {
        throw ArgumentError('最低${trackingType.label}需大于 0 且不高于常规目标');
      }
    }
  }

  Future<void> archiveWorkoutTemplate(int id, {DateTime? now}) =>
      (update(workoutTemplates)..where((t) => t.id.equals(id))).write(
        WorkoutTemplatesCompanion(archivedAt: Value(now ?? DateTime.now())),
      );

  Future<void> linkTemplateToWorkout(
    int workoutId,
    TemplateVersion version,
  ) async {
    await (update(workouts)..where((w) => w.id.equals(workoutId))).write(
      WorkoutsCompanion(
        templateVersionId: Value(version.id),
        templateNameSnapshot: Value(version.name),
        templateEvaluationPolicyVersion: const Value(1),
      ),
    );
  }

  Future<void> clearTemplateLink(int workoutId) =>
      (update(workouts)..where((w) => w.id.equals(workoutId))).write(
        const WorkoutsCompanion(
          templateVersionId: Value(null),
          templateNameSnapshot: Value(null),
          templateEvaluationPolicyVersion: Value(null),
        ),
      );

  Future<TemplateProgress> evaluateWorkoutTemplate(int workoutId) async {
    final workout = await getWorkout(workoutId);
    final versionId = workout?.templateVersionId;
    if (workout == null || versionId == null) {
      return const TemplateProgress(
        tier: PlanTier.none,
        minimumCompleted: 0,
        minimumTotal: 0,
        regularCompleted: 0,
        regularTotal: 0,
      );
    }
    final policyVersion = workout.templateEvaluationPolicyVersion ?? 1;
    if (policyVersion != 1) {
      throw StateError('不支持的模板评估策略版本：$policyVersion');
    }
    final definition = await getTemplateDefinitionByVersion(versionId);
    if (definition == null) {
      return const TemplateProgress(
        tier: PlanTier.none,
        minimumCompleted: 0,
        minimumTotal: 0,
        regularCompleted: 0,
        regularTotal: 0,
      );
    }
    final actualSets = await getWorkoutSets(workoutId);
    var minimumCompleted = 0;
    var minimumTotal = 0;
    var regularCompleted = 0;
    for (final planned in definition.sets) {
      final candidates = actualSets.where(
        (actual) => actual.templateSetId == planned.id && isValidSet(actual),
      );
      if (candidates.any((actual) => _meetsTarget(actual, planned))) {
        regularCompleted++;
      }
      if (_hasMinimumTarget(planned)) {
        minimumTotal++;
        if (candidates.any((actual) => _meetsMinimum(actual, planned))) {
          minimumCompleted++;
        }
      }
    }
    final regularTotal = definition.sets.length;
    final tier = regularTotal > 0 && regularCompleted == regularTotal
        ? PlanTier.regular
        : minimumTotal > 0 && minimumCompleted == minimumTotal
        ? PlanTier.min
        : PlanTier.belowMin;
    return TemplateProgress(
      tier: tier,
      minimumCompleted: minimumCompleted,
      minimumTotal: minimumTotal,
      regularCompleted: regularCompleted,
      regularTotal: regularTotal,
    );
  }

  static bool _hasMinimumTarget(TemplateSet planned) =>
      planned.minimumReps != null ||
      planned.minimumDurationSeconds != null ||
      planned.minimumDistanceMeters != null;

  static bool _meetsTarget(WorkoutSet actual, TemplateSet planned) =>
      (planned.reps != null && (actual.reps ?? 0) >= planned.reps!) ||
      (planned.durationSeconds != null &&
          (actual.durationSeconds ?? 0) >= planned.durationSeconds!) ||
      (planned.distanceMeters != null &&
          (actual.distanceMeters ?? 0) >= planned.distanceMeters!);

  static bool _meetsMinimum(WorkoutSet actual, TemplateSet planned) =>
      (planned.minimumReps != null &&
          (actual.reps ?? 0) >= planned.minimumReps!) ||
      (planned.minimumDurationSeconds != null &&
          (actual.durationSeconds ?? 0) >= planned.minimumDurationSeconds!) ||
      (planned.minimumDistanceMeters != null &&
          (actual.distanceMeters ?? 0) >= planned.minimumDistanceMeters!);

  // ---- 休息标记 ----

  /// 监听某天的休息标记（dateOnly 归一化）
  Stream<RestMark?> watchRestMark(DateTime date) => (select(
    restMarks,
  )..where((t) => t.date.equals(dateOnly(date)))).watchSingleOrNull();

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

  // ---- 周期目标规则 ----

  Stream<List<RuleSet>> watchRuleSets({bool includeArchived = false}) =>
      (select(ruleSets)
            ..where(
              (rule) => includeArchived
                  ? const Constant(true)
                  : rule.archivedAt.isNull(),
            )
            ..orderBy([(rule) => OrderingTerm.asc(rule.createdAt)]))
          .watch();

  Future<RuleSet?> getRuleSet(int id) =>
      (select(ruleSets)..where((rule) => rule.id.equals(id))).getSingleOrNull();

  Future<int> createRuleSet({
    String? presetKey,
    required String name,
    required RulePeriod period,
    required DateTime effectiveFromDate,
    DateTime? effectiveUntilDate,
    required RuleCombineMode combineMode,
    required RuleNode expression,
    int evaluationPolicyVersion = 1,
    DateTime? now,
  }) {
    _validateRuleSet(
      name,
      effectiveFromDate,
      effectiveUntilDate,
      combineMode,
      expression,
      evaluationPolicyVersion,
    );
    return into(ruleSets).insert(
      RuleSetsCompanion.insert(
        presetKey: Value(presetKey),
        name: name.trim(),
        period: period,
        effectiveFromDate: dateOnly(effectiveFromDate),
        effectiveUntilDate: Value(
          effectiveUntilDate == null ? null : dateOnly(effectiveUntilDate),
        ),
        combineMode: combineMode,
        expressionJson: jsonEncode(expression.toJson()),
        evaluationPolicyVersion: evaluationPolicyVersion,
        createdAt: now ?? DateTime.now(),
      ),
    );
  }

  Future<void> updateRuleSetDefinition(
    int id, {
    required String name,
    required RulePeriod period,
    required DateTime effectiveFromDate,
    DateTime? effectiveUntilDate,
    required RuleCombineMode combineMode,
    required RuleNode expression,
    int evaluationPolicyVersion = 1,
  }) {
    _validateRuleSet(
      name,
      effectiveFromDate,
      effectiveUntilDate,
      combineMode,
      expression,
      evaluationPolicyVersion,
    );
    return (update(ruleSets)..where((rule) => rule.id.equals(id))).write(
      RuleSetsCompanion(
        name: Value(name.trim()),
        period: Value(period),
        effectiveFromDate: Value(dateOnly(effectiveFromDate)),
        effectiveUntilDate: Value(
          effectiveUntilDate == null ? null : dateOnly(effectiveUntilDate),
        ),
        combineMode: Value(combineMode),
        expressionJson: Value(jsonEncode(expression.toJson())),
        evaluationPolicyVersion: Value(evaluationPolicyVersion),
      ),
    );
  }

  Future<void> archiveRuleSet(int id, {DateTime? now}) =>
      (update(ruleSets)..where((rule) => rule.id.equals(id))).write(
        RuleSetsCompanion(archivedAt: Value(now ?? DateTime.now())),
      );

  Future<int> activateRuleSetPreset(
    String key, {
    DateTime? effectiveFromDate,
    DateTime? now,
  }) async {
    final matches = ruleSetPresets.where((item) => item.key == key);
    if (matches.isEmpty) throw ArgumentError.value(key, 'key', '未知周期目标预设');
    final preset = matches.first;
    final active =
        await (select(ruleSets)..where(
              (rule) => rule.presetKey.equals(key) & rule.archivedAt.isNull(),
            ))
            .getSingleOrNull();
    if (active != null) return active.id;
    return createRuleSet(
      presetKey: key,
      name: preset.name,
      period: preset.period,
      effectiveFromDate: effectiveFromDate ?? dateOnly(now ?? DateTime.now()),
      combineMode: preset.combineMode,
      expression: preset.buildExpression(),
      now: now,
    );
  }

  RuleNode decodeRuleExpression(RuleSet ruleSet) => RuleNode.fromJson(
    Map<String, Object?>.from(jsonDecode(ruleSet.expressionJson) as Map),
  );

  static void _validateRuleSet(
    String name,
    DateTime effectiveFromDate,
    DateTime? effectiveUntilDate,
    RuleCombineMode combineMode,
    RuleNode expression,
    int policyVersion,
  ) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', '目标名称不能为空');
    }
    if (effectiveUntilDate != null &&
        dateOnly(effectiveUntilDate).isBefore(dateOnly(effectiveFromDate))) {
      throw ArgumentError('结束日期不能早于开始日期');
    }
    if (policyVersion != 1) {
      throw ArgumentError('当前只支持评估策略版本 1');
    }
    if ((combineMode == RuleCombineMode.all && expression is! AllRule) ||
        (combineMode == RuleCombineMode.any && expression is! AnyRule)) {
      throw ArgumentError('组合模式与表达式根节点不一致');
    }
    void validateNode(RuleNode node) {
      switch (node) {
        case ComparisonRule comparison:
          MetricRegistry.builtIn().definition(
            comparison.metricId,
            comparison.metricVersion,
          );
          if (!comparison.target.isFinite) {
            throw ArgumentError('目标值必须是有限数字');
          }
        case AllRule all:
          for (final child in all.children) {
            validateNode(child);
          }
        case AnyRule any:
          for (final child in any.children) {
            validateNode(child);
          }
      }
    }

    validateNode(expression);
  }

  Future<List<RuleSetProgress>> evaluateRuleSets(DateTime date) async {
    final day = dateOnly(date);
    final active =
        await (select(ruleSets)
              ..where(
                (rule) =>
                    rule.archivedAt.isNull() &
                    rule.effectiveFromDate.isSmallerOrEqualValue(day) &
                    (rule.effectiveUntilDate.isNull() |
                        rule.effectiveUntilDate.isBiggerOrEqualValue(day)),
              )
              ..orderBy([(rule) => OrderingTerm.asc(rule.createdAt)]))
            .get();
    final contexts = <RulePeriod, MetricContext>{};
    final results = <RuleSetProgress>[];
    for (final ruleSet in active) {
      final context = contexts[ruleSet.period] ??=
          await _metricContextForPeriod(day, ruleSet.period);
      final evaluator = RuleEvaluator(
        metrics: MetricRegistry.builtIn(),
        policyVersion: ruleSet.evaluationPolicyVersion,
      );
      results.add(
        RuleSetProgress(
          ruleSet,
          evaluator.evaluate(decodeRuleExpression(ruleSet), context),
        ),
      );
    }
    return results;
  }

  Future<MetricContext> _metricContextForPeriod(
    DateTime day,
    RulePeriod period,
  ) {
    final start = period == RulePeriod.day ? day : weekStart(day);
    final end = start.add(Duration(days: period == RulePeriod.day ? 1 : 7));
    return buildMetricContext(periodStart: start, periodEndExclusive: end);
  }

  Stream<List<RuleSetProgress>> watchRuleSetProgress(DateTime date) =>
      _watchAny([
        watchRuleSets(),
        select(workouts).watch(),
        select(workoutExercises).watch(),
        select(workoutSets).watch(),
      ]).asyncMap((_) => evaluateRuleSets(date));

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
    final day = dateOnly(date);
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
    final day = dateOnly(date);
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
    final start = weekStart(date);
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
    final day = dateOnly(date);
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
