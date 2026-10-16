/// 指标读取的事实范围。
enum MetricInputScope { sessions, sets }

/// 指标的聚合方式。
enum MetricAggregation { distinctCount, count, sum }

/// 指标遇到缺失字段时的处理方式。
enum MissingDataPolicy {
  zeroWhenNoMatchingFacts,
  insufficientWhenMatchedFactMissing,
}

/// 规则可使用的稳定过滤条件。
class MetricFilters {
  const MetricFilters({this.exerciseId, this.category, this.setRole});

  final int? exerciseId;
  final String? category;
  final String? setRole;

  bool get isEmpty =>
      exerciseId == null && category == null && setRole == null;

  Map<String, Object> toJson() => {
    'exerciseId': ?exerciseId,
    'category': ?category,
    'setRole': ?setRole,
  };

  factory MetricFilters.fromJson(Map<String, Object?> json) => MetricFilters(
    exerciseId: json['exerciseId'] as int?,
    category: json['category'] as String?,
    setRole: json['setRole'] as String?,
  );
}

/// 一组可供指标读取的训练事实，不依赖 Drift 数据类。
class MetricSetFact {
  const MetricSetFact({
    required this.setRole,
    required this.setStatus,
    this.reps,
    this.durationSeconds,
    this.distanceMeters,
  });

  final String setRole;
  final String setStatus;
  final int? reps;
  final int? durationSeconds;
  final double? distanceMeters;
}

class MetricExerciseFact {
  const MetricExerciseFact({
    required this.exerciseId,
    required this.category,
    required this.trackingType,
    required this.sets,
  });

  final int? exerciseId;
  final String category;
  final String trackingType;
  final List<MetricSetFact> sets;
}

class MetricSessionFact {
  const MetricSessionFact({
    required this.workoutId,
    required this.date,
    required this.completed,
    required this.totalSeconds,
    required this.exercises,
  });

  final int workoutId;
  final DateTime date;
  final bool completed;
  final int? totalSeconds;
  final List<MetricExerciseFact> exercises;
}

class MetricContext {
  const MetricContext({
    required this.periodStart,
    required this.periodEndExclusive,
    required this.sessions,
  });

  final DateTime periodStart;
  final DateTime periodEndExclusive;
  final List<MetricSessionFact> sessions;

  Iterable<MetricSessionFact> get completedSessions => sessions.where(
    (session) =>
        session.completed &&
        !session.date.isBefore(periodStart) &&
        session.date.isBefore(periodEndExclusive),
  );
}

class MetricValue {
  const MetricValue.available({
    required num this.value,
    required this.unit,
    required this.definitionVersion,
  }) : insufficientData = false,
       missingFields = const [];

  const MetricValue.insufficient({
    required this.unit,
    required this.definitionVersion,
    required this.missingFields,
  }) : value = null,
       insufficientData = true;

  final num? value;
  final String unit;
  final int definitionVersion;
  final bool insufficientData;
  final List<String> missingFields;
}

typedef MetricComputer = MetricValue Function(
  MetricContext context,
  MetricFilters filters,
);

class MetricDefinition {
  const MetricDefinition({
    required this.metricId,
    required this.name,
    required this.unit,
    required this.inputScope,
    required this.aggregation,
    required this.definitionVersion,
    required this.missingDataPolicy,
    required this.compute,
  });

  final String metricId;
  final String name;
  final String unit;
  final MetricInputScope inputScope;
  final MetricAggregation aggregation;
  final int definitionVersion;
  final MissingDataPolicy missingDataPolicy;
  final MetricComputer compute;
}

/// 应用内置指标注册表；不加载用户代码或动态表达式。
class MetricRegistry {
  MetricRegistry._(this._definitions);

  factory MetricRegistry.builtIn() => MetricRegistry._({
    for (final definition in _builtInDefinitions)
      definition.metricId: definition,
  });

  final Map<String, MetricDefinition> _definitions;

  List<MetricDefinition> get definitions =>
      List.unmodifiable(_definitions.values);

  MetricDefinition definition(String metricId, int version) {
    final definition = _definitions[metricId];
    if (definition == null) throw ArgumentError('未知指标：$metricId');
    if (definition.definitionVersion != version) {
      throw StateError('不支持的指标版本：$metricId@$version');
    }
    return definition;
  }

  MetricValue evaluate(
    String metricId,
    int version,
    MetricContext context,
    MetricFilters filters,
  ) => definition(metricId, version).compute(context, filters);
}

Iterable<MetricExerciseFact> _matchingExercises(
  MetricSessionFact session,
  MetricFilters filters,
) => session.exercises.where(
  (exercise) =>
      (filters.exerciseId == null ||
          exercise.exerciseId == filters.exerciseId) &&
      (filters.category == null || exercise.category == filters.category),
);

bool _sessionMatchesFilters(MetricSessionFact session, MetricFilters filters) {
  final exercises = _matchingExercises(session, filters);
  final matchesExercise = filters.exerciseId == null && filters.category == null
      ? true
      : exercises.isNotEmpty;
  final matchesRole =
      filters.setRole == null ||
      exercises.any(
        (exercise) => exercise.sets.any(
          (set) =>
              set.setStatus == 'completed' && set.setRole == filters.setRole,
        ),
      );
  return matchesExercise && matchesRole;
}

Iterable<(MetricExerciseFact, MetricSetFact)> _matchingCompletedExerciseSets(
  MetricContext context,
  MetricFilters filters,
) sync* {
  for (final session in context.completedSessions) {
    for (final exercise in _matchingExercises(session, filters)) {
      for (final set in exercise.sets) {
        if (set.setStatus != 'completed') continue;
        if (filters.setRole != null && set.setRole != filters.setRole) continue;
        yield (exercise, set);
      }
    }
  }
}

