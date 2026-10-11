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

class $ExerciseEntriesTable extends ExerciseEntries
    with TableInfo<$ExerciseEntriesTable, ExerciseEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caloriesBurnedMeta = const VerificationMeta(
    'caloriesBurned',
  );
  @override
  late final GeneratedColumn<int> caloriesBurned = GeneratedColumn<int>(
    'calories_burned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    name,
    durationMinutes,
    caloriesBurned,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseEntry> instance, {
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
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('calories_burned')) {
      context.handle(
        _caloriesBurnedMeta,
        caloriesBurned.isAcceptableOrUnknown(
          data['calories_burned']!,
          _caloriesBurnedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caloriesBurnedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      caloriesBurned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories_burned'],
      )!,
    );
  }

  @override
  $ExerciseEntriesTable createAlias(String alias) {
    return $ExerciseEntriesTable(attachedDatabase, alias);
  }
}

class ExerciseEntry extends DataClass implements Insertable<ExerciseEntry> {
  final int id;
  final DateTime date;
  final String name;
  final int durationMinutes;
  final int caloriesBurned;
  const ExerciseEntry({
    required this.id,
    required this.date,
    required this.name,
    required this.durationMinutes,
    required this.caloriesBurned,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['name'] = Variable<String>(name);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['calories_burned'] = Variable<int>(caloriesBurned);
    return map;
  }

  ExerciseEntriesCompanion toCompanion(bool nullToAbsent) {
    return ExerciseEntriesCompanion(
      id: Value(id),
      date: Value(date),
      name: Value(name),
      durationMinutes: Value(durationMinutes),
      caloriesBurned: Value(caloriesBurned),
    );
  }

  factory ExerciseEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseEntry(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      name: serializer.fromJson<String>(json['name']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      caloriesBurned: serializer.fromJson<int>(json['caloriesBurned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'name': serializer.toJson<String>(name),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'caloriesBurned': serializer.toJson<int>(caloriesBurned),
    };
  }

  ExerciseEntry copyWith({
    int? id,
    DateTime? date,
    String? name,
    int? durationMinutes,
    int? caloriesBurned,
  }) => ExerciseEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    name: name ?? this.name,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    caloriesBurned: caloriesBurned ?? this.caloriesBurned,
  );
  ExerciseEntry copyWithCompanion(ExerciseEntriesCompanion data) {
    return ExerciseEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      name: data.name.present ? data.name.value : this.name,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      caloriesBurned: data.caloriesBurned.present
          ? data.caloriesBurned.value
          : this.caloriesBurned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('name: $name, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('caloriesBurned: $caloriesBurned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, name, durationMinutes, caloriesBurned);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.name == this.name &&
          other.durationMinutes == this.durationMinutes &&
          other.caloriesBurned == this.caloriesBurned);
}

class ExerciseEntriesCompanion extends UpdateCompanion<ExerciseEntry> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> name;
  final Value<int> durationMinutes;
  final Value<int> caloriesBurned;
  const ExerciseEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.name = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.caloriesBurned = const Value.absent(),
  });
  ExerciseEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String name,
    required int durationMinutes,
    required int caloriesBurned,
  }) : date = Value(date),
       name = Value(name),
       durationMinutes = Value(durationMinutes),
       caloriesBurned = Value(caloriesBurned);
  static Insertable<ExerciseEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? name,
    Expression<int>? durationMinutes,
    Expression<int>? caloriesBurned,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (name != null) 'name': name,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (caloriesBurned != null) 'calories_burned': caloriesBurned,
    });
  }

  ExerciseEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<String>? name,
    Value<int>? durationMinutes,
    Value<int>? caloriesBurned,
  }) {
    return ExerciseEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      name: name ?? this.name,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (caloriesBurned.present) {
      map['calories_burned'] = Variable<int>(caloriesBurned.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('name: $name, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('caloriesBurned: $caloriesBurned')
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoodEntriesTable foodEntries = $FoodEntriesTable(this);
  late final $ExerciseEntriesTable exerciseEntries = $ExerciseEntriesTable(
    this,
  );
  late final $FavoriteFoodsTable favoriteFoods = $FavoriteFoodsTable(this);
  late final $WeeklyExerciseGoalsTable weeklyExerciseGoals =
      $WeeklyExerciseGoalsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    foodEntries,
    exerciseEntries,
    favoriteFoods,
    weeklyExerciseGoals,
  ];
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
typedef $$ExerciseEntriesTableCreateCompanionBuilder =
    ExerciseEntriesCompanion Function({
      Value<int> id,
      required DateTime date,
      required String name,
      required int durationMinutes,
      required int caloriesBurned,
    });
typedef $$ExerciseEntriesTableUpdateCompanionBuilder =
    ExerciseEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<String> name,
      Value<int> durationMinutes,
      Value<int> caloriesBurned,
    });

class $$ExerciseEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseEntriesTable> {
  $$ExerciseEntriesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get caloriesBurned => $composableBuilder(
    column: $table.caloriesBurned,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExerciseEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseEntriesTable> {
  $$ExerciseEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get caloriesBurned => $composableBuilder(
    column: $table.caloriesBurned,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExerciseEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseEntriesTable> {
  $$ExerciseEntriesTableAnnotationComposer({
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get caloriesBurned => $composableBuilder(
    column: $table.caloriesBurned,
    builder: (column) => column,
  );
}

class $$ExerciseEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseEntriesTable,
          ExerciseEntry,
          $$ExerciseEntriesTableFilterComposer,
          $$ExerciseEntriesTableOrderingComposer,
          $$ExerciseEntriesTableAnnotationComposer,
          $$ExerciseEntriesTableCreateCompanionBuilder,
          $$ExerciseEntriesTableUpdateCompanionBuilder,
          (
            ExerciseEntry,
            BaseReferences<_$AppDatabase, $ExerciseEntriesTable, ExerciseEntry>,
          ),
          ExerciseEntry,
          PrefetchHooks Function()
        > {
  $$ExerciseEntriesTableTableManager(
    _$AppDatabase db,
    $ExerciseEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<int> caloriesBurned = const Value.absent(),
              }) => ExerciseEntriesCompanion(
                id: id,
                date: date,
                name: name,
                durationMinutes: durationMinutes,
                caloriesBurned: caloriesBurned,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required String name,
                required int durationMinutes,
                required int caloriesBurned,
              }) => ExerciseEntriesCompanion.insert(
                id: id,
                date: date,
                name: name,
                durationMinutes: durationMinutes,
                caloriesBurned: caloriesBurned,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExerciseEntriesTable, ExerciseEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ExerciseEntriesTable,
                    ExerciseEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExerciseEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseEntriesTable,
      ExerciseEntry,
      $$ExerciseEntriesTableFilterComposer,
      $$ExerciseEntriesTableOrderingComposer,
      $$ExerciseEntriesTableAnnotationComposer,
      $$ExerciseEntriesTableCreateCompanionBuilder,
      $$ExerciseEntriesTableUpdateCompanionBuilder,
      (
        ExerciseEntry,
        BaseReferences<_$AppDatabase, $ExerciseEntriesTable, ExerciseEntry>,
      ),
      ExerciseEntry,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoodEntriesTableTableManager get foodEntries =>
      $$FoodEntriesTableTableManager(_db, _db.foodEntries);
  $$ExerciseEntriesTableTableManager get exerciseEntries =>
      $$ExerciseEntriesTableTableManager(_db, _db.exerciseEntries);
  $$FavoriteFoodsTableTableManager get favoriteFoods =>
      $$FavoriteFoodsTableTableManager(_db, _db.favoriteFoods);
  $$WeeklyExerciseGoalsTableTableManager get weeklyExerciseGoals =>
      $$WeeklyExerciseGoalsTableTableManager(_db, _db.weeklyExerciseGoals);
}
