import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hoi/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // 固定时间，注入 now，不用真实等待
  final t0 = DateTime(2026, 10, 5, 10, 0, 0); // 周一 10:00

  Future<Workout> workoutById(int id) async => (await db.getWorkout(id))!;

  test('一场训练多个动作多组，周统计次数仍只计 1', () async {
    final wid = await db.insertCompletedWorkout(
      date: t0,
      totalSeconds: 3600,
    );
    final e1 = await db.addWorkoutExercise(
        wid, name: '深蹲', category: ExerciseCategory.resistance);
    final e2 = await db.addWorkoutExercise(
        wid, name: '跑步', category: ExerciseCategory.cardio);
    await db.addWorkoutSet(e1, reps: 10, weightKg: 60);
    await db.addWorkoutSet(e1, reps: 10);
    await db.addWorkoutSet(e2, durationSeconds: 1800);

    final day = await db.watchCompletedWorkouts(t0).first;
    final week = await db.watchCompletedWorkoutsInWeek(t0).first;
    expect(day, hasLength(1));
    expect(week, hasLength(1));
    expect(week.single.id, wid);
  });

  test('次数型与持续时间型组都能正确保存读取', () async {
    final wid = await db.insertCompletedWorkout(date: t0);
    final e = await db.addWorkoutExercise(
        wid, name: '平板支撑', category: ExerciseCategory.core);
    await db.addWorkoutSet(e, reps: 12, weightKg: 20.5, note: '第一组');
    await db.addWorkoutSet(e, durationSeconds: 90);

    final sets = await db.watchWorkoutSets(wid).first;
    expect(sets, hasLength(2));
    expect(sets[0].reps, 12);
    expect(sets[0].durationSeconds, isNull);
    expect(sets[0].weightKg, 20.5);
    expect(sets[0].note, '第一组');
    expect(sets[1].reps, isNull);
    expect(sets[1].durationSeconds, 90);
    // 两条都是有效组
    expect(sets.every(AppDatabase.isValidSet), isTrue);
  });

  test('暂停 10 分钟再恢复，计时与结束总用时都不含暂停段', () async {
    final w = await db.startWorkout(now: t0);
    await db.pauseWorkout(w.id, now: t0.add(const Duration(minutes: 5)));
    await db.resumeWorkout(w.id, now: t0.add(const Duration(minutes: 15)));

    var cur = await workoutById(w.id);
    expect(cur.pausedSeconds, 600);
    expect(cur.pausedAt, isNull);
    // 开始 20 分钟时：1200 秒 - 600 秒暂停 = 600
    expect(
      AppDatabase.elapsedSeconds(cur, now: t0.add(const Duration(minutes: 20))),
      600,
    );

    final e = await db.addWorkoutExercise(
        w.id, name: '慢跑', category: ExerciseCategory.cardio);
    await db.addWorkoutSet(e, durationSeconds: 600);
    await db.finishWorkout(w.id, now: t0.add(const Duration(minutes: 25)));

    cur = await workoutById(w.id);
    expect(cur.status, WorkoutStatus.completed);
    // 25 分钟 - 10 分钟暂停 = 900 秒
    expect(cur.totalSeconds, 900);
    expect(cur.endedAt, t0.add(const Duration(minutes: 25)));
  });

  test('暂停中结束训练，进行中的暂停段也不计入总用时', () async {
    final w = await db.startWorkout(now: t0);
    await db.pauseWorkout(w.id, now: t0.add(const Duration(minutes: 5)));

    final e = await db.addWorkoutExercise(
        w.id, name: '骑行', category: ExerciseCategory.cardio);
    await db.addWorkoutSet(e, durationSeconds: 300);
    // 暂停中直接结束：10 分钟时结束，总用时 = 5 分钟
    await db.finishWorkout(w.id, now: t0.add(const Duration(minutes: 10)));

    final cur = await workoutById(w.id);
    expect(cur.totalSeconds, 300);
    expect(cur.pausedAt, isNull);
  });

  test('startWorkout 后可恢复同一场训练，再次 startWorkout 不创建第二场', () async {
    final w1 = await db.startWorkout(now: t0);

    // 模拟重启后恢复：重新查询进行中的训练
    final ongoing = await db.getOngoingWorkout();
    expect(ongoing?.id, w1.id);
    expect(ongoing?.startedAt, t0);

    final w2 = await db.startWorkout(now: t0.add(const Duration(minutes: 1)));
    expect(w2.id, w1.id);
    expect(await db.select(db.workouts).get(), hasLength(1));

    // 监听流同样返回该场训练
    final watched = await db.watchOngoingWorkout().first;
    expect(watched?.id, w1.id);
  });

  test('补记 totalSeconds 为 null 时周分钟统计不推算，只计入次数', () async {
    await db.insertCompletedWorkout(date: t0, totalSeconds: null);
    await db.insertCompletedWorkout(date: t0, totalSeconds: 1800);

    final week = await db.watchCompletedWorkoutsInWeek(t0).first;
    expect(week, hasLength(2)); // 次数计 2
    // 分钟只累计已知总用时：1800 秒 = 30 分钟，未知的不补 0 也不推算
    final totalSeconds =
        week.fold<int>(0, (sum, w) => sum + (w.totalSeconds ?? 0));
    expect(totalSeconds ~/ 60, 30);

    final nullOne = week.firstWhere((w) => w.totalSeconds == null);
    expect(nullOne.startedAt, isNull);
    expect(nullOne.endedAt, isNull);
  });

  test('进行中训练不出现在已完成列表与周统计里', () async {
    await db.startWorkout(now: t0);

    expect(await db.watchCompletedWorkouts(t0).first, isEmpty);
    expect(await db.watchCompletedWorkoutsInWeek(t0).first, isEmpty);
  });

  test('无有效组时 finishWorkout 抛 StateError', () async {
    final w = await db.startWorkout(now: t0);
    // 完全没有组
    expect(
      () => db.finishWorkout(w.id, now: t0.add(const Duration(minutes: 10))),
      throwsStateError,
    );

    // 有组但全无效（次数为空、时长为 0）
    final e = await db.addWorkoutExercise(
        w.id, name: '拉伸', category: ExerciseCategory.functional);
    await db.addWorkoutSet(e, durationSeconds: 0);
    expect(
      () => db.finishWorkout(w.id, now: t0.add(const Duration(minutes: 10))),
      throwsStateError,
    );
    // 训练仍是进行中
    expect((await workoutById(w.id)).status, WorkoutStatus.inProgress);

    // 补一条有效组后可以结束
    await db.addWorkoutSet(e, reps: 5);
    await db.finishWorkout(w.id, now: t0.add(const Duration(minutes: 10)));
    final done = await workoutById(w.id);
    expect(done.status, WorkoutStatus.completed);
    expect(done.totalSeconds, 600);
  });

  test('discardWorkout 级联删除动作与组', () async {
    final w = await db.startWorkout(now: t0);
    final e = await db.addWorkoutExercise(
        w.id, name: '硬拉', category: ExerciseCategory.resistance);
    await db.addWorkoutSet(e, reps: 8, weightKg: 80);
    await db.addWorkoutSet(e, reps: 8, weightKg: 80);

    await db.discardWorkout(w.id);

    expect(await db.select(db.workouts).get(), isEmpty);
    expect(await db.select(db.workoutExercises).get(), isEmpty);
    expect(await db.select(db.workoutSets).get(), isEmpty);
    expect(await db.getOngoingWorkout(), isNull);
  });

  test('updateWorkoutMeta 可修改、可清空总用时与感受', () async {
    final wid = await db.insertCompletedWorkout(
      date: t0,
      totalSeconds: 1800,
      feeling: '轻松',
    );

    // 只改感受，总用时不变
    await db.updateWorkoutMeta(wid, feeling: const Value('有点累'));
    var w = await workoutById(wid);
    expect(w.totalSeconds, 1800);
    expect(w.feeling, '有点累');

    // 清空总用时
    await db.updateWorkoutMeta(wid, totalSeconds: const Value(null));
    w = await workoutById(wid);
    expect(w.totalSeconds, isNull);
    expect(w.feeling, '有点累');
  });

  group('阶段 2：方案与达标', () {
    Future<ExercisePlan> planById(int id) async =>
        (await db.getExercisePlan(id))!;

    Future<PlanEvaluation> evaluateById(int wid) async {
      final w = (await db.getWorkout(wid))!;
      return AppDatabase.evaluateWorkout(
          w, await db.getWorkoutExercises(wid), await db.getWorkoutSets(wid));
    }

    /// 建一场关联方案的已完成训练，含一个同名动作
    Future<({int workoutId, int exerciseId})> linkedWorkout(
      ExercisePlan plan, {
      DateTime? date,
    }) async {
      final wid = await db.insertCompletedWorkout(date: date ?? t0);
      await db.linkPlanToWorkout(wid, plan);
      final eid = await db.addWorkoutExercise(wid,
          name: plan.exerciseName, category: plan.category);
      return (workoutId: wid, exerciseId: eid);
    }

    test('sets 指标下无效组不参与达标', () async {
      final pid = await db.insertExercisePlan(
        name: '深蹲方案',
        exerciseName: '深蹲',
        category: ExerciseCategory.resistance,
        metric: PlanMetric.sets,
        minThreshold: 2,
        regularThreshold: 3,
      );
      final w = await linkedWorkout(await planById(pid));
      // 无效组：次数为 0、全空、时长为 0
      await db.addWorkoutSet(w.exerciseId, reps: 0);
      await db.addWorkoutSet(w.exerciseId);
      await db.addWorkoutSet(w.exerciseId, durationSeconds: 0);
      var ev = await evaluateById(w.workoutId);
      expect(ev.actual, 0);
      expect(ev.tier, PlanTier.belowMin);

      // 补两条有效组后达到最低
      await db.addWorkoutSet(w.exerciseId, reps: 10);
      await db.addWorkoutSet(w.exerciseId, reps: 10);
      ev = await evaluateById(w.workoutId);
      expect(ev.actual, 2);
      expect(ev.tier, PlanTier.min);
    });

    test('duration 与 sets 指标各自的 belowMin / min / regular 判定', () async {
      final durationPid = await db.insertExercisePlan(
        name: '步行方案',
        exerciseName: '步行',
        category: ExerciseCategory.cardio,
        metric: PlanMetric.duration,
        minThreshold: 900, // 15 分钟
        regularThreshold: 1800, // 30 分钟
      );
      final durationPlan = await planById(durationPid);

      // duration：600 秒未达最低
      var w = await linkedWorkout(durationPlan);
      await db.addWorkoutSet(w.exerciseId, durationSeconds: 600);
      var ev = await evaluateById(w.workoutId);
      expect(ev.actual, 600);
      expect(ev.tier, PlanTier.belowMin);

      // duration：1200 秒达最低
      w = await linkedWorkout(durationPlan);
      await db.addWorkoutSet(w.exerciseId, durationSeconds: 1200);
      ev = await evaluateById(w.workoutId);
      expect(ev.tier, PlanTier.min);

      // duration：两条时长组累计 2000 秒达常规
      w = await linkedWorkout(durationPlan);
      await db.addWorkoutSet(w.exerciseId, durationSeconds: 1200);
      await db.addWorkoutSet(w.exerciseId, durationSeconds: 800);
      ev = await evaluateById(w.workoutId);
      expect(ev.actual, 2000);
      expect(ev.tier, PlanTier.regular);

      final setsPid = await db.insertExercisePlan(
        name: '俯卧撑方案',
        exerciseName: '俯卧撑',
        category: ExerciseCategory.resistance,
        metric: PlanMetric.sets,
        minThreshold: 2,
        regularThreshold: 3,
      );
      final setsPlan = await planById(setsPid);

      // sets：1 组未达最低
      w = await linkedWorkout(setsPlan);
      await db.addWorkoutSet(w.exerciseId, reps: 8);
      ev = await evaluateById(w.workoutId);
      expect(ev.actual, 1);
      expect(ev.tier, PlanTier.belowMin);

      // sets：2 组达最低
      w = await linkedWorkout(setsPlan);
      await db.addWorkoutSet(w.exerciseId, reps: 8);
      await db.addWorkoutSet(w.exerciseId, durationSeconds: 60);
      ev = await evaluateById(w.workoutId);
      expect(ev.actual, 2);
      expect(ev.tier, PlanTier.min);

      // sets：3 组达常规
      w = await linkedWorkout(setsPlan);
      for (var i = 0; i < 3; i++) {
        await db.addWorkoutSet(w.exerciseId, reps: 8);
      }
      ev = await evaluateById(w.workoutId);
      expect(ev.actual, 3);
      expect(ev.tier, PlanTier.regular);
    });

    test('不同名动作的记录不替代目标动作', () async {
      final pid = await db.insertExercisePlan(
        name: '步行方案',
        exerciseName: '步行',
        category: ExerciseCategory.cardio,
        metric: PlanMetric.duration,
        minThreshold: 900,
        regularThreshold: 1800,
      );
      final plan = await planById(pid);
      final wid = await db.insertCompletedWorkout(date: t0);
      await db.linkPlanToWorkout(wid, plan);
      // 大量其他动作的记录也不累计
      final running = await db.addWorkoutExercise(wid,
          name: '跑步', category: ExerciseCategory.cardio);
      await db.addWorkoutSet(running, durationSeconds: 3600);
      var ev = await evaluateById(wid);
      expect(ev.actual, 0);
      expect(ev.tier, PlanTier.belowMin);

      // 同名动作才累计
      final walking = await db.addWorkoutExercise(wid,
          name: '步行', category: ExerciseCategory.cardio);
      await db.addWorkoutSet(walking, durationSeconds: 300);
      ev = await evaluateById(wid);
      expect(ev.actual, 300);
      expect(ev.tier, PlanTier.belowMin);
    });

    test('未关联方案的训练评估为 none；方案表为空时每日状态为 noPlan', () async {
      final wid = await db.insertCompletedWorkout(date: t0, totalSeconds: 1800);
      final eid = await db.addWorkoutExercise(wid,
          name: '跑步', category: ExerciseCategory.cardio);
      await db.addWorkoutSet(eid, durationSeconds: 1800);

      final ev = await evaluateById(wid);
      expect(ev.tier, PlanTier.none);
      expect(ev.actual, 0);

      // 即使当天有已完成训练，方案表为空也不误判完成
      expect(await db.watchDailyStatus(t0).first, DailyStatus.noPlan);
    });

    test('补记关联方案后归属正确日期与周，并参与当天判定', () async {
      final pid = await db.insertExercisePlan(
        name: '深蹲方案',
        exerciseName: '深蹲',
        category: ExerciseCategory.resistance,
        metric: PlanMetric.sets,
        minThreshold: 2,
        regularThreshold: 3,
      );
      final w = await linkedWorkout(await planById(pid));

      // 归属正确日期与周
      final day = await db.watchCompletedWorkouts(t0).first;
      expect(day.single.id, w.workoutId);
      expect(day.single.date, AppDatabase.dateOnly(t0));
      expect(await db.watchCompletedWorkoutsInWeek(t0).first, hasLength(1));

      // 1 组：有已完成训练但未达最低 → recorded
      await db.addWorkoutSet(w.exerciseId, reps: 8);
      expect(await db.watchDailyStatus(t0).first, DailyStatus.recorded);

      // 2 组 → 最低完成；3 组 → 常规完成
      await db.addWorkoutSet(w.exerciseId, reps: 8);
      expect(await db.watchDailyStatus(t0).first, DailyStatus.minDone);
      await db.addWorkoutSet(w.exerciseId, reps: 8);
      expect(await db.watchDailyStatus(t0).first, DailyStatus.regularDone);
    });

    test('方案编辑阈值、删除方案后，历史训练按快照判定结果不变', () async {
      final pid = await db.insertExercisePlan(
        name: '步行方案',
        exerciseName: '步行',
        category: ExerciseCategory.cardio,
        metric: PlanMetric.duration,
        minThreshold: 900,
        regularThreshold: 1800,
      );
      final w = await linkedWorkout(await planById(pid));
      await db.addWorkoutSet(w.exerciseId, durationSeconds: 1200);
      expect((await evaluateById(w.workoutId)).tier, PlanTier.min);

      // 编辑方案阈值：快照不变，判定结果不变
      await db.updateExercisePlan(
        pid,
        name: '步行方案（加强版）',
        exerciseName: '步行',
        category: ExerciseCategory.cardio,
        metric: PlanMetric.duration,
        minThreshold: 3600,
        regularThreshold: 7200,
      );
      var workout = await workoutById(w.workoutId);
      expect(workout.planMin, 900);
      expect(workout.planRegular, 1800);
      expect((await evaluateById(w.workoutId)).tier, PlanTier.min);

      // 删除方案：训练与其动作、组原样保留，仍按快照判定
      await db.deleteExercisePlan(pid);
      expect(await db.select(db.exercisePlans).get(), isEmpty);
      workout = await workoutById(w.workoutId);
      expect(workout.planName, '步行方案');
      expect((await evaluateById(w.workoutId)).tier, PlanTier.min);
      expect(await db.getWorkoutExercises(w.workoutId), hasLength(1));
      expect(await db.getWorkoutSets(w.workoutId), hasLength(1));
    });

    test('增删组记录后重新 evaluate，档位随之变化', () async {
      final pid = await db.insertExercisePlan(
        name: '俯卧撑方案',
        exerciseName: '俯卧撑',
        category: ExerciseCategory.resistance,
        metric: PlanMetric.sets,
        minThreshold: 2,
        regularThreshold: 3,
      );
      final w = await linkedWorkout(await planById(pid));

      final s1 = await db.addWorkoutSet(w.exerciseId, reps: 8);
      expect((await evaluateById(w.workoutId)).tier, PlanTier.belowMin);
      await db.addWorkoutSet(w.exerciseId, reps: 8);
      expect((await evaluateById(w.workoutId)).tier, PlanTier.min);
      await db.addWorkoutSet(w.exerciseId, reps: 8);
      expect((await evaluateById(w.workoutId)).tier, PlanTier.regular);

      // 删掉一组回到最低，再删到只剩一组回到未达最低
      final sets = await db.getWorkoutSets(w.workoutId);
      await db.deleteWorkoutSet(sets.last.id);
      expect((await evaluateById(w.workoutId)).tier, PlanTier.min);
      await db.deleteWorkoutSet(s1);
      expect((await evaluateById(w.workoutId)).tier, PlanTier.belowMin);
    });

    test('休息标记可 upsert 与取消；有标记的当天状态为 rest，且不影响周统计', () async {
      // upsert：同一天重复标记只保留一行，备注被更新
      await db.setRestMark(t0, note: '膝盖不舒服');
      await db.setRestMark(t0, note: '出差');
      expect(await db.select(db.restMarks).get(), hasLength(1));
      var mark = await db.watchRestMark(t0).first;
      expect(mark, isNotNull);
      expect(mark!.note, '出差');
      expect(mark.date, AppDatabase.dateOnly(t0));

      // 有方案、无完成训练、有休息标记 → rest
      await db.insertExercisePlan(
        name: '步行方案',
        exerciseName: '步行',
        category: ExerciseCategory.cardio,
        metric: PlanMetric.duration,
        minThreshold: 900,
        regularThreshold: 1800,
      );
      expect(await db.watchDailyStatus(t0).first, DailyStatus.rest);
      // 休息标记不产生训练记录，周统计次数不受影响
      expect(await db.watchCompletedWorkoutsInWeek(t0).first, isEmpty);

      // 取消标记后恢复为 none
      await db.removeRestMark(t0);
      expect(await db.watchRestMark(t0).first, isNull);
      expect(await db.watchDailyStatus(t0).first, DailyStatus.none);
    });

    test('阈值校验：最低不大于 0 或常规低于最低时抛 ArgumentError', () async {
      expect(
        () => db.insertExercisePlan(
          name: 'x',
          exerciseName: 'x',
          category: ExerciseCategory.cardio,
          metric: PlanMetric.duration,
          minThreshold: 0,
          regularThreshold: 600,
        ),
        throwsArgumentError,
      );
      expect(
        () => db.insertExercisePlan(
          name: 'x',
          exerciseName: 'x',
          category: ExerciseCategory.cardio,
          metric: PlanMetric.sets,
          minThreshold: 3,
          regularThreshold: 2,
        ),
        throwsArgumentError,
      );
      final pid = await db.insertExercisePlan(
        name: 'x',
        exerciseName: 'x',
        category: ExerciseCategory.cardio,
        metric: PlanMetric.sets,
        minThreshold: 2,
        regularThreshold: 3,
      );
      expect(
        () => db.updateExercisePlan(
          pid,
          name: 'x',
          exerciseName: 'x',
          category: ExerciseCategory.cardio,
          metric: PlanMetric.sets,
          minThreshold: 5,
          regularThreshold: 4,
        ),
        throwsArgumentError,
      );
    });

    test('startWorkout 关联方案：写入快照并预添加动作；幂等时不改关联', () async {
      final pid = await db.insertExercisePlan(
        name: '晨间步行',
        exerciseName: '步行',
        category: ExerciseCategory.cardio,
        metric: PlanMetric.duration,
        minThreshold: 900,
        regularThreshold: 1800,
      );
      final plan = await planById(pid);
      final w = await db.startWorkout(now: t0, plan: plan);

      // 快照写入 + 预添加绑定动作
      expect(w.planId, pid);
      expect(w.planName, '晨间步行');
      expect(w.planExerciseName, '步行');
      expect(w.planMetric, PlanMetric.duration);
      expect(w.planMin, 900);
      expect(w.planRegular, 1800);
      final exercises = await db.getWorkoutExercises(w.id);
      expect(exercises.single.name, '步行');
      expect(exercises.single.category, ExerciseCategory.cardio);

      // 已有进行中训练时幂等返回，不关联新方案
      final pid2 = await db.insertExercisePlan(
        name: '俯卧撑方案',
        exerciseName: '俯卧撑',
        category: ExerciseCategory.resistance,
        metric: PlanMetric.sets,
        minThreshold: 2,
        regularThreshold: 3,
      );
      final w2 =
          await db.startWorkout(now: t0, plan: await planById(pid2));
      expect(w2.id, w.id);
      expect((await workoutById(w.id)).planId, pid);
    });
  });
}
