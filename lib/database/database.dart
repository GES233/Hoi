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

@DriftDatabase(tables: [FoodEntries, ExerciseEntries, FavoriteFoods])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  static QueryExecutor _openConnection() => driftDatabase(name: 'hoi_tracker');

  @override
  int get schemaVersion => 1;

  /// 只保留日期部分，保证按天查询的一致性
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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
}
