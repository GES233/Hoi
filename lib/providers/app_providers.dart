import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// 当前选中的日期（只含日期部分），默认今天
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => AppDatabase.dateOnly(DateTime.now());

  /// 按天数前后移动选中日期
  void shift(int days) =>
      state = AppDatabase.dateOnly(state.add(Duration(days: days)));
}

final selectedDateProvider =
    NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);

final foodEntriesProvider = StreamProvider.autoDispose<List<FoodEntry>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(databaseProvider).watchFoodEntries(date);
});

final exerciseEntriesProvider =
    StreamProvider.autoDispose<List<ExerciseEntry>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(databaseProvider).watchExerciseEntries(date);
});

final favoriteFoodsProvider = StreamProvider.autoDispose<List<FavoriteFood>>(
  (ref) => ref.watch(databaseProvider).watchFavoriteFoods(),
);

/// 选中日期所在周（周一至周日）的全部运动记录
final weekExerciseEntriesProvider =
    StreamProvider.autoDispose<List<ExerciseEntry>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(databaseProvider).watchExerciseEntriesInWeek(date);
});

/// 每周运动目标（次数 + 分钟）
final weeklyGoalsProvider = StreamProvider.autoDispose<WeeklyExerciseGoal>(
  (ref) => ref.watch(databaseProvider).watchWeeklyGoals(),
);
