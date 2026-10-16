import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/rules/metric.dart';
import '../domain/rules/rule_ast.dart';
import '../domain/rules/rule_evaluator.dart';

part 'database.g.dart';
part 'daos/food_dao.dart';
part 'daos/workout_dao.dart';
part 'daos/workout_entry_dao.dart';
part 'daos/exercise_catalog_dao.dart';
part 'daos/template_dao.dart';
part 'daos/rule_dao.dart';
part 'daos/daily_status_dao.dart';
part 'daos/daily_checkin_dao.dart';

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

extension LoadConventionLabel on LoadConvention {
  String get label => switch (this) {
    LoadConvention.none => '无负重',
    LoadConvention.external => '外加负重',
    LoadConvention.assistance => '助力',
    LoadConvention.bodyweight => '自重',
  };
}

/// 次数是总数还是每侧数量
enum RepsConvention { total, perSide }

extension RepsConventionLabel on RepsConvention {
  String get label => switch (this) {
    RepsConvention.total => '双侧/总数',
    RepsConvention.perSide => '单侧',
  };
}

/// 组角色与完成状态使用稳定文本持久化
enum SetRole { warmup, work, cooldown }

extension SetRoleLabel on SetRole {
  String get label => switch (this) {
    SetRole.warmup => '热身组',
    SetRole.work => '工作组',
    SetRole.cooldown => '放松组',
  };
}

enum SetStatus { completed, skipped }

enum RulePeriod { day, week }

enum RuleCombineMode { all, any }

/// 训练状态：进行中 / 已完成
enum WorkoutStatus { inProgress, completed }

/// 模板编辑器使用的输入模式
enum PlanMetric { duration, sets, distance }

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

/// 每日主观状态与自由备注；评分使用 1–5，字段均可单独留空。
class DailyCheckins extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime().unique()();
  IntColumn get sleepRating => integer().nullable()();
  IntColumn get stressRating => integer().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
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
    DailyCheckins,
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
  int get schemaVersion => 6;

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
        return;
      }
      if (from < 5) {
        await m.addColumn(exercises, exercises.builtinKey);
        await m.addColumn(ruleSets, ruleSets.presetKey);
        await m.deleteTable('weekly_exercise_goals');
      }
      if (from < 6) {
        await m.createTable(dailyCheckins);
      }
    },
    beforeOpen: (_) async {
      await _ensureIndexes();
      if (!seedBuiltIns) return;
      await _ensureBuiltInExercises();
      await _ensureDefaultRulePreset();
    },
  );

  Future<void> _ensureIndexes() async {
    final tables =
        (await customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table'",
            ).get())
            .map((row) => row.read<String>('name'))
            .toSet();
    const indexByTable = [
      (
        'workouts',
        'CREATE INDEX IF NOT EXISTS idx_workouts_date_status ON workouts (date, status)',
      ),
      (
        'workouts',
        'CREATE INDEX IF NOT EXISTS idx_workouts_started_at ON workouts (started_at)',
      ),
      (
        'workout_exercises',
        'CREATE INDEX IF NOT EXISTS idx_workout_exercises_workout_id ON workout_exercises (workout_id, sort_order)',
      ),
      (
        'workout_sets',
        'CREATE INDEX IF NOT EXISTS idx_workout_sets_exercise_id ON workout_sets (exercise_id, sort_order)',
      ),
      (
        'food_entries',
        'CREATE INDEX IF NOT EXISTS idx_food_entries_date ON food_entries (date)',
      ),
      (
        'template_exercises',
        'CREATE INDEX IF NOT EXISTS idx_template_exercises_version_id ON template_exercises (template_version_id, sort_order)',
      ),
      (
        'template_sets',
        'CREATE INDEX IF NOT EXISTS idx_template_sets_exercise_id ON template_sets (template_exercise_id, sort_order)',
      ),
    ];
    for (final (table, statement) in indexByTable) {
      if (tables.contains(table)) {
        await customStatement(statement);
      }
    }
  }

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

  /// 有效组定义：已完成，且核心事实大于 0。
  /// 传入 [trackingType] 时优先校验对应口径字段（若该字段已填但 <= 0 则视为无效）。
  static bool isValidSet(WorkoutSet s, {TrackingType? trackingType}) {
    if (s.setStatus != SetStatus.completed) return false;
    final primaryValue = switch (trackingType) {
      TrackingType.reps => s.reps,
      TrackingType.duration => s.durationSeconds,
      TrackingType.distance => s.distanceMeters,
      null => null,
    };
    if (primaryValue != null) return primaryValue > 0;
    return (s.reps ?? 0) > 0 ||
        (s.durationSeconds ?? 0) > 0 ||
        (s.distanceMeters ?? 0) > 0;
  }

  /// 当前已计时的秒数：now - startedAt - 已暂停秒数 - 正在暂停的这一段；
  /// startedAt 为空（异常或旧数据）时返回 0。权威数据在数据库，UI 只负责显示
  static int elapsedSeconds(Workout w, {DateTime? now}) {
    final startedAt = w.startedAt;
    if (startedAt == null) return 0;
    final t = now ?? DateTime.now();
    var elapsed = t.difference(startedAt).inSeconds - w.pausedSeconds;
    final pausedAt = w.pausedAt;
    if (pausedAt != null) elapsed -= t.difference(pausedAt).inSeconds;
    return elapsed < 0 ? 0 : elapsed;
  }
}
