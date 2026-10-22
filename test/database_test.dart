import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hoi/database/database.dart';
import 'package:hoi/domain/rules/metric.dart';
import 'package:hoi/domain/rules/rule_ast.dart';
import 'package:hoi/domain/rules/rule_evaluator.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.withOptions(
      executor: NativeDatabase.memory(),
      seedBuiltIns: false,
    );
  });

  tearDown(() async {
    await db.close();
  });

  final t0 = DateTime(2026, 10, 5, 10); // 周一 10:00

  Future<Workout> workoutById(int id) async => (await db.getWorkout(id))!;

  Future<int> addCatalogExercise(
    String name,
    TrackingType trackingType, {
    ExerciseCategory category = ExerciseCategory.resistance,
  }) {
    return db.insertExercise(
      name: name,
      category: category,
      trackingType: trackingType,
    );
  }

  Future<WorkoutTemplateDefinition> createTemplate({
    required String name,
    required List<TemplateExerciseInput> exercises,
  }) async {
    final id = await db.createWorkoutTemplate(name: name, exercises: exercises);
    return (await db.getTemplateDefinition(id))!;
  }

  test('一场训练多个动作多组，日与周统计都只计 1 场', () async {
    final workoutId = await db.insertCompletedWorkout(
      startedAt: t0,
      endedAt: t0.add(const Duration(hours: 1)),
      totalSeconds: 3600,
    );
    final squat = await db.addWorkoutExercise(
      workoutId,
      name: '深蹲',
      category: ExerciseCategory.resistance,
    );
    final running = await db.addWorkoutExercise(
      workoutId,
      name: '跑步',
      category: ExerciseCategory.cardio,
    );
    await db.addWorkoutSet(squat, reps: 10, weightKg: 60);
    await db.addWorkoutSet(squat, reps: 10);
    await db.addWorkoutSet(running, durationSeconds: 1800);

    expect(await db.watchCompletedWorkouts(t0).first, hasLength(1));
    expect(await db.watchCompletedWorkoutsInWeek(t0).first, hasLength(1));
  });

  test('次数、时长、距离与扩展组事实均可保存', () async {
    final workoutId = await db.insertCompletedWorkout(
      startedAt: t0,
      endedAt: t0.add(const Duration(minutes: 30)),
    );
    final exerciseId = await db.addWorkoutExercise(
      workoutId,
      name: '综合训练',
      category: ExerciseCategory.functional,
    );
    await db.addWorkoutSet(
      exerciseId,
      reps: 12,
      durationSeconds: 90,
      distanceMeters: 250.5,
      weightKg: 20.5,
      assistanceKg: 5,
      rpe: 8,
      rir: 2,
      note: '第一组',
    );

    final set = (await db.getWorkoutSets(workoutId)).single;
    expect(set.reps, 12);
    expect(set.durationSeconds, 90);
    expect(set.distanceMeters, 250.5);
    expect(set.weightKg, 20.5);
    expect(set.assistanceKg, 5);
    expect(set.rpe, 8);
    expect(set.rir, 2);
    expect(set.note, '第一组');
    expect(AppDatabase.isValidSet(set), isTrue);
  });

  test('暂停、恢复和结束计时排除暂停段', () async {
    final workout = await db.startWorkout(now: t0);
    await db.pauseWorkout(workout.id, now: t0.add(const Duration(minutes: 5)));
    await db.resumeWorkout(
      workout.id,
      now: t0.add(const Duration(minutes: 15)),
    );
    final exerciseId = await db.addWorkoutExercise(
      workout.id,
      name: '慢跑',
      category: ExerciseCategory.cardio,
    );
    await db.addWorkoutSet(exerciseId, durationSeconds: 600);
    await db.finishWorkout(
      workout.id,
      now: t0.add(const Duration(minutes: 25)),
    );

    final completed = await workoutById(workout.id);
    expect(completed.status, WorkoutStatus.completed);
    expect(completed.pausedSeconds, 600);
    expect(completed.totalSeconds, 900);
  });

  test('startWorkout 幂等，且无有效组不能结束', () async {
    final first = await db.startWorkout(now: t0);
    final second = await db.startWorkout(
      now: t0.add(const Duration(minutes: 1)),
    );
    expect(second.id, first.id);
    expect(await db.select(db.workouts).get(), hasLength(1));

    expect(() => db.finishWorkout(first.id), throwsStateError);
    final exerciseId = await db.addWorkoutExercise(
      first.id,
      name: '拉伸',
      category: ExerciseCategory.functional,
    );
    await db.addWorkoutSet(exerciseId, durationSeconds: 0);
    expect(() => db.finishWorkout(first.id), throwsStateError);
    await db.addWorkoutSet(exerciseId, reps: 5);
    await db.finishWorkout(first.id, now: t0.add(const Duration(minutes: 10)));
    expect((await workoutById(first.id)).status, WorkoutStatus.completed);
  });

  test('discardWorkout 显式级联删除动作与组', () async {
    final workout = await db.startWorkout(now: t0);
    final exerciseId = await db.addWorkoutExercise(
      workout.id,
      name: '硬拉',
      category: ExerciseCategory.resistance,
    );
    await db.addWorkoutSet(exerciseId, reps: 8, weightKg: 80);

    await db.discardWorkout(workout.id);

    expect(await db.select(db.workouts).get(), isEmpty);
    expect(await db.select(db.workoutExercises).get(), isEmpty);
    expect(await db.select(db.workoutSets).get(), isEmpty);
  });

  test('updateWorkoutMeta 可修改并清空可空字段', () async {
    final workoutId = await db.insertCompletedWorkout(
      startedAt: t0,
      endedAt: t0.add(const Duration(minutes: 30)),
      totalSeconds: 1800,
      feeling: '轻松',
    );
    await db.updateWorkoutMeta(workoutId, feeling: const Value('有点累'));
    await db.updateWorkoutMeta(workoutId, totalSeconds: const Value(null));

    final workout = await workoutById(workoutId);
    expect(workout.totalSeconds, isNull);
    expect(workout.feeling, '有点累');
  });

  test('每日状态可按日期保存、更新并在全部清空时删除', () async {
    await db.saveDailyCheckin(
      t0,
      sleepRating: 4,
      stressRating: 2,
      note: '状态平稳',
      now: t0,
    );
    var checkin = await db.watchDailyCheckin(t0).first;
    expect(checkin?.sleepRating, 4);
    expect(checkin?.stressRating, 2);
    expect(checkin?.note, '状态平稳');

    await db.saveDailyCheckin(
      t0,
      sleepRating: 5,
      note: '  睡得很好  ',
      now: t0.add(const Duration(hours: 1)),
    );
    checkin = await db.watchDailyCheckin(t0).first;
    expect(checkin?.sleepRating, 5);
    expect(checkin?.stressRating, isNull);
    expect(checkin?.note, '睡得很好');

    await db.saveDailyCheckin(t0, note: '   ');
    expect(await db.watchDailyCheckin(t0).first, isNull);
    expect(() => db.saveDailyCheckin(t0, sleepRating: 6), throwsArgumentError);
  });

  test('补记保存起止时间并按开始日期归属，拒绝反向区间', () async {
    final end = t0.add(const Duration(days: 1, minutes: 30));
    final workoutId = await db.insertCompletedWorkout(
      startedAt: t0.add(const Duration(hours: 13, minutes: 30)),
      endedAt: end,
    );
    final workout = await workoutById(workoutId);
    expect(workout.date, AppDatabase.dateOnly(t0));
    expect(workout.startedAt, t0.add(const Duration(hours: 13, minutes: 30)));
    expect(workout.endedAt, end);
    expect(workout.totalSeconds, 11 * 3600);

    expect(
      () => db.insertCompletedWorkout(startedAt: end, endedAt: t0),
      throwsArgumentError,
    );
  });

  test('首次打开会激活动作目录与每周基础运动预设', () async {
    await db.close();
    final directory = Directory.systemTemp.createTempSync('hoi-presets-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/presets.sqlite');
    final seeded = AppDatabase(NativeDatabase(file));
    addTearDown(seeded.close);

    final exercises = await seeded.watchExercises().first;
    expect(exercises, hasLength(AppDatabase.builtInExercisePresets.length));
    expect(
      exercises.map((exercise) => exercise.builtinKey).toSet(),
      AppDatabase.builtInExercisePresets.map((preset) => preset.key).toSet(),
    );

    final rules = await seeded.watchRuleSets().first;
    expect(rules, hasLength(1));
    expect(rules.single.presetKey, 'weekly_consistency');
    final expression = seeded.decodeRuleExpression(rules.single) as AllRule;
    expect(expression.children, hasLength(2));

    final progress = await seeded.evaluateRuleSets(t0);
    expect(progress.single.evaluation.children[0].actual, 0);
    expect(progress.single.evaluation.children[0].target, 3);
    expect(progress.single.evaluation.children[1].actual, 0);
    expect(progress.single.evaluation.children[1].target, 90 * 60);

    expect(
      await seeded.activateRuleSetPreset('weekly_consistency'),
      rules.single.id,
    );
    await seeded.archiveRuleSet(rules.single.id, now: t0);
    final reactivated = await seeded.activateRuleSetPreset(
      'weekly_consistency',
      effectiveFromDate: t0,
      now: t0,
    );
    expect(reactivated, isNot(rules.single.id));
    expect(await seeded.watchRuleSets().first, hasLength(1));

    await seeded.close();
    final reopened = AppDatabase(NativeDatabase(file));
    addTearDown(reopened.close);
    expect(await reopened.watchRuleSets().first, hasLength(1));
    expect(await reopened.watchExercises().first, hasLength(exercises.length));
  });

  test('v3 升到 v6 会重置旧表，第二次打开不会再次清空', () async {
    await db.close();
    final directory = Directory.systemTemp.createTempSync('hoi-v6-reset-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/legacy.sqlite');
    final legacyTables = [
      'workout_sets',
      'workout_exercises',
      'workouts',
      'exercise_plans',
      'rest_marks',
      'weekly_exercise_goals',
      'favorite_foods',
      'food_entries',
    ];
    final migrated = AppDatabase.withOptions(
      executor: NativeDatabase(
        file,
        setup: (raw) {
          for (final table in legacyTables) {
            raw.execute('CREATE TABLE $table (id INTEGER PRIMARY KEY)');
            raw.execute('INSERT INTO $table DEFAULT VALUES');
          }
          raw.execute('PRAGMA user_version = 3');
        },
      ),
      seedBuiltIns: false,
    );
    final exerciseId = await migrated.insertExercise(
      name: '迁移后动作',
      category: ExerciseCategory.functional,
      trackingType: TrackingType.reps,
    );
    expect(await migrated.select(migrated.foodEntries).get(), isEmpty);
    expect(await migrated.select(migrated.exercises).get(), hasLength(1));
    await migrated.close();

    final reopened = AppDatabase.withOptions(
      executor: NativeDatabase(file),
      seedBuiltIns: false,
    );
    addTearDown(reopened.close);
    expect((await reopened.getExercise(exerciseId))?.name, '迁移后动作');
  });

  test('v4 升到 v6 保留动作与规则、移除旧周目标并建立每日状态表', () async {
    await db.close();
    final directory = Directory.systemTemp.createTempSync('hoi-v6-migration-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/v4.sqlite');
    final migrated = AppDatabase.withOptions(
      executor: NativeDatabase(
        file,
        setup: (raw) {
          raw.execute('''
            CREATE TABLE exercises (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              category TEXT NOT NULL,
              tracking_type TEXT NOT NULL,
              load_convention TEXT NOT NULL,
              reps_convention TEXT NOT NULL,
              archived_at INTEGER NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          raw.execute('''
            CREATE TABLE rule_sets (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              period TEXT NOT NULL,
              effective_from_date INTEGER NOT NULL,
              effective_until_date INTEGER NULL,
              combine_mode TEXT NOT NULL,
              expression_json TEXT NOT NULL,
              evaluation_policy_version INTEGER NOT NULL,
              archived_at INTEGER NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          raw.execute('''
            CREATE TABLE weekly_exercise_goals (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              target_sessions INTEGER NOT NULL,
              target_minutes INTEGER NOT NULL
            )
          ''');
          raw.execute('''
            INSERT INTO exercises (
              name, category, tracking_type, load_convention,
              reps_convention, created_at
            ) VALUES ('旧动作', 'resistance', 'reps', 'none', 'total', 0)
          ''');
          raw.execute('''
            INSERT INTO rule_sets (
              name, period, effective_from_date, combine_mode,
              expression_json, evaluation_policy_version, created_at
            ) VALUES (
              '旧目标', 'week', 0, 'all',
              '{"type":"all","children":[{"type":"comparison","metric":"session_count","operator":">=","target":1}]}',
              1, 0
            )
          ''');
          raw.execute('''
            INSERT INTO weekly_exercise_goals (target_sessions, target_minutes)
            VALUES (3, 90)
          ''');
          raw.execute('PRAGMA user_version = 4');
        },
      ),
      seedBuiltIns: false,
    );
    addTearDown(migrated.close);

    final exercise = (await migrated.select(migrated.exercises).get()).single;
    final rule = (await migrated.select(migrated.ruleSets).get()).single;
    expect(exercise.name, '旧动作');
    expect(exercise.builtinKey, isNull);
    expect(rule.name, '旧目标');
    expect(rule.presetKey, isNull);
    await migrated.saveDailyCheckin(t0, sleepRating: 4);
    expect((await migrated.watchDailyCheckin(t0).first)?.sleepRating, 4);
    final oldTable = await migrated
        .customSelect(
          "SELECT name FROM sqlite_master WHERE name = 'weekly_exercise_goals'",
        )
        .get();
    expect(oldTable, isEmpty);
  });

  group('阶段 1：动作身份与模板版本', () {
    test('一个模板版本支持多个动作，每个动作支持多个计划组', () async {
      final squatId = await addCatalogExercise('深蹲', TrackingType.reps);
      final runId = await addCatalogExercise(
        '跑步',
        TrackingType.distance,
        category: ExerciseCategory.cardio,
      );
      final definition = await createTemplate(
        name: '全身训练',
        exercises: [
          TemplateExerciseInput(
            exerciseId: squatId,
            sets: const [
              TemplateSetInput(reps: 8, minimumReps: 5),
              TemplateSetInput(reps: 8),
            ],
          ),
          TemplateExerciseInput(
            exerciseId: runId,
            sets: const [
              TemplateSetInput(
                distanceMeters: 1000,
                minimumDistanceMeters: 500,
              ),
            ],
          ),
        ],
      );

      expect(definition.exercises, hasLength(2));
      expect(definition.sets, hasLength(3));
      expect(definition.exercises.map((e) => e.exerciseId), [squatId, runId]);
      expect(definition.exercises.first.exerciseNameSnapshot, '深蹲');
      expect(
        definition.exercises.last.trackingTypeSnapshot,
        TrackingType.distance,
      );
    });

    test('按模板开始训练复制动作快照，实际组自动关联下一个计划组', () async {
      final exerciseId = await addCatalogExercise('俯卧撑', TrackingType.reps);
      final definition = await createTemplate(
        name: '俯卧撑三组',
        exercises: [
          TemplateExerciseInput(
            exerciseId: exerciseId,
            sets: const [
              TemplateSetInput(reps: 10, minimumReps: 5),
              TemplateSetInput(reps: 10),
              TemplateSetInput(reps: 10),
            ],
          ),
        ],
      );
      final workout = await db.startWorkout(
        now: t0,
        templateVersion: definition.version,
      );
      final actualExercise = (await db.getWorkoutExercises(workout.id)).single;
      expect(actualExercise.catalogExerciseId, exerciseId);
      expect(actualExercise.templateExerciseId, definition.exercises.single.id);
      expect(actualExercise.name, '俯卧撑');

      await db.addWorkoutSet(actualExercise.id, reps: 6);
      await db.addWorkoutSet(actualExercise.id, reps: 10);
      await db.addWorkoutSet(actualExercise.id, reps: 10);
      final actualSets = await db.getWorkoutSets(workout.id);
      expect(
        actualSets.map((set) => set.templateSetId),
        definition.sets.map((set) => set.id),
      );
      final progress = await db.evaluateWorkoutTemplate(workout.id);
      expect(progress.minimumCompleted, 1);
      expect(progress.minimumTotal, 1);
      expect(progress.regularCompleted, 2);
      expect(progress.regularTotal, 3);
      expect(progress.tier, PlanTier.min);
    });

    test('未配置最低量时仍可记录，只有常规全部完成才达常规', () async {
      final exerciseId = await addCatalogExercise(
        '平板支撑',
        TrackingType.duration,
      );
      final definition = await createTemplate(
        name: '平板支撑',
        exercises: [
          TemplateExerciseInput(
            exerciseId: exerciseId,
            sets: const [TemplateSetInput(durationSeconds: 60)],
          ),
        ],
      );
      final workout = await db.startWorkout(
        templateVersion: definition.version,
      );
      final actualExercise = (await db.getWorkoutExercises(workout.id)).single;

      await db.addWorkoutSet(actualExercise.id, durationSeconds: 30);
      var progress = await db.evaluateWorkoutTemplate(workout.id);
      expect(progress.minimumTotal, 0);
      expect(progress.tier, PlanTier.belowMin);

      await db.updateWorkoutSet(
        (await db.getWorkoutSets(workout.id)).single.id,
        durationSeconds: const Value(60),
      );
      progress = await db.evaluateWorkoutTemplate(workout.id);
      expect(progress.tier, PlanTier.regular);
    });

    test('跳过组和零值组不完成计划，计划外动作与额外组被保留', () async {
      final exerciseId = await addCatalogExercise('深蹲', TrackingType.reps);
      final definition = await createTemplate(
        name: '深蹲',
        exercises: [
          TemplateExerciseInput(
            exerciseId: exerciseId,
            sets: const [TemplateSetInput(reps: 8, minimumReps: 5)],
          ),
        ],
      );
      final workout = await db.startWorkout(
        templateVersion: definition.version,
      );
      final plannedExercise = (await db.getWorkoutExercises(workout.id)).single;
      await db.addWorkoutSet(
        plannedExercise.id,
        reps: 8,
        setStatus: SetStatus.skipped,
      );
      await db.addWorkoutSet(plannedExercise.id, reps: 0);
      var progress = await db.evaluateWorkoutTemplate(workout.id);
      expect(progress.tier, PlanTier.belowMin);

      // 两个计划组槽位已占用，后续记录成为额外组，不会错误替代已跳过的计划组。
      final extraSetId = await db.addWorkoutSet(plannedExercise.id, reps: 20);
      final extraSet = (await db.getWorkoutSets(workout.id))
          .firstWhere((set) => set.id == extraSetId);
      expect(extraSet.templateSetId, isNull);
      final extraExerciseId = await db.addWorkoutExercise(
        workout.id,
        name: '散步',
        category: ExerciseCategory.cardio,
      );
      await db.addWorkoutSet(extraExerciseId, durationSeconds: 600);
      expect(await db.getWorkoutExercises(workout.id), hasLength(2));
      progress = await db.evaluateWorkoutTemplate(workout.id);
      expect(progress.tier, PlanTier.belowMin);
    });

    test('修订创建新版本，旧训练继续按原版本和动作快照解释', () async {
      final exerciseId = await addCatalogExercise(
        '步行',
        TrackingType.duration,
        category: ExerciseCategory.cardio,
      );
      final v1 = await createTemplate(
        name: '晨间步行',
        exercises: [
          TemplateExerciseInput(
            exerciseId: exerciseId,
            sets: const [
              TemplateSetInput(
                durationSeconds: 1800,
                minimumDurationSeconds: 900,
              ),
            ],
          ),
        ],
      );
      final workout = await db.startWorkout(templateVersion: v1.version);
      final actualExercise = (await db.getWorkoutExercises(workout.id)).single;
      await db.addWorkoutSet(actualExercise.id, durationSeconds: 1200);
      expect((await db.evaluateWorkoutTemplate(workout.id)).tier, PlanTier.min);

      await db.updateExercise(
        exerciseId,
        name: '快走',
        category: ExerciseCategory.cardio,
        trackingType: TrackingType.duration,
      );
      await db.reviseWorkoutTemplate(
        v1.template.id,
        name: '晨间快走',
        exercises: [
          TemplateExerciseInput(
            exerciseId: exerciseId,
            sets: const [
              TemplateSetInput(
                durationSeconds: 3600,
                minimumDurationSeconds: 1800,
              ),
            ],
          ),
        ],
      );

      final current = (await db.getTemplateDefinition(v1.template.id))!;
      final old = (await db.getTemplateDefinitionByVersion(v1.version.id))!;
      expect(current.version.versionNumber, 2);
      expect(current.exercises.single.exerciseNameSnapshot, '快走');
      expect(old.version.versionNumber, 1);
      expect(old.exercises.single.exerciseNameSnapshot, '步行');
      expect((await workoutById(workout.id)).templateVersionId, v1.version.id);
      expect(
        (await workoutById(workout.id)).templateEvaluationPolicyVersion,
        1,
      );
      expect((await db.evaluateWorkoutTemplate(workout.id)).tier, PlanTier.min);
    });

    test('归档模板和动作不删除历史训练或不可变版本', () async {
      final exerciseId = await addCatalogExercise('划船', TrackingType.reps);
      final definition = await createTemplate(
        name: '划船训练',
        exercises: [
          TemplateExerciseInput(
            exerciseId: exerciseId,
            sets: const [TemplateSetInput(reps: 10)],
          ),
        ],
      );
      final workout = await db.startWorkout(
        templateVersion: definition.version,
      );
      final actualExercise = (await db.getWorkoutExercises(workout.id)).single;
      await db.addWorkoutSet(actualExercise.id, reps: 10);
      await db.archiveWorkoutTemplate(definition.template.id, now: t0);
      await db.archiveExercise(exerciseId, now: t0);

      expect(await db.watchWorkoutTemplates().first, isEmpty);
      expect(await db.watchExercises().first, isEmpty);
      expect(
        await db.getTemplateDefinitionByVersion(definition.version.id),
        isNotNull,
      );
      expect(await db.getWorkout(workout.id), isNotNull);
      expect(await db.getWorkoutExercises(workout.id), hasLength(1));
      expect(
        (await db.evaluateWorkoutTemplate(workout.id)).tier,
        PlanTier.regular,
      );
    });

    test('模板校验拒绝空模板、空计划组与不合法最低量', () async {
      final exerciseId = await addCatalogExercise('深蹲', TrackingType.reps);
      expect(
        () => db.createWorkoutTemplate(name: '空模板', exercises: const []),
        throwsArgumentError,
      );
      expect(
        () => db.createWorkoutTemplate(
          name: '空动作',
          exercises: [
            TemplateExerciseInput(exerciseId: exerciseId, sets: const []),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => db.createWorkoutTemplate(
          name: '错误最低量',
          exercises: [
            TemplateExerciseInput(
              exerciseId: exerciseId,
              sets: const [TemplateSetInput(reps: 5, minimumReps: 6)],
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('每日状态区分无方案、休息、已记录、最低与常规', () async {
      expect(await db.watchDailyStatus(t0).first, DailyStatus.noPlan);
      final exerciseId = await addCatalogExercise('俯卧撑', TrackingType.reps);
      final definition = await createTemplate(
        name: '俯卧撑',
        exercises: [
          TemplateExerciseInput(
            exerciseId: exerciseId,
            sets: const [TemplateSetInput(reps: 10, minimumReps: 5)],
          ),
        ],
      );
      await db.setRestMark(t0, note: '恢复');
      expect(await db.watchDailyStatus(t0).first, DailyStatus.rest);
      await db.removeRestMark(t0);
      expect(await db.watchDailyStatus(t0).first, DailyStatus.none);

      final workout = await db.startWorkout(
        now: t0,
        templateVersion: definition.version,
      );
      final actualExercise = (await db.getWorkoutExercises(workout.id)).single;
      final setId = await db.addWorkoutSet(actualExercise.id, reps: 3);
      await db.finishWorkout(
        workout.id,
        now: t0.add(const Duration(minutes: 10)),
      );
      expect(await db.watchDailyStatus(t0).first, DailyStatus.recorded);
      await db.updateWorkoutSet(setId, reps: const Value(6));
      expect(await db.watchDailyStatus(t0).first, DailyStatus.minDone);
      await db.updateWorkoutSet(setId, reps: const Value(10));
      expect(await db.watchDailyStatus(t0).first, DailyStatus.regularDone);
    });
  });

  group('阶段 3：周期目标持久化', () {
    test('RuleSet JSON 持久化后可按周读取事实并评估 ALL', () async {
      final runningId = await addCatalogExercise(
        '跑步',
        TrackingType.duration,
        category: ExerciseCategory.cardio,
      );
      for (var i = 0; i < 3; i++) {
        final workoutId = await db.insertCompletedWorkout(
          startedAt: t0.add(Duration(days: i)),
          endedAt: t0.add(Duration(days: i, minutes: 10)),
        );
        final exerciseId = await db.addWorkoutExercise(
          workoutId,
          name: '跑步',
          category: ExerciseCategory.cardio,
          catalogExerciseId: runningId,
          trackingType: TrackingType.duration,
        );
        await db.addWorkoutSet(exerciseId, durationSeconds: 600);
      }
      final expression = AllRule([
        const ComparisonRule(
          metricId: 'session_count',
          operator: ComparisonOperator.greaterOrEqual,
          target: 3,
        ),
        ComparisonRule(
          metricId: 'duration',
          filters: MetricFilters(exerciseId: runningId),
          operator: ComparisonOperator.greaterOrEqual,
          target: 1800,
        ),
      ]);
      final ruleId = await db.createRuleSet(
        name: '每周三次并跑满半小时',
        period: RulePeriod.week,
        effectiveFromDate: t0,
        combineMode: RuleCombineMode.all,
        expression: expression,
      );

      final saved = (await db.getRuleSet(ruleId))!;
      expect(db.decodeRuleExpression(saved), isA<AllRule>());
      final result = (await db.evaluateRuleSets(t0)).single;
      expect(result.ruleSet.id, ruleId);
      expect(result.evaluation.status, RuleResultStatus.passed);
      expect(result.evaluation.children.map((child) => child.actual), [
        3,
        1800,
      ]);
    });

    test('编辑与归档规则不改训练事实，生效日期会过滤规则', () async {
      final workoutId = await db.insertCompletedWorkout(
        startedAt: t0,
        endedAt: t0.add(const Duration(minutes: 30)),
      );
      final original = AllRule(const [
        ComparisonRule(
          metricId: 'session_count',
          operator: ComparisonOperator.greaterOrEqual,
          target: 2,
        ),
      ]);
      final ruleId = await db.createRuleSet(
        name: '每日两次',
        period: RulePeriod.day,
        effectiveFromDate: t0,
        effectiveUntilDate: t0,
        combineMode: RuleCombineMode.all,
        expression: original,
      );
      expect(
        (await db.evaluateRuleSets(t0)).single.evaluation.status,
        RuleResultStatus.partial,
      );
      expect(
        await db.evaluateRuleSets(t0.add(const Duration(days: 1))),
        isEmpty,
      );

      await db.updateRuleSetDefinition(
        ruleId,
        name: '每日一次',
        period: RulePeriod.day,
        effectiveFromDate: t0,
        effectiveUntilDate: t0,
        combineMode: RuleCombineMode.any,
        expression: AnyRule(const [
          ComparisonRule(
            metricId: 'session_count',
            operator: ComparisonOperator.greaterOrEqual,
            target: 1,
          ),
        ]),
      );
      expect(
        (await db.evaluateRuleSets(t0)).single.evaluation.status,
        RuleResultStatus.passed,
      );
      expect(await db.getWorkout(workoutId), isNotNull);
      await db.archiveRuleSet(ruleId, now: t0);
      expect(await db.watchRuleSets().first, isEmpty);
      expect(await db.getWorkout(workoutId), isNotNull);
    });

    test('不完整或根组合不一致的 RuleSet 不保存', () async {
      expect(
        () => db.createRuleSet(
          name: '',
          period: RulePeriod.week,
          effectiveFromDate: t0,
          combineMode: RuleCombineMode.all,
          expression: AllRule(const [
            ComparisonRule(
              metricId: 'session_count',
              operator: ComparisonOperator.greaterOrEqual,
              target: 1,
            ),
          ]),
        ),
        throwsArgumentError,
      );
      expect(
        () => db.createRuleSet(
          name: '错误组合',
          period: RulePeriod.week,
          effectiveFromDate: t0,
          combineMode: RuleCombineMode.all,
          expression: AnyRule(const [
            ComparisonRule(
              metricId: 'session_count',
              operator: ComparisonOperator.greaterOrEqual,
              target: 1,
            ),
          ]),
        ),
        throwsArgumentError,
      );
      expect(await db.select(db.ruleSets).get(), isEmpty);
    });

    test('RuleSet 在关闭并重新打开数据库后仍可恢复', () async {
      await db.close();
      final directory = Directory.systemTemp.createTempSync(
        'hoi-rule-persistence-',
      );
      final file = File('${directory.path}/rules.sqlite');
      try {
        final first = AppDatabase.withOptions(
          executor: NativeDatabase(file),
          seedBuiltIns: false,
        );
        await first.createRuleSet(
          name: '每周三次',
          period: RulePeriod.week,
          effectiveFromDate: t0,
          combineMode: RuleCombineMode.all,
          expression: AllRule(const [
            ComparisonRule(
              metricId: 'session_count',
              operator: ComparisonOperator.greaterOrEqual,
              target: 3,
            ),
          ]),
        );
        await first.close();

        final second = AppDatabase.withOptions(
          executor: NativeDatabase(file),
          seedBuiltIns: false,
        );
        final saved = (await second.watchRuleSets().first).single;
        expect(saved.name, '每周三次');
        expect(second.decodeRuleExpression(saved), isA<AllRule>());
        await second.close();
      } finally {
        directory.deleteSync(recursive: true);
      }
    });

    test('补记训练关联方案时自动绑定计划动作与计划组，取消关联时一并清理', () async {
      final pushupId = await addCatalogExercise('俯卧撑', TrackingType.reps);
      final definition = await createTemplate(
        name: '俯卧撑两组',
        exercises: [
          TemplateExerciseInput(
            exerciseId: pushupId,
            sets: const [
              TemplateSetInput(reps: 10, minimumReps: 5),
              TemplateSetInput(reps: 10),
            ],
          ),
        ],
      );

      // 模拟补记：先插入训练、动作和组（未传 templateExerciseId / templateSetId），再关联方案
      final workoutId = await db.insertCompletedWorkout(
        startedAt: t0,
        endedAt: t0.add(const Duration(minutes: 20)),
      );
      final exerciseId = await db.addWorkoutExercise(
        workoutId,
        name: '俯卧撑',
        category: ExerciseCategory.resistance,
        catalogExerciseId: pushupId,
        trackingType: TrackingType.reps,
      );
      await db.addWorkoutSet(exerciseId, reps: 10);
      await db.addWorkoutSet(exerciseId, reps: 10);
      await db.linkTemplateToWorkout(workoutId, definition.version);

      final progress = await db.evaluateWorkoutTemplate(workoutId);
      expect(progress.tier, PlanTier.regular);
      expect(progress.regularCompleted, 2);
      expect(progress.minimumCompleted, 1);

      final weekStatuses = await db.watchWeekDailyStatus(t0).first;
      expect(weekStatuses[AppDatabase.dateOnly(t0)], DailyStatus.regularDone);

      // 取消方案关联后，动作与组上的计划槽位引用应一并清空
      await db.clearTemplateLink(workoutId);
      final afterExercises = await db.getWorkoutExercises(workoutId);
      final afterSets = await db.getWorkoutSets(workoutId);
      expect(afterExercises.single.templateExerciseId, isNull);
      expect(afterSets.every((s) => s.templateSetId == null), isTrue);
      expect((await db.evaluateWorkoutTemplate(workoutId)).tier, PlanTier.none);
    });

    test('同日已完成训练按开始时间升序排列（相同开始时间按 id 兜底）', () async {
      final eveningId = await db.insertCompletedWorkout(
        startedAt: t0.add(const Duration(hours: 8)),
        endedAt: t0.add(const Duration(hours: 9)),
      );
      final morningId = await db.insertCompletedWorkout(
        startedAt: t0,
        endedAt: t0.add(const Duration(hours: 1)),
      );
      final morningTieId = await db.insertCompletedWorkout(
        startedAt: t0,
        endedAt: t0.add(const Duration(minutes: 30)),
      );

      final list = await db.watchCompletedWorkouts(t0).first;
      expect(list.map((w) => w.id).toList(), [
        morningId,
        morningTieId,
        eveningId,
      ]);
    });

    test('动作目录支持全局重排与按分类局部重排', () async {
      final runId = await addCatalogExercise(
        '跑步',
        TrackingType.distance,
        category: ExerciseCategory.cardio,
      );
      final squatId = await addCatalogExercise(
        '深蹲',
        TrackingType.reps,
        category: ExerciseCategory.resistance,
      );
      final ropeId = await addCatalogExercise(
        '跳绳',
        TrackingType.duration,
        category: ExerciseCategory.cardio,
      );
      final plankId = await addCatalogExercise(
        '平板支撑',
        TrackingType.duration,
        category: ExerciseCategory.core,
      );

      expect(
        (await db.getExercises()).map((e) => e.id).toList(),
        [runId, squatId, ropeId, plankId],
      );

      // 仅对「心肺」分类下的 [runId, ropeId] 局部重排为 [ropeId, runId]，其它分类槽位保持不变
      await db.reorderExercises([ropeId, runId]);
      expect(
        (await db.getExercises()).map((e) => e.id).toList(),
        [ropeId, squatId, runId, plankId],
      );

      // 全局重排
      await db.reorderExercises([plankId, squatId, ropeId, runId]);
      final reordered = await db.getExercises();
      expect(reordered.map((e) => e.id).toList(), [
        plankId,
        squatId,
        ropeId,
        runId,
      ]);
      expect(reordered.map((e) => e.sortOrder).toList(), [0, 1, 2, 3]);
    });
  });
}
