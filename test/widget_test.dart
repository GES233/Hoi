import 'package:drift/drift.dart' show DatabaseConnection, Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:hoi/database/database.dart';
import 'package:hoi/providers/app_providers.dart';
import 'package:hoi/screens/home_screen.dart';

void main() {
  late AppDatabase db;
  var dbClosed = false;

  setUp(() {
    // closeStreamsSynchronously：关闭查询流时不走零时长 Timer，
    // 避免 FakeAsync 下 db.close() 等待永不触发的定时器而卡死（页面跳转后会触发该路径）
    db = AppDatabase(DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ));
    dbClosed = false;
  });

  tearDown(() async {
    if (!dbClosed) await db.close();
  });

  Future<void> pumpHome(WidgetTester tester, {DateTime Function()? clock}) async {
    // 默认 800x600 视口装不下整个首页，加高避免 ListView 懒加载把离屏内容移出树
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          if (clock != null) setStopwatchClockProvider.overrideWithValue(clock),
        ],
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

  /// 预置一个组数型方案与一场关联它的已完成训练
  /// （exerciseName 与动作同名，repsPerSet 组数为实际有效组数）
  Future<void> seedPlanAndWorkout({
    required int minSets,
    required int regularSets,
    required int actualSets,
  }) async {
    final today = AppDatabase.dateOnly(DateTime.now());
    final planId = await db.insertExercisePlan(
      name: '俯卧撑保底',
      exerciseName: '俯卧撑',
      category: ExerciseCategory.resistance,
      metric: PlanMetric.sets,
      minThreshold: minSets,
      regularThreshold: regularSets,
    );
    final workoutId =
        await db.insertCompletedWorkout(date: today, totalSeconds: 600);
    final exerciseId = await db.addWorkoutExercise(
      workoutId,
      name: '俯卧撑',
      category: ExerciseCategory.resistance,
    );
    for (var i = 0; i < actualSets; i++) {
      await db.addWorkoutSet(exerciseId, reps: 10);
    }
    final plan = await db.getExercisePlan(planId);
    await db.linkPlanToWorkout(workoutId, plan!);
  }

  testWidgets('首页展示开始与补记入口，无悬浮按钮与净热量', (tester) async {
    await pumpHome(tester);

    expect(find.text(HomeScreen.formatDate(DateTime.now())), findsOneWidget);
    expect(find.text('开始运动'), findsOneWidget);
    expect(find.text('补记运动'), findsOneWidget);
    expect(find.text('添加饮食'), findsOneWidget);
    // 入口全部在内容流内，不使用悬浮按钮
    expect(find.byType(FloatingActionButton), findsNothing);
    // 独立汇总卡已移除，热量摘要并入饮食分区；不出现净热量
    expect(find.text('总摄入'), findsNothing);
    expect(find.text('总消耗'), findsNothing);
    expect(find.text('净热量'), findsNothing);
    expect(find.text('当日摄入 0 kcal'), findsOneWidget);
    expect(find.text('饮食记录'), findsOneWidget);
    expect(find.text('运动记录'), findsOneWidget);
    expect(find.text('暂无记录'), findsNWidgets(2));
    // 选中今天时不显示「回到今天」
    expect(find.text('回到今天'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('插入饮食和已完成训练后摘要更新，删除后消失', (tester) async {
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
    expect(find.text('当日摄入 140 kcal'), findsOneWidget);
    expect(find.text('总用时 30 分钟'), findsOneWidget);

    // 删除饮食条目（运动分区在饮食分区之前，需精确定位「鸡蛋」所在行）
    await tester.tap(find.descendant(
      of: find.ancestor(of: find.text('鸡蛋'), matching: find.byType(ListTile)),
      matching: find.byIcon(Icons.delete_outline),
    ));
    await tester.pumpAndSettle();
    expect(find.text('鸡蛋'), findsNothing);
    expect(find.text('跑步'), findsOneWidget);
    expect(find.text('当日摄入 0 kcal'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('日期左右箭头切换日期，历史日期补记为主、可回到今天', (tester) async {
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

    // 切到前一天：显示「回到今天」与历史日期辅助文案
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(
      find.text(HomeScreen.formatDate(today.subtract(const Duration(days: 1)))),
      findsOneWidget,
    );
    expect(find.text('米饭'), findsNothing);
    expect(find.text('回到今天'), findsOneWidget);
    expect(find.text('「开始运动」从现在开始计时；补记归属选中日期'), findsOneWidget);
    // 历史日期：补记为主按钮（FilledButton），开始为次按钮（OutlinedButton）
    expect(
      find.ancestor(
        of: find.text('补记运动'),
        matching: find.byType(FilledButton),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text('开始运动'),
        matching: find.byType(OutlinedButton),
      ),
      findsOneWidget,
    );

    // 回到今天
    await tester.tap(find.text('回到今天'));
    await tester.pumpAndSettle();
    expect(find.text(HomeScreen.formatDate(today)), findsOneWidget);
    expect(find.text('回到今天'), findsNothing);
    expect(find.text('米饭'), findsOneWidget);
    // 今天：开始运动为主按钮
    expect(
      find.ancestor(
        of: find.text('开始运动'),
        matching: find.byType(FilledButton),
      ),
      findsOneWidget,
    );

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

  testWidgets('有进行中训练时展示继续训练入口', (tester) async {
    await pumpHome(tester);
    expect(find.text('开始运动'), findsOneWidget);
    expect(find.text('训练进行中'), findsNothing);

    await db.startWorkout();
    await tester.pumpAndSettle();

    // 进行中训练卡与选中日期无关，提供继续入口；「开始运动」让位
    expect(find.text('训练进行中'), findsOneWidget);
    expect(find.text('继续训练'), findsOneWidget);
    expect(find.text('开始运动'), findsNothing);
    expect(find.text('补记运动'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('最低完成显示成功状态', (tester) async {
    // 最低 1 组、常规 3 组的方案，实际完成 1 组 → 达最低未达常规
    await seedPlanAndWorkout(minSets: 1, regularSets: 3, actualSets: 1);
    await pumpHome(tester);

    expect(find.text('俯卧撑保底'), findsOneWidget);
    expect(find.text('最低完成'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsWidgets);
    // 达最低时不出现常规失败语义
    expect(find.text('常规完成'), findsNothing);
    expect(find.textContaining('失败'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('常规未完成不显示失败', (tester) async {
    // 最低 2 组、常规 3 组的方案，实际完成 1 组 → 未达最低
    await seedPlanAndWorkout(minSets: 2, regularSets: 3, actualSets: 1);
    await pumpHome(tester);

    expect(find.text('俯卧撑保底'), findsOneWidget);
    expect(find.textContaining('未达最低'), findsOneWidget);
    // 不使用失败文案或警告图标
    expect(find.textContaining('失败'), findsNothing);
    expect(find.byIcon(Icons.warning_amber), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsNothing);

    await finishTest(tester);
  });

  testWidgets('补记不要求精确开始时间，日期默认选中日期', (tester) async {
    await pumpHome(tester);
    final today = AppDatabase.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    // 选中昨天后进入补记
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    await tester.tap(find.text('补记运动'));
    await tester.pumpAndSettle();

    // 补记页只有日期（默认选中日期），没有精确开始时间字段
    expect(find.text('补记运动'), findsOneWidget); // AppBar 标题
    expect(
      find.text(DateFormat('yyyy年M月d日').format(yesterday)),
      findsOneWidget,
    );
    expect(find.textContaining('开始时间'), findsNothing);

    // 返回首页后再收尾：推入的路由未弹出时 db.close() 会挂起
    await tester.pageBack();
    await tester.pumpAndSettle();

    await finishTest(tester);
  });

  testWidgets('饮食记录入口可用', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('添加饮食'));
    await tester.pumpAndSettle();
    expect(find.text('食物名称'), findsOneWidget);
    expect(find.text('热量 (kcal)'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('食物名称'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('组级小秒表：开始一组→结束并保存写入时长组；大秒表已降级', (tester) async {
    // 假时钟注入组级秒表，不依赖真实等待
    var fakeNow = DateTime(2026, 10, 5, 10, 0, 0);
    await pumpHome(tester, clock: () => fakeNow);

    // 训练页有常驻 periodic Timer（每秒刷新显示），进入后不能 pumpAndSettle，
    // 统一用固定时长 pump 推进
    Future<void> pumpFrames() async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    await tester.tap(find.text('开始运动'));
    await pumpFrames();
    await pumpFrames();
    expect(find.text('进行中的训练'), findsOneWidget); // 已到训练页

    // 大秒表降级：总用时为紧凑一行，页面上没有大号计时读数（无 >=30 字号文本）
    expect(find.textContaining('总用时'), findsOneWidget);
    expect(find.text('结束训练'), findsOneWidget);
    expect(
      tester
          .widgetList<Text>(find.byType(Text))
          .any((t) => (t.style?.fontSize ?? 0) >= 30),
      isFalse,
    );

    // 添加动作
    await tester.tap(find.text('添加动作'));
    await pumpFrames();
    await tester.enterText(find.byType(TextFormField).first, '平板支撑');
    await tester.tap(find.text('添加'));
    await pumpFrames();
    await pumpFrames();
    expect(find.textContaining('平板支撑'), findsOneWidget);

    // 开始一组 → 假时钟推进 90 秒 → 结束并保存
    await tester.tap(find.text('开始一组'));
    await pumpFrames();
    fakeNow = fakeNow.add(const Duration(seconds: 90));
    await tester.pump(const Duration(seconds: 1)); // 让显示随 Timer 刷新一次
    await tester.tap(find.text('结束并保存'));
    await pumpFrames();
    await pumpFrames();

    final workout = await db.getOngoingWorkout();
    final sets = await db.getWorkoutSets(workout!.id);
    expect(sets, hasLength(1));
    expect(sets.single.durationSeconds, 90);
    expect(AppDatabase.isValidSet(sets.single), isTrue);

    // 返回首页后再收尾：推入的路由未弹出时 db.close() 可能挂起，
    // 且训练页的 periodic Timer 需要随组件树卸载取消
    await tester.pageBack();
    await pumpFrames();

    await finishTest(tester);
  });
}
