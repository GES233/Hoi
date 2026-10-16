part of '../database.dart';

extension TemplateDao on AppDatabase {
  // ---- 训练模板 ----

  Stream<List<WorkoutTemplateSummary>> watchWorkoutTemplates({
    bool includeArchived = false,
  }) {
    final query =
        select(workoutTemplates).join([
            innerJoin(
              templateVersions,
              templateVersions.templateId.equalsExp(workoutTemplates.id) &
                  templateVersions.versionNumber.equalsExp(
                    workoutTemplates.currentVersionNumber,
                  ),
            ),
          ])
          ..where(
            includeArchived
                ? const Constant(true)
                : workoutTemplates.archivedAt.isNull(),
          )
          ..orderBy([OrderingTerm.asc(workoutTemplates.createdAt)]);
    return query
        .map(
          (row) => WorkoutTemplateSummary(
            row.readTable(workoutTemplates),
            row.readTable(templateVersions),
          ),
        )
        .watch();
  }

  Future<TemplateVersion?> getTemplateVersion(int id) => (select(
    templateVersions,
  )..where((v) => v.id.equals(id))).getSingleOrNull();

  Future<WorkoutTemplateDefinition?> getTemplateDefinition(
    int templateId,
  ) async {
    final template = await (select(
      workoutTemplates,
    )..where((t) => t.id.equals(templateId))).getSingleOrNull();
    if (template == null) return null;
    final version =
        await (select(templateVersions)..where(
              (v) =>
                  v.templateId.equals(templateId) &
                  v.versionNumber.equals(template.currentVersionNumber),
            ))
            .getSingle();
    return _getTemplateDefinition(template, version);
  }

  Future<WorkoutTemplateDefinition?> getTemplateDefinitionByVersion(
    int versionId,
  ) async {
    final version = await getTemplateVersion(versionId);
    if (version == null) return null;
    final template = await (select(
      workoutTemplates,
    )..where((t) => t.id.equals(version.templateId))).getSingle();
    return _getTemplateDefinition(template, version);
  }

