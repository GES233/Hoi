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

/// 饮食记录
class FoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 只存日期部分（本地时间午夜）
  DateTimeColumn get date => dateTime()();
  IntColumn get mealType => intEnum<MealType>()();
  TextColumn get name => text()();
  IntColumn get calories => integer()();
}

/// 运动记录
class ExerciseEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get name => text()();
  IntColumn get durationMinutes => integer()();
  IntColumn get caloriesBurned => integer()();
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

@DriftDatabase(tables: [
  FoodEntries,
  ExerciseEntries,
  FavoriteFoods,
  WeeklyExerciseGoals,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  static QueryExecutor _openConnection() => driftDatabase(name: 'hoi_tracker');

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(weeklyExerciseGoals);
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

  Stream<List<FoodEntry>> watchFoodEntries(DateTime date) =>
      (select(foodEntries)..where((t) => t.date.equals(dateOnly(date))))
          .watch();

  Stream<List<ExerciseEntry>> watchExerciseEntries(DateTime date) =>
      (select(exerciseEntries)..where((t) => t.date.equals(dateOnly(date))))
          .watch();

  Future<int> insertFoodEntry(FoodEntriesCompanion entry) =>
      into(foodEntries).insert(entry);

  Future<int> insertExerciseEntry(ExerciseEntriesCompanion entry) =>
      into(exerciseEntries).insert(entry);

  Future<int> deleteFoodEntry(int id) =>
      (delete(foodEntries)..where((t) => t.id.equals(id))).go();

  Future<int> deleteExerciseEntry(int id) =>
      (delete(exerciseEntries)..where((t) => t.id.equals(id))).go();

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

  /// 监听所在周（周一至周日）的全部运动记录
  Stream<List<ExerciseEntry>> watchExerciseEntriesInWeek(DateTime date) {
    final start = weekStart(date);
    final end = start.add(const Duration(days: 7));
    return (select(exerciseEntries)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end)))
        .watch();
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
}