bool _isValidSet(MetricExerciseFact exercise, MetricSetFact set) {
  if (set.setStatus != 'completed') return false;
  final primary = switch (exercise.trackingType) {
    'reps' => set.reps,
    'duration' => set.durationSeconds,
    'distance' => set.distanceMeters,
    _ => null,
  };
  if (primary != null) return primary > 0;
  return (set.reps ?? 0) > 0 ||
      (set.durationSeconds ?? 0) > 0 ||
      (set.distanceMeters ?? 0) > 0;
}

MetricValue _sumMetric(
  MetricContext context,
  MetricFilters filters, {
  required String trackingType,
  required String unit,
  required String missingField,
  required num? Function(MetricSetFact set) read,
}) {
  var total = 0.0;
  var integral = true;
  final missing = <String>{};
  for (final (exercise, set) in _matchingCompletedExerciseSets(
    context,
    filters,
  )) {
    final value = read(set);
    if (value == null) {
      if (exercise.trackingType == trackingType || filters.exerciseId != null) {
        missing.add(missingField);
      }
      continue;
    }
    if (value is double && value != value.roundToDouble()) integral = false;
    total += value.toDouble();
  }
  if (missing.isNotEmpty) {
    return MetricValue.insufficient(
      unit: unit,
      definitionVersion: 1,
      missingFields: missing.toList()..sort(),
    );
  }
  return MetricValue.available(
    value: integral ? total.toInt() : total,
    unit: unit,
    definitionVersion: 1,
  );
}

final _builtInDefinitions = <MetricDefinition>[
  MetricDefinition(
    metricId: 'session_count',
    name: '训练次数',
    unit: 'session',
    inputScope: MetricInputScope.sessions,
    aggregation: MetricAggregation.distinctCount,
    definitionVersion: 1,
    missingDataPolicy: MissingDataPolicy.zeroWhenNoMatchingFacts,
    compute: (context, filters) {
      final ids = <int>{};
      for (final session in context.completedSessions) {
        if (_sessionMatchesFilters(session, filters)) {
          ids.add(session.workoutId);
        }
      }
      return MetricValue.available(
        value: ids.length,
        unit: 'session',
        definitionVersion: 1,
      );
    },
  ),
  MetricDefinition(
    metricId: 'session_duration',
    name: '训练总时长',
    unit: 'second',
    inputScope: MetricInputScope.sessions,
    aggregation: MetricAggregation.sum,
    definitionVersion: 1,
    missingDataPolicy: MissingDataPolicy.insufficientWhenMatchedFactMissing,
    compute: (context, filters) {
      var total = 0;
      for (final session in context.completedSessions) {
        if (!_sessionMatchesFilters(session, filters)) continue;
        final seconds = session.totalSeconds;
        if (seconds == null) {
          return const MetricValue.insufficient(
            unit: 'second',
            definitionVersion: 1,
            missingFields: ['total_seconds'],
          );
        }
        total += seconds;
      }
      return MetricValue.available(
        value: total,
        unit: 'second',
        definitionVersion: 1,
      );
    },
  ),
  MetricDefinition(
    metricId: 'valid_set_count',
    name: '有效组数',
    unit: 'set',
    inputScope: MetricInputScope.sets,
    aggregation: MetricAggregation.count,
    definitionVersion: 1,
    missingDataPolicy: MissingDataPolicy.zeroWhenNoMatchingFacts,
    compute: (context, filters) {
      var count = 0;
      for (final session in context.completedSessions) {
        for (final exercise in _matchingExercises(session, filters)) {
          count += exercise.sets.where((set) {
            if (filters.setRole != null && set.setRole != filters.setRole) {
              return false;
            }
            return _isValidSet(exercise, set);
          }).length;
        }
      }
      return MetricValue.available(
        value: count,
        unit: 'set',
        definitionVersion: 1,
      );
    },
  ),
  MetricDefinition(
    metricId: 'reps',
    name: '次数',
    unit: 'rep',
    inputScope: MetricInputScope.sets,
    aggregation: MetricAggregation.sum,
    definitionVersion: 1,
    missingDataPolicy: MissingDataPolicy.insufficientWhenMatchedFactMissing,
    compute: (context, filters) => _sumMetric(
      context,
      filters,
      trackingType: 'reps',
      unit: 'rep',
      missingField: 'reps',
      read: (set) => set.reps,
    ),
  ),
  MetricDefinition(
    metricId: 'duration',
    name: '持续时间',
    unit: 'second',
    inputScope: MetricInputScope.sets,
    aggregation: MetricAggregation.sum,
    definitionVersion: 1,
    missingDataPolicy: MissingDataPolicy.insufficientWhenMatchedFactMissing,
    compute: (context, filters) => _sumMetric(
      context,
      filters,
      trackingType: 'duration',
      unit: 'second',
      missingField: 'duration_seconds',
      read: (set) => set.durationSeconds,
    ),
  ),
  MetricDefinition(
    metricId: 'distance',
    name: '距离',
    unit: 'meter',
    inputScope: MetricInputScope.sets,
    aggregation: MetricAggregation.sum,
    definitionVersion: 1,
    missingDataPolicy: MissingDataPolicy.insufficientWhenMatchedFactMissing,
    compute: (context, filters) => _sumMetric(
      context,
      filters,
      trackingType: 'distance',
      unit: 'meter',
      missingField: 'distance_meters',
      read: (set) => set.distanceMeters,
    ),
  ),
];