  Future<WorkoutTemplateDefinition> _getTemplateDefinition(
    WorkoutTemplate template,
    TemplateVersion version,
  ) async {
    final plannedExercises =
        await (select(templateExercises)
              ..where((e) => e.templateVersionId.equals(version.id))
              ..orderBy([(e) => OrderingTerm.asc(e.sortOrder)]))
            .get();
    final ids = plannedExercises.map((e) => e.id).toList();
    final plannedSets = ids.isEmpty
        ? <TemplateSet>[]
        : await (select(templateSets)
                ..where((s) => s.templateExerciseId.isIn(ids))
                ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
              .get();
    return WorkoutTemplateDefinition(
      template: template,
      version: version,
      exercises: plannedExercises,
      sets: plannedSets,
    );
  }

  Future<int> createWorkoutTemplate({
    required String name,
    required List<TemplateExerciseInput> exercises,
    String? note,
    DateTime? now,
  }) async {
    _validateTemplate(name, exercises);
    final t = now ?? DateTime.now();
    return transaction(() async {
      final templateId = await into(workoutTemplates).insert(
        WorkoutTemplatesCompanion.insert(currentVersionNumber: 1, createdAt: t),
      );
      await _insertTemplateVersion(
        templateId: templateId,
        versionNumber: 1,
        name: name.trim(),
        note: note,
        inputs: exercises,
        createdAt: t,
      );
      return templateId;
    });
  }

  Future<void> reviseWorkoutTemplate(
    int templateId, {
    required String name,
    required List<TemplateExerciseInput> exercises,
    String? note,
    DateTime? now,
  }) async {
    _validateTemplate(name, exercises);
    final template = await (select(
      workoutTemplates,
    )..where((t) => t.id.equals(templateId))).getSingle();
    final next = template.currentVersionNumber + 1;
    await transaction(() async {
      await _insertTemplateVersion(
        templateId: templateId,
        versionNumber: next,
        name: name.trim(),
        note: note,
        inputs: exercises,
        createdAt: now ?? DateTime.now(),
      );
      await (update(workoutTemplates)..where((t) => t.id.equals(templateId)))
          .write(WorkoutTemplatesCompanion(currentVersionNumber: Value(next)));
    });
  }

  static void _validateTemplate(
    String name,
    List<TemplateExerciseInput> inputs,
  ) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', '模板名称不能为空');
    }
    if (inputs.isEmpty) {
      throw ArgumentError.value(inputs, 'exercises', '模板至少需要一个动作');
    }
    if (inputs.any((e) => e.sets.isEmpty)) {
      throw ArgumentError.value(inputs, 'exercises', '每个模板动作至少需要一个计划组');
    }
  }

  Future<void> _insertTemplateVersion({
    required int templateId,
    required int versionNumber,
    required String name,
    required String? note,
    required List<TemplateExerciseInput> inputs,
    required DateTime createdAt,
  }) async {
    final versionId = await into(templateVersions).insert(
      TemplateVersionsCompanion.insert(
        templateId: templateId,
        versionNumber: versionNumber,
        name: name,
        note: Value(note),
        createdAt: createdAt,
      ),
    );
    for (
      var exerciseOrder = 0;
      exerciseOrder < inputs.length;
      exerciseOrder++
    ) {
      final input = inputs[exerciseOrder];
      final catalog = await getExercise(input.exerciseId);
      if (catalog == null || catalog.archivedAt != null) {
        throw StateError('模板动作不存在或已归档：${input.exerciseId}');
      }
      _validateTemplateSets(catalog.trackingType, input.sets);
      final templateExerciseId = await into(templateExercises).insert(
        TemplateExercisesCompanion.insert(
          templateVersionId: versionId,
          exerciseId: catalog.id,
          exerciseNameSnapshot: catalog.name,
          categorySnapshot: catalog.category,
          trackingTypeSnapshot: catalog.trackingType,
          loadConventionSnapshot: catalog.loadConvention,
          repsConventionSnapshot: catalog.repsConvention,
          note: Value(input.note),
          sortOrder: exerciseOrder,
        ),
      );
      for (var setOrder = 0; setOrder < input.sets.length; setOrder++) {
        final set = input.sets[setOrder];
        await into(templateSets).insert(
          TemplateSetsCompanion.insert(
            templateExerciseId: templateExerciseId,
            setRole: set.role,
            reps: Value(set.reps),
            minimumReps: Value(set.minimumReps),
            durationSeconds: Value(set.durationSeconds),
            minimumDurationSeconds: Value(set.minimumDurationSeconds),
            distanceMeters: Value(set.distanceMeters),
            minimumDistanceMeters: Value(set.minimumDistanceMeters),
            externalLoadKg: Value(set.externalLoadKg),
            assistanceKg: Value(set.assistanceKg),
            rpe: Value(set.rpe),
            rir: Value(set.rir),
            sortOrder: setOrder,
          ),
        );
      }
    }
  }

  static void _validateTemplateSets(
    TrackingType trackingType,
    List<TemplateSetInput> sets,
  ) {
    for (final set in sets) {
      final (num? target, num? minimum) = switch (trackingType) {
        TrackingType.reps => (set.reps, set.minimumReps),
        TrackingType.duration => (
          set.durationSeconds,
          set.minimumDurationSeconds,
        ),
        TrackingType.distance => (
          set.distanceMeters,
          set.minimumDistanceMeters,
        ),
      };
      if (target == null || target <= 0) {
        throw ArgumentError('计划组的${trackingType.label}目标需大于 0');
      }
      if (minimum != null && (minimum <= 0 || minimum > target)) {
        throw ArgumentError('最低${trackingType.label}需大于 0 且不高于常规目标');
      }
    }
  }

  Future<void> archiveWorkoutTemplate(int id, {DateTime? now}) =>
      (update(workoutTemplates)..where((t) => t.id.equals(id))).write(
        WorkoutTemplatesCompanion(archivedAt: Value(now ?? DateTime.now())),
      );

  Future<void> linkTemplateToWorkout(
    int workoutId,
    TemplateVersion version,
  ) async {
    await transaction(() async {
      await (update(workouts)..where((w) => w.id.equals(workoutId))).write(
        WorkoutsCompanion(
          templateVersionId: Value(version.id),
          templateNameSnapshot: Value(version.name),
          templateEvaluationPolicyVersion: const Value(1),
        ),
      );
      final plannedExercises =
          await (select(templateExercises)
                ..where((e) => e.templateVersionId.equals(version.id))
                ..orderBy([(e) => OrderingTerm.asc(e.sortOrder)]))
              .get();
      final plannedExerciseIds = plannedExercises.map((e) => e.id).toSet();
      final plannedSets = plannedExerciseIds.isEmpty
          ? const <TemplateSet>[]
          : await (select(templateSets)
                  ..where((s) => s.templateExerciseId.isIn(plannedExerciseIds))
                  ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
                .get();
      final plannedSetsByExercise = <int, List<TemplateSet>>{};
      for (final s in plannedSets) {
        (plannedSetsByExercise[s.templateExerciseId] ??= []).add(s);
      }

      final actualExercises = await getWorkoutExercises(workoutId);
      final usedPlannedExercises = <int>{};
      final resolvedExerciseLink = <int, int?>{};

      // 保留已指向当前模板版本的动作关联
      for (final actual in actualExercises) {
        final linkedId = actual.templateExerciseId;
        if (linkedId != null &&
            plannedExerciseIds.contains(linkedId) &&
            !usedPlannedExercises.contains(linkedId)) {
          usedPlannedExercises.add(linkedId);
          resolvedExerciseLink[actual.id] = linkedId;
        }
      }

      // 为尚未关联（或关联了旧模板版本）的动作按动作 ID 或快照名称顺序匹配计划动作
      for (final actual in actualExercises) {
        if (resolvedExerciseLink.containsKey(actual.id)) continue;
        final matched = plannedExercises.cast<TemplateExercise?>().firstWhere(
          (planned) =>
              !usedPlannedExercises.contains(planned!.id) &&
              ((actual.catalogExerciseId != null &&
                      planned.exerciseId == actual.catalogExerciseId) ||
                  (actual.catalogExerciseId == null &&
                      planned.exerciseNameSnapshot == actual.name)),
          orElse: () => null,
        );
        final nextTemplateExerciseId = matched?.id;
        resolvedExerciseLink[actual.id] = nextTemplateExerciseId;
        if (nextTemplateExerciseId != null) {
          usedPlannedExercises.add(nextTemplateExerciseId);
        }
        if (actual.templateExerciseId != nextTemplateExerciseId) {
          await (update(
            workoutExercises,
          )..where((e) => e.id.equals(actual.id))).write(
            WorkoutExercisesCompanion(
              templateExerciseId: Value(nextTemplateExerciseId),
            ),
          );
        }
      }

      // 同步每个动作下的计划组槽位关联
      for (final actual in actualExercises) {
        final plannedExerciseId = resolvedExerciseLink[actual.id];
        final actualSets =
            await (select(workoutSets)
                  ..where((s) => s.exerciseId.equals(actual.id))
                  ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
                .get();
        if (plannedExerciseId == null) {
          if (actualSets.any((s) => s.templateSetId != null)) {
            await (update(
              workoutSets,
            )..where((s) => s.exerciseId.equals(actual.id))).write(
              const WorkoutSetsCompanion(templateSetId: Value(null)),
            );
          }
          continue;
        }
        final candidates =
            plannedSetsByExercise[plannedExerciseId] ?? const <TemplateSet>[];
        final candidateIds = candidates.map((s) => s.id).toSet();
        final usedSetIds = <int>{};
        for (final set in actualSets) {
          final currentId = set.templateSetId;
          if (currentId != null &&
              candidateIds.contains(currentId) &&
              !usedSetIds.contains(currentId)) {
            usedSetIds.add(currentId);
          }
        }
        for (final set in actualSets) {
          final currentId = set.templateSetId;
          if (currentId != null && candidateIds.contains(currentId)) continue;
          final matchedSet = candidates.cast<TemplateSet?>().firstWhere(
            (c) => !usedSetIds.contains(c!.id),
            orElse: () => null,
          );
          final nextSetId = matchedSet?.id;
          if (nextSetId != null) usedSetIds.add(nextSetId);
          if (currentId != nextSetId) {
            await (update(
              workoutSets,
            )..where((s) => s.id.equals(set.id))).write(
              WorkoutSetsCompanion(templateSetId: Value(nextSetId)),
            );
          }
        }
      }
    });
  }

  Future<void> clearTemplateLink(int workoutId) async {
    await transaction(() async {
      await (update(workouts)..where((w) => w.id.equals(workoutId))).write(
        const WorkoutsCompanion(
          templateVersionId: Value(null),
          templateNameSnapshot: Value(null),
          templateEvaluationPolicyVersion: Value(null),
        ),
      );
      final exerciseIds =
          await (selectOnly(workoutExercises)
                ..addColumns([workoutExercises.id])
                ..where(workoutExercises.workoutId.equals(workoutId)))
              .map((row) => row.read(workoutExercises.id)!)
              .get();
      if (exerciseIds.isNotEmpty) {
        await (update(
          workoutSets,
        )..where((s) => s.exerciseId.isIn(exerciseIds))).write(
          const WorkoutSetsCompanion(templateSetId: Value(null)),
        );
        await (update(
          workoutExercises,
        )..where((e) => e.workoutId.equals(workoutId))).write(
          const WorkoutExercisesCompanion(templateExerciseId: Value(null)),
        );
      }
    });
  }

  Future<TemplateProgress> evaluateWorkoutTemplate(int workoutId) async {
    final workout = await getWorkout(workoutId);
    final versionId = workout?.templateVersionId;
    if (workout == null || versionId == null) {
      return const TemplateProgress(
        tier: PlanTier.none,
        minimumCompleted: 0,
        minimumTotal: 0,
        regularCompleted: 0,
        regularTotal: 0,
      );
    }
    final policyVersion = workout.templateEvaluationPolicyVersion ?? 1;
    if (policyVersion != 1) {
      throw StateError('不支持的模板评估策略版本：$policyVersion');
    }
    final definition = await getTemplateDefinitionByVersion(versionId);
    if (definition == null) {
      return const TemplateProgress(
        tier: PlanTier.none,
        minimumCompleted: 0,
        minimumTotal: 0,
        regularCompleted: 0,
        regularTotal: 0,
      );
    }
    final actualSets = await getWorkoutSets(workoutId);
    return _evaluateSetsAgainstPlanned(definition.sets, actualSets);
  }

  static TemplateProgress _evaluateSetsAgainstPlanned(
    List<TemplateSet> plannedSets,
    List<WorkoutSet> actualSets,
  ) {
    var minimumCompleted = 0;
    var minimumTotal = 0;
    var regularCompleted = 0;
    for (final planned in plannedSets) {
      final candidates = actualSets.where(
        (actual) =>
            actual.templateSetId == planned.id &&
            AppDatabase.isValidSet(actual),
      );
      if (candidates.any((actual) => _meetsTarget(actual, planned))) {
        regularCompleted++;
      }
      if (_hasMinimumTarget(planned)) {
        minimumTotal++;
        if (candidates.any((actual) => _meetsMinimum(actual, planned))) {
          minimumCompleted++;
        }
      }
    }
    final regularTotal = plannedSets.length;
    final tier = regularTotal > 0 && regularCompleted == regularTotal
        ? PlanTier.regular
        : minimumTotal > 0 && minimumCompleted == minimumTotal
        ? PlanTier.min
        : PlanTier.belowMin;
    return TemplateProgress(
      tier: tier,
      minimumCompleted: minimumCompleted,
      minimumTotal: minimumTotal,
      regularCompleted: regularCompleted,
      regularTotal: regularTotal,
    );
  }

  static bool _hasMinimumTarget(TemplateSet planned) =>
      planned.minimumReps != null ||
      planned.minimumDurationSeconds != null ||
      planned.minimumDistanceMeters != null;

  static bool _meetsTarget(WorkoutSet actual, TemplateSet planned) =>
      (planned.reps != null && (actual.reps ?? 0) >= planned.reps!) ||
      (planned.durationSeconds != null &&
          (actual.durationSeconds ?? 0) >= planned.durationSeconds!) ||
      (planned.distanceMeters != null &&
          (actual.distanceMeters ?? 0) >= planned.distanceMeters!);

  static bool _meetsMinimum(WorkoutSet actual, TemplateSet planned) =>
      (planned.minimumReps != null &&
          (actual.reps ?? 0) >= planned.minimumReps!) ||
      (planned.minimumDurationSeconds != null &&
          (actual.durationSeconds ?? 0) >= planned.minimumDurationSeconds!) ||
      (planned.minimumDistanceMeters != null &&
          (actual.distanceMeters ?? 0) >= planned.minimumDistanceMeters!);
}
