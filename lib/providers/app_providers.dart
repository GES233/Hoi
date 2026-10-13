import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// 组级小秒表的时钟来源；测试可 override 为可控假时钟
final setStopwatchClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// 当前选中的日期（只含日期部分），默认今天
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => AppDatabase.dateOnly(DateTime.now());

  /// 按天数前后移动选中日期
  void shift(int days) =>
      state = AppDatabase.dateOnly(state.add(Duration(days: days)));

  /// 直接选中某天（DatePicker 用）
  void select(DateTime date) => state = AppDatabase.dateOnly(date);

  /// 回到今天
  void goToday() => state = AppDatabase.dateOnly(DateTime.now());
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

final foodEntriesProvider = StreamProvider.autoDispose<List<FoodEntry>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(databaseProvider).watchFoodEntries(date);
});

final favoriteFoodsProvider = StreamProvider.autoDispose<List<FavoriteFood>>(
  (ref) => ref.watch(databaseProvider).watchFavoriteFoods(),
);

/// 每周运动目标（次数 + 分钟）
final weeklyGoalsProvider = StreamProvider.autoDispose<WeeklyExerciseGoal>(
  (ref) => ref.watch(databaseProvider).watchWeeklyGoals(),
);

/// 当前进行中的训练（至多一场）
final ongoingWorkoutProvider = StreamProvider.autoDispose<Workout?>(
  (ref) => ref.watch(databaseProvider).watchOngoingWorkout(),
);

/// 选中日期当天的已完成训练
final completedWorkoutsProvider = StreamProvider.autoDispose<List<Workout>>((
  ref,
) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(databaseProvider).watchCompletedWorkouts(date);
});

/// 选中日期所在周（周一至周日）的已完成训练
final weekWorkoutsProvider = StreamProvider.autoDispose<List<Workout>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(databaseProvider).watchCompletedWorkoutsInWeek(date);
});

/// 指定训练的动作列表
final workoutExercisesProvider = StreamProvider.autoDispose
    .family<List<WorkoutExercise>, int>(
      (ref, workoutId) =>
          ref.watch(databaseProvider).watchWorkoutExercises(workoutId),
    );

/// 指定训练的组列表（跨全部动作，按动作顺序、组顺序排列）
final workoutSetsProvider = StreamProvider.autoDispose
    .family<List<WorkoutSet>, int>(
      (ref, workoutId) =>
          ref.watch(databaseProvider).watchWorkoutSets(workoutId),
    );

final templateSetsProvider = FutureProvider.autoDispose
    .family<List<TemplateSet>, int>((ref, templateExerciseId) {
      return ref
          .watch(databaseProvider)
          .getTemplateSetsForExercise(templateExerciseId);
    });

/// 全部未归档训练模板及其当前版本（按创建时间排序）
final workoutTemplatesProvider =
    StreamProvider.autoDispose<List<WorkoutTemplateSummary>>(
      (ref) => ref.watch(databaseProvider).watchWorkoutTemplates(),
    );

/// 模板当前版本的完整定义；模板版本变化时自动重新读取
final templateDefinitionProvider = FutureProvider.autoDispose
    .family<WorkoutTemplateDefinition?, int>((ref, templateId) async {
      ref.watch(workoutTemplatesProvider);
      return ref.watch(databaseProvider).getTemplateDefinition(templateId);
    });

/// 指定训练相对其模板版本的实时完成度
final workoutTemplateProgressProvider = FutureProvider.autoDispose
    .family<TemplateProgress, int>((ref, workoutId) async {
      ref.watch(workoutExercisesProvider(workoutId));
      ref.watch(workoutSetsProvider(workoutId));
      return ref.watch(databaseProvider).evaluateWorkoutTemplate(workoutId);
    });

/// 选中日期的每日状态（含方案达标与休息标记）
final dailyStatusProvider = StreamProvider.autoDispose<DailyStatus>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(databaseProvider).watchDailyStatus(date);
});

final exercisesProvider = StreamProvider.autoDispose<List<Exercise>>(
  (ref) => ref.watch(databaseProvider).watchExercises(),
);

final ruleSetsProvider = StreamProvider.autoDispose<List<RuleSet>>(
  (ref) => ref.watch(databaseProvider).watchRuleSets(),
);

final ruleSetProgressProvider =
    StreamProvider.autoDispose<List<RuleSetProgress>>((ref) {
      final date = ref.watch(selectedDateProvider);
      return ref.watch(databaseProvider).watchRuleSetProgress(date);
    });

/// 选中日期的休息标记
final restMarkProvider = StreamProvider.autoDispose<RestMark?>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(databaseProvider).watchRestMark(date);
});

/// 选中日期所在周（周一至周日）每天的每日状态，供周条点阵使用
final weekDailyStatusProvider =
    StreamProvider.autoDispose<Map<DateTime, DailyStatus>>((ref) {
      final date = ref.watch(selectedDateProvider);
      return ref.watch(databaseProvider).watchWeekDailyStatus(date);
    });

/// 选中日期各模板的最高完成度（key 为模板 id）
final dailyTemplateProgressProvider =
    StreamProvider.autoDispose<Map<int, TemplateProgress>>((ref) {
      final date = ref.watch(selectedDateProvider);
      return ref.watch(databaseProvider).watchDailyTemplateProgress(date);
    });
