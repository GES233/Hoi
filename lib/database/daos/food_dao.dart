part of '../database.dart';

extension FoodDao on AppDatabase {
  // ---- 饮食 ----

  Stream<List<FoodEntry>> watchFoodEntries(DateTime date) => (select(
    foodEntries,
  )..where((t) => t.date.equals(AppDatabase.dateOnly(date)))).watch();

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
}
