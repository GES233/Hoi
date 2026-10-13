// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $FoodEntriesTable extends FoodEntries
    with TableInfo<$FoodEntriesTable, FoodEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MealType, int> mealType =
      GeneratedColumn<int>(
        'meal_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<MealType>($FoodEntriesTable.$convertermealType);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
    'calories',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, mealType, name, calories];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    } else if (isInserting) {
      context.missing(_caloriesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      mealType: $FoodEntriesTable.$convertermealType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}meal_type'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories'],
      )!,
    );
  }

  @override
  $FoodEntriesTable createAlias(String alias) {
    return $FoodEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MealType, int, int> $convertermealType =
      const EnumIndexConverter<MealType>(MealType.values);
}

class FoodEntry extends DataClass implements Insertable<FoodEntry> {
  final int id;

  /// 只存日期部分（本地时间午夜）
  final DateTime date;
  final MealType mealType;
  final String name;
  final int calories;
  const FoodEntry({
    required this.id,
    required this.date,
    required this.mealType,
    required this.name,
    required this.calories,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    {
      map['meal_type'] = Variable<int>(
        $FoodEntriesTable.$convertermealType.toSql(mealType),
      );
    }
    map['name'] = Variable<String>(name);
    map['calories'] = Variable<int>(calories);
    return map;
  }

  FoodEntriesCompanion toCompanion(bool nullToAbsent) {
    return FoodEntriesCompanion(
      id: Value(id),
      date: Value(date),
      mealType: Value(mealType),
      name: Value(name),
      calories: Value(calories),
    );
  }

  factory FoodEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodEntry(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      mealType: $FoodEntriesTable.$convertermealType.fromJson(
        serializer.fromJson<int>(json['mealType']),
      ),
      name: serializer.fromJson<String>(json['name']),
      calories: serializer.fromJson<int>(json['calories']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'mealType': serializer.toJson<int>(
        $FoodEntriesTable.$convertermealType.toJson(mealType),
      ),
      'name': serializer.toJson<String>(name),
      'calories': serializer.toJson<int>(calories),
    };
  }

  FoodEntry copyWith({
    int? id,
    DateTime? date,
    MealType? mealType,
    String? name,
    int? calories,
  }) => FoodEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    mealType: mealType ?? this.mealType,
    name: name ?? this.name,
    calories: calories ?? this.calories,
  );
  FoodEntry copyWithCompanion(FoodEntriesCompanion data) {
    return FoodEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      name: data.name.present ? data.name.value : this.name,
      calories: data.calories.present ? data.calories.value : this.calories,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('mealType: $mealType, ')
          ..write('name: $name, ')
          ..write('calories: $calories')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, mealType, name, calories);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.mealType == this.mealType &&
          other.name == this.name &&
          other.calories == this.calories);
}

class FoodEntriesCompanion extends UpdateCompanion<FoodEntry> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<MealType> mealType;
  final Value<String> name;
  final Value<int> calories;
  const FoodEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.mealType = const Value.absent(),
    this.name = const Value.absent(),
    this.calories = const Value.absent(),
  });
  FoodEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required MealType mealType,
    required String name,
    required int calories,
  }) : date = Value(date),
       mealType = Value(mealType),
       name = Value(name),
       calories = Value(calories);
  static Insertable<FoodEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? mealType,
    Expression<String>? name,
    Expression<int>? calories,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (mealType != null) 'meal_type': mealType,
      if (name != null) 'name': name,
      if (calories != null) 'calories': calories,
    });
  }

  FoodEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<MealType>? mealType,
    Value<String>? name,
    Value<int>? calories,
  }) {
    return FoodEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      name: name ?? this.name,
      calories: calories ?? this.calories,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<int>(
        $FoodEntriesTable.$convertermealType.toSql(mealType.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('mealType: $mealType, ')
          ..write('name: $name, ')
          ..write('calories: $calories')
          ..write(')'))
        .toString();
  }
}

class $FavoriteFoodsTable extends FavoriteFoods
    with TableInfo<$FavoriteFoodsTable, FavoriteFood> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteFoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
    'calories',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, calories];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteFood> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    } else if (isInserting) {
      context.missing(_caloriesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FavoriteFood map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteFood(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories'],
      )!,
    );
  }

  @override
  $FavoriteFoodsTable createAlias(String alias) {
    return $FavoriteFoodsTable(attachedDatabase, alias);
  }
}

class FavoriteFood extends DataClass implements Insertable<FavoriteFood> {
  final int id;
  final String name;
  final int calories;
  const FavoriteFood({
    required this.id,
    required this.name,
    required this.calories,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['calories'] = Variable<int>(calories);
    return map;
  }

  FavoriteFoodsCompanion toCompanion(bool nullToAbsent) {
    return FavoriteFoodsCompanion(
      id: Value(id),
      name: Value(name),
      calories: Value(calories),
    );
  }

  factory FavoriteFood.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteFood(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      calories: serializer.fromJson<int>(json['calories']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'calories': serializer.toJson<int>(calories),
    };
  }

  FavoriteFood copyWith({int? id, String? name, int? calories}) => FavoriteFood(
    id: id ?? this.id,
    name: name ?? this.name,
    calories: calories ?? this.calories,
  );
  FavoriteFood copyWithCompanion(FavoriteFoodsCompanion data) {
    return FavoriteFood(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      calories: data.calories.present ? data.calories.value : this.calories,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteFood(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('calories: $calories')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, calories);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteFood &&
          other.id == this.id &&
          other.name == this.name &&
          other.calories == this.calories);
}

class FavoriteFoodsCompanion extends UpdateCompanion<FavoriteFood> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> calories;
  const FavoriteFoodsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.calories = const Value.absent(),
  });
  FavoriteFoodsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int calories,
  }) : name = Value(name),
       calories = Value(calories);
  static Insertable<FavoriteFood> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? calories,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (calories != null) 'calories': calories,
    });
  }

  FavoriteFoodsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? calories,
  }) {
    return FavoriteFoodsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteFoodsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('calories: $calories')
          ..write(')'))
        .toString();
  }
}

class $WeeklyExerciseGoalsTable extends WeeklyExerciseGoals
    with TableInfo<$WeeklyExerciseGoalsTable, WeeklyExerciseGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeklyExerciseGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _targetSessionsMeta = const VerificationMeta(
    'targetSessions',
  );
  @override
  late final GeneratedColumn<int> targetSessions = GeneratedColumn<int>(
    'target_sessions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetMinutesMeta = const VerificationMeta(
    'targetMinutes',
  );
  @override
  late final GeneratedColumn<int> targetMinutes = GeneratedColumn<int>(
    'target_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, targetSessions, targetMinutes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekly_exercise_goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeeklyExerciseGoal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('target_sessions')) {
      context.handle(
        _targetSessionsMeta,
        targetSessions.isAcceptableOrUnknown(
          data['target_sessions']!,
          _targetSessionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetSessionsMeta);
    }
    if (data.containsKey('target_minutes')) {
      context.handle(
        _targetMinutesMeta,
        targetMinutes.isAcceptableOrUnknown(
          data['target_minutes']!,
          _targetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetMinutesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeeklyExerciseGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeeklyExerciseGoal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      targetSessions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_sessions'],
      )!,
      targetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_minutes'],
      )!,
    );
  }

  @override
  $WeeklyExerciseGoalsTable createAlias(String alias) {
    return $WeeklyExerciseGoalsTable(attachedDatabase, alias);
  }
}

