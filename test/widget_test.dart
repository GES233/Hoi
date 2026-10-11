import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hoi/database/database.dart';
import 'package:hoi/providers/app_providers.dart';
import 'package:hoi/screens/home_screen.dart';

void main() {
  late AppDatabase db;
  var dbClosed = false;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dbClosed = false;
  });

  tearDown(() async {
    if (!dbClosed) await db.close();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    // 默认 800x600 视口装不下整个首页，加高避免 ListView 懒加载把离屏内容移出树
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 每个测试结束前调用：先关闭数据库，再卸载组件树。
  /// drift 在取消查询流时会调度零时长 Timer（StreamQueryStore.markAsClosed），
  /// 若组件树卸载时数据库仍打开，flutter_test 会报 "Timer still pending"。
  /// drift 官方建议在 widget 测试里 await Database.close()。
  Future<void> finishTest(WidgetTester tester) async {
    await db.close();
    dbClosed = true;
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  testWidgets('首页显示日期、入口按钮、汇总与空列表', (tester) async {
    await pumpHome(tester);

    expect(find.text(HomeScreen.formatDate(DateTime.now())), findsOneWidget);
    expect(find.text('开始运动'), findsOneWidget);
    expect(find.text('补记运动'), findsOneWidget);
    expect(find.text('总摄入'), findsOneWidget);
    // 汇总卡不再显示总消耗与净热量
    expect(find.text('总消耗'), findsNothing);
    expect(find.text('净热量'), findsNothing);
    expect(find.text('饮食记录'), findsOneWidget);
    expect(find.text('运动记录'), findsOneWidget);
    expect(find.text('暂无记录'), findsNWidgets(2));

    await finishTest(tester);
  });

  testWidgets('插入饮食和已完成训练后汇总更新，删除后消失', (tester) async {
    await pumpHome(tester);
    final today = AppDatabase.dateOnly(DateTime.now());

    await db.insertFoodEntry(
      FoodEntriesCompanion(
        date: Value(today),
        mealType: const Value(MealType.breakfast),
        name: const Value('鸡蛋'),
        calories: const Value(140),
      ),
    );
    final workoutId =
        await db.insertCompletedWorkout(date: today, totalSeconds: 1800);
    await db.addWorkoutExercise(
      workoutId,
      name: '跑步',
      category: ExerciseCategory.cardio,
    );
    await tester.pumpAndSettle();

    expect(find.text('早餐'), findsOneWidget);
    expect(find.text('鸡蛋'), findsOneWidget);
    expect(find.text('跑步'), findsOneWidget);
    expect(find.text('140'), findsOneWidget); // 总摄入
    expect(find.text('总用时 30 分钟'), findsOneWidget);

    // 删除饮食条目
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(find.text('鸡蛋'), findsNothing);
    expect(find.text('跑步'), findsOneWidget);
    expect(find.text('0'), findsOneWidget); // 总摄入归零

    await finishTest(tester);
  });

  testWidgets('日期左右箭头切换日期，历史日期不显示今天的条目', (tester) async {
    await pumpHome(tester);
    final today = AppDatabase.dateOnly(DateTime.now());
    await db.insertFoodEntry(
      FoodEntriesCompanion(
        date: Value(today),
        mealType: const Value(MealType.lunch),
        name: const Value('米饭'),
        calories: const Value(300),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('米饭'), findsOneWidget);

    // 切到前一天
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(
      find.text(HomeScreen.formatDate(today.subtract(const Duration(days: 1)))),
      findsOneWidget,
    );
    expect(find.text('米饭'), findsNothing);

    // 切回今天
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text(HomeScreen.formatDate(today)), findsOneWidget);
    expect(find.text('米饭'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('常用食物可保存并用于快速填入', (tester) async {
    await pumpHome(tester);

    await db.upsertFavoriteFood('苹果', 95);
    await db.upsertFavoriteFood('苹果', 100); // 同名 upsert 不报错
    final favorites = await db.select(db.favoriteFoods).get();
    expect(favorites, hasLength(1));
    expect(favorites.single.calories, 100);

    await finishTest(tester);
  });

  testWidgets('本周运动卡片按已完成训练统计次数与时长', (tester) async {
    await pumpHome(tester);
    final today = AppDatabase.dateOnly(DateTime.now());

    // 空表时使用默认目标：每周 3 次、90 分钟
    expect(find.text('本周运动'), findsOneWidget);
    expect(find.text('0 / 3 次'), findsOneWidget);
    expect(find.text('0 / 90 分钟'), findsOneWidget);

    // 一场训练含多个动作多组，次数仍只计 1
    final workoutId =
        await db.insertCompletedWorkout(date: today, totalSeconds: 1800);
    final e1 = await db.addWorkoutExercise(
        workoutId, name: '深蹲', category: ExerciseCategory.resistance);
    final e2 = await db.addWorkoutExercise(
        workoutId, name: '跑步', category: ExerciseCategory.cardio);
    await db.addWorkoutSet(e1, reps: 10);
    await db.addWorkoutSet(e1, reps: 10);
    await db.addWorkoutSet(e2, durationSeconds: 1800);
    await tester.pumpAndSettle();

    expect(find.text('1 / 3 次'), findsOneWidget);
    expect(find.text('30 / 90 分钟'), findsOneWidget);

    // 修改目标后进度按新目标显示
    await db.updateWeeklyGoals(targetSessions: 5, targetMinutes: 120);
    await tester.pumpAndSettle();
    expect(find.text('1 / 5 次'), findsOneWidget);
    expect(find.text('30 / 120 分钟'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('有进行中训练时入口显示「继续训练」', (tester) async {
    await pumpHome(tester);
    expect(find.text('开始运动'), findsOneWidget);

    await db.startWorkout();
    await tester.pumpAndSettle();
    expect(find.text('继续训练'), findsOneWidget);
    expect(find.text('开始运动'), findsNothing);

    await finishTest(tester);
  });
}
