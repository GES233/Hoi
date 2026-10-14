import 'package:drift/drift.dart' show DatabaseConnection, Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:hoi/database/database.dart';
import 'package:hoi/domain/rules/rule_ast.dart';
import 'package:hoi/providers/app_providers.dart';
import 'package:hoi/screens/home_screen.dart';

void main() {
  late AppDatabase db;
  var dbClosed = false;

  setUp(() {
    // closeStreamsSynchronously：关闭查询流时不走零时长 Timer，
    // 避免 FakeAsync 下 db.close() 等待永不触发的定时器而卡死（页面跳转后会触发该路径）
    db = AppDatabase.withOptions(
      executor: DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
      seedBuiltIns: false,
    );
    dbClosed = false;
  });

  tearDown(() async {
    // 测试中途失败时不会走到 finishTest（路由未弹出、组件树未卸载），
    // 此时 db.close() 可能挂起；加超时兜底，避免整个测试文件卡死 10 分钟
    if (!dbClosed) {
      await db.close().timeout(const Duration(seconds: 15), onTimeout: () {});
    }
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    DateTime Function()? clock,
  }) async {
    // 默认 800x600 视口装不下整个首页，加高避免 ListView 懒加载把离屏内容移出树
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          if (clock != null) ...[
            setStopwatchClockProvider.overrideWithValue(clock),
            appClockProvider.overrideWithValue(clock),
          ],
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

  /// 在周条中选中目标日期：先用周箭头切到目标所在周，再点日期数字。
  /// 周条不允许前往未来，这里只用于选中过去日期
  Future<void> selectDateInStrip(WidgetTester tester, DateTime target) async {
    final today = AppDatabase.dateOnly(DateTime.now());
    final weeksBack =
        AppDatabase.weekStart(today)
            .difference(AppDatabase.weekStart(target))
            .inDays ~/
        7;
    for (var i = 0; i < weeksBack; i++) {
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('${target.day}'));
    await tester.pumpAndSettle();
  }

  /// 预置一个组数型模板与一场使用该版本的已完成训练。
  Future<void> seedPlanAndWorkout({
    required int minSets,
    required int regularSets,
    required int actualSets,
  }) async {
    final today = AppDatabase.dateOnly(DateTime.now());
    final exerciseId = await db.insertExercise(
      name: '俯卧撑',
      category: ExerciseCategory.resistance,
      trackingType: TrackingType.reps,
    );
    final templateId = await db.createWorkoutTemplate(
      name: '俯卧撑保底',
      exercises: [
        TemplateExerciseInput(
          exerciseId: exerciseId,
          sets: [
            for (var i = 0; i < regularSets; i++)
              TemplateSetInput(reps: 1, minimumReps: i < minSets ? 1 : null),
          ],
        ),
      ],
    );
    final definition = (await db.getTemplateDefinition(templateId))!;
    final workout = await db.startWorkout(
      now: today.add(const Duration(hours: 10)),
      templateVersion: definition.version,
    );
    final actualExercise = (await db.getWorkoutExercises(workout.id)).single;
    for (var i = 0; i < actualSets; i++) {
      await db.addWorkoutSet(actualExercise.id, reps: 10);
    }
    await db.finishWorkout(
      workout.id,
      totalSeconds: 600,
      now: today.add(const Duration(hours: 10, minutes: 10)),
    );
  }

  testWidgets('首页展示开始、补记与单项入口，无悬浮按钮与净热量', (tester) async {
    await pumpHome(tester);

    expect(find.text(HomeScreen.formatDate(DateTime.now())), findsOneWidget);
    expect(find.text('开始运动'), findsOneWidget);
    expect(find.text('补记运动'), findsOneWidget);
    expect(find.text('记录单项运动'), findsOneWidget);
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

  testWidgets('首页紧凑展示每日状态并从回顾入口查看运动时段', (tester) async {
    Future<void> pumpFrames() async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    final today = AppDatabase.dateOnly(DateTime.now());
    await db.saveDailyCheckin(
      today,
      sleepRating: 4,
      stressRating: 2,
      note: '下午精神不错',
    );
    final startedAt = today.add(const Duration(hours: 18));
    final endedAt = startedAt.add(const Duration(minutes: 45));
    final workoutId = await db.insertCompletedWorkout(
      startedAt: startedAt,
      endedAt: endedAt,
      totalSeconds: 2400,
    );

    await pumpHome(tester, clock: () => endedAt);

    expect(find.text('睡眠 较好 · 压力 较低 · 下午精神不错'), findsOneWidget);
    expect(find.text('本周回顾'), findsOneWidget);
    expect(find.text('1 次 · 已记录 40 分钟'), findsOneWidget);
    expect(find.text('运动时段'), findsNothing);

    await tester.tap(find.text('本周回顾'));
    await pumpFrames();
    expect(find.text('运动时段'), findsOneWidget);
    expect(find.byTooltip('展开完整时间轴'), findsOneWidget);

    final dayIndex = today.weekday - 1;
    await tester.tap(find.byKey(ValueKey('timeline-$workoutId-$dayIndex')));
    await pumpFrames();
    expect(
      find.text('开始 ${DateFormat('M月d日 HH:mm').format(startedAt)}'),
      findsOneWidget,
    );
    expect(
      find.text('结束 ${DateFormat('M月d日 HH:mm').format(endedAt)}'),
      findsOneWidget,
    );
    expect(find.text('有效用时 40 分钟'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await pumpFrames();
    await tester.pageBack();
    await pumpFrames();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.runAsync(db.close);
    dbClosed = true;
  });

  testWidgets('周期目标表单校验不完整规则并持久化结构化规则', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('目标'));
    await tester.pumpAndSettle();
    expect(find.text('尚未设置每日或每周目标'), findsOneWidget);

    await tester.tap(find.text('新建目标'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('请输入目标名称'), findsOneWidget);
    expect(find.text('请输入有效数字'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, '每周训练三次');
    await tester.enterText(fields.last, '3');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('每周训练三次'), findsOneWidget);
    final saved = await db.select(db.ruleSets).get();
    expect(saved, hasLength(1));
    expect(saved.single.period, RulePeriod.week);
    expect(saved.single.combineMode, RuleCombineMode.all);
    expect(saved.single.expressionJson, contains('session_count'));

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('今日方案'), findsOneWidget);
    expect(find.text('周期目标'), findsNothing);
    expect(find.text('每周训练三次'), findsNothing);
    expect(find.text('本周回顾'), findsOneWidget);
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
    final workoutId = await db.insertCompletedWorkout(
      startedAt: today.add(const Duration(hours: 8)),
      endedAt: today.add(const Duration(hours: 8, minutes: 30)),
      totalSeconds: 1800,
    );
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
    await tester.tap(
      find.descendant(
        of: find.ancestor(of: find.text('鸡蛋'), matching: find.byType(ListTile)),
        matching: find.byIcon(Icons.delete_outline),
      ),
    );
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
    final yesterday = today.subtract(const Duration(days: 1));
    await selectDateInStrip(tester, yesterday);
    expect(find.text(HomeScreen.formatDate(yesterday)), findsOneWidget);
    expect(find.text('米饭'), findsNothing);
    expect(find.text('回到今天'), findsOneWidget);
    expect(find.text('「开始运动」从现在开始计时；补记归属选中日期'), findsOneWidget);
    // 历史日期：补记为主按钮（FilledButton），开始为次按钮（OutlinedButton）
    expect(
      find.ancestor(of: find.text('补记运动'), matching: find.byType(FilledButton)),
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
      find.ancestor(of: find.text('开始运动'), matching: find.byType(FilledButton)),
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

  testWidgets('每周目标预设与本周概览按已完成训练统计次数与时长', (tester) async {
    final today = AppDatabase.dateOnly(DateTime.now());
    await db.activateRuleSetPreset(
      'weekly_consistency',
      effectiveFromDate: AppDatabase.weekStart(today),
    );
    await pumpHome(tester);

    // 首页只保留紧凑回顾入口，完整时间线和目标在回顾页。
    expect(find.text('本周回顾'), findsOneWidget);
    expect(find.text('0 次 · 已记录 0 分钟'), findsOneWidget);
    expect(find.text('每周基础运动'), findsNothing);
    await tester.tap(find.text('本周回顾'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('每周基础运动'), findsOneWidget);
    expect(find.text('0/3 次 · 0/90 分钟'), findsOneWidget);

    // 一场训练含多个动作多组，次数仍只计 1
    final workoutId = await db.insertCompletedWorkout(
      startedAt: today.add(const Duration(hours: 18)),
      endedAt: today.add(const Duration(hours: 18, minutes: 30)),
      totalSeconds: 1800,
    );
    final e1 = await db.addWorkoutExercise(
      workoutId,
      name: '深蹲',
      category: ExerciseCategory.resistance,
    );
    final e2 = await db.addWorkoutExercise(
      workoutId,
      name: '跑步',
      category: ExerciseCategory.cardio,
    );
    await db.addWorkoutSet(e1, reps: 10);
    await db.addWorkoutSet(e1, reps: 10);
    await db.addWorkoutSet(e2, durationSeconds: 1800);
    await tester.pumpAndSettle();

    expect(find.text('1/3 次 · 30/90 分钟'), findsOneWidget);

    // 激活后的预设是普通 RuleSet，可以按用户需要修改。
    final rule = (await db.select(db.ruleSets).get()).single;
    await db.updateRuleSetDefinition(
      rule.id,
      name: rule.name,
      period: RulePeriod.week,
      effectiveFromDate: rule.effectiveFromDate,
      combineMode: RuleCombineMode.all,
      expression: AllRule(const [
        ComparisonRule(
          metricId: 'session_count',
          operator: ComparisonOperator.greaterOrEqual,
          target: 5,
        ),
        ComparisonRule(
          metricId: 'session_duration',
          operator: ComparisonOperator.greaterOrEqual,
          target: 120 * 60,
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('1/5 次 · 30/120 分钟'), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.runAsync(db.close);
    dbClosed = true;
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
    expect(find.textContaining('已记录 1/3 组'), findsOneWidget);
    // 不使用失败文案或警告图标
    expect(find.textContaining('失败'), findsNothing);
    expect(find.byIcon(Icons.warning_amber), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsNothing);

    await finishTest(tester);
  });

  testWidgets('补记默认选中日期并要求起止时间', (tester) async {
    await pumpHome(tester);
    final today = AppDatabase.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    // 选中昨天后进入补记
    await selectDateInStrip(tester, yesterday);
    await tester.tap(find.text('补记运动'));
    await tester.pumpAndSettle();

    expect(find.text('补记运动'), findsOneWidget); // AppBar 标题
    expect(
      find.text(DateFormat('yyyy年M月d日').format(yesterday)),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsOneWidget);

    // 返回首页后再收尾：推入的路由未弹出时 db.close() 会挂起
    await tester.pageBack();
    await tester.pumpAndSettle();

    await finishTest(tester);
  });

  testWidgets('可新增运动类型并在动作库中编辑', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('动作'));
    await tester.pumpAndSettle();
    expect(find.text('运动类型'), findsOneWidget);

    await tester.tap(find.text('添加运动类型'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '运动名称'), '羽毛球');
    await tester.tap(find.widgetWithText(FilledButton, '添加'));
    await tester.pumpAndSettle();

    expect(find.text('羽毛球'), findsOneWidget);
    expect(find.text('心肺 · 按时长记录'), findsOneWidget);
    var exercises = await db.getExercises();
    expect(exercises.single.name, '羽毛球');

    await tester.tap(find.text('羽毛球'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '运动名称'), '双打羽毛球');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.text('双打羽毛球'), findsOneWidget);
    exercises = await db.getExercises();
    expect(exercises.single.name, '双打羽毛球');

    await tester.pageBack();
    await tester.pumpAndSettle();

    await finishTest(tester);
  });

  testWidgets('可单独记录一个运动并保存为当日记录', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('记录单项运动'));
    await tester.pumpAndSettle();
    expect(find.text('记录单项运动'), findsOneWidget);
    expect(find.text('关联方案（可选）'), findsNothing);

    await tester.tap(find.text('选择运动'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '动作名称'), '散步');
    await tester.tap(find.widgetWithText(FilledButton, '添加'));
    await tester.pumpAndSettle();

    expect(find.textContaining('散步'), findsOneWidget);
    expect(find.text('选择运动'), findsNothing);
    await tester.tap(find.text('添加组'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '持续秒数（可选）'), '1200');
    await tester.tap(find.widgetWithText(FilledButton, '添加'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存记录'));
    await tester.pumpAndSettle();

    expect(find.text('运动记录'), findsOneWidget);
    expect(find.text('散步'), findsOneWidget);
    final workouts = await db.select(db.workouts).get();
    final exercises = await db.getWorkoutExercises(workouts.single.id);
    final sets = await db.getWorkoutSets(workouts.single.id);
    expect(workouts.single.status, WorkoutStatus.completed);
    expect(workouts.single.startedAt, isNotNull);
    expect(workouts.single.endedAt, isNotNull);
    expect(
      workouts.single.endedAt!.difference(workouts.single.startedAt!),
      const Duration(hours: 1),
    );
    expect(exercises.single.name, '散步');
    expect(sets.single.durationSeconds, 1200);

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
    final plankId = await db.insertExercise(
      name: '平板支撑',
      category: ExerciseCategory.core,
      trackingType: TrackingType.duration,
      loadConvention: LoadConvention.bodyweight,
    );
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
    await tester.tap(find.text('新建自定义动作'));
    await pumpFrames();
    await tester.tap(find.text('平板支撑 · 时长').last);
    await pumpFrames();
    await tester.tap(find.text('添加'));
    await pumpFrames();
    await pumpFrames();
    expect(find.textContaining('平板支撑'), findsOneWidget);

    // 开始一组 → 假时钟推进 90 秒 → 完成本组
    await tester.tap(find.text('开始一组'));
    await pumpFrames();
    fakeNow = fakeNow.add(const Duration(seconds: 90));
    await tester.pump(const Duration(seconds: 1)); // 让显示随 Timer 刷新一次
    await tester.tap(find.text('完成本组'));
    await pumpFrames();
    await pumpFrames();

    final workout = await db.getOngoingWorkout();
    final exercises = await db.getWorkoutExercises(workout!.id);
    final sets = await db.getWorkoutSets(workout.id);
    expect(exercises.single.catalogExerciseId, plankId);
    expect(exercises.single.loadConventionSnapshot, LoadConvention.bodyweight);
    expect(sets, hasLength(1));
    expect(sets.single.durationSeconds, 90);
    expect(AppDatabase.isValidSet(sets.single), isTrue);

    // 返回首页后再收尾：推入的路由未弹出时 db.close() 可能挂起，
    // 且训练页的 periodic Timer 需要随组件树卸载取消
    await tester.pageBack();
    await pumpFrames();

    await finishTest(tester);
  });

  testWidgets('首页删除训练需二次确认', (tester) async {
    await pumpHome(tester);
    final today = AppDatabase.dateOnly(DateTime.now());
    final workoutId = await db.insertCompletedWorkout(
      startedAt: today.add(const Duration(hours: 10)),
      endedAt: today.add(const Duration(hours: 10, minutes: 10)),
      totalSeconds: 600,
    );
    await db.addWorkoutExercise(
      workoutId,
      name: '跑步',
      category: ExerciseCategory.cardio,
    );
    await tester.pumpAndSettle();
    expect(find.text('跑步'), findsOneWidget);

    Future<void> tapDelete() => tester.tap(
      find.descendant(
        of: find.ancestor(of: find.text('跑步'), matching: find.byType(ListTile)),
        matching: find.byIcon(Icons.delete_outline),
      ),
    );

    // 取消：不删除
    await tapDelete();
    await tester.pumpAndSettle();
    expect(find.text('删除训练'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('跑步'), findsOneWidget);

    // 确认：级联删除
    await tapDelete();
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('跑步'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('周条停留在本周时不可切到下一周', (tester) async {
    await pumpHome(tester);
    final next = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.chevron_right),
        matching: find.byType(IconButton),
      ),
    );
    expect(next.onPressed, isNull);
    // 上一周可用
    final prev = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.chevron_left),
        matching: find.byType(IconButton),
      ),
    );
    expect(prev.onPressed, isNotNull);

    await finishTest(tester);
  });

  testWidgets('训练页实时显示方案进度，达到最低时给出反馈', (tester) async {
    final exerciseId = await db.insertExercise(
      name: '俯卧撑',
      category: ExerciseCategory.resistance,
      trackingType: TrackingType.reps,
    );
    final templateId = await db.createWorkoutTemplate(
      name: '俯卧撑保底',
      exercises: [
        TemplateExerciseInput(
          exerciseId: exerciseId,
          sets: const [
            TemplateSetInput(reps: 1, minimumReps: 1),
            TemplateSetInput(reps: 1),
            TemplateSetInput(reps: 1),
          ],
        ),
      ],
    );
    final definition = (await db.getTemplateDefinition(templateId))!;
    await pumpHome(tester);
    await db.startWorkout(templateVersion: definition.version);
    await tester.pumpAndSettle();

    // 训练页有常驻 periodic Timer，进入后不能 pumpAndSettle
    Future<void> pumpFrames() async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    await tester.tap(find.text('继续训练'));
    await pumpFrames();
    await pumpFrames();
    expect(find.text('关联方案：俯卧撑保底'), findsOneWidget);
    expect(find.text('0 / 1 组'), findsOneWidget); // 最低 1 组，当前 0

    // startWorkout 已按方案预添加绑定动作「俯卧撑」，直接记一组 → 达到最低
    await tester.tap(find.text('添加组'));
    await pumpFrames();
    await tester.enterText(find.byType(TextField).first, '10');
    await tester.tap(find.text('添加'));
    await pumpFrames();
    await pumpFrames();

    expect(find.text('今天的最低方案已完成'), findsOneWidget); // SnackBar 反馈
    expect(find.text('已完成'), findsOneWidget); // 最低行变为已完成
    expect(find.text('1 / 3 组'), findsOneWidget); // 常规行继续显示进度

    await tester.pageBack();
    await pumpFrames();

    await finishTest(tester);
  });

  testWidgets('多动作训练区分计划组、跳过组、额外组与计划外动作', (tester) async {
    final squatId = await db.insertExercise(
      name: '深蹲',
      category: ExerciseCategory.resistance,
      trackingType: TrackingType.reps,
    );
    final runId = await db.insertExercise(
      name: '跑步',
      category: ExerciseCategory.cardio,
      trackingType: TrackingType.duration,
    );
    final templateId = await db.createWorkoutTemplate(
      name: '全身训练',
      exercises: [
        TemplateExerciseInput(
          exerciseId: squatId,
          sets: const [TemplateSetInput(reps: 10)],
        ),
        TemplateExerciseInput(
          exerciseId: runId,
          sets: const [TemplateSetInput(durationSeconds: 600)],
        ),
      ],
    );
    final definition = (await db.getTemplateDefinition(templateId))!;
    final workout = await db.startWorkout(templateVersion: definition.version);
    final exercises = await db.getWorkoutExercises(workout.id);
    await db.addWorkoutSet(exercises.first.id, setStatus: SetStatus.skipped);
    await db.addWorkoutSet(exercises.first.id, reps: 12); // 已超出唯一计划组
    final extraExercise = await db.addWorkoutExercise(
      workout.id,
      name: '散步',
      category: ExerciseCategory.cardio,
      trackingType: TrackingType.duration,
    );
    await db.addWorkoutSet(extraExercise, durationSeconds: 300);

    await pumpHome(tester);
    await tester.tap(find.text('继续训练'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('深蹲'), findsOneWidget);
    expect(find.text('跑步'), findsOneWidget);
    expect(find.text('散步'), findsOneWidget);
    expect(find.textContaining('计划动作 · 已记录 1/1'), findsOneWidget);
    expect(find.textContaining('计划组 · 已跳过'), findsOneWidget);
    expect(find.textContaining('额外组'), findsOneWidget);
    expect(find.text('计划外动作'), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    await finishTest(tester);
  });

  testWidgets('训练页点按组行可编辑该组（含备注）', (tester) async {
    await pumpHome(tester);

    Future<void> pumpFrames() async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    await tester.tap(find.text('开始运动'));
    await pumpFrames();
    await pumpFrames();

    // 添加动作并手填一组
    await tester.tap(find.text('添加动作'));
    await pumpFrames();
    await tester.enterText(find.byType(TextFormField).first, '俯卧撑');
    await tester.tap(find.text('添加'));
    await pumpFrames();
    await pumpFrames();
    await tester.tap(find.text('添加组'));
    await pumpFrames();
    await tester.enterText(find.byType(TextField).first, '10');
    await tester.tap(find.text('添加'));
    await pumpFrames();
    await pumpFrames();
    expect(find.textContaining('第 1 组'), findsOneWidget);

    // 点按组行 → 编辑对话框预填原值，修改次数并补备注
    await tester.tap(find.textContaining('第 1 组'));
    await pumpFrames();
    expect(find.text('编辑组'), findsOneWidget);
    expect(find.text('10'), findsOneWidget); // 次数已预填
    await tester.enterText(find.byType(TextField).first, '12');
    await tester.enterText(find.byType(TextField).last, '前 8 个全程，后 4 个退阶');
    await tester.tap(find.text('保存'));
    await pumpFrames();
    await pumpFrames();

    final workout = await db.getOngoingWorkout();
    final sets = await db.getWorkoutSets(workout!.id);
    expect(sets.single.reps, 12);
    expect(sets.single.note, '前 8 个全程，后 4 个退阶');
    expect(find.textContaining('自由组　12 次'), findsOneWidget);

    await tester.pageBack();
    await pumpFrames();

    await finishTest(tester);
  });
}