class WeeklyExerciseGoal extends DataClass
    implements Insertable<WeeklyExerciseGoal> {
  final int id;
  final int targetSessions;
  final int targetMinutes;
  const WeeklyExerciseGoal({
    required this.id,
    required this.targetSessions,
    required this.targetMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['target_sessions'] = Variable<int>(targetSessions);
    map['target_minutes'] = Variable<int>(targetMinutes);
    return map;
  }

  WeeklyExerciseGoalsCompanion toCompanion(bool nullToAbsent) {
    return WeeklyExerciseGoalsCompanion(
      id: Value(id),
      targetSessions: Value(targetSessions),
      targetMinutes: Value(targetMinutes),
    );
  }

  factory WeeklyExerciseGoal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeeklyExerciseGoal(
      id: serializer.fromJson<int>(json['id']),
      targetSessions: serializer.fromJson<int>(json['targetSessions']),
      targetMinutes: serializer.fromJson<int>(json['targetMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'targetSessions': serializer.toJson<int>(targetSessions),
      'targetMinutes': serializer.toJson<int>(targetMinutes),
    };
  }

  WeeklyExerciseGoal copyWith({
    int? id,
    int? targetSessions,
    int? targetMinutes,
  }) => WeeklyExerciseGoal(
    id: id ?? this.id,
    targetSessions: targetSessions ?? this.targetSessions,
    targetMinutes: targetMinutes ?? this.targetMinutes,
  );
  WeeklyExerciseGoal copyWithCompanion(WeeklyExerciseGoalsCompanion data) {
    return WeeklyExerciseGoal(
      id: data.id.present ? data.id.value : this.id,
      targetSessions: data.targetSessions.present
          ? data.targetSessions.value
          : this.targetSessions,
      targetMinutes: data.targetMinutes.present
          ? data.targetMinutes.value
          : this.targetMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyExerciseGoal(')
          ..write('id: $id, ')
          ..write('targetSessions: $targetSessions, ')
          ..write('targetMinutes: $targetMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, targetSessions, targetMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyExerciseGoal &&
          other.id == this.id &&
          other.targetSessions == this.targetSessions &&
          other.targetMinutes == this.targetMinutes);
}

class WeeklyExerciseGoalsCompanion extends UpdateCompanion<WeeklyExerciseGoal> {
  final Value<int> id;
  final Value<int> targetSessions;
  final Value<int> targetMinutes;
  const WeeklyExerciseGoalsCompanion({
    this.id = const Value.absent(),
    this.targetSessions = const Value.absent(),
    this.targetMinutes = const Value.absent(),
  });
  WeeklyExerciseGoalsCompanion.insert({
    this.id = const Value.absent(),
    required int targetSessions,
    required int targetMinutes,
  }) : targetSessions = Value(targetSessions),
       targetMinutes = Value(targetMinutes);
  static Insertable<WeeklyExerciseGoal> custom({
    Expression<int>? id,
    Expression<int>? targetSessions,
    Expression<int>? targetMinutes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetSessions != null) 'target_sessions': targetSessions,
      if (targetMinutes != null) 'target_minutes': targetMinutes,
    });
  }

  WeeklyExerciseGoalsCompanion copyWith({
    Value<int>? id,
    Value<int>? targetSessions,
    Value<int>? targetMinutes,
  }) {
    return WeeklyExerciseGoalsCompanion(
      id: id ?? this.id,
      targetSessions: targetSessions ?? this.targetSessions,
      targetMinutes: targetMinutes ?? this.targetMinutes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (targetSessions.present) {
      map['target_sessions'] = Variable<int>(targetSessions.value);
    }
    if (targetMinutes.present) {
      map['target_minutes'] = Variable<int>(targetMinutes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyExerciseGoalsCompanion(')
          ..write('id: $id, ')
          ..write('targetSessions: $targetSessions, ')
          ..write('targetMinutes: $targetMinutes')
          ..write(')'))
        .toString();
  }
}

class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ExerciseCategory, String>
  category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ExerciseCategory>($ExercisesTable.$convertercategory);
  @override
  late final GeneratedColumnWithTypeConverter<TrackingType, String>
  trackingType = GeneratedColumn<String>(
    'tracking_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<TrackingType>($ExercisesTable.$convertertrackingType);
  @override
  late final GeneratedColumnWithTypeConverter<LoadConvention, String>
  loadConvention = GeneratedColumn<String>(
    'load_convention',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<LoadConvention>($ExercisesTable.$converterloadConvention);
  @override
  late final GeneratedColumnWithTypeConverter<RepsConvention, String>
  repsConvention = GeneratedColumn<String>(
    'reps_convention',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<RepsConvention>($ExercisesTable.$converterrepsConvention);
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    trackingType,
    loadConvention,
    repsConvention,
    archivedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<Exercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: $ExercisesTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
      trackingType: $ExercisesTable.$convertertrackingType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tracking_type'],
        )!,
      ),
      loadConvention: $ExercisesTable.$converterloadConvention.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}load_convention'],
        )!,
      ),
      repsConvention: $ExercisesTable.$converterrepsConvention.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}reps_convention'],
        )!,
      ),
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ExerciseCategory, String, String>
  $convertercategory = const EnumNameConverter<ExerciseCategory>(
    ExerciseCategory.values,
  );
  static JsonTypeConverter2<TrackingType, String, String>
  $convertertrackingType = const EnumNameConverter<TrackingType>(
    TrackingType.values,
  );
  static JsonTypeConverter2<LoadConvention, String, String>
  $converterloadConvention = const EnumNameConverter<LoadConvention>(
    LoadConvention.values,
  );
  static JsonTypeConverter2<RepsConvention, String, String>
  $converterrepsConvention = const EnumNameConverter<RepsConvention>(
    RepsConvention.values,
  );
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final int id;
  final String name;
  final ExerciseCategory category;
  final TrackingType trackingType;
  final LoadConvention loadConvention;
  final RepsConvention repsConvention;
  final DateTime? archivedAt;
  final DateTime createdAt;
  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.trackingType,
    required this.loadConvention,
    required this.repsConvention,
    this.archivedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['category'] = Variable<String>(
        $ExercisesTable.$convertercategory.toSql(category),
      );
    }
    {
      map['tracking_type'] = Variable<String>(
        $ExercisesTable.$convertertrackingType.toSql(trackingType),
      );
    }
    {
      map['load_convention'] = Variable<String>(
        $ExercisesTable.$converterloadConvention.toSql(loadConvention),
      );
    }
    {
      map['reps_convention'] = Variable<String>(
        $ExercisesTable.$converterrepsConvention.toSql(repsConvention),
      );
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      trackingType: Value(trackingType),
      loadConvention: Value(loadConvention),
      repsConvention: Value(repsConvention),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      createdAt: Value(createdAt),
    );
  }

  factory Exercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: $ExercisesTable.$convertercategory.fromJson(
        serializer.fromJson<String>(json['category']),
      ),
      trackingType: $ExercisesTable.$convertertrackingType.fromJson(
        serializer.fromJson<String>(json['trackingType']),
      ),
      loadConvention: $ExercisesTable.$converterloadConvention.fromJson(
        serializer.fromJson<String>(json['loadConvention']),
      ),
      repsConvention: $ExercisesTable.$converterrepsConvention.fromJson(
        serializer.fromJson<String>(json['repsConvention']),
      ),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(
        $ExercisesTable.$convertercategory.toJson(category),
      ),
      'trackingType': serializer.toJson<String>(
        $ExercisesTable.$convertertrackingType.toJson(trackingType),
      ),
      'loadConvention': serializer.toJson<String>(
        $ExercisesTable.$converterloadConvention.toJson(loadConvention),
      ),
      'repsConvention': serializer.toJson<String>(
        $ExercisesTable.$converterrepsConvention.toJson(repsConvention),
      ),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Exercise copyWith({
    int? id,
    String? name,
    ExerciseCategory? category,
    TrackingType? trackingType,
    LoadConvention? loadConvention,
    RepsConvention? repsConvention,
    Value<DateTime?> archivedAt = const Value.absent(),
    DateTime? createdAt,
  }) => Exercise(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    trackingType: trackingType ?? this.trackingType,
    loadConvention: loadConvention ?? this.loadConvention,
    repsConvention: repsConvention ?? this.repsConvention,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      trackingType: data.trackingType.present
          ? data.trackingType.value
          : this.trackingType,
      loadConvention: data.loadConvention.present
          ? data.loadConvention.value
          : this.loadConvention,
      repsConvention: data.repsConvention.present
          ? data.repsConvention.value
          : this.repsConvention,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('trackingType: $trackingType, ')
          ..write('loadConvention: $loadConvention, ')
          ..write('repsConvention: $repsConvention, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    trackingType,
    loadConvention,
    repsConvention,
    archivedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.trackingType == this.trackingType &&
          other.loadConvention == this.loadConvention &&
          other.repsConvention == this.repsConvention &&
          other.archivedAt == this.archivedAt &&
          other.createdAt == this.createdAt);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<int> id;
  final Value<String> name;
  final Value<ExerciseCategory> category;
  final Value<TrackingType> trackingType;
  final Value<LoadConvention> loadConvention;
  final Value<RepsConvention> repsConvention;
  final Value<DateTime?> archivedAt;
  final Value<DateTime> createdAt;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.trackingType = const Value.absent(),
    this.loadConvention = const Value.absent(),
    this.repsConvention = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExercisesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required ExerciseCategory category,
    required TrackingType trackingType,
    required LoadConvention loadConvention,
    required RepsConvention repsConvention,
    this.archivedAt = const Value.absent(),
    required DateTime createdAt,
  }) : name = Value(name),
       category = Value(category),
       trackingType = Value(trackingType),
       loadConvention = Value(loadConvention),
       repsConvention = Value(repsConvention),
       createdAt = Value(createdAt);
  static Insertable<Exercise> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? trackingType,
    Expression<String>? loadConvention,
    Expression<String>? repsConvention,
    Expression<DateTime>? archivedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (trackingType != null) 'tracking_type': trackingType,
      if (loadConvention != null) 'load_convention': loadConvention,
      if (repsConvention != null) 'reps_convention': repsConvention,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExercisesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<ExerciseCategory>? category,
    Value<TrackingType>? trackingType,
    Value<LoadConvention>? loadConvention,
    Value<RepsConvention>? repsConvention,
    Value<DateTime?>? archivedAt,
    Value<DateTime>? createdAt,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      trackingType: trackingType ?? this.trackingType,
      loadConvention: loadConvention ?? this.loadConvention,
      repsConvention: repsConvention ?? this.repsConvention,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $ExercisesTable.$convertercategory.toSql(category.value),
      );
    }
    if (trackingType.present) {
      map['tracking_type'] = Variable<String>(
        $ExercisesTable.$convertertrackingType.toSql(trackingType.value),
      );
    }
    if (loadConvention.present) {
      map['load_convention'] = Variable<String>(
        $ExercisesTable.$converterloadConvention.toSql(loadConvention.value),
      );
    }
    if (repsConvention.present) {
      map['reps_convention'] = Variable<String>(
        $ExercisesTable.$converterrepsConvention.toSql(repsConvention.value),
      );
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('trackingType: $trackingType, ')
          ..write('loadConvention: $loadConvention, ')
          ..write('repsConvention: $repsConvention, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WorkoutTemplatesTable extends WorkoutTemplates
    with TableInfo<$WorkoutTemplatesTable, WorkoutTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _currentVersionNumberMeta =
      const VerificationMeta('currentVersionNumber');
  @override
  late final GeneratedColumn<int> currentVersionNumber = GeneratedColumn<int>(
    'current_version_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    currentVersionNumber,
    archivedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('current_version_number')) {
      context.handle(
        _currentVersionNumberMeta,
        currentVersionNumber.isAcceptableOrUnknown(
          data['current_version_number']!,
          _currentVersionNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentVersionNumberMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      currentVersionNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_version_number'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WorkoutTemplatesTable createAlias(String alias) {
    return $WorkoutTemplatesTable(attachedDatabase, alias);
  }
}

class WorkoutTemplate extends DataClass implements Insertable<WorkoutTemplate> {
  final int id;
  final int currentVersionNumber;
  final DateTime? archivedAt;
  final DateTime createdAt;
  const WorkoutTemplate({
    required this.id,
    required this.currentVersionNumber,
    this.archivedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['current_version_number'] = Variable<int>(currentVersionNumber);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WorkoutTemplatesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutTemplatesCompanion(
      id: Value(id),
      currentVersionNumber: Value(currentVersionNumber),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      createdAt: Value(createdAt),
    );
  }

  factory WorkoutTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutTemplate(
      id: serializer.fromJson<int>(json['id']),
      currentVersionNumber: serializer.fromJson<int>(
        json['currentVersionNumber'],
      ),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currentVersionNumber': serializer.toJson<int>(currentVersionNumber),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WorkoutTemplate copyWith({
    int? id,
    int? currentVersionNumber,
    Value<DateTime?> archivedAt = const Value.absent(),
    DateTime? createdAt,
  }) => WorkoutTemplate(
    id: id ?? this.id,
    currentVersionNumber: currentVersionNumber ?? this.currentVersionNumber,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  WorkoutTemplate copyWithCompanion(WorkoutTemplatesCompanion data) {
    return WorkoutTemplate(
      id: data.id.present ? data.id.value : this.id,
      currentVersionNumber: data.currentVersionNumber.present
          ? data.currentVersionNumber.value
          : this.currentVersionNumber,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplate(')
          ..write('id: $id, ')
          ..write('currentVersionNumber: $currentVersionNumber, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, currentVersionNumber, archivedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutTemplate &&
          other.id == this.id &&
          other.currentVersionNumber == this.currentVersionNumber &&
          other.archivedAt == this.archivedAt &&
          other.createdAt == this.createdAt);
}

class WorkoutTemplatesCompanion extends UpdateCompanion<WorkoutTemplate> {
  final Value<int> id;
  final Value<int> currentVersionNumber;
  final Value<DateTime?> archivedAt;
  final Value<DateTime> createdAt;
  const WorkoutTemplatesCompanion({
    this.id = const Value.absent(),
    this.currentVersionNumber = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WorkoutTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required int currentVersionNumber,
    this.archivedAt = const Value.absent(),
    required DateTime createdAt,
  }) : currentVersionNumber = Value(currentVersionNumber),
       createdAt = Value(createdAt);
  static Insertable<WorkoutTemplate> custom({
    Expression<int>? id,
    Expression<int>? currentVersionNumber,
    Expression<DateTime>? archivedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currentVersionNumber != null)
        'current_version_number': currentVersionNumber,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WorkoutTemplatesCompanion copyWith({
    Value<int>? id,
    Value<int>? currentVersionNumber,
    Value<DateTime?>? archivedAt,
    Value<DateTime>? createdAt,
  }) {
    return WorkoutTemplatesCompanion(
      id: id ?? this.id,
      currentVersionNumber: currentVersionNumber ?? this.currentVersionNumber,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currentVersionNumber.present) {
      map['current_version_number'] = Variable<int>(currentVersionNumber.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('currentVersionNumber: $currentVersionNumber, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TemplateVersionsTable extends TemplateVersions
    with TableInfo<$TemplateVersionsTable, TemplateVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_templates (id)',
    ),
  );
  static const VerificationMeta _versionNumberMeta = const VerificationMeta(
    'versionNumber',
  );
  @override
  late final GeneratedColumn<int> versionNumber = GeneratedColumn<int>(
    'version_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    versionNumber,
    name,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateVersion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('version_number')) {
      context.handle(
        _versionNumberMeta,
        versionNumber.isAcceptableOrUnknown(
          data['version_number']!,
          _versionNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionNumberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {templateId, versionNumber},
  ];
  @override
  TemplateVersion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateVersion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_id'],
      )!,
      versionNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version_number'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TemplateVersionsTable createAlias(String alias) {
    return $TemplateVersionsTable(attachedDatabase, alias);
  }
}

class TemplateVersion extends DataClass implements Insertable<TemplateVersion> {
  final int id;
  final int templateId;
  final int versionNumber;
  final String name;
  final String? note;
  final DateTime createdAt;
  const TemplateVersion({
    required this.id,
    required this.templateId,
    required this.versionNumber,
    required this.name,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['template_id'] = Variable<int>(templateId);
    map['version_number'] = Variable<int>(versionNumber);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TemplateVersionsCompanion toCompanion(bool nullToAbsent) {
    return TemplateVersionsCompanion(
      id: Value(id),
      templateId: Value(templateId),
      versionNumber: Value(versionNumber),
      name: Value(name),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory TemplateVersion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateVersion(
      id: serializer.fromJson<int>(json['id']),
      templateId: serializer.fromJson<int>(json['templateId']),
      versionNumber: serializer.fromJson<int>(json['versionNumber']),
      name: serializer.fromJson<String>(json['name']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'templateId': serializer.toJson<int>(templateId),
      'versionNumber': serializer.toJson<int>(versionNumber),
      'name': serializer.toJson<String>(name),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TemplateVersion copyWith({
    int? id,
    int? templateId,
    int? versionNumber,
    String? name,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => TemplateVersion(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    versionNumber: versionNumber ?? this.versionNumber,
    name: name ?? this.name,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  TemplateVersion copyWithCompanion(TemplateVersionsCompanion data) {
    return TemplateVersion(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      versionNumber: data.versionNumber.present
          ? data.versionNumber.value
          : this.versionNumber,
      name: data.name.present ? data.name.value : this.name,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateVersion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('versionNumber: $versionNumber, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, templateId, versionNumber, name, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateVersion &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.versionNumber == this.versionNumber &&
          other.name == this.name &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class TemplateVersionsCompanion extends UpdateCompanion<TemplateVersion> {
  final Value<int> id;
  final Value<int> templateId;
  final Value<int> versionNumber;
  final Value<String> name;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const TemplateVersionsCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.versionNumber = const Value.absent(),
    this.name = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TemplateVersionsCompanion.insert({
    this.id = const Value.absent(),
    required int templateId,
    required int versionNumber,
    required String name,
    this.note = const Value.absent(),
    required DateTime createdAt,
  }) : templateId = Value(templateId),
       versionNumber = Value(versionNumber),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<TemplateVersion> custom({
    Expression<int>? id,
    Expression<int>? templateId,
    Expression<int>? versionNumber,
    Expression<String>? name,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (versionNumber != null) 'version_number': versionNumber,
      if (name != null) 'name': name,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TemplateVersionsCompanion copyWith({
    Value<int>? id,
    Value<int>? templateId,
    Value<int>? versionNumber,
    Value<String>? name,
    Value<String?>? note,
    Value<DateTime>? createdAt,
  }) {
    return TemplateVersionsCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      versionNumber: versionNumber ?? this.versionNumber,
      name: name ?? this.name,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (versionNumber.present) {
      map['version_number'] = Variable<int>(versionNumber.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateVersionsCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('versionNumber: $versionNumber, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TemplateExercisesTable extends TemplateExercises
    with TableInfo<$TemplateExercisesTable, TemplateExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _templateVersionIdMeta = const VerificationMeta(
    'templateVersionId',
  );
  @override
  late final GeneratedColumn<int> templateVersionId = GeneratedColumn<int>(
    'template_version_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES template_versions (id)',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id)',
    ),
  );
  static const VerificationMeta _exerciseNameSnapshotMeta =
      const VerificationMeta('exerciseNameSnapshot');
  @override
  late final GeneratedColumn<String> exerciseNameSnapshot =
      GeneratedColumn<String>(
        'exercise_name_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  late final GeneratedColumnWithTypeConverter<ExerciseCategory, String>
  categorySnapshot =
      GeneratedColumn<String>(
        'category_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ExerciseCategory>(
        $TemplateExercisesTable.$convertercategorySnapshot,
      );
  @override
  late final GeneratedColumnWithTypeConverter<TrackingType, String>
  trackingTypeSnapshot =
      GeneratedColumn<String>(
        'tracking_type_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TrackingType>(
        $TemplateExercisesTable.$convertertrackingTypeSnapshot,
      );
  @override
  late final GeneratedColumnWithTypeConverter<LoadConvention, String>
  loadConventionSnapshot =
      GeneratedColumn<String>(
        'load_convention_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LoadConvention>(
        $TemplateExercisesTable.$converterloadConventionSnapshot,
      );
  @override
  late final GeneratedColumnWithTypeConverter<RepsConvention, String>
  repsConventionSnapshot =
      GeneratedColumn<String>(
        'reps_convention_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RepsConvention>(
        $TemplateExercisesTable.$converterrepsConventionSnapshot,
      );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateVersionId,
    exerciseId,
    exerciseNameSnapshot,
    categorySnapshot,
    trackingTypeSnapshot,
    loadConventionSnapshot,
    repsConventionSnapshot,
    note,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('template_version_id')) {
      context.handle(
        _templateVersionIdMeta,
        templateVersionId.isAcceptableOrUnknown(
          data['template_version_id']!,
          _templateVersionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateVersionIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('exercise_name_snapshot')) {
      context.handle(
        _exerciseNameSnapshotMeta,
        exerciseNameSnapshot.isAcceptableOrUnknown(
          data['exercise_name_snapshot']!,
          _exerciseNameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseNameSnapshotMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {templateVersionId, sortOrder},
  ];
  @override
  TemplateExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      templateVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_version_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      exerciseNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_name_snapshot'],
      )!,
      categorySnapshot: $TemplateExercisesTable.$convertercategorySnapshot
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}category_snapshot'],
            )!,
          ),
      trackingTypeSnapshot: $TemplateExercisesTable
          .$convertertrackingTypeSnapshot
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}tracking_type_snapshot'],
            )!,
          ),
      loadConventionSnapshot: $TemplateExercisesTable
          .$converterloadConventionSnapshot
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}load_convention_snapshot'],
            )!,
          ),
      repsConventionSnapshot: $TemplateExercisesTable
          .$converterrepsConventionSnapshot
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}reps_convention_snapshot'],
            )!,
          ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $TemplateExercisesTable createAlias(String alias) {
    return $TemplateExercisesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ExerciseCategory, String, String>
  $convertercategorySnapshot = const EnumNameConverter<ExerciseCategory>(
    ExerciseCategory.values,
  );
  static JsonTypeConverter2<TrackingType, String, String>
  $convertertrackingTypeSnapshot = const EnumNameConverter<TrackingType>(
    TrackingType.values,
  );
  static JsonTypeConverter2<LoadConvention, String, String>
  $converterloadConventionSnapshot = const EnumNameConverter<LoadConvention>(
    LoadConvention.values,
  );
  static JsonTypeConverter2<RepsConvention, String, String>
  $converterrepsConventionSnapshot = const EnumNameConverter<RepsConvention>(
    RepsConvention.values,
  );
}

class TemplateExercise extends DataClass
    implements Insertable<TemplateExercise> {
  final int id;
  final int templateVersionId;
  final int exerciseId;
  final String exerciseNameSnapshot;
  final ExerciseCategory categorySnapshot;
  final TrackingType trackingTypeSnapshot;
  final LoadConvention loadConventionSnapshot;
  final RepsConvention repsConventionSnapshot;
  final String? note;
  final int sortOrder;
  const TemplateExercise({
    required this.id,
    required this.templateVersionId,
    required this.exerciseId,
    required this.exerciseNameSnapshot,
    required this.categorySnapshot,
    required this.trackingTypeSnapshot,
    required this.loadConventionSnapshot,
    required this.repsConventionSnapshot,
    this.note,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['template_version_id'] = Variable<int>(templateVersionId);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['exercise_name_snapshot'] = Variable<String>(exerciseNameSnapshot);
    {
      map['category_snapshot'] = Variable<String>(
        $TemplateExercisesTable.$convertercategorySnapshot.toSql(
          categorySnapshot,
        ),
      );
    }
    {
      map['tracking_type_snapshot'] = Variable<String>(
        $TemplateExercisesTable.$convertertrackingTypeSnapshot.toSql(
          trackingTypeSnapshot,
        ),
      );
    }
    {
      map['load_convention_snapshot'] = Variable<String>(
        $TemplateExercisesTable.$converterloadConventionSnapshot.toSql(
          loadConventionSnapshot,
        ),
      );
    }
    {
      map['reps_convention_snapshot'] = Variable<String>(
        $TemplateExercisesTable.$converterrepsConventionSnapshot.toSql(
          repsConventionSnapshot,
        ),
      );
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TemplateExercisesCompanion toCompanion(bool nullToAbsent) {
    return TemplateExercisesCompanion(
      id: Value(id),
      templateVersionId: Value(templateVersionId),
      exerciseId: Value(exerciseId),
      exerciseNameSnapshot: Value(exerciseNameSnapshot),
      categorySnapshot: Value(categorySnapshot),
      trackingTypeSnapshot: Value(trackingTypeSnapshot),
      loadConventionSnapshot: Value(loadConventionSnapshot),
      repsConventionSnapshot: Value(repsConventionSnapshot),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      sortOrder: Value(sortOrder),
    );
  }

  factory TemplateExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateExercise(
      id: serializer.fromJson<int>(json['id']),
      templateVersionId: serializer.fromJson<int>(json['templateVersionId']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      exerciseNameSnapshot: serializer.fromJson<String>(
        json['exerciseNameSnapshot'],
      ),
      categorySnapshot: $TemplateExercisesTable.$convertercategorySnapshot
          .fromJson(serializer.fromJson<String>(json['categorySnapshot'])),
      trackingTypeSnapshot: $TemplateExercisesTable
          .$convertertrackingTypeSnapshot
          .fromJson(serializer.fromJson<String>(json['trackingTypeSnapshot'])),
      loadConventionSnapshot: $TemplateExercisesTable
          .$converterloadConventionSnapshot
          .fromJson(
            serializer.fromJson<String>(json['loadConventionSnapshot']),
          ),
      repsConventionSnapshot: $TemplateExercisesTable
          .$converterrepsConventionSnapshot
          .fromJson(
            serializer.fromJson<String>(json['repsConventionSnapshot']),
          ),
      note: serializer.fromJson<String?>(json['note']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'templateVersionId': serializer.toJson<int>(templateVersionId),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'exerciseNameSnapshot': serializer.toJson<String>(exerciseNameSnapshot),
      'categorySnapshot': serializer.toJson<String>(
        $TemplateExercisesTable.$convertercategorySnapshot.toJson(
          categorySnapshot,
        ),
      ),
      'trackingTypeSnapshot': serializer.toJson<String>(
        $TemplateExercisesTable.$convertertrackingTypeSnapshot.toJson(
          trackingTypeSnapshot,
        ),
      ),
      'loadConventionSnapshot': serializer.toJson<String>(
        $TemplateExercisesTable.$converterloadConventionSnapshot.toJson(
          loadConventionSnapshot,
        ),
      ),
      'repsConventionSnapshot': serializer.toJson<String>(
        $TemplateExercisesTable.$converterrepsConventionSnapshot.toJson(
          repsConventionSnapshot,
        ),
      ),
      'note': serializer.toJson<String?>(note),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TemplateExercise copyWith({
    int? id,
    int? templateVersionId,
    int? exerciseId,
    String? exerciseNameSnapshot,
    ExerciseCategory? categorySnapshot,
    TrackingType? trackingTypeSnapshot,
    LoadConvention? loadConventionSnapshot,
    RepsConvention? repsConventionSnapshot,
    Value<String?> note = const Value.absent(),
    int? sortOrder,
  }) => TemplateExercise(
    id: id ?? this.id,
    templateVersionId: templateVersionId ?? this.templateVersionId,
    exerciseId: exerciseId ?? this.exerciseId,
    exerciseNameSnapshot: exerciseNameSnapshot ?? this.exerciseNameSnapshot,
    categorySnapshot: categorySnapshot ?? this.categorySnapshot,
    trackingTypeSnapshot: trackingTypeSnapshot ?? this.trackingTypeSnapshot,
    loadConventionSnapshot:
        loadConventionSnapshot ?? this.loadConventionSnapshot,
    repsConventionSnapshot:
        repsConventionSnapshot ?? this.repsConventionSnapshot,
    note: note.present ? note.value : this.note,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  TemplateExercise copyWithCompanion(TemplateExercisesCompanion data) {
    return TemplateExercise(
      id: data.id.present ? data.id.value : this.id,
      templateVersionId: data.templateVersionId.present
          ? data.templateVersionId.value
          : this.templateVersionId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      exerciseNameSnapshot: data.exerciseNameSnapshot.present
          ? data.exerciseNameSnapshot.value
          : this.exerciseNameSnapshot,
      categorySnapshot: data.categorySnapshot.present
          ? data.categorySnapshot.value
          : this.categorySnapshot,
      trackingTypeSnapshot: data.trackingTypeSnapshot.present
          ? data.trackingTypeSnapshot.value
          : this.trackingTypeSnapshot,
      loadConventionSnapshot: data.loadConventionSnapshot.present
          ? data.loadConventionSnapshot.value
          : this.loadConventionSnapshot,
      repsConventionSnapshot: data.repsConventionSnapshot.present
          ? data.repsConventionSnapshot.value
          : this.repsConventionSnapshot,
      note: data.note.present ? data.note.value : this.note,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateExercise(')
          ..write('id: $id, ')
          ..write('templateVersionId: $templateVersionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseNameSnapshot: $exerciseNameSnapshot, ')
          ..write('categorySnapshot: $categorySnapshot, ')
          ..write('trackingTypeSnapshot: $trackingTypeSnapshot, ')
          ..write('loadConventionSnapshot: $loadConventionSnapshot, ')
          ..write('repsConventionSnapshot: $repsConventionSnapshot, ')
          ..write('note: $note, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateVersionId,
    exerciseId,
    exerciseNameSnapshot,
    categorySnapshot,
    trackingTypeSnapshot,
    loadConventionSnapshot,
    repsConventionSnapshot,
    note,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateExercise &&
          other.id == this.id &&
          other.templateVersionId == this.templateVersionId &&
          other.exerciseId == this.exerciseId &&
          other.exerciseNameSnapshot == this.exerciseNameSnapshot &&
          other.categorySnapshot == this.categorySnapshot &&
          other.trackingTypeSnapshot == this.trackingTypeSnapshot &&
          other.loadConventionSnapshot == this.loadConventionSnapshot &&
          other.repsConventionSnapshot == this.repsConventionSnapshot &&
          other.note == this.note &&
          other.sortOrder == this.sortOrder);
}

class TemplateExercisesCompanion extends UpdateCompanion<TemplateExercise> {
  final Value<int> id;
  final Value<int> templateVersionId;
  final Value<int> exerciseId;
  final Value<String> exerciseNameSnapshot;
  final Value<ExerciseCategory> categorySnapshot;
  final Value<TrackingType> trackingTypeSnapshot;
  final Value<LoadConvention> loadConventionSnapshot;
  final Value<RepsConvention> repsConventionSnapshot;
  final Value<String?> note;
  final Value<int> sortOrder;
  const TemplateExercisesCompanion({
    this.id = const Value.absent(),
    this.templateVersionId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.exerciseNameSnapshot = const Value.absent(),
    this.categorySnapshot = const Value.absent(),
    this.trackingTypeSnapshot = const Value.absent(),
    this.loadConventionSnapshot = const Value.absent(),
    this.repsConventionSnapshot = const Value.absent(),
    this.note = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  TemplateExercisesCompanion.insert({
    this.id = const Value.absent(),
    required int templateVersionId,
    required int exerciseId,
    required String exerciseNameSnapshot,
    required ExerciseCategory categorySnapshot,
    required TrackingType trackingTypeSnapshot,
    required LoadConvention loadConventionSnapshot,
    required RepsConvention repsConventionSnapshot,
    this.note = const Value.absent(),
    required int sortOrder,
  }) : templateVersionId = Value(templateVersionId),
       exerciseId = Value(exerciseId),
       exerciseNameSnapshot = Value(exerciseNameSnapshot),
       categorySnapshot = Value(categorySnapshot),
       trackingTypeSnapshot = Value(trackingTypeSnapshot),
       loadConventionSnapshot = Value(loadConventionSnapshot),
       repsConventionSnapshot = Value(repsConventionSnapshot),
       sortOrder = Value(sortOrder);
  static Insertable<TemplateExercise> custom({
    Expression<int>? id,
    Expression<int>? templateVersionId,
    Expression<int>? exerciseId,
    Expression<String>? exerciseNameSnapshot,
    Expression<String>? categorySnapshot,
    Expression<String>? trackingTypeSnapshot,
    Expression<String>? loadConventionSnapshot,
    Expression<String>? repsConventionSnapshot,
    Expression<String>? note,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateVersionId != null) 'template_version_id': templateVersionId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (exerciseNameSnapshot != null)
        'exercise_name_snapshot': exerciseNameSnapshot,
      if (categorySnapshot != null) 'category_snapshot': categorySnapshot,
      if (trackingTypeSnapshot != null)
        'tracking_type_snapshot': trackingTypeSnapshot,
      if (loadConventionSnapshot != null)
        'load_convention_snapshot': loadConventionSnapshot,
      if (repsConventionSnapshot != null)
        'reps_convention_snapshot': repsConventionSnapshot,
      if (note != null) 'note': note,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  TemplateExercisesCompanion copyWith({
    Value<int>? id,
    Value<int>? templateVersionId,
    Value<int>? exerciseId,
    Value<String>? exerciseNameSnapshot,
    Value<ExerciseCategory>? categorySnapshot,
    Value<TrackingType>? trackingTypeSnapshot,
    Value<LoadConvention>? loadConventionSnapshot,
    Value<RepsConvention>? repsConventionSnapshot,
    Value<String?>? note,
    Value<int>? sortOrder,
  }) {
    return TemplateExercisesCompanion(
      id: id ?? this.id,
      templateVersionId: templateVersionId ?? this.templateVersionId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseNameSnapshot: exerciseNameSnapshot ?? this.exerciseNameSnapshot,
      categorySnapshot: categorySnapshot ?? this.categorySnapshot,
      trackingTypeSnapshot: trackingTypeSnapshot ?? this.trackingTypeSnapshot,
      loadConventionSnapshot:
          loadConventionSnapshot ?? this.loadConventionSnapshot,
      repsConventionSnapshot:
          repsConventionSnapshot ?? this.repsConventionSnapshot,
      note: note ?? this.note,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (templateVersionId.present) {
      map['template_version_id'] = Variable<int>(templateVersionId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (exerciseNameSnapshot.present) {
      map['exercise_name_snapshot'] = Variable<String>(
        exerciseNameSnapshot.value,
      );
    }
    if (categorySnapshot.present) {
      map['category_snapshot'] = Variable<String>(
        $TemplateExercisesTable.$convertercategorySnapshot.toSql(
          categorySnapshot.value,
        ),
      );
    }
    if (trackingTypeSnapshot.present) {
      map['tracking_type_snapshot'] = Variable<String>(
        $TemplateExercisesTable.$convertertrackingTypeSnapshot.toSql(
          trackingTypeSnapshot.value,
        ),
      );
    }
    if (loadConventionSnapshot.present) {
      map['load_convention_snapshot'] = Variable<String>(
        $TemplateExercisesTable.$converterloadConventionSnapshot.toSql(
          loadConventionSnapshot.value,
        ),
      );
    }
    if (repsConventionSnapshot.present) {
      map['reps_convention_snapshot'] = Variable<String>(
        $TemplateExercisesTable.$converterrepsConventionSnapshot.toSql(
          repsConventionSnapshot.value,
        ),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateExercisesCompanion(')
          ..write('id: $id, ')
          ..write('templateVersionId: $templateVersionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseNameSnapshot: $exerciseNameSnapshot, ')
          ..write('categorySnapshot: $categorySnapshot, ')
          ..write('trackingTypeSnapshot: $trackingTypeSnapshot, ')
          ..write('loadConventionSnapshot: $loadConventionSnapshot, ')
          ..write('repsConventionSnapshot: $repsConventionSnapshot, ')
          ..write('note: $note, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $TemplateSetsTable extends TemplateSets
    with TableInfo<$TemplateSetsTable, TemplateSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _templateExerciseIdMeta =
      const VerificationMeta('templateExerciseId');
  @override
  late final GeneratedColumn<int> templateExerciseId = GeneratedColumn<int>(
    'template_exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES template_exercises (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SetRole, String> setRole =
      GeneratedColumn<String>(
        'set_role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SetRole>($TemplateSetsTable.$convertersetRole);
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minimumRepsMeta = const VerificationMeta(
    'minimumReps',
  );
  @override
  late final GeneratedColumn<int> minimumReps = GeneratedColumn<int>(
    'minimum_reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minimumDurationSecondsMeta =
      const VerificationMeta('minimumDurationSeconds');
  @override
  late final GeneratedColumn<int> minimumDurationSeconds = GeneratedColumn<int>(
    'minimum_duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_meters',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minimumDistanceMetersMeta =
      const VerificationMeta('minimumDistanceMeters');
  @override
  late final GeneratedColumn<double> minimumDistanceMeters =
      GeneratedColumn<double>(
        'minimum_distance_meters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _externalLoadKgMeta = const VerificationMeta(
    'externalLoadKg',
  );
  @override
  late final GeneratedColumn<double> externalLoadKg = GeneratedColumn<double>(
    'external_load_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assistanceKgMeta = const VerificationMeta(
    'assistanceKg',
  );
  @override
  late final GeneratedColumn<double> assistanceKg = GeneratedColumn<double>(
    'assistance_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<double> rpe = GeneratedColumn<double>(
    'rpe',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rirMeta = const VerificationMeta('rir');
  @override
  late final GeneratedColumn<double> rir = GeneratedColumn<double>(
    'rir',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateExerciseId,
    setRole,
    reps,
    minimumReps,
    durationSeconds,
    minimumDurationSeconds,
    distanceMeters,
    minimumDistanceMeters,
    externalLoadKg,
    assistanceKg,
    rpe,
    rir,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('template_exercise_id')) {
      context.handle(
        _templateExerciseIdMeta,
        templateExerciseId.isAcceptableOrUnknown(
          data['template_exercise_id']!,
          _templateExerciseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateExerciseIdMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('minimum_reps')) {
      context.handle(
        _minimumRepsMeta,
        minimumReps.isAcceptableOrUnknown(
          data['minimum_reps']!,
          _minimumRepsMeta,
        ),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('minimum_duration_seconds')) {
      context.handle(
        _minimumDurationSecondsMeta,
        minimumDurationSeconds.isAcceptableOrUnknown(
          data['minimum_duration_seconds']!,
          _minimumDurationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('minimum_distance_meters')) {
      context.handle(
        _minimumDistanceMetersMeta,
        minimumDistanceMeters.isAcceptableOrUnknown(
          data['minimum_distance_meters']!,
          _minimumDistanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('external_load_kg')) {
      context.handle(
        _externalLoadKgMeta,
        externalLoadKg.isAcceptableOrUnknown(
          data['external_load_kg']!,
          _externalLoadKgMeta,
        ),
      );
    }
    if (data.containsKey('assistance_kg')) {
      context.handle(
        _assistanceKgMeta,
        assistanceKg.isAcceptableOrUnknown(
          data['assistance_kg']!,
          _assistanceKgMeta,
        ),
      );
    }
    if (data.containsKey('rpe')) {
      context.handle(
        _rpeMeta,
        rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta),
      );
    }
    if (data.containsKey('rir')) {
      context.handle(
        _rirMeta,
        rir.isAcceptableOrUnknown(data['rir']!, _rirMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {templateExerciseId, sortOrder},
  ];
  @override
  TemplateSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      templateExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_exercise_id'],
      )!,
      setRole: $TemplateSetsTable.$convertersetRole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}set_role'],
        )!,
      ),
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      ),
      minimumReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minimum_reps'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      minimumDurationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minimum_duration_seconds'],
      ),
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      ),
      minimumDistanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}minimum_distance_meters'],
      ),
      externalLoadKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}external_load_kg'],
      ),
      assistanceKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}assistance_kg'],
      ),
      rpe: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rpe'],
      ),
      rir: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rir'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $TemplateSetsTable createAlias(String alias) {
    return $TemplateSetsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SetRole, String, String> $convertersetRole =
      const EnumNameConverter<SetRole>(SetRole.values);
}

class TemplateSet extends DataClass implements Insertable<TemplateSet> {
  final int id;
  final int templateExerciseId;
  final SetRole setRole;
  final int? reps;
  final int? minimumReps;
  final int? durationSeconds;
  final int? minimumDurationSeconds;
  final double? distanceMeters;
  final double? minimumDistanceMeters;
  final double? externalLoadKg;
  final double? assistanceKg;
  final double? rpe;
  final double? rir;
  final int sortOrder;
  const TemplateSet({
    required this.id,
    required this.templateExerciseId,
    required this.setRole,
    this.reps,
    this.minimumReps,
    this.durationSeconds,
    this.minimumDurationSeconds,
    this.distanceMeters,
    this.minimumDistanceMeters,
    this.externalLoadKg,
    this.assistanceKg,
    this.rpe,
    this.rir,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['template_exercise_id'] = Variable<int>(templateExerciseId);
    {
      map['set_role'] = Variable<String>(
        $TemplateSetsTable.$convertersetRole.toSql(setRole),
      );
    }
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || minimumReps != null) {
      map['minimum_reps'] = Variable<int>(minimumReps);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || minimumDurationSeconds != null) {
      map['minimum_duration_seconds'] = Variable<int>(minimumDurationSeconds);
    }
    if (!nullToAbsent || distanceMeters != null) {
      map['distance_meters'] = Variable<double>(distanceMeters);
    }
    if (!nullToAbsent || minimumDistanceMeters != null) {
      map['minimum_distance_meters'] = Variable<double>(minimumDistanceMeters);
    }
    if (!nullToAbsent || externalLoadKg != null) {
      map['external_load_kg'] = Variable<double>(externalLoadKg);
    }
    if (!nullToAbsent || assistanceKg != null) {
      map['assistance_kg'] = Variable<double>(assistanceKg);
    }
    if (!nullToAbsent || rpe != null) {
      map['rpe'] = Variable<double>(rpe);
    }
    if (!nullToAbsent || rir != null) {
      map['rir'] = Variable<double>(rir);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TemplateSetsCompanion toCompanion(bool nullToAbsent) {
    return TemplateSetsCompanion(
      id: Value(id),
      templateExerciseId: Value(templateExerciseId),
      setRole: Value(setRole),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      minimumReps: minimumReps == null && nullToAbsent
          ? const Value.absent()
          : Value(minimumReps),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      minimumDurationSeconds: minimumDurationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(minimumDurationSeconds),
      distanceMeters: distanceMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceMeters),
      minimumDistanceMeters: minimumDistanceMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(minimumDistanceMeters),
      externalLoadKg: externalLoadKg == null && nullToAbsent
          ? const Value.absent()
          : Value(externalLoadKg),
      assistanceKg: assistanceKg == null && nullToAbsent
          ? const Value.absent()
          : Value(assistanceKg),
      rpe: rpe == null && nullToAbsent ? const Value.absent() : Value(rpe),
      rir: rir == null && nullToAbsent ? const Value.absent() : Value(rir),
      sortOrder: Value(sortOrder),
    );
  }

  factory TemplateSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateSet(
      id: serializer.fromJson<int>(json['id']),
      templateExerciseId: serializer.fromJson<int>(json['templateExerciseId']),
      setRole: $TemplateSetsTable.$convertersetRole.fromJson(
        serializer.fromJson<String>(json['setRole']),
      ),
      reps: serializer.fromJson<int?>(json['reps']),
      minimumReps: serializer.fromJson<int?>(json['minimumReps']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      minimumDurationSeconds: serializer.fromJson<int?>(
        json['minimumDurationSeconds'],
      ),
      distanceMeters: serializer.fromJson<double?>(json['distanceMeters']),
      minimumDistanceMeters: serializer.fromJson<double?>(
        json['minimumDistanceMeters'],
      ),
      externalLoadKg: serializer.fromJson<double?>(json['externalLoadKg']),
      assistanceKg: serializer.fromJson<double?>(json['assistanceKg']),
      rpe: serializer.fromJson<double?>(json['rpe']),
      rir: serializer.fromJson<double?>(json['rir']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'templateExerciseId': serializer.toJson<int>(templateExerciseId),
      'setRole': serializer.toJson<String>(
        $TemplateSetsTable.$convertersetRole.toJson(setRole),
      ),
      'reps': serializer.toJson<int?>(reps),
      'minimumReps': serializer.toJson<int?>(minimumReps),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'minimumDurationSeconds': serializer.toJson<int?>(minimumDurationSeconds),
      'distanceMeters': serializer.toJson<double?>(distanceMeters),
      'minimumDistanceMeters': serializer.toJson<double?>(
        minimumDistanceMeters,
      ),
      'externalLoadKg': serializer.toJson<double?>(externalLoadKg),
      'assistanceKg': serializer.toJson<double?>(assistanceKg),
      'rpe': serializer.toJson<double?>(rpe),
      'rir': serializer.toJson<double?>(rir),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TemplateSet copyWith({
    int? id,
    int? templateExerciseId,
    SetRole? setRole,
    Value<int?> reps = const Value.absent(),
    Value<int?> minimumReps = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    Value<int?> minimumDurationSeconds = const Value.absent(),
    Value<double?> distanceMeters = const Value.absent(),
    Value<double?> minimumDistanceMeters = const Value.absent(),
    Value<double?> externalLoadKg = const Value.absent(),
    Value<double?> assistanceKg = const Value.absent(),
    Value<double?> rpe = const Value.absent(),
    Value<double?> rir = const Value.absent(),
    int? sortOrder,
  }) => TemplateSet(
    id: id ?? this.id,
    templateExerciseId: templateExerciseId ?? this.templateExerciseId,
    setRole: setRole ?? this.setRole,
    reps: reps.present ? reps.value : this.reps,
    minimumReps: minimumReps.present ? minimumReps.value : this.minimumReps,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    minimumDurationSeconds: minimumDurationSeconds.present
        ? minimumDurationSeconds.value
        : this.minimumDurationSeconds,
    distanceMeters: distanceMeters.present
        ? distanceMeters.value
        : this.distanceMeters,
    minimumDistanceMeters: minimumDistanceMeters.present
        ? minimumDistanceMeters.value
        : this.minimumDistanceMeters,
    externalLoadKg: externalLoadKg.present
        ? externalLoadKg.value
        : this.externalLoadKg,
    assistanceKg: assistanceKg.present ? assistanceKg.value : this.assistanceKg,
    rpe: rpe.present ? rpe.value : this.rpe,
    rir: rir.present ? rir.value : this.rir,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  TemplateSet copyWithCompanion(TemplateSetsCompanion data) {
    return TemplateSet(
      id: data.id.present ? data.id.value : this.id,
      templateExerciseId: data.templateExerciseId.present
          ? data.templateExerciseId.value
          : this.templateExerciseId,
      setRole: data.setRole.present ? data.setRole.value : this.setRole,
      reps: data.reps.present ? data.reps.value : this.reps,
      minimumReps: data.minimumReps.present
          ? data.minimumReps.value
          : this.minimumReps,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      minimumDurationSeconds: data.minimumDurationSeconds.present
          ? data.minimumDurationSeconds.value
          : this.minimumDurationSeconds,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      minimumDistanceMeters: data.minimumDistanceMeters.present
          ? data.minimumDistanceMeters.value
          : this.minimumDistanceMeters,
      externalLoadKg: data.externalLoadKg.present
          ? data.externalLoadKg.value
          : this.externalLoadKg,
      assistanceKg: data.assistanceKg.present
          ? data.assistanceKg.value
          : this.assistanceKg,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      rir: data.rir.present ? data.rir.value : this.rir,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateSet(')
          ..write('id: $id, ')
          ..write('templateExerciseId: $templateExerciseId, ')
          ..write('setRole: $setRole, ')
          ..write('reps: $reps, ')
          ..write('minimumReps: $minimumReps, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('minimumDurationSeconds: $minimumDurationSeconds, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('minimumDistanceMeters: $minimumDistanceMeters, ')
          ..write('externalLoadKg: $externalLoadKg, ')
          ..write('assistanceKg: $assistanceKg, ')
          ..write('rpe: $rpe, ')
          ..write('rir: $rir, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateExerciseId,
    setRole,
    reps,
    minimumReps,
    durationSeconds,
    minimumDurationSeconds,
    distanceMeters,
    minimumDistanceMeters,
    externalLoadKg,
    assistanceKg,
    rpe,
    rir,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateSet &&
          other.id == this.id &&
          other.templateExerciseId == this.templateExerciseId &&
          other.setRole == this.setRole &&
          other.reps == this.reps &&
          other.minimumReps == this.minimumReps &&
          other.durationSeconds == this.durationSeconds &&
          other.minimumDurationSeconds == this.minimumDurationSeconds &&
          other.distanceMeters == this.distanceMeters &&
          other.minimumDistanceMeters == this.minimumDistanceMeters &&
          other.externalLoadKg == this.externalLoadKg &&
          other.assistanceKg == this.assistanceKg &&
          other.rpe == this.rpe &&
          other.rir == this.rir &&
          other.sortOrder == this.sortOrder);
}

class TemplateSetsCompanion extends UpdateCompanion<TemplateSet> {
  final Value<int> id;
  final Value<int> templateExerciseId;
  final Value<SetRole> setRole;
  final Value<int?> reps;
  final Value<int?> minimumReps;
  final Value<int?> durationSeconds;
  final Value<int?> minimumDurationSeconds;
  final Value<double?> distanceMeters;
  final Value<double?> minimumDistanceMeters;
  final Value<double?> externalLoadKg;
  final Value<double?> assistanceKg;
  final Value<double?> rpe;
  final Value<double?> rir;
  final Value<int> sortOrder;
  const TemplateSetsCompanion({
    this.id = const Value.absent(),
    this.templateExerciseId = const Value.absent(),
    this.setRole = const Value.absent(),
    this.reps = const Value.absent(),
    this.minimumReps = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.minimumDurationSeconds = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.minimumDistanceMeters = const Value.absent(),
    this.externalLoadKg = const Value.absent(),
    this.assistanceKg = const Value.absent(),
    this.rpe = const Value.absent(),
    this.rir = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  TemplateSetsCompanion.insert({
    this.id = const Value.absent(),
    required int templateExerciseId,
    required SetRole setRole,
    this.reps = const Value.absent(),
    this.minimumReps = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.minimumDurationSeconds = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.minimumDistanceMeters = const Value.absent(),
    this.externalLoadKg = const Value.absent(),
    this.assistanceKg = const Value.absent(),
    this.rpe = const Value.absent(),
    this.rir = const Value.absent(),
    required int sortOrder,
  }) : templateExerciseId = Value(templateExerciseId),
       setRole = Value(setRole),
       sortOrder = Value(sortOrder);
  static Insertable<TemplateSet> custom({
    Expression<int>? id,
    Expression<int>? templateExerciseId,
    Expression<String>? setRole,
    Expression<int>? reps,
    Expression<int>? minimumReps,
    Expression<int>? durationSeconds,
    Expression<int>? minimumDurationSeconds,
    Expression<double>? distanceMeters,
    Expression<double>? minimumDistanceMeters,
    Expression<double>? externalLoadKg,
    Expression<double>? assistanceKg,
    Expression<double>? rpe,
    Expression<double>? rir,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateExerciseId != null)
        'template_exercise_id': templateExerciseId,
      if (setRole != null) 'set_role': setRole,
      if (reps != null) 'reps': reps,
      if (minimumReps != null) 'minimum_reps': minimumReps,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (minimumDurationSeconds != null)
        'minimum_duration_seconds': minimumDurationSeconds,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (minimumDistanceMeters != null)
        'minimum_distance_meters': minimumDistanceMeters,
      if (externalLoadKg != null) 'external_load_kg': externalLoadKg,
      if (assistanceKg != null) 'assistance_kg': assistanceKg,
      if (rpe != null) 'rpe': rpe,
      if (rir != null) 'rir': rir,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  TemplateSetsCompanion copyWith({
    Value<int>? id,
    Value<int>? templateExerciseId,
    Value<SetRole>? setRole,
    Value<int?>? reps,
    Value<int?>? minimumReps,
    Value<int?>? durationSeconds,
    Value<int?>? minimumDurationSeconds,
    Value<double?>? distanceMeters,
    Value<double?>? minimumDistanceMeters,
    Value<double?>? externalLoadKg,
    Value<double?>? assistanceKg,
    Value<double?>? rpe,
    Value<double?>? rir,
    Value<int>? sortOrder,
  }) {
    return TemplateSetsCompanion(
      id: id ?? this.id,
      templateExerciseId: templateExerciseId ?? this.templateExerciseId,
      setRole: setRole ?? this.setRole,
      reps: reps ?? this.reps,
      minimumReps: minimumReps ?? this.minimumReps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      minimumDurationSeconds:
          minimumDurationSeconds ?? this.minimumDurationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      minimumDistanceMeters:
          minimumDistanceMeters ?? this.minimumDistanceMeters,
      externalLoadKg: externalLoadKg ?? this.externalLoadKg,
      assistanceKg: assistanceKg ?? this.assistanceKg,
      rpe: rpe ?? this.rpe,
      rir: rir ?? this.rir,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (templateExerciseId.present) {
      map['template_exercise_id'] = Variable<int>(templateExerciseId.value);
    }
    if (setRole.present) {
      map['set_role'] = Variable<String>(
        $TemplateSetsTable.$convertersetRole.toSql(setRole.value),
      );
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (minimumReps.present) {
      map['minimum_reps'] = Variable<int>(minimumReps.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (minimumDurationSeconds.present) {
      map['minimum_duration_seconds'] = Variable<int>(
        minimumDurationSeconds.value,
      );
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (minimumDistanceMeters.present) {
      map['minimum_distance_meters'] = Variable<double>(
        minimumDistanceMeters.value,
      );
    }
    if (externalLoadKg.present) {
      map['external_load_kg'] = Variable<double>(externalLoadKg.value);
    }
    if (assistanceKg.present) {
      map['assistance_kg'] = Variable<double>(assistanceKg.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<double>(rpe.value);
    }
    if (rir.present) {
      map['rir'] = Variable<double>(rir.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateSetsCompanion(')
          ..write('id: $id, ')
          ..write('templateExerciseId: $templateExerciseId, ')
          ..write('setRole: $setRole, ')
          ..write('reps: $reps, ')
          ..write('minimumReps: $minimumReps, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('minimumDurationSeconds: $minimumDurationSeconds, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('minimumDistanceMeters: $minimumDistanceMeters, ')
          ..write('externalLoadKg: $externalLoadKg, ')
          ..write('assistanceKg: $assistanceKg, ')
          ..write('rpe: $rpe, ')
          ..write('rir: $rir, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $WorkoutsTable extends Workouts with TableInfo<$WorkoutsTable, Workout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WorkoutStatus, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<WorkoutStatus>($WorkoutsTable.$converterstatus);
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pausedAtMeta = const VerificationMeta(
    'pausedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pausedAt = GeneratedColumn<DateTime>(
    'paused_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pausedSecondsMeta = const VerificationMeta(
    'pausedSeconds',
  );
  @override
  late final GeneratedColumn<int> pausedSeconds = GeneratedColumn<int>(
    'paused_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalSecondsMeta = const VerificationMeta(
    'totalSeconds',
  );
  @override
  late final GeneratedColumn<int> totalSeconds = GeneratedColumn<int>(
    'total_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _feelingMeta = const VerificationMeta(
    'feeling',
  );
  @override
  late final GeneratedColumn<String> feeling = GeneratedColumn<String>(
    'feeling',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _templateVersionIdMeta = const VerificationMeta(
    'templateVersionId',
  );
  @override
  late final GeneratedColumn<int> templateVersionId = GeneratedColumn<int>(
    'template_version_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES template_versions (id)',
    ),
  );
  static const VerificationMeta _templateNameSnapshotMeta =
      const VerificationMeta('templateNameSnapshot');
  @override
  late final GeneratedColumn<String> templateNameSnapshot =
      GeneratedColumn<String>(
        'template_name_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _templateEvaluationPolicyVersionMeta =
      const VerificationMeta('templateEvaluationPolicyVersion');
  @override
  late final GeneratedColumn<int> templateEvaluationPolicyVersion =
      GeneratedColumn<int>(
        'template_evaluation_policy_version',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    status,
    startedAt,
    endedAt,
    pausedAt,
    pausedSeconds,
    totalSeconds,
    feeling,
    templateVersionId,
    templateNameSnapshot,
    templateEvaluationPolicyVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Workout> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('paused_at')) {
      context.handle(
        _pausedAtMeta,
        pausedAt.isAcceptableOrUnknown(data['paused_at']!, _pausedAtMeta),
      );
    }
    if (data.containsKey('paused_seconds')) {
      context.handle(
        _pausedSecondsMeta,
        pausedSeconds.isAcceptableOrUnknown(
          data['paused_seconds']!,
          _pausedSecondsMeta,
        ),
      );
    }
    if (data.containsKey('total_seconds')) {
      context.handle(
        _totalSecondsMeta,
        totalSeconds.isAcceptableOrUnknown(
          data['total_seconds']!,
          _totalSecondsMeta,
        ),
      );
    }
    if (data.containsKey('feeling')) {
      context.handle(
        _feelingMeta,
        feeling.isAcceptableOrUnknown(data['feeling']!, _feelingMeta),
      );
    }
    if (data.containsKey('template_version_id')) {
      context.handle(
        _templateVersionIdMeta,
        templateVersionId.isAcceptableOrUnknown(
          data['template_version_id']!,
          _templateVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('template_name_snapshot')) {
      context.handle(
        _templateNameSnapshotMeta,
        templateNameSnapshot.isAcceptableOrUnknown(
          data['template_name_snapshot']!,
          _templateNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('template_evaluation_policy_version')) {
      context.handle(
        _templateEvaluationPolicyVersionMeta,
        templateEvaluationPolicyVersion.isAcceptableOrUnknown(
          data['template_evaluation_policy_version']!,
          _templateEvaluationPolicyVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Workout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Workout(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      status: $WorkoutsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      pausedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paused_at'],
      ),
      pausedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paused_seconds'],
      )!,
      totalSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_seconds'],
      ),
      feeling: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feeling'],
      ),
      templateVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_version_id'],
      ),
      templateNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_name_snapshot'],
      ),
      templateEvaluationPolicyVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_evaluation_policy_version'],
      ),
    );
  }

  @override
  $WorkoutsTable createAlias(String alias) {
    return $WorkoutsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WorkoutStatus, int, int> $converterstatus =
      const EnumIndexConverter<WorkoutStatus>(WorkoutStatus.values);
}

class Workout extends DataClass implements Insertable<Workout> {
  final int id;

  /// 归属日期（只存日期部分）；实时训练取开始当天，跨午夜不拆分
  final DateTime date;
  final WorkoutStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;

  /// 暂停中标记；非空表示当前处于暂停
  final DateTime? pausedAt;

  /// 已累计的暂停秒数（恢复时累加）
  final int pausedSeconds;

  /// 训练总用时（秒）；未知即为 null，绝不推算
  final int? totalSeconds;
  final String? feeling;
  final int? templateVersionId;
  final String? templateNameSnapshot;
  final int? templateEvaluationPolicyVersion;
  const Workout({
    required this.id,
    required this.date,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.pausedAt,
    required this.pausedSeconds,
    this.totalSeconds,
    this.feeling,
    this.templateVersionId,
    this.templateNameSnapshot,
    this.templateEvaluationPolicyVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    {
      map['status'] = Variable<int>(
        $WorkoutsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || pausedAt != null) {
      map['paused_at'] = Variable<DateTime>(pausedAt);
    }
    map['paused_seconds'] = Variable<int>(pausedSeconds);
    if (!nullToAbsent || totalSeconds != null) {
      map['total_seconds'] = Variable<int>(totalSeconds);
    }
    if (!nullToAbsent || feeling != null) {
      map['feeling'] = Variable<String>(feeling);
    }
    if (!nullToAbsent || templateVersionId != null) {
      map['template_version_id'] = Variable<int>(templateVersionId);
    }
    if (!nullToAbsent || templateNameSnapshot != null) {
      map['template_name_snapshot'] = Variable<String>(templateNameSnapshot);
    }
    if (!nullToAbsent || templateEvaluationPolicyVersion != null) {
      map['template_evaluation_policy_version'] = Variable<int>(
        templateEvaluationPolicyVersion,
      );
    }
    return map;
  }

  WorkoutsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutsCompanion(
      id: Value(id),
      date: Value(date),
      status: Value(status),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      pausedAt: pausedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedAt),
      pausedSeconds: Value(pausedSeconds),
      totalSeconds: totalSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(totalSeconds),
      feeling: feeling == null && nullToAbsent
          ? const Value.absent()
          : Value(feeling),
      templateVersionId: templateVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateVersionId),
      templateNameSnapshot: templateNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(templateNameSnapshot),
      templateEvaluationPolicyVersion:
          templateEvaluationPolicyVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(templateEvaluationPolicyVersion),
    );
  }

  factory Workout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Workout(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      status: $WorkoutsTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      pausedAt: serializer.fromJson<DateTime?>(json['pausedAt']),
      pausedSeconds: serializer.fromJson<int>(json['pausedSeconds']),
      totalSeconds: serializer.fromJson<int?>(json['totalSeconds']),
      feeling: serializer.fromJson<String?>(json['feeling']),
      templateVersionId: serializer.fromJson<int?>(json['templateVersionId']),
      templateNameSnapshot: serializer.fromJson<String?>(
        json['templateNameSnapshot'],
      ),
      templateEvaluationPolicyVersion: serializer.fromJson<int?>(
        json['templateEvaluationPolicyVersion'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'status': serializer.toJson<int>(
        $WorkoutsTable.$converterstatus.toJson(status),
      ),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'pausedAt': serializer.toJson<DateTime?>(pausedAt),
      'pausedSeconds': serializer.toJson<int>(pausedSeconds),
      'totalSeconds': serializer.toJson<int?>(totalSeconds),
      'feeling': serializer.toJson<String?>(feeling),
      'templateVersionId': serializer.toJson<int?>(templateVersionId),
      'templateNameSnapshot': serializer.toJson<String?>(templateNameSnapshot),
      'templateEvaluationPolicyVersion': serializer.toJson<int?>(
        templateEvaluationPolicyVersion,
      ),
    };
  }

  Workout copyWith({
    int? id,
    DateTime? date,
    WorkoutStatus? status,
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> endedAt = const Value.absent(),
    Value<DateTime?> pausedAt = const Value.absent(),
    int? pausedSeconds,
    Value<int?> totalSeconds = const Value.absent(),
    Value<String?> feeling = const Value.absent(),
    Value<int?> templateVersionId = const Value.absent(),
    Value<String?> templateNameSnapshot = const Value.absent(),
    Value<int?> templateEvaluationPolicyVersion = const Value.absent(),
  }) => Workout(
    id: id ?? this.id,
    date: date ?? this.date,
    status: status ?? this.status,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    pausedAt: pausedAt.present ? pausedAt.value : this.pausedAt,
    pausedSeconds: pausedSeconds ?? this.pausedSeconds,
    totalSeconds: totalSeconds.present ? totalSeconds.value : this.totalSeconds,
    feeling: feeling.present ? feeling.value : this.feeling,
    templateVersionId: templateVersionId.present
        ? templateVersionId.value
        : this.templateVersionId,
    templateNameSnapshot: templateNameSnapshot.present
        ? templateNameSnapshot.value
        : this.templateNameSnapshot,
    templateEvaluationPolicyVersion: templateEvaluationPolicyVersion.present
        ? templateEvaluationPolicyVersion.value
        : this.templateEvaluationPolicyVersion,
  );
  Workout copyWithCompanion(WorkoutsCompanion data) {
    return Workout(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      pausedAt: data.pausedAt.present ? data.pausedAt.value : this.pausedAt,
      pausedSeconds: data.pausedSeconds.present
          ? data.pausedSeconds.value
          : this.pausedSeconds,
      totalSeconds: data.totalSeconds.present
          ? data.totalSeconds.value
          : this.totalSeconds,
      feeling: data.feeling.present ? data.feeling.value : this.feeling,
      templateVersionId: data.templateVersionId.present
          ? data.templateVersionId.value
          : this.templateVersionId,
      templateNameSnapshot: data.templateNameSnapshot.present
          ? data.templateNameSnapshot.value
          : this.templateNameSnapshot,
      templateEvaluationPolicyVersion:
          data.templateEvaluationPolicyVersion.present
          ? data.templateEvaluationPolicyVersion.value
          : this.templateEvaluationPolicyVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Workout(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('pausedSeconds: $pausedSeconds, ')
          ..write('totalSeconds: $totalSeconds, ')
          ..write('feeling: $feeling, ')
          ..write('templateVersionId: $templateVersionId, ')
          ..write('templateNameSnapshot: $templateNameSnapshot, ')
          ..write(
            'templateEvaluationPolicyVersion: $templateEvaluationPolicyVersion',
          )
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    status,
    startedAt,
    endedAt,
    pausedAt,
    pausedSeconds,
    totalSeconds,
    feeling,
    templateVersionId,
    templateNameSnapshot,
    templateEvaluationPolicyVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Workout &&
          other.id == this.id &&
          other.date == this.date &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.pausedAt == this.pausedAt &&
          other.pausedSeconds == this.pausedSeconds &&
          other.totalSeconds == this.totalSeconds &&
          other.feeling == this.feeling &&
          other.templateVersionId == this.templateVersionId &&
          other.templateNameSnapshot == this.templateNameSnapshot &&
          other.templateEvaluationPolicyVersion ==
              this.templateEvaluationPolicyVersion);
}

class WorkoutsCompanion extends UpdateCompanion<Workout> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<WorkoutStatus> status;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> endedAt;
  final Value<DateTime?> pausedAt;
  final Value<int> pausedSeconds;
  final Value<int?> totalSeconds;
  final Value<String?> feeling;
  final Value<int?> templateVersionId;
  final Value<String?> templateNameSnapshot;
  final Value<int?> templateEvaluationPolicyVersion;
  const WorkoutsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.pausedSeconds = const Value.absent(),
    this.totalSeconds = const Value.absent(),
    this.feeling = const Value.absent(),
    this.templateVersionId = const Value.absent(),
    this.templateNameSnapshot = const Value.absent(),
    this.templateEvaluationPolicyVersion = const Value.absent(),
  });
  WorkoutsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required WorkoutStatus status,
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.pausedSeconds = const Value.absent(),
    this.totalSeconds = const Value.absent(),
    this.feeling = const Value.absent(),
    this.templateVersionId = const Value.absent(),
    this.templateNameSnapshot = const Value.absent(),
    this.templateEvaluationPolicyVersion = const Value.absent(),
  }) : date = Value(date),
       status = Value(status);
  static Insertable<Workout> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? status,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<DateTime>? pausedAt,
    Expression<int>? pausedSeconds,
    Expression<int>? totalSeconds,
    Expression<String>? feeling,
    Expression<int>? templateVersionId,
    Expression<String>? templateNameSnapshot,
    Expression<int>? templateEvaluationPolicyVersion,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (pausedAt != null) 'paused_at': pausedAt,
      if (pausedSeconds != null) 'paused_seconds': pausedSeconds,
      if (totalSeconds != null) 'total_seconds': totalSeconds,
      if (feeling != null) 'feeling': feeling,
      if (templateVersionId != null) 'template_version_id': templateVersionId,
      if (templateNameSnapshot != null)
        'template_name_snapshot': templateNameSnapshot,
      if (templateEvaluationPolicyVersion != null)
        'template_evaluation_policy_version': templateEvaluationPolicyVersion,
    });
  }

  WorkoutsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<WorkoutStatus>? status,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? endedAt,
    Value<DateTime?>? pausedAt,
    Value<int>? pausedSeconds,
    Value<int?>? totalSeconds,
    Value<String?>? feeling,
    Value<int?>? templateVersionId,
    Value<String?>? templateNameSnapshot,
    Value<int?>? templateEvaluationPolicyVersion,
  }) {
    return WorkoutsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      pausedSeconds: pausedSeconds ?? this.pausedSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      feeling: feeling ?? this.feeling,
      templateVersionId: templateVersionId ?? this.templateVersionId,
      templateNameSnapshot: templateNameSnapshot ?? this.templateNameSnapshot,
      templateEvaluationPolicyVersion:
          templateEvaluationPolicyVersion ??
          this.templateEvaluationPolicyVersion,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $WorkoutsTable.$converterstatus.toSql(status.value),
      );
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (pausedAt.present) {
      map['paused_at'] = Variable<DateTime>(pausedAt.value);
    }
    if (pausedSeconds.present) {
      map['paused_seconds'] = Variable<int>(pausedSeconds.value);
    }
    if (totalSeconds.present) {
      map['total_seconds'] = Variable<int>(totalSeconds.value);
    }
    if (feeling.present) {
      map['feeling'] = Variable<String>(feeling.value);
    }
    if (templateVersionId.present) {
      map['template_version_id'] = Variable<int>(templateVersionId.value);
    }
    if (templateNameSnapshot.present) {
      map['template_name_snapshot'] = Variable<String>(
        templateNameSnapshot.value,
      );
    }
    if (templateEvaluationPolicyVersion.present) {
      map['template_evaluation_policy_version'] = Variable<int>(
        templateEvaluationPolicyVersion.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('pausedSeconds: $pausedSeconds, ')
          ..write('totalSeconds: $totalSeconds, ')
          ..write('feeling: $feeling, ')
          ..write('templateVersionId: $templateVersionId, ')
          ..write('templateNameSnapshot: $templateNameSnapshot, ')
          ..write(
            'templateEvaluationPolicyVersion: $templateEvaluationPolicyVersion',
          )
          ..write(')'))
        .toString();
  }
}

class $WorkoutExercisesTable extends WorkoutExercises
    with TableInfo<$WorkoutExercisesTable, WorkoutExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<int> workoutId = GeneratedColumn<int>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workouts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _catalogExerciseIdMeta = const VerificationMeta(
    'catalogExerciseId',
  );
  @override
  late final GeneratedColumn<int> catalogExerciseId = GeneratedColumn<int>(
    'catalog_exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'exercise_name_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ExerciseCategory, String>
  category = GeneratedColumn<String>(
    'category_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ExerciseCategory>($WorkoutExercisesTable.$convertercategory);
  @override
  late final GeneratedColumnWithTypeConverter<TrackingType, String>
  trackingTypeSnapshot =
      GeneratedColumn<String>(
        'tracking_type_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TrackingType>(
        $WorkoutExercisesTable.$convertertrackingTypeSnapshot,
      );
  @override
  late final GeneratedColumnWithTypeConverter<LoadConvention, String>
  loadConventionSnapshot =
      GeneratedColumn<String>(
        'load_convention_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LoadConvention>(
        $WorkoutExercisesTable.$converterloadConventionSnapshot,
      );
  @override
  late final GeneratedColumnWithTypeConverter<RepsConvention, String>
  repsConventionSnapshot =
      GeneratedColumn<String>(
        'reps_convention_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RepsConvention>(
        $WorkoutExercisesTable.$converterrepsConventionSnapshot,
      );
  static const VerificationMeta _templateExerciseIdMeta =
      const VerificationMeta('templateExerciseId');
  @override
  late final GeneratedColumn<int> templateExerciseId = GeneratedColumn<int>(
    'template_exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES template_exercises (id)',
    ),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workoutId,
    catalogExerciseId,
    name,
    category,
    trackingTypeSnapshot,
    loadConventionSnapshot,
    repsConventionSnapshot,
    templateExerciseId,
    note,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('catalog_exercise_id')) {
      context.handle(
        _catalogExerciseIdMeta,
        catalogExerciseId.isAcceptableOrUnknown(
          data['catalog_exercise_id']!,
          _catalogExerciseIdMeta,
        ),
      );
    }
    if (data.containsKey('exercise_name_snapshot')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['exercise_name_snapshot']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('template_exercise_id')) {
      context.handle(
        _templateExerciseIdMeta,
        templateExerciseId.isAcceptableOrUnknown(
          data['template_exercise_id']!,
          _templateExerciseIdMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}workout_id'],
      )!,
      catalogExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}catalog_exercise_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_name_snapshot'],
      )!,
      category: $WorkoutExercisesTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category_snapshot'],
        )!,
      ),
      trackingTypeSnapshot: $WorkoutExercisesTable
          .$convertertrackingTypeSnapshot
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}tracking_type_snapshot'],
            )!,
          ),
      loadConventionSnapshot: $WorkoutExercisesTable
          .$converterloadConventionSnapshot
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}load_convention_snapshot'],
            )!,
          ),
      repsConventionSnapshot: $WorkoutExercisesTable
          .$converterrepsConventionSnapshot
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}reps_convention_snapshot'],
            )!,
          ),
      templateExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_exercise_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $WorkoutExercisesTable createAlias(String alias) {
    return $WorkoutExercisesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ExerciseCategory, String, String>
  $convertercategory = const EnumNameConverter<ExerciseCategory>(
    ExerciseCategory.values,
  );
  static JsonTypeConverter2<TrackingType, String, String>
  $convertertrackingTypeSnapshot = const EnumNameConverter<TrackingType>(
    TrackingType.values,
  );
  static JsonTypeConverter2<LoadConvention, String, String>
  $converterloadConventionSnapshot = const EnumNameConverter<LoadConvention>(
    LoadConvention.values,
  );
  static JsonTypeConverter2<RepsConvention, String, String>
  $converterrepsConventionSnapshot = const EnumNameConverter<RepsConvention>(
    RepsConvention.values,
  );
}

class WorkoutExercise extends DataClass implements Insertable<WorkoutExercise> {
  final int id;
  final int workoutId;
  final int? catalogExerciseId;
  final String name;
  final ExerciseCategory category;
  final TrackingType trackingTypeSnapshot;
  final LoadConvention loadConventionSnapshot;
  final RepsConvention repsConventionSnapshot;
  final int? templateExerciseId;
  final String? note;
  final int sortOrder;
  const WorkoutExercise({
    required this.id,
    required this.workoutId,
    this.catalogExerciseId,
    required this.name,
    required this.category,
    required this.trackingTypeSnapshot,
    required this.loadConventionSnapshot,
    required this.repsConventionSnapshot,
    this.templateExerciseId,
    this.note,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['workout_id'] = Variable<int>(workoutId);
    if (!nullToAbsent || catalogExerciseId != null) {
      map['catalog_exercise_id'] = Variable<int>(catalogExerciseId);
    }
    map['exercise_name_snapshot'] = Variable<String>(name);
    {
      map['category_snapshot'] = Variable<String>(
        $WorkoutExercisesTable.$convertercategory.toSql(category),
      );
    }
    {
      map['tracking_type_snapshot'] = Variable<String>(
        $WorkoutExercisesTable.$convertertrackingTypeSnapshot.toSql(
          trackingTypeSnapshot,
        ),
      );
    }
    {
      map['load_convention_snapshot'] = Variable<String>(
        $WorkoutExercisesTable.$converterloadConventionSnapshot.toSql(
          loadConventionSnapshot,
        ),
      );
    }
    {
      map['reps_convention_snapshot'] = Variable<String>(
        $WorkoutExercisesTable.$converterrepsConventionSnapshot.toSql(
          repsConventionSnapshot,
        ),
      );
    }
    if (!nullToAbsent || templateExerciseId != null) {
      map['template_exercise_id'] = Variable<int>(templateExerciseId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  WorkoutExercisesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutExercisesCompanion(
      id: Value(id),
      workoutId: Value(workoutId),
      catalogExerciseId: catalogExerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(catalogExerciseId),
      name: Value(name),
      category: Value(category),
      trackingTypeSnapshot: Value(trackingTypeSnapshot),
      loadConventionSnapshot: Value(loadConventionSnapshot),
      repsConventionSnapshot: Value(repsConventionSnapshot),
      templateExerciseId: templateExerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateExerciseId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      sortOrder: Value(sortOrder),
    );
  }

  factory WorkoutExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutExercise(
      id: serializer.fromJson<int>(json['id']),
      workoutId: serializer.fromJson<int>(json['workoutId']),
      catalogExerciseId: serializer.fromJson<int?>(json['catalogExerciseId']),
      name: serializer.fromJson<String>(json['name']),
      category: $WorkoutExercisesTable.$convertercategory.fromJson(
        serializer.fromJson<String>(json['category']),
      ),
      trackingTypeSnapshot: $WorkoutExercisesTable
          .$convertertrackingTypeSnapshot
          .fromJson(serializer.fromJson<String>(json['trackingTypeSnapshot'])),
      loadConventionSnapshot: $WorkoutExercisesTable
          .$converterloadConventionSnapshot
          .fromJson(
            serializer.fromJson<String>(json['loadConventionSnapshot']),
          ),
      repsConventionSnapshot: $WorkoutExercisesTable
          .$converterrepsConventionSnapshot
          .fromJson(
            serializer.fromJson<String>(json['repsConventionSnapshot']),
          ),
      templateExerciseId: serializer.fromJson<int?>(json['templateExerciseId']),
      note: serializer.fromJson<String?>(json['note']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workoutId': serializer.toJson<int>(workoutId),
      'catalogExerciseId': serializer.toJson<int?>(catalogExerciseId),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(
        $WorkoutExercisesTable.$convertercategory.toJson(category),
      ),
      'trackingTypeSnapshot': serializer.toJson<String>(
        $WorkoutExercisesTable.$convertertrackingTypeSnapshot.toJson(
          trackingTypeSnapshot,
        ),
      ),
      'loadConventionSnapshot': serializer.toJson<String>(
        $WorkoutExercisesTable.$converterloadConventionSnapshot.toJson(
          loadConventionSnapshot,
        ),
      ),
      'repsConventionSnapshot': serializer.toJson<String>(
        $WorkoutExercisesTable.$converterrepsConventionSnapshot.toJson(
          repsConventionSnapshot,
        ),
      ),
      'templateExerciseId': serializer.toJson<int?>(templateExerciseId),
      'note': serializer.toJson<String?>(note),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  WorkoutExercise copyWith({
    int? id,
    int? workoutId,
    Value<int?> catalogExerciseId = const Value.absent(),
    String? name,
    ExerciseCategory? category,
    TrackingType? trackingTypeSnapshot,
    LoadConvention? loadConventionSnapshot,
    RepsConvention? repsConventionSnapshot,
    Value<int?> templateExerciseId = const Value.absent(),
    Value<String?> note = const Value.absent(),
    int? sortOrder,
  }) => WorkoutExercise(
    id: id ?? this.id,
    workoutId: workoutId ?? this.workoutId,
    catalogExerciseId: catalogExerciseId.present
        ? catalogExerciseId.value
        : this.catalogExerciseId,
    name: name ?? this.name,
    category: category ?? this.category,
    trackingTypeSnapshot: trackingTypeSnapshot ?? this.trackingTypeSnapshot,
    loadConventionSnapshot:
        loadConventionSnapshot ?? this.loadConventionSnapshot,
    repsConventionSnapshot:
        repsConventionSnapshot ?? this.repsConventionSnapshot,
    templateExerciseId: templateExerciseId.present
        ? templateExerciseId.value
        : this.templateExerciseId,
    note: note.present ? note.value : this.note,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  WorkoutExercise copyWithCompanion(WorkoutExercisesCompanion data) {
    return WorkoutExercise(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      catalogExerciseId: data.catalogExerciseId.present
          ? data.catalogExerciseId.value
          : this.catalogExerciseId,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      trackingTypeSnapshot: data.trackingTypeSnapshot.present
          ? data.trackingTypeSnapshot.value
          : this.trackingTypeSnapshot,
      loadConventionSnapshot: data.loadConventionSnapshot.present
          ? data.loadConventionSnapshot.value
          : this.loadConventionSnapshot,
      repsConventionSnapshot: data.repsConventionSnapshot.present
          ? data.repsConventionSnapshot.value
          : this.repsConventionSnapshot,
      templateExerciseId: data.templateExerciseId.present
          ? data.templateExerciseId.value
          : this.templateExerciseId,
      note: data.note.present ? data.note.value : this.note,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutExercise(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('catalogExerciseId: $catalogExerciseId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('trackingTypeSnapshot: $trackingTypeSnapshot, ')
          ..write('loadConventionSnapshot: $loadConventionSnapshot, ')
          ..write('repsConventionSnapshot: $repsConventionSnapshot, ')
          ..write('templateExerciseId: $templateExerciseId, ')
          ..write('note: $note, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workoutId,
    catalogExerciseId,
    name,
    category,
    trackingTypeSnapshot,
    loadConventionSnapshot,
    repsConventionSnapshot,
    templateExerciseId,
    note,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutExercise &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.catalogExerciseId == this.catalogExerciseId &&
          other.name == this.name &&
          other.category == this.category &&
          other.trackingTypeSnapshot == this.trackingTypeSnapshot &&
          other.loadConventionSnapshot == this.loadConventionSnapshot &&
          other.repsConventionSnapshot == this.repsConventionSnapshot &&
          other.templateExerciseId == this.templateExerciseId &&
          other.note == this.note &&
          other.sortOrder == this.sortOrder);
}

class WorkoutExercisesCompanion extends UpdateCompanion<WorkoutExercise> {
  final Value<int> id;
  final Value<int> workoutId;
  final Value<int?> catalogExerciseId;
  final Value<String> name;
  final Value<ExerciseCategory> category;
  final Value<TrackingType> trackingTypeSnapshot;
  final Value<LoadConvention> loadConventionSnapshot;
  final Value<RepsConvention> repsConventionSnapshot;
  final Value<int?> templateExerciseId;
  final Value<String?> note;
  final Value<int> sortOrder;
  const WorkoutExercisesCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.catalogExerciseId = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.trackingTypeSnapshot = const Value.absent(),
    this.loadConventionSnapshot = const Value.absent(),
    this.repsConventionSnapshot = const Value.absent(),
    this.templateExerciseId = const Value.absent(),
    this.note = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  WorkoutExercisesCompanion.insert({
    this.id = const Value.absent(),
    required int workoutId,
    this.catalogExerciseId = const Value.absent(),
    required String name,
    required ExerciseCategory category,
    required TrackingType trackingTypeSnapshot,
    required LoadConvention loadConventionSnapshot,
    required RepsConvention repsConventionSnapshot,
    this.templateExerciseId = const Value.absent(),
    this.note = const Value.absent(),
    required int sortOrder,
  }) : workoutId = Value(workoutId),
       name = Value(name),
       category = Value(category),
       trackingTypeSnapshot = Value(trackingTypeSnapshot),
       loadConventionSnapshot = Value(loadConventionSnapshot),
       repsConventionSnapshot = Value(repsConventionSnapshot),
       sortOrder = Value(sortOrder);
  static Insertable<WorkoutExercise> custom({
    Expression<int>? id,
    Expression<int>? workoutId,
    Expression<int>? catalogExerciseId,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? trackingTypeSnapshot,
    Expression<String>? loadConventionSnapshot,
    Expression<String>? repsConventionSnapshot,
    Expression<int>? templateExerciseId,
    Expression<String>? note,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (catalogExerciseId != null) 'catalog_exercise_id': catalogExerciseId,
      if (name != null) 'exercise_name_snapshot': name,
      if (category != null) 'category_snapshot': category,
      if (trackingTypeSnapshot != null)
        'tracking_type_snapshot': trackingTypeSnapshot,
      if (loadConventionSnapshot != null)
        'load_convention_snapshot': loadConventionSnapshot,
      if (repsConventionSnapshot != null)
        'reps_convention_snapshot': repsConventionSnapshot,
      if (templateExerciseId != null)
        'template_exercise_id': templateExerciseId,
      if (note != null) 'note': note,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  WorkoutExercisesCompanion copyWith({
    Value<int>? id,
    Value<int>? workoutId,
    Value<int?>? catalogExerciseId,
    Value<String>? name,
    Value<ExerciseCategory>? category,
    Value<TrackingType>? trackingTypeSnapshot,
    Value<LoadConvention>? loadConventionSnapshot,
    Value<RepsConvention>? repsConventionSnapshot,
    Value<int?>? templateExerciseId,
    Value<String?>? note,
    Value<int>? sortOrder,
  }) {
    return WorkoutExercisesCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      catalogExerciseId: catalogExerciseId ?? this.catalogExerciseId,
      name: name ?? this.name,
      category: category ?? this.category,
      trackingTypeSnapshot: trackingTypeSnapshot ?? this.trackingTypeSnapshot,
      loadConventionSnapshot:
          loadConventionSnapshot ?? this.loadConventionSnapshot,
      repsConventionSnapshot:
          repsConventionSnapshot ?? this.repsConventionSnapshot,
      templateExerciseId: templateExerciseId ?? this.templateExerciseId,
      note: note ?? this.note,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<int>(workoutId.value);
    }
    if (catalogExerciseId.present) {
      map['catalog_exercise_id'] = Variable<int>(catalogExerciseId.value);
    }
    if (name.present) {
      map['exercise_name_snapshot'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category_snapshot'] = Variable<String>(
        $WorkoutExercisesTable.$convertercategory.toSql(category.value),
      );
    }
    if (trackingTypeSnapshot.present) {
      map['tracking_type_snapshot'] = Variable<String>(
        $WorkoutExercisesTable.$convertertrackingTypeSnapshot.toSql(
          trackingTypeSnapshot.value,
        ),
      );
    }
    if (loadConventionSnapshot.present) {
      map['load_convention_snapshot'] = Variable<String>(
        $WorkoutExercisesTable.$converterloadConventionSnapshot.toSql(
          loadConventionSnapshot.value,
        ),
      );
    }
    if (repsConventionSnapshot.present) {
      map['reps_convention_snapshot'] = Variable<String>(
        $WorkoutExercisesTable.$converterrepsConventionSnapshot.toSql(
          repsConventionSnapshot.value,
        ),
      );
    }
    if (templateExerciseId.present) {
      map['template_exercise_id'] = Variable<int>(templateExerciseId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutExercisesCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('catalogExerciseId: $catalogExerciseId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('trackingTypeSnapshot: $trackingTypeSnapshot, ')
          ..write('loadConventionSnapshot: $loadConventionSnapshot, ')
          ..write('repsConventionSnapshot: $repsConventionSnapshot, ')
          ..write('templateExerciseId: $templateExerciseId, ')
          ..write('note: $note, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSetsTable extends WorkoutSets
    with TableInfo<$WorkoutSetsTable, WorkoutSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_exercises (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _templateSetIdMeta = const VerificationMeta(
    'templateSetId',
  );
  @override
  late final GeneratedColumn<int> templateSetId = GeneratedColumn<int>(
    'template_set_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES template_sets (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SetRole, String> setRole =
      GeneratedColumn<String>(
        'set_role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SetRole>($WorkoutSetsTable.$convertersetRole);
  @override
  late final GeneratedColumnWithTypeConverter<SetStatus, String> setStatus =
      GeneratedColumn<String>(
        'set_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SetStatus>($WorkoutSetsTable.$convertersetStatus);
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_meters',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'external_load_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assistanceKgMeta = const VerificationMeta(
    'assistanceKg',
  );
  @override
  late final GeneratedColumn<double> assistanceKg = GeneratedColumn<double>(
    'assistance_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<double> rpe = GeneratedColumn<double>(
    'rpe',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rirMeta = const VerificationMeta('rir');
  @override
  late final GeneratedColumn<double> rir = GeneratedColumn<double>(
    'rir',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    exerciseId,
    templateSetId,
    setRole,
    setStatus,
    reps,
    durationSeconds,
    distanceMeters,
    weightKg,
    assistanceKg,
    rpe,
    rir,
    note,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('template_set_id')) {
      context.handle(
        _templateSetIdMeta,
        templateSetId.isAcceptableOrUnknown(
          data['template_set_id']!,
          _templateSetIdMeta,
        ),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('external_load_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(
          data['external_load_kg']!,
          _weightKgMeta,
        ),
      );
    }
    if (data.containsKey('assistance_kg')) {
      context.handle(
        _assistanceKgMeta,
        assistanceKg.isAcceptableOrUnknown(
          data['assistance_kg']!,
          _assistanceKgMeta,
        ),
      );
    }
    if (data.containsKey('rpe')) {
      context.handle(
        _rpeMeta,
        rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta),
      );
    }
    if (data.containsKey('rir')) {
      context.handle(
        _rirMeta,
        rir.isAcceptableOrUnknown(data['rir']!, _rirMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      templateSetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_set_id'],
      ),
      setRole: $WorkoutSetsTable.$convertersetRole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}set_role'],
        )!,
      ),
      setStatus: $WorkoutSetsTable.$convertersetStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}set_status'],
        )!,
      ),
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}external_load_kg'],
      ),
      assistanceKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}assistance_kg'],
      ),
      rpe: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rpe'],
      ),
      rir: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rir'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $WorkoutSetsTable createAlias(String alias) {
    return $WorkoutSetsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SetRole, String, String> $convertersetRole =
      const EnumNameConverter<SetRole>(SetRole.values);
  static JsonTypeConverter2<SetStatus, String, String> $convertersetStatus =
      const EnumNameConverter<SetStatus>(SetStatus.values);
}

class WorkoutSet extends DataClass implements Insertable<WorkoutSet> {
  final int id;
  final int exerciseId;
  final int? templateSetId;
  final SetRole setRole;
  final SetStatus setStatus;
  final int? reps;
  final int? durationSeconds;
  final double? distanceMeters;
  final double? weightKg;
  final double? assistanceKg;
  final double? rpe;
  final double? rir;
  final String? note;
  final int sortOrder;
  const WorkoutSet({
    required this.id,
    required this.exerciseId,
    this.templateSetId,
    required this.setRole,
    required this.setStatus,
    this.reps,
    this.durationSeconds,
    this.distanceMeters,
    this.weightKg,
    this.assistanceKg,
    this.rpe,
    this.rir,
    this.note,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['exercise_id'] = Variable<int>(exerciseId);
    if (!nullToAbsent || templateSetId != null) {
      map['template_set_id'] = Variable<int>(templateSetId);
    }
    {
      map['set_role'] = Variable<String>(
        $WorkoutSetsTable.$convertersetRole.toSql(setRole),
      );
    }
    {
      map['set_status'] = Variable<String>(
        $WorkoutSetsTable.$convertersetStatus.toSql(setStatus),
      );
    }
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || distanceMeters != null) {
      map['distance_meters'] = Variable<double>(distanceMeters);
    }
    if (!nullToAbsent || weightKg != null) {
      map['external_load_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || assistanceKg != null) {
      map['assistance_kg'] = Variable<double>(assistanceKg);
    }
    if (!nullToAbsent || rpe != null) {
      map['rpe'] = Variable<double>(rpe);
    }
    if (!nullToAbsent || rir != null) {
      map['rir'] = Variable<double>(rir);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  WorkoutSetsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSetsCompanion(
      id: Value(id),
      exerciseId: Value(exerciseId),
      templateSetId: templateSetId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateSetId),
      setRole: Value(setRole),
      setStatus: Value(setStatus),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      distanceMeters: distanceMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceMeters),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      assistanceKg: assistanceKg == null && nullToAbsent
          ? const Value.absent()
          : Value(assistanceKg),
      rpe: rpe == null && nullToAbsent ? const Value.absent() : Value(rpe),
      rir: rir == null && nullToAbsent ? const Value.absent() : Value(rir),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      sortOrder: Value(sortOrder),
    );
  }

  factory WorkoutSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSet(
      id: serializer.fromJson<int>(json['id']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      templateSetId: serializer.fromJson<int?>(json['templateSetId']),
      setRole: $WorkoutSetsTable.$convertersetRole.fromJson(
        serializer.fromJson<String>(json['setRole']),
      ),
      setStatus: $WorkoutSetsTable.$convertersetStatus.fromJson(
        serializer.fromJson<String>(json['setStatus']),
      ),
      reps: serializer.fromJson<int?>(json['reps']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      distanceMeters: serializer.fromJson<double?>(json['distanceMeters']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      assistanceKg: serializer.fromJson<double?>(json['assistanceKg']),
      rpe: serializer.fromJson<double?>(json['rpe']),
      rir: serializer.fromJson<double?>(json['rir']),
      note: serializer.fromJson<String?>(json['note']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'templateSetId': serializer.toJson<int?>(templateSetId),
      'setRole': serializer.toJson<String>(
        $WorkoutSetsTable.$convertersetRole.toJson(setRole),
      ),
      'setStatus': serializer.toJson<String>(
        $WorkoutSetsTable.$convertersetStatus.toJson(setStatus),
      ),
      'reps': serializer.toJson<int?>(reps),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'distanceMeters': serializer.toJson<double?>(distanceMeters),
      'weightKg': serializer.toJson<double?>(weightKg),
      'assistanceKg': serializer.toJson<double?>(assistanceKg),
      'rpe': serializer.toJson<double?>(rpe),
      'rir': serializer.toJson<double?>(rir),
      'note': serializer.toJson<String?>(note),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  WorkoutSet copyWith({
    int? id,
    int? exerciseId,
    Value<int?> templateSetId = const Value.absent(),
    SetRole? setRole,
    SetStatus? setStatus,
    Value<int?> reps = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    Value<double?> distanceMeters = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<double?> assistanceKg = const Value.absent(),
    Value<double?> rpe = const Value.absent(),
    Value<double?> rir = const Value.absent(),
    Value<String?> note = const Value.absent(),
    int? sortOrder,
  }) => WorkoutSet(
    id: id ?? this.id,
    exerciseId: exerciseId ?? this.exerciseId,
    templateSetId: templateSetId.present
        ? templateSetId.value
        : this.templateSetId,
    setRole: setRole ?? this.setRole,
    setStatus: setStatus ?? this.setStatus,
    reps: reps.present ? reps.value : this.reps,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    distanceMeters: distanceMeters.present
        ? distanceMeters.value
        : this.distanceMeters,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    assistanceKg: assistanceKg.present ? assistanceKg.value : this.assistanceKg,
    rpe: rpe.present ? rpe.value : this.rpe,
    rir: rir.present ? rir.value : this.rir,
    note: note.present ? note.value : this.note,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  WorkoutSet copyWithCompanion(WorkoutSetsCompanion data) {
    return WorkoutSet(
      id: data.id.present ? data.id.value : this.id,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      templateSetId: data.templateSetId.present
          ? data.templateSetId.value
          : this.templateSetId,
      setRole: data.setRole.present ? data.setRole.value : this.setRole,
      setStatus: data.setStatus.present ? data.setStatus.value : this.setStatus,
      reps: data.reps.present ? data.reps.value : this.reps,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      assistanceKg: data.assistanceKg.present
          ? data.assistanceKg.value
          : this.assistanceKg,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      rir: data.rir.present ? data.rir.value : this.rir,
      note: data.note.present ? data.note.value : this.note,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSet(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('templateSetId: $templateSetId, ')
          ..write('setRole: $setRole, ')
          ..write('setStatus: $setStatus, ')
          ..write('reps: $reps, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('weightKg: $weightKg, ')
          ..write('assistanceKg: $assistanceKg, ')
          ..write('rpe: $rpe, ')
          ..write('rir: $rir, ')
          ..write('note: $note, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    exerciseId,
    templateSetId,
    setRole,
    setStatus,
    reps,
    durationSeconds,
    distanceMeters,
    weightKg,
    assistanceKg,
    rpe,
    rir,
    note,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSet &&
          other.id == this.id &&
          other.exerciseId == this.exerciseId &&
          other.templateSetId == this.templateSetId &&
          other.setRole == this.setRole &&
          other.setStatus == this.setStatus &&
          other.reps == this.reps &&
          other.durationSeconds == this.durationSeconds &&
          other.distanceMeters == this.distanceMeters &&
          other.weightKg == this.weightKg &&
          other.assistanceKg == this.assistanceKg &&
          other.rpe == this.rpe &&
          other.rir == this.rir &&
          other.note == this.note &&
          other.sortOrder == this.sortOrder);
}

class WorkoutSetsCompanion extends UpdateCompanion<WorkoutSet> {
  final Value<int> id;
  final Value<int> exerciseId;
  final Value<int?> templateSetId;
  final Value<SetRole> setRole;
  final Value<SetStatus> setStatus;
  final Value<int?> reps;
  final Value<int?> durationSeconds;
  final Value<double?> distanceMeters;
  final Value<double?> weightKg;
  final Value<double?> assistanceKg;
  final Value<double?> rpe;
  final Value<double?> rir;
  final Value<String?> note;
  final Value<int> sortOrder;
  const WorkoutSetsCompanion({
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.templateSetId = const Value.absent(),
    this.setRole = const Value.absent(),
    this.setStatus = const Value.absent(),
    this.reps = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.assistanceKg = const Value.absent(),
    this.rpe = const Value.absent(),
    this.rir = const Value.absent(),
    this.note = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  WorkoutSetsCompanion.insert({
    this.id = const Value.absent(),
    required int exerciseId,
    this.templateSetId = const Value.absent(),
    required SetRole setRole,
    required SetStatus setStatus,
    this.reps = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.assistanceKg = const Value.absent(),
    this.rpe = const Value.absent(),
    this.rir = const Value.absent(),
    this.note = const Value.absent(),
    required int sortOrder,
  }) : exerciseId = Value(exerciseId),
       setRole = Value(setRole),
       setStatus = Value(setStatus),
       sortOrder = Value(sortOrder);
  static Insertable<WorkoutSet> custom({
    Expression<int>? id,
    Expression<int>? exerciseId,
    Expression<int>? templateSetId,
    Expression<String>? setRole,
    Expression<String>? setStatus,
    Expression<int>? reps,
    Expression<int>? durationSeconds,
    Expression<double>? distanceMeters,
    Expression<double>? weightKg,
    Expression<double>? assistanceKg,
    Expression<double>? rpe,
    Expression<double>? rir,
    Expression<String>? note,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (templateSetId != null) 'template_set_id': templateSetId,
      if (setRole != null) 'set_role': setRole,
      if (setStatus != null) 'set_status': setStatus,
      if (reps != null) 'reps': reps,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (weightKg != null) 'external_load_kg': weightKg,
      if (assistanceKg != null) 'assistance_kg': assistanceKg,
      if (rpe != null) 'rpe': rpe,
      if (rir != null) 'rir': rir,
      if (note != null) 'note': note,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  WorkoutSetsCompanion copyWith({
    Value<int>? id,
    Value<int>? exerciseId,
    Value<int?>? templateSetId,
    Value<SetRole>? setRole,
    Value<SetStatus>? setStatus,
    Value<int?>? reps,
    Value<int?>? durationSeconds,
    Value<double?>? distanceMeters,
    Value<double?>? weightKg,
    Value<double?>? assistanceKg,
    Value<double?>? rpe,
    Value<double?>? rir,
    Value<String?>? note,
    Value<int>? sortOrder,
  }) {
    return WorkoutSetsCompanion(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      templateSetId: templateSetId ?? this.templateSetId,
      setRole: setRole ?? this.setRole,
      setStatus: setStatus ?? this.setStatus,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      weightKg: weightKg ?? this.weightKg,
      assistanceKg: assistanceKg ?? this.assistanceKg,
      rpe: rpe ?? this.rpe,
      rir: rir ?? this.rir,
      note: note ?? this.note,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (templateSetId.present) {
      map['template_set_id'] = Variable<int>(templateSetId.value);
    }
    if (setRole.present) {
      map['set_role'] = Variable<String>(
        $WorkoutSetsTable.$convertersetRole.toSql(setRole.value),
      );
    }
    if (setStatus.present) {
      map['set_status'] = Variable<String>(
        $WorkoutSetsTable.$convertersetStatus.toSql(setStatus.value),
      );
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (weightKg.present) {
      map['external_load_kg'] = Variable<double>(weightKg.value);
    }
    if (assistanceKg.present) {
      map['assistance_kg'] = Variable<double>(assistanceKg.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<double>(rpe.value);
    }
    if (rir.present) {
      map['rir'] = Variable<double>(rir.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSetsCompanion(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('templateSetId: $templateSetId, ')
          ..write('setRole: $setRole, ')
          ..write('setStatus: $setStatus, ')
          ..write('reps: $reps, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('weightKg: $weightKg, ')
          ..write('assistanceKg: $assistanceKg, ')
          ..write('rpe: $rpe, ')
          ..write('rir: $rir, ')
          ..write('note: $note, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $RestMarksTable extends RestMarks
    with TableInfo<$RestMarksTable, RestMark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RestMarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rest_marks';
  @override
  VerificationContext validateIntegrity(
    Insertable<RestMark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RestMark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RestMark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $RestMarksTable createAlias(String alias) {
    return $RestMarksTable(attachedDatabase, alias);
  }
}

class RestMark extends DataClass implements Insertable<RestMark> {
  final int id;
  final DateTime date;
  final String? note;
  const RestMark({required this.id, required this.date, this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  RestMarksCompanion toCompanion(bool nullToAbsent) {
    return RestMarksCompanion(
      id: Value(id),
      date: Value(date),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory RestMark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RestMark(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'note': serializer.toJson<String?>(note),
    };
  }

  RestMark copyWith({
    int? id,
    DateTime? date,
    Value<String?> note = const Value.absent(),
  }) => RestMark(
    id: id ?? this.id,
    date: date ?? this.date,
    note: note.present ? note.value : this.note,
  );
  RestMark copyWithCompanion(RestMarksCompanion data) {
    return RestMark(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RestMark(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RestMark &&
          other.id == this.id &&
          other.date == this.date &&
          other.note == this.note);
}

class RestMarksCompanion extends UpdateCompanion<RestMark> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String?> note;
  const RestMarksCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
  });
  RestMarksCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    this.note = const Value.absent(),
  }) : date = Value(date);
  static Insertable<RestMark> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
    });
  }

  RestMarksCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<String?>? note,
  }) {
    return RestMarksCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RestMarksCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $RuleSetsTable extends RuleSets with TableInfo<$RuleSetsTable, RuleSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RuleSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RulePeriod, String> period =
      GeneratedColumn<String>(
        'period',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RulePeriod>($RuleSetsTable.$converterperiod);
  static const VerificationMeta _effectiveFromDateMeta = const VerificationMeta(
    'effectiveFromDate',
  );
  @override
  late final GeneratedColumn<DateTime> effectiveFromDate =
      GeneratedColumn<DateTime>(
        'effective_from_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _effectiveUntilDateMeta =
      const VerificationMeta('effectiveUntilDate');
  @override
  late final GeneratedColumn<DateTime> effectiveUntilDate =
      GeneratedColumn<DateTime>(
        'effective_until_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<RuleCombineMode, String>
  combineMode = GeneratedColumn<String>(
    'combine_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<RuleCombineMode>($RuleSetsTable.$convertercombineMode);
  static const VerificationMeta _expressionJsonMeta = const VerificationMeta(
    'expressionJson',
  );
  @override
  late final GeneratedColumn<String> expressionJson = GeneratedColumn<String>(
    'expression_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evaluationPolicyVersionMeta =
      const VerificationMeta('evaluationPolicyVersion');
  @override
  late final GeneratedColumn<int> evaluationPolicyVersion =
      GeneratedColumn<int>(
        'evaluation_policy_version',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    period,
    effectiveFromDate,
    effectiveUntilDate,
    combineMode,
    expressionJson,
    evaluationPolicyVersion,
    archivedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rule_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<RuleSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('effective_from_date')) {
      context.handle(
        _effectiveFromDateMeta,
        effectiveFromDate.isAcceptableOrUnknown(
          data['effective_from_date']!,
          _effectiveFromDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveFromDateMeta);
    }
    if (data.containsKey('effective_until_date')) {
      context.handle(
        _effectiveUntilDateMeta,
        effectiveUntilDate.isAcceptableOrUnknown(
          data['effective_until_date']!,
          _effectiveUntilDateMeta,
        ),
      );
    }
    if (data.containsKey('expression_json')) {
      context.handle(
        _expressionJsonMeta,
        expressionJson.isAcceptableOrUnknown(
          data['expression_json']!,
          _expressionJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expressionJsonMeta);
    }
    if (data.containsKey('evaluation_policy_version')) {
      context.handle(
        _evaluationPolicyVersionMeta,
        evaluationPolicyVersion.isAcceptableOrUnknown(
          data['evaluation_policy_version']!,
          _evaluationPolicyVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evaluationPolicyVersionMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RuleSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RuleSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      period: $RuleSetsTable.$converterperiod.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}period'],
        )!,
      ),
      effectiveFromDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}effective_from_date'],
      )!,
      effectiveUntilDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}effective_until_date'],
      ),
      combineMode: $RuleSetsTable.$convertercombineMode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}combine_mode'],
        )!,
      ),
      expressionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expression_json'],
      )!,
      evaluationPolicyVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}evaluation_policy_version'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RuleSetsTable createAlias(String alias) {
    return $RuleSetsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RulePeriod, String, String> $converterperiod =
      const EnumNameConverter<RulePeriod>(RulePeriod.values);
  static JsonTypeConverter2<RuleCombineMode, String, String>
  $convertercombineMode = const EnumNameConverter<RuleCombineMode>(
    RuleCombineMode.values,
  );
}

class RuleSet extends DataClass implements Insertable<RuleSet> {
  final int id;
  final String name;
  final RulePeriod period;
  final DateTime effectiveFromDate;
  final DateTime? effectiveUntilDate;
  final RuleCombineMode combineMode;
  final String expressionJson;
  final int evaluationPolicyVersion;
  final DateTime? archivedAt;
  final DateTime createdAt;
  const RuleSet({
    required this.id,
    required this.name,
    required this.period,
    required this.effectiveFromDate,
    this.effectiveUntilDate,
    required this.combineMode,
    required this.expressionJson,
    required this.evaluationPolicyVersion,
    this.archivedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['period'] = Variable<String>(
        $RuleSetsTable.$converterperiod.toSql(period),
      );
    }
    map['effective_from_date'] = Variable<DateTime>(effectiveFromDate);
    if (!nullToAbsent || effectiveUntilDate != null) {
      map['effective_until_date'] = Variable<DateTime>(effectiveUntilDate);
    }
    {
      map['combine_mode'] = Variable<String>(
        $RuleSetsTable.$convertercombineMode.toSql(combineMode),
      );
    }
    map['expression_json'] = Variable<String>(expressionJson);
    map['evaluation_policy_version'] = Variable<int>(evaluationPolicyVersion);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RuleSetsCompanion toCompanion(bool nullToAbsent) {
    return RuleSetsCompanion(
      id: Value(id),
      name: Value(name),
      period: Value(period),
      effectiveFromDate: Value(effectiveFromDate),
      effectiveUntilDate: effectiveUntilDate == null && nullToAbsent
          ? const Value.absent()
          : Value(effectiveUntilDate),
      combineMode: Value(combineMode),
      expressionJson: Value(expressionJson),
      evaluationPolicyVersion: Value(evaluationPolicyVersion),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      createdAt: Value(createdAt),
    );
  }

  factory RuleSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RuleSet(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      period: $RuleSetsTable.$converterperiod.fromJson(
        serializer.fromJson<String>(json['period']),
      ),
      effectiveFromDate: serializer.fromJson<DateTime>(
        json['effectiveFromDate'],
      ),
      effectiveUntilDate: serializer.fromJson<DateTime?>(
        json['effectiveUntilDate'],
      ),
      combineMode: $RuleSetsTable.$convertercombineMode.fromJson(
        serializer.fromJson<String>(json['combineMode']),
      ),
      expressionJson: serializer.fromJson<String>(json['expressionJson']),
      evaluationPolicyVersion: serializer.fromJson<int>(
        json['evaluationPolicyVersion'],
      ),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'period': serializer.toJson<String>(
        $RuleSetsTable.$converterperiod.toJson(period),
      ),
      'effectiveFromDate': serializer.toJson<DateTime>(effectiveFromDate),
      'effectiveUntilDate': serializer.toJson<DateTime?>(effectiveUntilDate),
      'combineMode': serializer.toJson<String>(
        $RuleSetsTable.$convertercombineMode.toJson(combineMode),
      ),
      'expressionJson': serializer.toJson<String>(expressionJson),
      'evaluationPolicyVersion': serializer.toJson<int>(
        evaluationPolicyVersion,
      ),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RuleSet copyWith({
    int? id,
    String? name,
    RulePeriod? period,
    DateTime? effectiveFromDate,
    Value<DateTime?> effectiveUntilDate = const Value.absent(),
    RuleCombineMode? combineMode,
    String? expressionJson,
    int? evaluationPolicyVersion,
    Value<DateTime?> archivedAt = const Value.absent(),
    DateTime? createdAt,
  }) => RuleSet(
    id: id ?? this.id,
    name: name ?? this.name,
    period: period ?? this.period,
    effectiveFromDate: effectiveFromDate ?? this.effectiveFromDate,
    effectiveUntilDate: effectiveUntilDate.present
        ? effectiveUntilDate.value
        : this.effectiveUntilDate,
    combineMode: combineMode ?? this.combineMode,
    expressionJson: expressionJson ?? this.expressionJson,
    evaluationPolicyVersion:
        evaluationPolicyVersion ?? this.evaluationPolicyVersion,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  RuleSet copyWithCompanion(RuleSetsCompanion data) {
    return RuleSet(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      period: data.period.present ? data.period.value : this.period,
      effectiveFromDate: data.effectiveFromDate.present
          ? data.effectiveFromDate.value
          : this.effectiveFromDate,
      effectiveUntilDate: data.effectiveUntilDate.present
          ? data.effectiveUntilDate.value
          : this.effectiveUntilDate,
      combineMode: data.combineMode.present
          ? data.combineMode.value
          : this.combineMode,
      expressionJson: data.expressionJson.present
          ? data.expressionJson.value
          : this.expressionJson,
      evaluationPolicyVersion: data.evaluationPolicyVersion.present
          ? data.evaluationPolicyVersion.value
          : this.evaluationPolicyVersion,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RuleSet(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('period: $period, ')
          ..write('effectiveFromDate: $effectiveFromDate, ')
          ..write('effectiveUntilDate: $effectiveUntilDate, ')
          ..write('combineMode: $combineMode, ')
          ..write('expressionJson: $expressionJson, ')
          ..write('evaluationPolicyVersion: $evaluationPolicyVersion, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    period,
    effectiveFromDate,
    effectiveUntilDate,
    combineMode,
    expressionJson,
    evaluationPolicyVersion,
    archivedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RuleSet &&
          other.id == this.id &&
          other.name == this.name &&
          other.period == this.period &&
          other.effectiveFromDate == this.effectiveFromDate &&
          other.effectiveUntilDate == this.effectiveUntilDate &&
          other.combineMode == this.combineMode &&
          other.expressionJson == this.expressionJson &&
          other.evaluationPolicyVersion == this.evaluationPolicyVersion &&
          other.archivedAt == this.archivedAt &&
          other.createdAt == this.createdAt);
}

class RuleSetsCompanion extends UpdateCompanion<RuleSet> {
  final Value<int> id;
  final Value<String> name;
  final Value<RulePeriod> period;
  final Value<DateTime> effectiveFromDate;
  final Value<DateTime?> effectiveUntilDate;
  final Value<RuleCombineMode> combineMode;
  final Value<String> expressionJson;
  final Value<int> evaluationPolicyVersion;
  final Value<DateTime?> archivedAt;
  final Value<DateTime> createdAt;
  const RuleSetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.period = const Value.absent(),
    this.effectiveFromDate = const Value.absent(),
    this.effectiveUntilDate = const Value.absent(),
    this.combineMode = const Value.absent(),
    this.expressionJson = const Value.absent(),
    this.evaluationPolicyVersion = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RuleSetsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required RulePeriod period,
    required DateTime effectiveFromDate,
    this.effectiveUntilDate = const Value.absent(),
    required RuleCombineMode combineMode,
    required String expressionJson,
    required int evaluationPolicyVersion,
    this.archivedAt = const Value.absent(),
    required DateTime createdAt,
  }) : name = Value(name),
       period = Value(period),
       effectiveFromDate = Value(effectiveFromDate),
       combineMode = Value(combineMode),
       expressionJson = Value(expressionJson),
       evaluationPolicyVersion = Value(evaluationPolicyVersion),
       createdAt = Value(createdAt);
  static Insertable<RuleSet> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? period,
    Expression<DateTime>? effectiveFromDate,
    Expression<DateTime>? effectiveUntilDate,
    Expression<String>? combineMode,
    Expression<String>? expressionJson,
    Expression<int>? evaluationPolicyVersion,
    Expression<DateTime>? archivedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (period != null) 'period': period,
      if (effectiveFromDate != null) 'effective_from_date': effectiveFromDate,
      if (effectiveUntilDate != null)
        'effective_until_date': effectiveUntilDate,
      if (combineMode != null) 'combine_mode': combineMode,
      if (expressionJson != null) 'expression_json': expressionJson,
      if (evaluationPolicyVersion != null)
        'evaluation_policy_version': evaluationPolicyVersion,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RuleSetsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<RulePeriod>? period,
    Value<DateTime>? effectiveFromDate,
    Value<DateTime?>? effectiveUntilDate,
    Value<RuleCombineMode>? combineMode,
    Value<String>? expressionJson,
    Value<int>? evaluationPolicyVersion,
    Value<DateTime?>? archivedAt,
    Value<DateTime>? createdAt,
  }) {
    return RuleSetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      period: period ?? this.period,
      effectiveFromDate: effectiveFromDate ?? this.effectiveFromDate,
      effectiveUntilDate: effectiveUntilDate ?? this.effectiveUntilDate,
      combineMode: combineMode ?? this.combineMode,
      expressionJson: expressionJson ?? this.expressionJson,
      evaluationPolicyVersion:
          evaluationPolicyVersion ?? this.evaluationPolicyVersion,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (period.present) {
      map['period'] = Variable<String>(
        $RuleSetsTable.$converterperiod.toSql(period.value),
      );
    }
    if (effectiveFromDate.present) {
      map['effective_from_date'] = Variable<DateTime>(effectiveFromDate.value);
    }
    if (effectiveUntilDate.present) {
      map['effective_until_date'] = Variable<DateTime>(
        effectiveUntilDate.value,
      );
    }
    if (combineMode.present) {
      map['combine_mode'] = Variable<String>(
        $RuleSetsTable.$convertercombineMode.toSql(combineMode.value),
      );
    }
    if (expressionJson.present) {
      map['expression_json'] = Variable<String>(expressionJson.value);
    }
    if (evaluationPolicyVersion.present) {
      map['evaluation_policy_version'] = Variable<int>(
        evaluationPolicyVersion.value,
      );
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RuleSetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('period: $period, ')
          ..write('effectiveFromDate: $effectiveFromDate, ')
          ..write('effectiveUntilDate: $effectiveUntilDate, ')
          ..write('combineMode: $combineMode, ')
          ..write('expressionJson: $expressionJson, ')
          ..write('evaluationPolicyVersion: $evaluationPolicyVersion, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoodEntriesTable foodEntries = $FoodEntriesTable(this);
  late final $FavoriteFoodsTable favoriteFoods = $FavoriteFoodsTable(this);
  late final $WeeklyExerciseGoalsTable weeklyExerciseGoals =
      $WeeklyExerciseGoalsTable(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $WorkoutTemplatesTable workoutTemplates = $WorkoutTemplatesTable(
    this,
  );
  late final $TemplateVersionsTable templateVersions = $TemplateVersionsTable(
    this,
  );
  late final $TemplateExercisesTable templateExercises =
      $TemplateExercisesTable(this);
  late final $TemplateSetsTable templateSets = $TemplateSetsTable(this);
  late final $WorkoutsTable workouts = $WorkoutsTable(this);
  late final $WorkoutExercisesTable workoutExercises = $WorkoutExercisesTable(
    this,
  );
  late final $WorkoutSetsTable workoutSets = $WorkoutSetsTable(this);
  late final $RestMarksTable restMarks = $RestMarksTable(this);
  late final $RuleSetsTable ruleSets = $RuleSetsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    foodEntries,
    favoriteFoods,
    weeklyExerciseGoals,
    exercises,
    workoutTemplates,
    templateVersions,
    templateExercises,
    templateSets,
    workouts,
    workoutExercises,
    workoutSets,
    restMarks,
    ruleSets,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workouts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('workout_exercises', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('workout_sets', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$FoodEntriesTableCreateCompanionBuilder =
    FoodEntriesCompanion Function({
      Value<int> id,
      required DateTime date,
      required MealType mealType,
      required String name,
      required int calories,
    });
typedef $$FoodEntriesTableUpdateCompanionBuilder =
    FoodEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<MealType> mealType,
      Value<String> name,
      Value<int> calories,
    });

class $$FoodEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FoodEntriesTable> {
  $$FoodEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MealType, MealType, int> get mealType =>
      $composableBuilder(
        column: $table.mealType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodEntriesTable> {
  $$FoodEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodEntriesTable> {
  $$FoodEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MealType, int> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);
}

class $$FoodEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodEntriesTable,
          FoodEntry,
          $$FoodEntriesTableFilterComposer,
          $$FoodEntriesTableOrderingComposer,
          $$FoodEntriesTableAnnotationComposer,
          $$FoodEntriesTableCreateCompanionBuilder,
          $$FoodEntriesTableUpdateCompanionBuilder,
          (
            FoodEntry,
            BaseReferences<_$AppDatabase, $FoodEntriesTable, FoodEntry>,
          ),
          FoodEntry,
          PrefetchHooks Function()
        > {
  $$FoodEntriesTableTableManager(_$AppDatabase db, $FoodEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<MealType> mealType = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> calories = const Value.absent(),
              }) => FoodEntriesCompanion(
                id: id,
                date: date,
                mealType: mealType,
                name: name,
                calories: calories,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required MealType mealType,
                required String name,
                required int calories,
              }) => FoodEntriesCompanion.insert(
                id: id,
                date: date,
                mealType: mealType,
                name: name,
                calories: calories,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoodEntriesTable, FoodEntry>(table),
                  BaseReferences<_$AppDatabase, $FoodEntriesTable, FoodEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodEntriesTable,
      FoodEntry,
      $$FoodEntriesTableFilterComposer,
      $$FoodEntriesTableOrderingComposer,
      $$FoodEntriesTableAnnotationComposer,
      $$FoodEntriesTableCreateCompanionBuilder,
      $$FoodEntriesTableUpdateCompanionBuilder,
      (FoodEntry, BaseReferences<_$AppDatabase, $FoodEntriesTable, FoodEntry>),
      FoodEntry,
      PrefetchHooks Function()
    >;
typedef $$FavoriteFoodsTableCreateCompanionBuilder =
    FavoriteFoodsCompanion Function({
      Value<int> id,
      required String name,
      required int calories,
    });
typedef $$FavoriteFoodsTableUpdateCompanionBuilder =
    FavoriteFoodsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> calories,
    });

class $$FavoriteFoodsTableFilterComposer
    extends Composer<_$AppDatabase, $FavoriteFoodsTable> {
  $$FavoriteFoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoriteFoodsTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoriteFoodsTable> {
  $$FavoriteFoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoriteFoodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoriteFoodsTable> {
  $$FavoriteFoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);
}

class $$FavoriteFoodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoriteFoodsTable,
          FavoriteFood,
          $$FavoriteFoodsTableFilterComposer,
          $$FavoriteFoodsTableOrderingComposer,
          $$FavoriteFoodsTableAnnotationComposer,
          $$FavoriteFoodsTableCreateCompanionBuilder,
          $$FavoriteFoodsTableUpdateCompanionBuilder,
          (
            FavoriteFood,
            BaseReferences<_$AppDatabase, $FavoriteFoodsTable, FavoriteFood>,
          ),
          FavoriteFood,
          PrefetchHooks Function()
        > {
  $$FavoriteFoodsTableTableManager(_$AppDatabase db, $FavoriteFoodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteFoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteFoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteFoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> calories = const Value.absent(),
          }) => FavoriteFoodsCompanion(id: id, name: name, calories: calories),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int calories,
              }) => FavoriteFoodsCompanion.insert(
                id: id,
                name: name,
                calories: calories,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoriteFoodsTable, FavoriteFood>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FavoriteFoodsTable,
                    FavoriteFood
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoriteFoodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoriteFoodsTable,
      FavoriteFood,
      $$FavoriteFoodsTableFilterComposer,
      $$FavoriteFoodsTableOrderingComposer,
      $$FavoriteFoodsTableAnnotationComposer,
      $$FavoriteFoodsTableCreateCompanionBuilder,
      $$FavoriteFoodsTableUpdateCompanionBuilder,
      (
        FavoriteFood,
        BaseReferences<_$AppDatabase, $FavoriteFoodsTable, FavoriteFood>,
      ),
      FavoriteFood,
      PrefetchHooks Function()
    >;
typedef $$WeeklyExerciseGoalsTableCreateCompanionBuilder =
    WeeklyExerciseGoalsCompanion Function({
      Value<int> id,
      required int targetSessions,
      required int targetMinutes,
    });
typedef $$WeeklyExerciseGoalsTableUpdateCompanionBuilder =
    WeeklyExerciseGoalsCompanion Function({
      Value<int> id,
      Value<int> targetSessions,
      Value<int> targetMinutes,
    });

class $$WeeklyExerciseGoalsTableFilterComposer
    extends Composer<_$AppDatabase, $WeeklyExerciseGoalsTable> {
  $$WeeklyExerciseGoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetSessions => $composableBuilder(
    column: $table.targetSessions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetMinutes => $composableBuilder(
    column: $table.targetMinutes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeeklyExerciseGoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeeklyExerciseGoalsTable> {
  $$WeeklyExerciseGoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetSessions => $composableBuilder(
    column: $table.targetSessions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetMinutes => $composableBuilder(
    column: $table.targetMinutes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeeklyExerciseGoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeeklyExerciseGoalsTable> {
  $$WeeklyExerciseGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get targetSessions => $composableBuilder(
    column: $table.targetSessions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetMinutes => $composableBuilder(
    column: $table.targetMinutes,
    builder: (column) => column,
  );
}

class $$WeeklyExerciseGoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeeklyExerciseGoalsTable,
          WeeklyExerciseGoal,
          $$WeeklyExerciseGoalsTableFilterComposer,
          $$WeeklyExerciseGoalsTableOrderingComposer,
          $$WeeklyExerciseGoalsTableAnnotationComposer,
          $$WeeklyExerciseGoalsTableCreateCompanionBuilder,
          $$WeeklyExerciseGoalsTableUpdateCompanionBuilder,
          (
            WeeklyExerciseGoal,
            BaseReferences<
              _$AppDatabase,
              $WeeklyExerciseGoalsTable,
              WeeklyExerciseGoal
            >,
          ),
          WeeklyExerciseGoal,
          PrefetchHooks Function()
        > {
  $$WeeklyExerciseGoalsTableTableManager(
    _$AppDatabase db,
    $WeeklyExerciseGoalsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeeklyExerciseGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeeklyExerciseGoalsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WeeklyExerciseGoalsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> targetSessions = const Value.absent(),
                Value<int> targetMinutes = const Value.absent(),
              }) => WeeklyExerciseGoalsCompanion(
                id: id,
                targetSessions: targetSessions,
                targetMinutes: targetMinutes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int targetSessions,
                required int targetMinutes,
              }) => WeeklyExerciseGoalsCompanion.insert(
                id: id,
                targetSessions: targetSessions,
                targetMinutes: targetMinutes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WeeklyExerciseGoalsTable, WeeklyExerciseGoal>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $WeeklyExerciseGoalsTable,
                    WeeklyExerciseGoal
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeeklyExerciseGoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeeklyExerciseGoalsTable,
      WeeklyExerciseGoal,
      $$WeeklyExerciseGoalsTableFilterComposer,
      $$WeeklyExerciseGoalsTableOrderingComposer,
      $$WeeklyExerciseGoalsTableAnnotationComposer,
      $$WeeklyExerciseGoalsTableCreateCompanionBuilder,
      $$WeeklyExerciseGoalsTableUpdateCompanionBuilder,
      (
        WeeklyExerciseGoal,
        BaseReferences<
          _$AppDatabase,
          $WeeklyExerciseGoalsTable,
          WeeklyExerciseGoal
        >,
      ),
      WeeklyExerciseGoal,
      PrefetchHooks Function()
    >;
typedef $$ExercisesTableCreateCompanionBuilder = ExercisesCompanion Function({
  Value<int> id,
  required String name,
  required ExerciseCategory category,
  required TrackingType trackingType,
  required LoadConvention loadConvention,
  required RepsConvention repsConvention,
  Value<DateTime?> archivedAt,
  required DateTime createdAt,
});
typedef $$ExercisesTableUpdateCompanionBuilder = ExercisesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<ExerciseCategory> category,
  Value<TrackingType> trackingType,
  Value<LoadConvention> loadConvention,
  Value<RepsConvention> repsConvention,
  Value<DateTime?> archivedAt,
  Value<DateTime> createdAt,
});

final class $$ExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $ExercisesTable, Exercise> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TemplateExercisesTable, List<TemplateExercise>>
  _templateExercisesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.templateExercises,
        aliasName: 'exercises__id__template_exercises__exercise_id',
      );

  $$TemplateExercisesTableProcessedTableManager get templateExercisesRefs {
    final manager = $$TemplateExercisesTableTableManager(
      $_db,
      $_db.templateExercises,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _templateExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WorkoutExercisesTable, List<WorkoutExercise>>
  _workoutExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutExercises,
    aliasName: 'exercises__id__workout_exercises__catalog_exercise_id',
  );

  $$WorkoutExercisesTableProcessedTableManager get workoutExercisesRefs {
    final manager = $$WorkoutExercisesTableTableManager(
      $_db,
      $_db.workoutExercises,
    ).filter((f) => f.catalogExerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workoutExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ExerciseCategory, ExerciseCategory, String>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<TrackingType, TrackingType, String>
  get trackingType => $composableBuilder(
    column: $table.trackingType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<LoadConvention, LoadConvention, String>
  get loadConvention => $composableBuilder(
    column: $table.loadConvention,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<RepsConvention, RepsConvention, String>
  get repsConvention => $composableBuilder(
    column: $table.repsConvention,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> templateExercisesRefs(
    Expression<bool> Function($$TemplateExercisesTableFilterComposer f) f,
  ) {
    final $$TemplateExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateExercises,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateExercisesTableFilterComposer(
            $db: $db,
            $table: $db.templateExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workoutExercisesRefs(
    Expression<bool> Function($$WorkoutExercisesTableFilterComposer f) f,
  ) {
    final $$WorkoutExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.catalogExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutExercisesTableFilterComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackingType => $composableBuilder(
    column: $table.trackingType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loadConvention => $composableBuilder(
    column: $table.loadConvention,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repsConvention => $composableBuilder(
    column: $table.repsConvention,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ExerciseCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TrackingType, String> get trackingType =>
      $composableBuilder(
        column: $table.trackingType,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<LoadConvention, String> get loadConvention =>
      $composableBuilder(
        column: $table.loadConvention,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<RepsConvention, String> get repsConvention =>
      $composableBuilder(
        column: $table.repsConvention,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> templateExercisesRefs<T extends Object>(
    Expression<T> Function($$TemplateExercisesTableAnnotationComposer a) f,
  ) {
    final $$TemplateExercisesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.templateExercises,
          getReferencedColumn: (t) => t.exerciseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TemplateExercisesTableAnnotationComposer(
                $db: $db,
                $table: $db.templateExercises,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> workoutExercisesRefs<T extends Object>(
    Expression<T> Function($$WorkoutExercisesTableAnnotationComposer a) f,
  ) {
    final $$WorkoutExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.catalogExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesTable,
          Exercise,
          $$ExercisesTableFilterComposer,
          $$ExercisesTableOrderingComposer,
          $$ExercisesTableAnnotationComposer,
          $$ExercisesTableCreateCompanionBuilder,
          $$ExercisesTableUpdateCompanionBuilder,
          (Exercise, $$ExercisesTableReferences),
          Exercise,
          PrefetchHooks Function({
            bool templateExercisesRefs,
            bool workoutExercisesRefs,
          })
        > {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<ExerciseCategory> category = const Value.absent(),
                Value<TrackingType> trackingType = const Value.absent(),
                Value<LoadConvention> loadConvention = const Value.absent(),
                Value<RepsConvention> repsConvention = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                name: name,
                category: category,
                trackingType: trackingType,
                loadConvention: loadConvention,
                repsConvention: repsConvention,
                archivedAt: archivedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required ExerciseCategory category,
                required TrackingType trackingType,
                required LoadConvention loadConvention,
                required RepsConvention repsConvention,
                Value<DateTime?> archivedAt = const Value.absent(),
                required DateTime createdAt,
              }) => ExercisesCompanion.insert(
                id: id,
                name: name,
                category: category,
                trackingType: trackingType,
                loadConvention: loadConvention,
                repsConvention: repsConvention,
                archivedAt: archivedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExercisesTable, Exercise>(table),
                  $$ExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({templateExercisesRefs = false, workoutExercisesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (templateExercisesRefs) db.templateExercises,
                    if (workoutExercisesRefs) db.workoutExercises,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (templateExercisesRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          TemplateExercise
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._templateExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).templateExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workoutExercisesRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          WorkoutExercise
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._workoutExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.catalogExerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesTable,
      Exercise,
      $$ExercisesTableFilterComposer,
      $$ExercisesTableOrderingComposer,
      $$ExercisesTableAnnotationComposer,
      $$ExercisesTableCreateCompanionBuilder,
      $$ExercisesTableUpdateCompanionBuilder,
      (Exercise, $$ExercisesTableReferences),
      Exercise,
      PrefetchHooks Function({
        bool templateExercisesRefs,
        bool workoutExercisesRefs,
      })
    >;
typedef $$WorkoutTemplatesTableCreateCompanionBuilder =
    WorkoutTemplatesCompanion Function({
      Value<int> id,
      required int currentVersionNumber,
      Value<DateTime?> archivedAt,
      required DateTime createdAt,
    });
typedef $$WorkoutTemplatesTableUpdateCompanionBuilder =
    WorkoutTemplatesCompanion Function({
      Value<int> id,
      Value<int> currentVersionNumber,
      Value<DateTime?> archivedAt,
      Value<DateTime> createdAt,
    });

final class $$WorkoutTemplatesTableReferences
    extends
        BaseReferences<_$AppDatabase, $WorkoutTemplatesTable, WorkoutTemplate> {
  $$WorkoutTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TemplateVersionsTable, List<TemplateVersion>>
  _templateVersionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.templateVersions,
    aliasName: 'workout_templates__id__template_versions__template_id',
  );

  $$TemplateVersionsTableProcessedTableManager get templateVersionsRefs {
    final manager = $$TemplateVersionsTableTableManager(
      $_db,
      $_db.templateVersions,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _templateVersionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentVersionNumber => $composableBuilder(
    column: $table.currentVersionNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> templateVersionsRefs(
    Expression<bool> Function($$TemplateVersionsTableFilterComposer f) f,
  ) {
    final $$TemplateVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateVersions,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateVersionsTableFilterComposer(
            $db: $db,
            $table: $db.templateVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentVersionNumber => $composableBuilder(
    column: $table.currentVersionNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get currentVersionNumber => $composableBuilder(
    column: $table.currentVersionNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> templateVersionsRefs<T extends Object>(
    Expression<T> Function($$TemplateVersionsTableAnnotationComposer a) f,
  ) {
    final $$TemplateVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateVersions,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.templateVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutTemplatesTable,
          WorkoutTemplate,
          $$WorkoutTemplatesTableFilterComposer,
          $$WorkoutTemplatesTableOrderingComposer,
          $$WorkoutTemplatesTableAnnotationComposer,
          $$WorkoutTemplatesTableCreateCompanionBuilder,
          $$WorkoutTemplatesTableUpdateCompanionBuilder,
          (WorkoutTemplate, $$WorkoutTemplatesTableReferences),
          WorkoutTemplate,
          PrefetchHooks Function({bool templateVersionsRefs})
        > {
  $$WorkoutTemplatesTableTableManager(
    _$AppDatabase db,
    $WorkoutTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> currentVersionNumber = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WorkoutTemplatesCompanion(
                id: id,
                currentVersionNumber: currentVersionNumber,
                archivedAt: archivedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int currentVersionNumber,
                Value<DateTime?> archivedAt = const Value.absent(),
                required DateTime createdAt,
              }) => WorkoutTemplatesCompanion.insert(
                id: id,
                currentVersionNumber: currentVersionNumber,
                archivedAt: archivedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkoutTemplatesTable, WorkoutTemplate>(table),
                  $$WorkoutTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({templateVersionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (templateVersionsRefs) db.templateVersions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (templateVersionsRefs)
                    await $_getPrefetchedData<
                      WorkoutTemplate,
                      $WorkoutTemplatesTable,
                      TemplateVersion
                    >(
                      currentTable: table,
                      referencedTable: $$WorkoutTemplatesTableReferences
                          ._templateVersionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$WorkoutTemplatesTableReferences(
                            db,
                            table,
                            p0,
                          ).templateVersionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.templateId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutTemplatesTable,
      WorkoutTemplate,
      $$WorkoutTemplatesTableFilterComposer,
      $$WorkoutTemplatesTableOrderingComposer,
      $$WorkoutTemplatesTableAnnotationComposer,
      $$WorkoutTemplatesTableCreateCompanionBuilder,
      $$WorkoutTemplatesTableUpdateCompanionBuilder,
      (WorkoutTemplate, $$WorkoutTemplatesTableReferences),
      WorkoutTemplate,
      PrefetchHooks Function({bool templateVersionsRefs})
    >;
typedef $$TemplateVersionsTableCreateCompanionBuilder =
    TemplateVersionsCompanion Function({
      Value<int> id,
      required int templateId,
      required int versionNumber,
      required String name,
      Value<String?> note,
      required DateTime createdAt,
    });
typedef $$TemplateVersionsTableUpdateCompanionBuilder =
    TemplateVersionsCompanion Function({
      Value<int> id,
      Value<int> templateId,
      Value<int> versionNumber,
      Value<String> name,
      Value<String?> note,
      Value<DateTime> createdAt,
    });

final class $$TemplateVersionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $TemplateVersionsTable, TemplateVersion> {
  $$TemplateVersionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkoutTemplatesTable _templateIdTable(_$AppDatabase db) => db
      .workoutTemplates
      .createAlias('template_versions__template_id__workout_templates__id');

  $$WorkoutTemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<int>('template_id')!;

    final manager = $$WorkoutTemplatesTableTableManager(
      $_db,
      $_db.workoutTemplates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TemplateExercisesTable, List<TemplateExercise>>
  _templateExercisesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.templateExercises,
        aliasName:
            'template_versions__id__template_exercises__template_version_id',
      );

  $$TemplateExercisesTableProcessedTableManager get templateExercisesRefs {
    final manager = $$TemplateExercisesTableTableManager(
      $_db,
      $_db.templateExercises,
    ).filter((f) => f.templateVersionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _templateExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WorkoutsTable, List<Workout>> _workoutsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.workouts,
    aliasName: 'template_versions__id__workouts__template_version_id',
  );

  $$WorkoutsTableProcessedTableManager get workoutsRefs {
    final manager = $$WorkoutsTableTableManager(
      $_db,
      $_db.workouts,
    ).filter((f) => f.templateVersionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TemplateVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $TemplateVersionsTable> {
  $$TemplateVersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get versionNumber => $composableBuilder(
    column: $table.versionNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutTemplatesTableFilterComposer get templateId {
    final $$WorkoutTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.workoutTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.workoutTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> templateExercisesRefs(
    Expression<bool> Function($$TemplateExercisesTableFilterComposer f) f,
  ) {
    final $$TemplateExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateExercises,
      getReferencedColumn: (t) => t.templateVersionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateExercisesTableFilterComposer(
            $db: $db,
            $table: $db.templateExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workoutsRefs(
    Expression<bool> Function($$WorkoutsTableFilterComposer f) f,
  ) {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.templateVersionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplateVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplateVersionsTable> {
  $$TemplateVersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get versionNumber => $composableBuilder(
    column: $table.versionNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutTemplatesTableOrderingComposer get templateId {
    final $$WorkoutTemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.workoutTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutTemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.workoutTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplateVersionsTable> {
  $$TemplateVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get versionNumber => $composableBuilder(
    column: $table.versionNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WorkoutTemplatesTableAnnotationComposer get templateId {
    final $$WorkoutTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.workoutTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> templateExercisesRefs<T extends Object>(
    Expression<T> Function($$TemplateExercisesTableAnnotationComposer a) f,
  ) {
    final $$TemplateExercisesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.templateExercises,
          getReferencedColumn: (t) => t.templateVersionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TemplateExercisesTableAnnotationComposer(
                $db: $db,
                $table: $db.templateExercises,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> workoutsRefs<T extends Object>(
    Expression<T> Function($$WorkoutsTableAnnotationComposer a) f,
  ) {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.templateVersionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplateVersionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplateVersionsTable,
          TemplateVersion,
          $$TemplateVersionsTableFilterComposer,
          $$TemplateVersionsTableOrderingComposer,
          $$TemplateVersionsTableAnnotationComposer,
          $$TemplateVersionsTableCreateCompanionBuilder,
          $$TemplateVersionsTableUpdateCompanionBuilder,
          (TemplateVersion, $$TemplateVersionsTableReferences),
          TemplateVersion,
          PrefetchHooks Function({
            bool templateId,
            bool templateExercisesRefs,
            bool workoutsRefs,
          })
        > {
  $$TemplateVersionsTableTableManager(
    _$AppDatabase db,
    $TemplateVersionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplateVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplateVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplateVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> templateId = const Value.absent(),
                Value<int> versionNumber = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TemplateVersionsCompanion(
                id: id,
                templateId: templateId,
                versionNumber: versionNumber,
                name: name,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int templateId,
                required int versionNumber,
                required String name,
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
              }) => TemplateVersionsCompanion.insert(
                id: id,
                templateId: templateId,
                versionNumber: versionNumber,
                name: name,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TemplateVersionsTable, TemplateVersion>(table),
                  $$TemplateVersionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                templateId = false,
                templateExercisesRefs = false,
                workoutsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (templateExercisesRefs) db.templateExercises,
                    if (workoutsRefs) db.workouts,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (templateId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.templateId,
                            referencedTable: $$TemplateVersionsTableReferences
                                ._templateIdTable(db),
                            referencedColumn: $$TemplateVersionsTableReferences
                                ._templateIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (templateExercisesRefs)
                        await $_getPrefetchedData<
                          TemplateVersion,
                          $TemplateVersionsTable,
                          TemplateExercise
                        >(
                          currentTable: table,
                          referencedTable: $$TemplateVersionsTableReferences
                              ._templateExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TemplateVersionsTableReferences(
                                db,
                                table,
                                p0,
                              ).templateExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.templateVersionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workoutsRefs)
                        await $_getPrefetchedData<
                          TemplateVersion,
                          $TemplateVersionsTable,
                          Workout
                        >(
                          currentTable: table,
                          referencedTable: $$TemplateVersionsTableReferences
                              ._workoutsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TemplateVersionsTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.templateVersionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TemplateVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplateVersionsTable,
      TemplateVersion,
      $$TemplateVersionsTableFilterComposer,
      $$TemplateVersionsTableOrderingComposer,
      $$TemplateVersionsTableAnnotationComposer,
      $$TemplateVersionsTableCreateCompanionBuilder,
      $$TemplateVersionsTableUpdateCompanionBuilder,
      (TemplateVersion, $$TemplateVersionsTableReferences),
      TemplateVersion,
      PrefetchHooks Function({
        bool templateId,
        bool templateExercisesRefs,
        bool workoutsRefs,
      })
    >;
typedef $$TemplateExercisesTableCreateCompanionBuilder =
    TemplateExercisesCompanion Function({
      Value<int> id,
      required int templateVersionId,
      required int exerciseId,
      required String exerciseNameSnapshot,
      required ExerciseCategory categorySnapshot,
      required TrackingType trackingTypeSnapshot,
      required LoadConvention loadConventionSnapshot,
      required RepsConvention repsConventionSnapshot,
      Value<String?> note,
      required int sortOrder,
    });
typedef $$TemplateExercisesTableUpdateCompanionBuilder =
    TemplateExercisesCompanion Function({
      Value<int> id,
      Value<int> templateVersionId,
      Value<int> exerciseId,
      Value<String> exerciseNameSnapshot,
      Value<ExerciseCategory> categorySnapshot,
      Value<TrackingType> trackingTypeSnapshot,
      Value<LoadConvention> loadConventionSnapshot,
      Value<RepsConvention> repsConventionSnapshot,
      Value<String?> note,
      Value<int> sortOrder,
    });

final class $$TemplateExercisesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TemplateExercisesTable,
          TemplateExercise
        > {
  $$TemplateExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TemplateVersionsTable _templateVersionIdTable(_$AppDatabase db) =>
      db.templateVersions.createAlias(
        'template_exercises__template_version_id__template_versions__id',
      );

  $$TemplateVersionsTableProcessedTableManager get templateVersionId {
    final $_column = $_itemColumn<int>('template_version_id')!;

    final manager = $$TemplateVersionsTableTableManager(
      $_db,
      $_db.templateVersions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateVersionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) => db.exercises
      .createAlias('template_exercises__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TemplateSetsTable, List<TemplateSet>>
  _templateSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.templateSets,
    aliasName: 'template_exercises__id__template_sets__template_exercise_id',
  );

  $$TemplateSetsTableProcessedTableManager get templateSetsRefs {
    final manager = $$TemplateSetsTableTableManager($_db, $_db.templateSets)
        .filter(
          (f) => f.templateExerciseId.id.sqlEquals($_itemColumn<int>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_templateSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WorkoutExercisesTable, List<WorkoutExercise>>
  _workoutExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutExercises,
    aliasName:
        'template_exercises__id__workout_exercises__template_exercise_id',
  );

  $$WorkoutExercisesTableProcessedTableManager get workoutExercisesRefs {
    final manager =
        $$WorkoutExercisesTableTableManager($_db, $_db.workoutExercises).filter(
          (f) => f.templateExerciseId.id.sqlEquals($_itemColumn<int>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _workoutExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TemplateExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseNameSnapshot => $composableBuilder(
    column: $table.exerciseNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ExerciseCategory, ExerciseCategory, String>
  get categorySnapshot => $composableBuilder(
    column: $table.categorySnapshot,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<TrackingType, TrackingType, String>
  get trackingTypeSnapshot => $composableBuilder(
    column: $table.trackingTypeSnapshot,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<LoadConvention, LoadConvention, String>
  get loadConventionSnapshot => $composableBuilder(
    column: $table.loadConventionSnapshot,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<RepsConvention, RepsConvention, String>
  get repsConventionSnapshot => $composableBuilder(
    column: $table.repsConventionSnapshot,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$TemplateVersionsTableFilterComposer get templateVersionId {
    final $$TemplateVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateVersionId,
      referencedTable: $db.templateVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateVersionsTableFilterComposer(
            $db: $db,
            $table: $db.templateVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> templateSetsRefs(
    Expression<bool> Function($$TemplateSetsTableFilterComposer f) f,
  ) {
    final $$TemplateSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateSets,
      getReferencedColumn: (t) => t.templateExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateSetsTableFilterComposer(
            $db: $db,
            $table: $db.templateSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workoutExercisesRefs(
    Expression<bool> Function($$WorkoutExercisesTableFilterComposer f) f,
  ) {
    final $$WorkoutExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.templateExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutExercisesTableFilterComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplateExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseNameSnapshot => $composableBuilder(
    column: $table.exerciseNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categorySnapshot => $composableBuilder(
    column: $table.categorySnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackingTypeSnapshot => $composableBuilder(
    column: $table.trackingTypeSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loadConventionSnapshot => $composableBuilder(
    column: $table.loadConventionSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repsConventionSnapshot => $composableBuilder(
    column: $table.repsConventionSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$TemplateVersionsTableOrderingComposer get templateVersionId {
    final $$TemplateVersionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateVersionId,
      referencedTable: $db.templateVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateVersionsTableOrderingComposer(
            $db: $db,
            $table: $db.templateVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exerciseNameSnapshot => $composableBuilder(
    column: $table.exerciseNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ExerciseCategory, String>
  get categorySnapshot => $composableBuilder(
    column: $table.categorySnapshot,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TrackingType, String>
  get trackingTypeSnapshot => $composableBuilder(
    column: $table.trackingTypeSnapshot,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<LoadConvention, String>
  get loadConventionSnapshot => $composableBuilder(
    column: $table.loadConventionSnapshot,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RepsConvention, String>
  get repsConventionSnapshot => $composableBuilder(
    column: $table.repsConventionSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$TemplateVersionsTableAnnotationComposer get templateVersionId {
    final $$TemplateVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateVersionId,
      referencedTable: $db.templateVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.templateVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> templateSetsRefs<T extends Object>(
    Expression<T> Function($$TemplateSetsTableAnnotationComposer a) f,
  ) {
    final $$TemplateSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateSets,
      getReferencedColumn: (t) => t.templateExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.templateSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> workoutExercisesRefs<T extends Object>(
    Expression<T> Function($$WorkoutExercisesTableAnnotationComposer a) f,
  ) {
    final $$WorkoutExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.templateExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplateExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplateExercisesTable,
          TemplateExercise,
          $$TemplateExercisesTableFilterComposer,
          $$TemplateExercisesTableOrderingComposer,
          $$TemplateExercisesTableAnnotationComposer,
          $$TemplateExercisesTableCreateCompanionBuilder,
          $$TemplateExercisesTableUpdateCompanionBuilder,
          (TemplateExercise, $$TemplateExercisesTableReferences),
          TemplateExercise,
          PrefetchHooks Function({
            bool templateVersionId,
            bool exerciseId,
            bool templateSetsRefs,
            bool workoutExercisesRefs,
          })
        > {
  $$TemplateExercisesTableTableManager(
    _$AppDatabase db,
    $TemplateExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplateExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplateExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplateExercisesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> templateVersionId = const Value.absent(),
                Value<int> exerciseId = const Value.absent(),
                Value<String> exerciseNameSnapshot = const Value.absent(),
                Value<ExerciseCategory> categorySnapshot = const Value.absent(),
                Value<TrackingType> trackingTypeSnapshot = const Value.absent(),
                Value<LoadConvention> loadConventionSnapshot =
                    const Value.absent(),
                Value<RepsConvention> repsConventionSnapshot =
                    const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => TemplateExercisesCompanion(
                id: id,
                templateVersionId: templateVersionId,
                exerciseId: exerciseId,
                exerciseNameSnapshot: exerciseNameSnapshot,
                categorySnapshot: categorySnapshot,
                trackingTypeSnapshot: trackingTypeSnapshot,
                loadConventionSnapshot: loadConventionSnapshot,
                repsConventionSnapshot: repsConventionSnapshot,
                note: note,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int templateVersionId,
                required int exerciseId,
                required String exerciseNameSnapshot,
                required ExerciseCategory categorySnapshot,
                required TrackingType trackingTypeSnapshot,
                required LoadConvention loadConventionSnapshot,
                required RepsConvention repsConventionSnapshot,
                Value<String?> note = const Value.absent(),
                required int sortOrder,
              }) => TemplateExercisesCompanion.insert(
                id: id,
                templateVersionId: templateVersionId,
                exerciseId: exerciseId,
                exerciseNameSnapshot: exerciseNameSnapshot,
                categorySnapshot: categorySnapshot,
                trackingTypeSnapshot: trackingTypeSnapshot,
                loadConventionSnapshot: loadConventionSnapshot,
                repsConventionSnapshot: repsConventionSnapshot,
                note: note,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TemplateExercisesTable, TemplateExercise>(table),
                  $$TemplateExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                templateVersionId = false,
                exerciseId = false,
                templateSetsRefs = false,
                workoutExercisesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (templateSetsRefs) db.templateSets,
                    if (workoutExercisesRefs) db.workoutExercises,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (templateVersionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.templateVersionId,
                            referencedTable: $$TemplateExercisesTableReferences
                                ._templateVersionIdTable(db),
                            referencedColumn: $$TemplateExercisesTableReferences
                                ._templateVersionIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (exerciseId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.exerciseId,
                            referencedTable: $$TemplateExercisesTableReferences
                                ._exerciseIdTable(db),
                            referencedColumn: $$TemplateExercisesTableReferences
                                ._exerciseIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (templateSetsRefs)
                        await $_getPrefetchedData<
                          TemplateExercise,
                          $TemplateExercisesTable,
                          TemplateSet
                        >(
                          currentTable: table,
                          referencedTable: $$TemplateExercisesTableReferences
                              ._templateSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TemplateExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).templateSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.templateExerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workoutExercisesRefs)
                        await $_getPrefetchedData<
                          TemplateExercise,
                          $TemplateExercisesTable,
                          WorkoutExercise
                        >(
                          currentTable: table,
                          referencedTable: $$TemplateExercisesTableReferences
                              ._workoutExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TemplateExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.templateExerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TemplateExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplateExercisesTable,
      TemplateExercise,
      $$TemplateExercisesTableFilterComposer,
      $$TemplateExercisesTableOrderingComposer,
      $$TemplateExercisesTableAnnotationComposer,
      $$TemplateExercisesTableCreateCompanionBuilder,
      $$TemplateExercisesTableUpdateCompanionBuilder,
      (TemplateExercise, $$TemplateExercisesTableReferences),
      TemplateExercise,
      PrefetchHooks Function({
        bool templateVersionId,
        bool exerciseId,
        bool templateSetsRefs,
        bool workoutExercisesRefs,
      })
    >;
typedef $$TemplateSetsTableCreateCompanionBuilder =
    TemplateSetsCompanion Function({
      Value<int> id,
      required int templateExerciseId,
      required SetRole setRole,
      Value<int?> reps,
      Value<int?> minimumReps,
      Value<int?> durationSeconds,
      Value<int?> minimumDurationSeconds,
      Value<double?> distanceMeters,
      Value<double?> minimumDistanceMeters,
      Value<double?> externalLoadKg,
      Value<double?> assistanceKg,
      Value<double?> rpe,
      Value<double?> rir,
      required int sortOrder,
    });
typedef $$TemplateSetsTableUpdateCompanionBuilder =
    TemplateSetsCompanion Function({
      Value<int> id,
      Value<int> templateExerciseId,
      Value<SetRole> setRole,
      Value<int?> reps,
      Value<int?> minimumReps,
      Value<int?> durationSeconds,
      Value<int?> minimumDurationSeconds,
      Value<double?> distanceMeters,
      Value<double?> minimumDistanceMeters,
      Value<double?> externalLoadKg,
      Value<double?> assistanceKg,
      Value<double?> rpe,
      Value<double?> rir,
      Value<int> sortOrder,
    });

final class $$TemplateSetsTableReferences
    extends BaseReferences<_$AppDatabase, $TemplateSetsTable, TemplateSet> {
  $$TemplateSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TemplateExercisesTable _templateExerciseIdTable(_$AppDatabase db) =>
      db.templateExercises.createAlias(
        'template_sets__template_exercise_id__template_exercises__id',
      );

  $$TemplateExercisesTableProcessedTableManager get templateExerciseId {
    final $_column = $_itemColumn<int>('template_exercise_id')!;

    final manager = $$TemplateExercisesTableTableManager(
      $_db,
      $_db.templateExercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateExerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WorkoutSetsTable, List<WorkoutSet>>
  _workoutSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutSets,
    aliasName: 'template_sets__id__workout_sets__template_set_id',
  );

  $$WorkoutSetsTableProcessedTableManager get workoutSetsRefs {
    final manager = $$WorkoutSetsTableTableManager(
      $_db,
      $_db.workoutSets,
    ).filter((f) => f.templateSetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TemplateSetsTableFilterComposer
    extends Composer<_$AppDatabase, $TemplateSetsTable> {
  $$TemplateSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SetRole, SetRole, String> get setRole =>
      $composableBuilder(
        column: $table.setRole,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minimumReps => $composableBuilder(
    column: $table.minimumReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minimumDurationSeconds => $composableBuilder(
    column: $table.minimumDurationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minimumDistanceMeters => $composableBuilder(
    column: $table.minimumDistanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get externalLoadKg => $composableBuilder(
    column: $table.externalLoadKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get assistanceKg => $composableBuilder(
    column: $table.assistanceKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rir => $composableBuilder(
    column: $table.rir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$TemplateExercisesTableFilterComposer get templateExerciseId {
    final $$TemplateExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateExerciseId,
      referencedTable: $db.templateExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateExercisesTableFilterComposer(
            $db: $db,
            $table: $db.templateExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> workoutSetsRefs(
    Expression<bool> Function($$WorkoutSetsTableFilterComposer f) f,
  ) {
    final $$WorkoutSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.templateSetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSetsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplateSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplateSetsTable> {
  $$TemplateSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setRole => $composableBuilder(
    column: $table.setRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minimumReps => $composableBuilder(
    column: $table.minimumReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minimumDurationSeconds => $composableBuilder(
    column: $table.minimumDurationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minimumDistanceMeters => $composableBuilder(
    column: $table.minimumDistanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get externalLoadKg => $composableBuilder(
    column: $table.externalLoadKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get assistanceKg => $composableBuilder(
    column: $table.assistanceKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rir => $composableBuilder(
    column: $table.rir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$TemplateExercisesTableOrderingComposer get templateExerciseId {
    final $$TemplateExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateExerciseId,
      referencedTable: $db.templateExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.templateExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplateSetsTable> {
  $$TemplateSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SetRole, String> get setRole =>
      $composableBuilder(column: $table.setRole, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get minimumReps => $composableBuilder(
    column: $table.minimumReps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minimumDurationSeconds => $composableBuilder(
    column: $table.minimumDurationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minimumDistanceMeters => $composableBuilder(
    column: $table.minimumDistanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get externalLoadKg => $composableBuilder(
    column: $table.externalLoadKg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get assistanceKg => $composableBuilder(
    column: $table.assistanceKg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumn<double> get rir =>
      $composableBuilder(column: $table.rir, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$TemplateExercisesTableAnnotationComposer get templateExerciseId {
    final $$TemplateExercisesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.templateExerciseId,
          referencedTable: $db.templateExercises,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TemplateExercisesTableAnnotationComposer(
                $db: $db,
                $table: $db.templateExercises,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> workoutSetsRefs<T extends Object>(
    Expression<T> Function($$WorkoutSetsTableAnnotationComposer a) f,
  ) {
    final $$WorkoutSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.templateSetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplateSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplateSetsTable,
          TemplateSet,
          $$TemplateSetsTableFilterComposer,
          $$TemplateSetsTableOrderingComposer,
          $$TemplateSetsTableAnnotationComposer,
          $$TemplateSetsTableCreateCompanionBuilder,
          $$TemplateSetsTableUpdateCompanionBuilder,
          (TemplateSet, $$TemplateSetsTableReferences),
          TemplateSet,
          PrefetchHooks Function({
            bool templateExerciseId,
            bool workoutSetsRefs,
          })
        > {
  $$TemplateSetsTableTableManager(_$AppDatabase db, $TemplateSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplateSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplateSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplateSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> templateExerciseId = const Value.absent(),
                Value<SetRole> setRole = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<int?> minimumReps = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<int?> minimumDurationSeconds = const Value.absent(),
                Value<double?> distanceMeters = const Value.absent(),
                Value<double?> minimumDistanceMeters = const Value.absent(),
                Value<double?> externalLoadKg = const Value.absent(),
                Value<double?> assistanceKg = const Value.absent(),
                Value<double?> rpe = const Value.absent(),
                Value<double?> rir = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => TemplateSetsCompanion(
                id: id,
                templateExerciseId: templateExerciseId,
                setRole: setRole,
                reps: reps,
                minimumReps: minimumReps,
                durationSeconds: durationSeconds,
                minimumDurationSeconds: minimumDurationSeconds,
                distanceMeters: distanceMeters,
                minimumDistanceMeters: minimumDistanceMeters,
                externalLoadKg: externalLoadKg,
                assistanceKg: assistanceKg,
                rpe: rpe,
                rir: rir,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int templateExerciseId,
                required SetRole setRole,
                Value<int?> reps = const Value.absent(),
                Value<int?> minimumReps = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<int?> minimumDurationSeconds = const Value.absent(),
                Value<double?> distanceMeters = const Value.absent(),
                Value<double?> minimumDistanceMeters = const Value.absent(),
                Value<double?> externalLoadKg = const Value.absent(),
                Value<double?> assistanceKg = const Value.absent(),
                Value<double?> rpe = const Value.absent(),
                Value<double?> rir = const Value.absent(),
                required int sortOrder,
              }) => TemplateSetsCompanion.insert(
                id: id,
                templateExerciseId: templateExerciseId,
                setRole: setRole,
                reps: reps,
                minimumReps: minimumReps,
                durationSeconds: durationSeconds,
                minimumDurationSeconds: minimumDurationSeconds,
                distanceMeters: distanceMeters,
                minimumDistanceMeters: minimumDistanceMeters,
                externalLoadKg: externalLoadKg,
                assistanceKg: assistanceKg,
                rpe: rpe,
                rir: rir,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TemplateSetsTable, TemplateSet>(table),
                  $$TemplateSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({templateExerciseId = false, workoutSetsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workoutSetsRefs) db.workoutSets,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (templateExerciseId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.templateExerciseId,
                            referencedTable: $$TemplateSetsTableReferences
                                ._templateExerciseIdTable(db),
                            referencedColumn: $$TemplateSetsTableReferences
                                ._templateExerciseIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workoutSetsRefs)
                        await $_getPrefetchedData<
                          TemplateSet,
                          $TemplateSetsTable,
                          WorkoutSet
                        >(
                          currentTable: table,
                          referencedTable: $$TemplateSetsTableReferences
                              ._workoutSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TemplateSetsTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.templateSetId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TemplateSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplateSetsTable,
      TemplateSet,
      $$TemplateSetsTableFilterComposer,
      $$TemplateSetsTableOrderingComposer,
      $$TemplateSetsTableAnnotationComposer,
      $$TemplateSetsTableCreateCompanionBuilder,
      $$TemplateSetsTableUpdateCompanionBuilder,
      (TemplateSet, $$TemplateSetsTableReferences),
      TemplateSet,
      PrefetchHooks Function({bool templateExerciseId, bool workoutSetsRefs})
    >;
typedef $$WorkoutsTableCreateCompanionBuilder = WorkoutsCompanion Function({
  Value<int> id,
  required DateTime date,
  required WorkoutStatus status,
  Value<DateTime?> startedAt,
  Value<DateTime?> endedAt,
  Value<DateTime?> pausedAt,
  Value<int> pausedSeconds,
  Value<int?> totalSeconds,
  Value<String?> feeling,
  Value<int?> templateVersionId,
  Value<String?> templateNameSnapshot,
  Value<int?> templateEvaluationPolicyVersion,
});
typedef $$WorkoutsTableUpdateCompanionBuilder = WorkoutsCompanion Function({
  Value<int> id,
  Value<DateTime> date,
  Value<WorkoutStatus> status,
  Value<DateTime?> startedAt,
  Value<DateTime?> endedAt,
  Value<DateTime?> pausedAt,
  Value<int> pausedSeconds,
  Value<int?> totalSeconds,
  Value<String?> feeling,
  Value<int?> templateVersionId,
  Value<String?> templateNameSnapshot,
  Value<int?> templateEvaluationPolicyVersion,
});

final class $$WorkoutsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutsTable, Workout> {
  $$WorkoutsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TemplateVersionsTable _templateVersionIdTable(_$AppDatabase db) => db
      .templateVersions
      .createAlias('workouts__template_version_id__template_versions__id');

  $$TemplateVersionsTableProcessedTableManager? get templateVersionId {
    final $_column = $_itemColumn<int>('template_version_id');
    if ($_column == null) return null;
    final manager = $$TemplateVersionsTableTableManager(
      $_db,
      $_db.templateVersions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateVersionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WorkoutExercisesTable, List<WorkoutExercise>>
  _workoutExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutExercises,
    aliasName: 'workouts__id__workout_exercises__workout_id',
  );

  $$WorkoutExercisesTableProcessedTableManager get workoutExercisesRefs {
    final manager = $$WorkoutExercisesTableTableManager(
      $_db,
      $_db.workoutExercises,
    ).filter((f) => f.workoutId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workoutExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WorkoutStatus, WorkoutStatus, int>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pausedAt => $composableBuilder(
    column: $table.pausedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pausedSeconds => $composableBuilder(
    column: $table.pausedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feeling => $composableBuilder(
    column: $table.feeling,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateNameSnapshot => $composableBuilder(
    column: $table.templateNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get templateEvaluationPolicyVersion => $composableBuilder(
    column: $table.templateEvaluationPolicyVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$TemplateVersionsTableFilterComposer get templateVersionId {
    final $$TemplateVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateVersionId,
      referencedTable: $db.templateVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateVersionsTableFilterComposer(
            $db: $db,
            $table: $db.templateVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> workoutExercisesRefs(
    Expression<bool> Function($$WorkoutExercisesTableFilterComposer f) f,
  ) {
    final $$WorkoutExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutExercisesTableFilterComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pausedAt => $composableBuilder(
    column: $table.pausedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pausedSeconds => $composableBuilder(
    column: $table.pausedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feeling => $composableBuilder(
    column: $table.feeling,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateNameSnapshot => $composableBuilder(
    column: $table.templateNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get templateEvaluationPolicyVersion =>
      $composableBuilder(
        column: $table.templateEvaluationPolicyVersion,
        builder: (column) => ColumnOrderings(column),
      );

  $$TemplateVersionsTableOrderingComposer get templateVersionId {
    final $$TemplateVersionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateVersionId,
      referencedTable: $db.templateVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateVersionsTableOrderingComposer(
            $db: $db,
            $table: $db.templateVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WorkoutStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get pausedAt =>
      $composableBuilder(column: $table.pausedAt, builder: (column) => column);

  GeneratedColumn<int> get pausedSeconds => $composableBuilder(
    column: $table.pausedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get feeling =>
      $composableBuilder(column: $table.feeling, builder: (column) => column);

  GeneratedColumn<String> get templateNameSnapshot => $composableBuilder(
    column: $table.templateNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get templateEvaluationPolicyVersion =>
      $composableBuilder(
        column: $table.templateEvaluationPolicyVersion,
        builder: (column) => column,
      );

  $$TemplateVersionsTableAnnotationComposer get templateVersionId {
    final $$TemplateVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateVersionId,
      referencedTable: $db.templateVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.templateVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> workoutExercisesRefs<T extends Object>(
    Expression<T> Function($$WorkoutExercisesTableAnnotationComposer a) f,
  ) {
    final $$WorkoutExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutsTable,
          Workout,
          $$WorkoutsTableFilterComposer,
          $$WorkoutsTableOrderingComposer,
          $$WorkoutsTableAnnotationComposer,
          $$WorkoutsTableCreateCompanionBuilder,
          $$WorkoutsTableUpdateCompanionBuilder,
          (Workout, $$WorkoutsTableReferences),
          Workout,
          PrefetchHooks Function({
            bool templateVersionId,
            bool workoutExercisesRefs,
          })
        > {
  $$WorkoutsTableTableManager(_$AppDatabase db, $WorkoutsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<WorkoutStatus> status = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime?> pausedAt = const Value.absent(),
                Value<int> pausedSeconds = const Value.absent(),
                Value<int?> totalSeconds = const Value.absent(),
                Value<String?> feeling = const Value.absent(),
                Value<int?> templateVersionId = const Value.absent(),
                Value<String?> templateNameSnapshot = const Value.absent(),
                Value<int?> templateEvaluationPolicyVersion =
                    const Value.absent(),
              }) => WorkoutsCompanion(
                id: id,
                date: date,
                status: status,
                startedAt: startedAt,
                endedAt: endedAt,
                pausedAt: pausedAt,
                pausedSeconds: pausedSeconds,
                totalSeconds: totalSeconds,
                feeling: feeling,
                templateVersionId: templateVersionId,
                templateNameSnapshot: templateNameSnapshot,
                templateEvaluationPolicyVersion:
                    templateEvaluationPolicyVersion,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required WorkoutStatus status,
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime?> pausedAt = const Value.absent(),
                Value<int> pausedSeconds = const Value.absent(),
                Value<int?> totalSeconds = const Value.absent(),
                Value<String?> feeling = const Value.absent(),
                Value<int?> templateVersionId = const Value.absent(),
                Value<String?> templateNameSnapshot = const Value.absent(),
                Value<int?> templateEvaluationPolicyVersion =
                    const Value.absent(),
              }) => WorkoutsCompanion.insert(
                id: id,
                date: date,
                status: status,
                startedAt: startedAt,
                endedAt: endedAt,
                pausedAt: pausedAt,
                pausedSeconds: pausedSeconds,
                totalSeconds: totalSeconds,
                feeling: feeling,
                templateVersionId: templateVersionId,
                templateNameSnapshot: templateNameSnapshot,
                templateEvaluationPolicyVersion:
                    templateEvaluationPolicyVersion,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkoutsTable, Workout>(table),
                  $$WorkoutsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({templateVersionId = false, workoutExercisesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workoutExercisesRefs) db.workoutExercises,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (templateVersionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.templateVersionId,
                            referencedTable: $$WorkoutsTableReferences
                                ._templateVersionIdTable(db),
                            referencedColumn: $$WorkoutsTableReferences
                                ._templateVersionIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workoutExercisesRefs)
                        await $_getPrefetchedData<
                          Workout,
                          $WorkoutsTable,
                          WorkoutExercise
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutsTableReferences
                              ._workoutExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workoutId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutsTable,
      Workout,
      $$WorkoutsTableFilterComposer,
      $$WorkoutsTableOrderingComposer,
      $$WorkoutsTableAnnotationComposer,
      $$WorkoutsTableCreateCompanionBuilder,
      $$WorkoutsTableUpdateCompanionBuilder,
      (Workout, $$WorkoutsTableReferences),
      Workout,
      PrefetchHooks Function({
        bool templateVersionId,
        bool workoutExercisesRefs,
      })
    >;
typedef $$WorkoutExercisesTableCreateCompanionBuilder =
    WorkoutExercisesCompanion Function({
      Value<int> id,
      required int workoutId,
      Value<int?> catalogExerciseId,
      required String name,
      required ExerciseCategory category,
      required TrackingType trackingTypeSnapshot,
      required LoadConvention loadConventionSnapshot,
      required RepsConvention repsConventionSnapshot,
      Value<int?> templateExerciseId,
      Value<String?> note,
      required int sortOrder,
    });
typedef $$WorkoutExercisesTableUpdateCompanionBuilder =
    WorkoutExercisesCompanion Function({
      Value<int> id,
      Value<int> workoutId,
      Value<int?> catalogExerciseId,
      Value<String> name,
      Value<ExerciseCategory> category,
      Value<TrackingType> trackingTypeSnapshot,
      Value<LoadConvention> loadConventionSnapshot,
      Value<RepsConvention> repsConventionSnapshot,
      Value<int?> templateExerciseId,
      Value<String?> note,
      Value<int> sortOrder,
    });

final class $$WorkoutExercisesTableReferences
    extends
        BaseReferences<_$AppDatabase, $WorkoutExercisesTable, WorkoutExercise> {
  $$WorkoutExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.workouts.createAlias('workout_exercises__workout_id__workouts__id');

  $$WorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<int>('workout_id')!;

    final manager = $$WorkoutsTableTableManager(
      $_db,
      $_db.workouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _catalogExerciseIdTable(_$AppDatabase db) => db
      .exercises
      .createAlias('workout_exercises__catalog_exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager? get catalogExerciseId {
    final $_column = $_itemColumn<int>('catalog_exercise_id');
    if ($_column == null) return null;
    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_catalogExerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TemplateExercisesTable _templateExerciseIdTable(_$AppDatabase db) =>
      db.templateExercises.createAlias(
        'workout_exercises__template_exercise_id__template_exercises__id',
      );

  $$TemplateExercisesTableProcessedTableManager? get templateExerciseId {
    final $_column = $_itemColumn<int>('template_exercise_id');
    if ($_column == null) return null;
    final manager = $$TemplateExercisesTableTableManager(
      $_db,
      $_db.templateExercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateExerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WorkoutSetsTable, List<WorkoutSet>>
  _workoutSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutSets,
    aliasName: 'workout_exercises__id__workout_sets__exercise_id',
  );

  $$WorkoutSetsTableProcessedTableManager get workoutSetsRefs {
    final manager = $$WorkoutSetsTableTableManager(
      $_db,
      $_db.workoutSets,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutExercisesTable> {
  $$WorkoutExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ExerciseCategory, ExerciseCategory, String>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<TrackingType, TrackingType, String>
  get trackingTypeSnapshot => $composableBuilder(
    column: $table.trackingTypeSnapshot,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<LoadConvention, LoadConvention, String>
  get loadConventionSnapshot => $composableBuilder(
    column: $table.loadConventionSnapshot,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<RepsConvention, RepsConvention, String>
  get repsConventionSnapshot => $composableBuilder(
    column: $table.repsConventionSnapshot,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutsTableFilterComposer get workoutId {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get catalogExerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.catalogExerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TemplateExercisesTableFilterComposer get templateExerciseId {
    final $$TemplateExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateExerciseId,
      referencedTable: $db.templateExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateExercisesTableFilterComposer(
            $db: $db,
            $table: $db.templateExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> workoutSetsRefs(
    Expression<bool> Function($$WorkoutSetsTableFilterComposer f) f,
  ) {
    final $$WorkoutSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSetsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutExercisesTable> {
  $$WorkoutExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackingTypeSnapshot => $composableBuilder(
    column: $table.trackingTypeSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loadConventionSnapshot => $composableBuilder(
    column: $table.loadConventionSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repsConventionSnapshot => $composableBuilder(
    column: $table.repsConventionSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutsTableOrderingComposer get workoutId {
    final $$WorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get catalogExerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.catalogExerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TemplateExercisesTableOrderingComposer get templateExerciseId {
    final $$TemplateExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateExerciseId,
      referencedTable: $db.templateExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.templateExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutExercisesTable> {
  $$WorkoutExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ExerciseCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TrackingType, String>
  get trackingTypeSnapshot => $composableBuilder(
    column: $table.trackingTypeSnapshot,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<LoadConvention, String>
  get loadConventionSnapshot => $composableBuilder(
    column: $table.loadConventionSnapshot,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RepsConvention, String>
  get repsConventionSnapshot => $composableBuilder(
    column: $table.repsConventionSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$WorkoutsTableAnnotationComposer get workoutId {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get catalogExerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.catalogExerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TemplateExercisesTableAnnotationComposer get templateExerciseId {
    final $$TemplateExercisesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.templateExerciseId,
          referencedTable: $db.templateExercises,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TemplateExercisesTableAnnotationComposer(
                $db: $db,
                $table: $db.templateExercises,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> workoutSetsRefs<T extends Object>(
    Expression<T> Function($$WorkoutSetsTableAnnotationComposer a) f,
  ) {
    final $$WorkoutSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutExercisesTable,
          WorkoutExercise,
          $$WorkoutExercisesTableFilterComposer,
          $$WorkoutExercisesTableOrderingComposer,
          $$WorkoutExercisesTableAnnotationComposer,
          $$WorkoutExercisesTableCreateCompanionBuilder,
          $$WorkoutExercisesTableUpdateCompanionBuilder,
          (WorkoutExercise, $$WorkoutExercisesTableReferences),
          WorkoutExercise,
          PrefetchHooks Function({
            bool workoutId,
            bool catalogExerciseId,
            bool templateExerciseId,
            bool workoutSetsRefs,
          })
        > {
  $$WorkoutExercisesTableTableManager(
    _$AppDatabase db,
    $WorkoutExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> workoutId = const Value.absent(),
                Value<int?> catalogExerciseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<ExerciseCategory> category = const Value.absent(),
                Value<TrackingType> trackingTypeSnapshot = const Value.absent(),
                Value<LoadConvention> loadConventionSnapshot =
                    const Value.absent(),
                Value<RepsConvention> repsConventionSnapshot =
                    const Value.absent(),
                Value<int?> templateExerciseId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => WorkoutExercisesCompanion(
                id: id,
                workoutId: workoutId,
                catalogExerciseId: catalogExerciseId,
                name: name,
                category: category,
                trackingTypeSnapshot: trackingTypeSnapshot,
                loadConventionSnapshot: loadConventionSnapshot,
                repsConventionSnapshot: repsConventionSnapshot,
                templateExerciseId: templateExerciseId,
                note: note,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int workoutId,
                Value<int?> catalogExerciseId = const Value.absent(),
                required String name,
                required ExerciseCategory category,
                required TrackingType trackingTypeSnapshot,
                required LoadConvention loadConventionSnapshot,
                required RepsConvention repsConventionSnapshot,
                Value<int?> templateExerciseId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required int sortOrder,
              }) => WorkoutExercisesCompanion.insert(
                id: id,
                workoutId: workoutId,
                catalogExerciseId: catalogExerciseId,
                name: name,
                category: category,
                trackingTypeSnapshot: trackingTypeSnapshot,
                loadConventionSnapshot: loadConventionSnapshot,
                repsConventionSnapshot: repsConventionSnapshot,
                templateExerciseId: templateExerciseId,
                note: note,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkoutExercisesTable, WorkoutExercise>(table),
                  $$WorkoutExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                workoutId = false,
                catalogExerciseId = false,
                templateExerciseId = false,
                workoutSetsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workoutSetsRefs) db.workoutSets,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (workoutId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.workoutId,
                            referencedTable: $$WorkoutExercisesTableReferences
                                ._workoutIdTable(db),
                            referencedColumn: $$WorkoutExercisesTableReferences
                                ._workoutIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (catalogExerciseId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.catalogExerciseId,
                            referencedTable: $$WorkoutExercisesTableReferences
                                ._catalogExerciseIdTable(db),
                            referencedColumn: $$WorkoutExercisesTableReferences
                                ._catalogExerciseIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (templateExerciseId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.templateExerciseId,
                            referencedTable: $$WorkoutExercisesTableReferences
                                ._templateExerciseIdTable(db),
                            referencedColumn: $$WorkoutExercisesTableReferences
                                ._templateExerciseIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workoutSetsRefs)
                        await $_getPrefetchedData<
                          WorkoutExercise,
                          $WorkoutExercisesTable,
                          WorkoutSet
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutExercisesTableReferences
                              ._workoutSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkoutExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutExercisesTable,
      WorkoutExercise,
      $$WorkoutExercisesTableFilterComposer,
      $$WorkoutExercisesTableOrderingComposer,
      $$WorkoutExercisesTableAnnotationComposer,
      $$WorkoutExercisesTableCreateCompanionBuilder,
      $$WorkoutExercisesTableUpdateCompanionBuilder,
      (WorkoutExercise, $$WorkoutExercisesTableReferences),
      WorkoutExercise,
      PrefetchHooks Function({
        bool workoutId,
        bool catalogExerciseId,
        bool templateExerciseId,
        bool workoutSetsRefs,
      })
    >;
typedef $$WorkoutSetsTableCreateCompanionBuilder =
    WorkoutSetsCompanion Function({
      Value<int> id,
      required int exerciseId,
      Value<int?> templateSetId,
      required SetRole setRole,
      required SetStatus setStatus,
      Value<int?> reps,
      Value<int?> durationSeconds,
      Value<double?> distanceMeters,
      Value<double?> weightKg,
      Value<double?> assistanceKg,
      Value<double?> rpe,
      Value<double?> rir,
      Value<String?> note,
      required int sortOrder,
    });
typedef $$WorkoutSetsTableUpdateCompanionBuilder =
    WorkoutSetsCompanion Function({
      Value<int> id,
      Value<int> exerciseId,
      Value<int?> templateSetId,
      Value<SetRole> setRole,
      Value<SetStatus> setStatus,
      Value<int?> reps,
      Value<int?> durationSeconds,
      Value<double?> distanceMeters,
      Value<double?> weightKg,
      Value<double?> assistanceKg,
      Value<double?> rpe,
      Value<double?> rir,
      Value<String?> note,
      Value<int> sortOrder,
    });

final class $$WorkoutSetsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutSetsTable, WorkoutSet> {
  $$WorkoutSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutExercisesTable _exerciseIdTable(_$AppDatabase db) => db
      .workoutExercises
      .createAlias('workout_sets__exercise_id__workout_exercises__id');

  $$WorkoutExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id')!;

    final manager = $$WorkoutExercisesTableTableManager(
      $_db,
      $_db.workoutExercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TemplateSetsTable _templateSetIdTable(_$AppDatabase db) => db
      .templateSets
      .createAlias('workout_sets__template_set_id__template_sets__id');

  $$TemplateSetsTableProcessedTableManager? get templateSetId {
    final $_column = $_itemColumn<int>('template_set_id');
    if ($_column == null) return null;
    final manager = $$TemplateSetsTableTableManager(
      $_db,
      $_db.templateSets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateSetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WorkoutSetsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SetRole, SetRole, String> get setRole =>
      $composableBuilder(
        column: $table.setRole,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<SetStatus, SetStatus, String> get setStatus =>
      $composableBuilder(
        column: $table.setStatus,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get assistanceKg => $composableBuilder(
    column: $table.assistanceKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rir => $composableBuilder(
    column: $table.rir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutExercisesTableFilterComposer get exerciseId {
    final $$WorkoutExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutExercisesTableFilterComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TemplateSetsTableFilterComposer get templateSetId {
    final $$TemplateSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateSetId,
      referencedTable: $db.templateSets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateSetsTableFilterComposer(
            $db: $db,
            $table: $db.templateSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setRole => $composableBuilder(
    column: $table.setRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setStatus => $composableBuilder(
    column: $table.setStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get assistanceKg => $composableBuilder(
    column: $table.assistanceKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rir => $composableBuilder(
    column: $table.rir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutExercisesTableOrderingComposer get exerciseId {
    final $$WorkoutExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TemplateSetsTableOrderingComposer get templateSetId {
    final $$TemplateSetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateSetId,
      referencedTable: $db.templateSets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateSetsTableOrderingComposer(
            $db: $db,
            $table: $db.templateSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SetRole, String> get setRole =>
      $composableBuilder(column: $table.setRole, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SetStatus, String> get setStatus =>
      $composableBuilder(column: $table.setStatus, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get assistanceKg => $composableBuilder(
    column: $table.assistanceKg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumn<double> get rir =>
      $composableBuilder(column: $table.rir, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$WorkoutExercisesTableAnnotationComposer get exerciseId {
    final $$WorkoutExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TemplateSetsTableAnnotationComposer get templateSetId {
    final $$TemplateSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateSetId,
      referencedTable: $db.templateSets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.templateSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutSetsTable,
          WorkoutSet,
          $$WorkoutSetsTableFilterComposer,
          $$WorkoutSetsTableOrderingComposer,
          $$WorkoutSetsTableAnnotationComposer,
          $$WorkoutSetsTableCreateCompanionBuilder,
          $$WorkoutSetsTableUpdateCompanionBuilder,
          (WorkoutSet, $$WorkoutSetsTableReferences),
          WorkoutSet,
          PrefetchHooks Function({bool exerciseId, bool templateSetId})
        > {
  $$WorkoutSetsTableTableManager(_$AppDatabase db, $WorkoutSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> exerciseId = const Value.absent(),
                Value<int?> templateSetId = const Value.absent(),
                Value<SetRole> setRole = const Value.absent(),
                Value<SetStatus> setStatus = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<double?> distanceMeters = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> assistanceKg = const Value.absent(),
                Value<double?> rpe = const Value.absent(),
                Value<double?> rir = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => WorkoutSetsCompanion(
                id: id,
                exerciseId: exerciseId,
                templateSetId: templateSetId,
                setRole: setRole,
                setStatus: setStatus,
                reps: reps,
                durationSeconds: durationSeconds,
                distanceMeters: distanceMeters,
                weightKg: weightKg,
                assistanceKg: assistanceKg,
                rpe: rpe,
                rir: rir,
                note: note,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int exerciseId,
                Value<int?> templateSetId = const Value.absent(),
                required SetRole setRole,
                required SetStatus setStatus,
                Value<int?> reps = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<double?> distanceMeters = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> assistanceKg = const Value.absent(),
                Value<double?> rpe = const Value.absent(),
                Value<double?> rir = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required int sortOrder,
              }) => WorkoutSetsCompanion.insert(
                id: id,
                exerciseId: exerciseId,
                templateSetId: templateSetId,
                setRole: setRole,
                setStatus: setStatus,
                reps: reps,
                durationSeconds: durationSeconds,
                distanceMeters: distanceMeters,
                weightKg: weightKg,
                assistanceKg: assistanceKg,
                rpe: rpe,
                rir: rir,
                note: note,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkoutSetsTable, WorkoutSet>(table),
                  $$WorkoutSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exerciseId = false, templateSetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (exerciseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.exerciseId,
                        referencedTable: $$WorkoutSetsTableReferences
                            ._exerciseIdTable(db),
                        referencedColumn: $$WorkoutSetsTableReferences
                            ._exerciseIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (templateSetId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.templateSetId,
                        referencedTable: $$WorkoutSetsTableReferences
                            ._templateSetIdTable(db),
                        referencedColumn: $$WorkoutSetsTableReferences
                            ._templateSetIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutSetsTable,
      WorkoutSet,
      $$WorkoutSetsTableFilterComposer,
      $$WorkoutSetsTableOrderingComposer,
      $$WorkoutSetsTableAnnotationComposer,
      $$WorkoutSetsTableCreateCompanionBuilder,
      $$WorkoutSetsTableUpdateCompanionBuilder,
      (WorkoutSet, $$WorkoutSetsTableReferences),
      WorkoutSet,
      PrefetchHooks Function({bool exerciseId, bool templateSetId})
    >;
typedef $$RestMarksTableCreateCompanionBuilder = RestMarksCompanion Function({
  Value<int> id,
  required DateTime date,
  Value<String?> note,
});
typedef $$RestMarksTableUpdateCompanionBuilder = RestMarksCompanion Function({
  Value<int> id,
  Value<DateTime> date,
  Value<String?> note,
});

class $$RestMarksTableFilterComposer
    extends Composer<_$AppDatabase, $RestMarksTable> {
  $$RestMarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RestMarksTableOrderingComposer
    extends Composer<_$AppDatabase, $RestMarksTable> {
  $$RestMarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RestMarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $RestMarksTable> {
  $$RestMarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$RestMarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RestMarksTable,
          RestMark,
          $$RestMarksTableFilterComposer,
          $$RestMarksTableOrderingComposer,
          $$RestMarksTableAnnotationComposer,
          $$RestMarksTableCreateCompanionBuilder,
          $$RestMarksTableUpdateCompanionBuilder,
          (RestMark, BaseReferences<_$AppDatabase, $RestMarksTable, RestMark>),
          RestMark,
          PrefetchHooks Function()
        > {
  $$RestMarksTableTableManager(_$AppDatabase db, $RestMarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RestMarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RestMarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RestMarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String?> note = const Value.absent(),
          }) => RestMarksCompanion(id: id, date: date, note: note),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
            Value<String?> note = const Value.absent(),
          }) => RestMarksCompanion.insert(id: id, date: date, note: note),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RestMarksTable, RestMark>(table),
                  BaseReferences<_$AppDatabase, $RestMarksTable, RestMark>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RestMarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RestMarksTable,
      RestMark,
      $$RestMarksTableFilterComposer,
      $$RestMarksTableOrderingComposer,
      $$RestMarksTableAnnotationComposer,
      $$RestMarksTableCreateCompanionBuilder,
      $$RestMarksTableUpdateCompanionBuilder,
      (RestMark, BaseReferences<_$AppDatabase, $RestMarksTable, RestMark>),
      RestMark,
      PrefetchHooks Function()
    >;
typedef $$RuleSetsTableCreateCompanionBuilder = RuleSetsCompanion Function({
  Value<int> id,
  required String name,
  required RulePeriod period,
  required DateTime effectiveFromDate,
  Value<DateTime?> effectiveUntilDate,
  required RuleCombineMode combineMode,
  required String expressionJson,
  required int evaluationPolicyVersion,
  Value<DateTime?> archivedAt,
  required DateTime createdAt,
});
typedef $$RuleSetsTableUpdateCompanionBuilder = RuleSetsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<RulePeriod> period,
  Value<DateTime> effectiveFromDate,
  Value<DateTime?> effectiveUntilDate,
  Value<RuleCombineMode> combineMode,
  Value<String> expressionJson,
  Value<int> evaluationPolicyVersion,
  Value<DateTime?> archivedAt,
  Value<DateTime> createdAt,
});

class $$RuleSetsTableFilterComposer
    extends Composer<_$AppDatabase, $RuleSetsTable> {
  $$RuleSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RulePeriod, RulePeriod, String> get period =>
      $composableBuilder(
        column: $table.period,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get effectiveFromDate => $composableBuilder(
    column: $table.effectiveFromDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get effectiveUntilDate => $composableBuilder(
    column: $table.effectiveUntilDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RuleCombineMode, RuleCombineMode, String>
  get combineMode => $composableBuilder(
    column: $table.combineMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get expressionJson => $composableBuilder(
    column: $table.expressionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get evaluationPolicyVersion => $composableBuilder(
    column: $table.evaluationPolicyVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RuleSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $RuleSetsTable> {
  $$RuleSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get effectiveFromDate => $composableBuilder(
    column: $table.effectiveFromDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get effectiveUntilDate => $composableBuilder(
    column: $table.effectiveUntilDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get combineMode => $composableBuilder(
    column: $table.combineMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expressionJson => $composableBuilder(
    column: $table.expressionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get evaluationPolicyVersion => $composableBuilder(
    column: $table.evaluationPolicyVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RuleSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RuleSetsTable> {
  $$RuleSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RulePeriod, String> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<DateTime> get effectiveFromDate => $composableBuilder(
    column: $table.effectiveFromDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get effectiveUntilDate => $composableBuilder(
    column: $table.effectiveUntilDate,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RuleCombineMode, String> get combineMode =>
      $composableBuilder(
        column: $table.combineMode,
        builder: (column) => column,
      );

  GeneratedColumn<String> get expressionJson => $composableBuilder(
    column: $table.expressionJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get evaluationPolicyVersion => $composableBuilder(
    column: $table.evaluationPolicyVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RuleSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RuleSetsTable,
          RuleSet,
          $$RuleSetsTableFilterComposer,
          $$RuleSetsTableOrderingComposer,
          $$RuleSetsTableAnnotationComposer,
          $$RuleSetsTableCreateCompanionBuilder,
          $$RuleSetsTableUpdateCompanionBuilder,
          (RuleSet, BaseReferences<_$AppDatabase, $RuleSetsTable, RuleSet>),
          RuleSet,
          PrefetchHooks Function()
        > {
  $$RuleSetsTableTableManager(_$AppDatabase db, $RuleSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RuleSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RuleSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RuleSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<RulePeriod> period = const Value.absent(),
                Value<DateTime> effectiveFromDate = const Value.absent(),
                Value<DateTime?> effectiveUntilDate = const Value.absent(),
                Value<RuleCombineMode> combineMode = const Value.absent(),
                Value<String> expressionJson = const Value.absent(),
                Value<int> evaluationPolicyVersion = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => RuleSetsCompanion(
                id: id,
                name: name,
                period: period,
                effectiveFromDate: effectiveFromDate,
                effectiveUntilDate: effectiveUntilDate,
                combineMode: combineMode,
                expressionJson: expressionJson,
                evaluationPolicyVersion: evaluationPolicyVersion,
                archivedAt: archivedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required RulePeriod period,
                required DateTime effectiveFromDate,
                Value<DateTime?> effectiveUntilDate = const Value.absent(),
                required RuleCombineMode combineMode,
                required String expressionJson,
                required int evaluationPolicyVersion,
                Value<DateTime?> archivedAt = const Value.absent(),
                required DateTime createdAt,
              }) => RuleSetsCompanion.insert(
                id: id,
                name: name,
                period: period,
                effectiveFromDate: effectiveFromDate,
                effectiveUntilDate: effectiveUntilDate,
                combineMode: combineMode,
                expressionJson: expressionJson,
                evaluationPolicyVersion: evaluationPolicyVersion,
                archivedAt: archivedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RuleSetsTable, RuleSet>(table),
                  BaseReferences<_$AppDatabase, $RuleSetsTable, RuleSet>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RuleSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RuleSetsTable,
      RuleSet,
      $$RuleSetsTableFilterComposer,
      $$RuleSetsTableOrderingComposer,
      $$RuleSetsTableAnnotationComposer,
      $$RuleSetsTableCreateCompanionBuilder,
      $$RuleSetsTableUpdateCompanionBuilder,
      (RuleSet, BaseReferences<_$AppDatabase, $RuleSetsTable, RuleSet>),
      RuleSet,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoodEntriesTableTableManager get foodEntries =>
      $$FoodEntriesTableTableManager(_db, _db.foodEntries);
  $$FavoriteFoodsTableTableManager get favoriteFoods =>
      $$FavoriteFoodsTableTableManager(_db, _db.favoriteFoods);
  $$WeeklyExerciseGoalsTableTableManager get weeklyExerciseGoals =>
      $$WeeklyExerciseGoalsTableTableManager(_db, _db.weeklyExerciseGoals);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$WorkoutTemplatesTableTableManager get workoutTemplates =>
      $$WorkoutTemplatesTableTableManager(_db, _db.workoutTemplates);
  $$TemplateVersionsTableTableManager get templateVersions =>
      $$TemplateVersionsTableTableManager(_db, _db.templateVersions);
  $$TemplateExercisesTableTableManager get templateExercises =>
      $$TemplateExercisesTableTableManager(_db, _db.templateExercises);
  $$TemplateSetsTableTableManager get templateSets =>
      $$TemplateSetsTableTableManager(_db, _db.templateSets);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db, _db.workouts);
  $$WorkoutExercisesTableTableManager get workoutExercises =>
      $$WorkoutExercisesTableTableManager(_db, _db.workoutExercises);
  $$WorkoutSetsTableTableManager get workoutSets =>
      $$WorkoutSetsTableTableManager(_db, _db.workoutSets);
  $$RestMarksTableTableManager get restMarks =>
      $$RestMarksTableTableManager(_db, _db.restMarks);
  $$RuleSetsTableTableManager get ruleSets =>
      $$RuleSetsTableTableManager(_db, _db.ruleSets);
}
