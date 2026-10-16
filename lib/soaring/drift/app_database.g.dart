// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AirportsTable extends Airports with TableInfo<$AirportsTable, Airport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AirportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _identMeta = const VerificationMeta('ident');
  @override
  late final GeneratedColumn<String> ident = GeneratedColumn<String>(
      'ident', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Unknown'));
  @override
  late final GeneratedColumnWithTypeConverter<dynamic, double> latitudeDeg =
      GeneratedColumn<double>('latitude_deg', aliasedName, false,
              type: DriftSqlType.double, requiredDuringInsert: true)
          .withConverter<dynamic>($AirportsTable.$converterlatitudeDeg);
  @override
  late final GeneratedColumnWithTypeConverter<dynamic, double> longitudeDeg =
      GeneratedColumn<double>('longitude_deg', aliasedName, false,
              type: DriftSqlType.double, requiredDuringInsert: true)
          .withConverter<dynamic>($AirportsTable.$converterlongitudeDeg);
  static const VerificationMeta _elevationFtMeta =
      const VerificationMeta('elevationFt');
  @override
  late final GeneratedColumn<int> elevationFt = GeneratedColumn<int>(
      'elevation_ft', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
      'state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _municipalityMeta =
      const VerificationMeta('municipality');
  @override
  late final GeneratedColumn<String> municipality = GeneratedColumn<String>(
      'municipality', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        ident,
        type,
        name,
        latitudeDeg,
        longitudeDeg,
        elevationFt,
        state,
        municipality
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'airport';
  @override
  VerificationContext validateIntegrity(Insertable<Airport> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ident')) {
      context.handle(
          _identMeta, ident.isAcceptableOrUnknown(data['ident']!, _identMeta));
    } else if (isInserting) {
      context.missing(_identMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('elevation_ft')) {
      context.handle(
          _elevationFtMeta,
          elevationFt.isAcceptableOrUnknown(
              data['elevation_ft']!, _elevationFtMeta));
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    }
    if (data.containsKey('municipality')) {
      context.handle(
          _municipalityMeta,
          municipality.isAcceptableOrUnknown(
              data['municipality']!, _municipalityMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Airport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Airport(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      ident: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ident'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      latitudeDeg: $AirportsTable.$converterlatitudeDeg.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude_deg'])!),
      longitudeDeg: $AirportsTable.$converterlongitudeDeg.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.double, data['${effectivePrefix}longitude_deg'])!),
      elevationFt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}elevation_ft'])!,
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state'])!,
      municipality: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}municipality'])!,
    );
  }

  @override
  $AirportsTable createAlias(String alias) {
    return $AirportsTable(attachedDatabase, alias);
  }

  static TypeConverter<dynamic, double> $converterlatitudeDeg =
      const LatLngConverter();
  static TypeConverter<dynamic, double> $converterlongitudeDeg =
      const LatLngConverter();
}

class Airport extends DataClass implements Insertable<Airport> {
  final int id;
  final String ident;
  final String type;
  final String name;
  final dynamic latitudeDeg;
  final dynamic longitudeDeg;
  final int elevationFt;
  final String state;
  final String municipality;
  const Airport(
      {required this.id,
      required this.ident,
      required this.type,
      required this.name,
      this.latitudeDeg,
      this.longitudeDeg,
      required this.elevationFt,
      required this.state,
      required this.municipality});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ident'] = Variable<String>(ident);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || latitudeDeg != null) {
      map['latitude_deg'] = Variable<double>(
          $AirportsTable.$converterlatitudeDeg.toSql(latitudeDeg));
    }
    if (!nullToAbsent || longitudeDeg != null) {
      map['longitude_deg'] = Variable<double>(
          $AirportsTable.$converterlongitudeDeg.toSql(longitudeDeg));
    }
    map['elevation_ft'] = Variable<int>(elevationFt);
    map['state'] = Variable<String>(state);
    map['municipality'] = Variable<String>(municipality);
    return map;
  }

  AirportsCompanion toCompanion(bool nullToAbsent) {
    return AirportsCompanion(
      id: Value(id),
      ident: Value(ident),
      type: Value(type),
      name: Value(name),
      latitudeDeg: latitudeDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(latitudeDeg),
      longitudeDeg: longitudeDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(longitudeDeg),
      elevationFt: Value(elevationFt),
      state: Value(state),
      municipality: Value(municipality),
    );
  }

  factory Airport.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Airport(
      id: serializer.fromJson<int>(json['id']),
      ident: serializer.fromJson<String>(json['ident']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      latitudeDeg: serializer.fromJson<dynamic>(json['latitudeDeg']),
      longitudeDeg: serializer.fromJson<dynamic>(json['longitudeDeg']),
      elevationFt: serializer.fromJson<int>(json['elevationFt']),
      state: serializer.fromJson<String>(json['state']),
      municipality: serializer.fromJson<String>(json['municipality']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ident': serializer.toJson<String>(ident),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'latitudeDeg': serializer.toJson<dynamic>(latitudeDeg),
      'longitudeDeg': serializer.toJson<dynamic>(longitudeDeg),
      'elevationFt': serializer.toJson<int>(elevationFt),
      'state': serializer.toJson<String>(state),
      'municipality': serializer.toJson<String>(municipality),
    };
  }

  Airport copyWith(
          {int? id,
          String? ident,
          String? type,
          String? name,
          Value<dynamic> latitudeDeg = const Value.absent(),
          Value<dynamic> longitudeDeg = const Value.absent(),
          int? elevationFt,
          String? state,
          String? municipality}) =>
      Airport(
        id: id ?? this.id,
        ident: ident ?? this.ident,
        type: type ?? this.type,
        name: name ?? this.name,
        latitudeDeg: latitudeDeg.present ? latitudeDeg.value : this.latitudeDeg,
        longitudeDeg:
            longitudeDeg.present ? longitudeDeg.value : this.longitudeDeg,
        elevationFt: elevationFt ?? this.elevationFt,
        state: state ?? this.state,
        municipality: municipality ?? this.municipality,
      );
  Airport copyWithCompanion(AirportsCompanion data) {
    return Airport(
      id: data.id.present ? data.id.value : this.id,
      ident: data.ident.present ? data.ident.value : this.ident,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      latitudeDeg:
          data.latitudeDeg.present ? data.latitudeDeg.value : this.latitudeDeg,
      longitudeDeg: data.longitudeDeg.present
          ? data.longitudeDeg.value
          : this.longitudeDeg,
      elevationFt:
          data.elevationFt.present ? data.elevationFt.value : this.elevationFt,
      state: data.state.present ? data.state.value : this.state,
      municipality: data.municipality.present
          ? data.municipality.value
          : this.municipality,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Airport(')
          ..write('id: $id, ')
          ..write('ident: $ident, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('latitudeDeg: $latitudeDeg, ')
          ..write('longitudeDeg: $longitudeDeg, ')
          ..write('elevationFt: $elevationFt, ')
          ..write('state: $state, ')
          ..write('municipality: $municipality')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ident, type, name, latitudeDeg,
      longitudeDeg, elevationFt, state, municipality);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Airport &&
          other.id == this.id &&
          other.ident == this.ident &&
          other.type == this.type &&
          other.name == this.name &&
          other.latitudeDeg == this.latitudeDeg &&
          other.longitudeDeg == this.longitudeDeg &&
          other.elevationFt == this.elevationFt &&
          other.state == this.state &&
          other.municipality == this.municipality);
}

class AirportsCompanion extends UpdateCompanion<Airport> {
  final Value<int> id;
  final Value<String> ident;
  final Value<String> type;
  final Value<String> name;
  final Value<dynamic> latitudeDeg;
  final Value<dynamic> longitudeDeg;
  final Value<int> elevationFt;
  final Value<String> state;
  final Value<String> municipality;
  const AirportsCompanion({
    this.id = const Value.absent(),
    this.ident = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.latitudeDeg = const Value.absent(),
    this.longitudeDeg = const Value.absent(),
    this.elevationFt = const Value.absent(),
    this.state = const Value.absent(),
    this.municipality = const Value.absent(),
  });
  AirportsCompanion.insert({
    this.id = const Value.absent(),
    required String ident,
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    required dynamic latitudeDeg,
    required dynamic longitudeDeg,
    this.elevationFt = const Value.absent(),
    this.state = const Value.absent(),
    this.municipality = const Value.absent(),
  })  : ident = Value(ident),
        latitudeDeg = Value(latitudeDeg),
        longitudeDeg = Value(longitudeDeg);
  static Insertable<Airport> custom({
    Expression<int>? id,
    Expression<String>? ident,
    Expression<String>? type,
    Expression<String>? name,
    Expression<double>? latitudeDeg,
    Expression<double>? longitudeDeg,
    Expression<int>? elevationFt,
    Expression<String>? state,
    Expression<String>? municipality,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ident != null) 'ident': ident,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (latitudeDeg != null) 'latitude_deg': latitudeDeg,
      if (longitudeDeg != null) 'longitude_deg': longitudeDeg,
      if (elevationFt != null) 'elevation_ft': elevationFt,
      if (state != null) 'state': state,
      if (municipality != null) 'municipality': municipality,
    });
  }

  AirportsCompanion copyWith(
      {Value<int>? id,
      Value<String>? ident,
      Value<String>? type,
      Value<String>? name,
      Value<dynamic>? latitudeDeg,
      Value<dynamic>? longitudeDeg,
      Value<int>? elevationFt,
      Value<String>? state,
      Value<String>? municipality}) {
    return AirportsCompanion(
      id: id ?? this.id,
      ident: ident ?? this.ident,
      type: type ?? this.type,
      name: name ?? this.name,
      latitudeDeg: latitudeDeg ?? this.latitudeDeg,
      longitudeDeg: longitudeDeg ?? this.longitudeDeg,
      elevationFt: elevationFt ?? this.elevationFt,
      state: state ?? this.state,
      municipality: municipality ?? this.municipality,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ident.present) {
      map['ident'] = Variable<String>(ident.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (latitudeDeg.present) {
      map['latitude_deg'] = Variable<double>(
          $AirportsTable.$converterlatitudeDeg.toSql(latitudeDeg.value));
    }
    if (longitudeDeg.present) {
      map['longitude_deg'] = Variable<double>(
          $AirportsTable.$converterlongitudeDeg.toSql(longitudeDeg.value));
    }
    if (elevationFt.present) {
      map['elevation_ft'] = Variable<int>(elevationFt.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (municipality.present) {
      map['municipality'] = Variable<String>(municipality.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AirportsCompanion(')
          ..write('id: $id, ')
          ..write('ident: $ident, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('latitudeDeg: $latitudeDeg, ')
          ..write('longitudeDeg: $longitudeDeg, ')
          ..write('elevationFt: $elevationFt, ')
          ..write('state: $state, ')
          ..write('municipality: $municipality')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _taskNameMeta =
      const VerificationMeta('taskName');
  @override
  late final GeneratedColumn<String> taskName = GeneratedColumn<String>(
      'task_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _distanceMeta =
      const VerificationMeta('distance');
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
      'distance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _taskOrderMeta =
      const VerificationMeta('taskOrder');
  @override
  late final GeneratedColumn<int> taskOrder = GeneratedColumn<int>(
      'task_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, taskName, distance, taskOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task';
  @override
  VerificationContext validateIntegrity(Insertable<Task> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_name')) {
      context.handle(_taskNameMeta,
          taskName.isAcceptableOrUnknown(data['task_name']!, _taskNameMeta));
    } else if (isInserting) {
      context.missing(_taskNameMeta);
    }
    if (data.containsKey('distance')) {
      context.handle(_distanceMeta,
          distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta));
    }
    if (data.containsKey('task_order')) {
      context.handle(_taskOrderMeta,
          taskOrder.isAcceptableOrUnknown(data['task_order']!, _taskOrderMeta));
    } else if (isInserting) {
      context.missing(_taskOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      taskName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_name'])!,
      distance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}distance'])!,
      taskOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}task_order'])!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final int id;
  final String taskName;
  final double distance;
  final int taskOrder;
  const Task(
      {required this.id,
      required this.taskName,
      required this.distance,
      required this.taskOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_name'] = Variable<String>(taskName);
    map['distance'] = Variable<double>(distance);
    map['task_order'] = Variable<int>(taskOrder);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      taskName: Value(taskName),
      distance: Value(distance),
      taskOrder: Value(taskOrder),
    );
  }

  factory Task.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      taskName: serializer.fromJson<String>(json['taskName']),
      distance: serializer.fromJson<double>(json['distance']),
      taskOrder: serializer.fromJson<int>(json['taskOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskName': serializer.toJson<String>(taskName),
      'distance': serializer.toJson<double>(distance),
      'taskOrder': serializer.toJson<int>(taskOrder),
    };
  }

  Task copyWith(
          {int? id, String? taskName, double? distance, int? taskOrder}) =>
      Task(
        id: id ?? this.id,
        taskName: taskName ?? this.taskName,
        distance: distance ?? this.distance,
        taskOrder: taskOrder ?? this.taskOrder,
      );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      taskName: data.taskName.present ? data.taskName.value : this.taskName,
      distance: data.distance.present ? data.distance.value : this.distance,
      taskOrder: data.taskOrder.present ? data.taskOrder.value : this.taskOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('taskName: $taskName, ')
          ..write('distance: $distance, ')
          ..write('taskOrder: $taskOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, taskName, distance, taskOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.taskName == this.taskName &&
          other.distance == this.distance &&
          other.taskOrder == this.taskOrder);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<String> taskName;
  final Value<double> distance;
  final Value<int> taskOrder;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.taskName = const Value.absent(),
    this.distance = const Value.absent(),
    this.taskOrder = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    required String taskName,
    this.distance = const Value.absent(),
    required int taskOrder,
  })  : taskName = Value(taskName),
        taskOrder = Value(taskOrder);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<String>? taskName,
    Expression<double>? distance,
    Expression<int>? taskOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskName != null) 'task_name': taskName,
      if (distance != null) 'distance': distance,
      if (taskOrder != null) 'task_order': taskOrder,
    });
  }

  TasksCompanion copyWith(
      {Value<int>? id,
      Value<String>? taskName,
      Value<double>? distance,
      Value<int>? taskOrder}) {
    return TasksCompanion(
      id: id ?? this.id,
      taskName: taskName ?? this.taskName,
      distance: distance ?? this.distance,
      taskOrder: taskOrder ?? this.taskOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskName.present) {
      map['task_name'] = Variable<String>(taskName.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (taskOrder.present) {
      map['task_order'] = Variable<int>(taskOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('taskName: $taskName, ')
          ..write('distance: $distance, ')
          ..write('taskOrder: $taskOrder')
          ..write(')'))
        .toString();
  }
}

class $TaskTurnpointsTable extends TaskTurnpoints
    with TableInfo<$TaskTurnpointsTable, TaskTurnpoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskTurnpointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
      'task_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES task (id) ON DELETE CASCADE'));
  static const VerificationMeta _taskOrderMeta =
      const VerificationMeta('taskOrder');
  @override
  late final GeneratedColumn<int> taskOrder = GeneratedColumn<int>(
      'task_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latitudeDegMeta =
      const VerificationMeta('latitudeDeg');
  @override
  late final GeneratedColumn<double> latitudeDeg = GeneratedColumn<double>(
      'latitude_deg', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeDegMeta =
      const VerificationMeta('longitudeDeg');
  @override
  late final GeneratedColumn<double> longitudeDeg = GeneratedColumn<double>(
      'longitude_deg', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _distanceFromPriorTurnpointMeta =
      const VerificationMeta('distanceFromPriorTurnpoint');
  @override
  late final GeneratedColumn<double> distanceFromPriorTurnpoint =
      GeneratedColumn<double>(
          'distance_from_prior_turnpoint', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _distanceFromStartingPointMeta =
      const VerificationMeta('distanceFromStartingPoint');
  @override
  late final GeneratedColumn<double> distanceFromStartingPoint =
      GeneratedColumn<double>(
          'distance_from_starting_point', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lastTurnpointMeta =
      const VerificationMeta('lastTurnpoint');
  @override
  late final GeneratedColumn<bool> lastTurnpoint = GeneratedColumn<bool>(
      'last_turnpoint', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("last_turnpoint" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        taskId,
        taskOrder,
        title,
        code,
        latitudeDeg,
        longitudeDeg,
        distanceFromPriorTurnpoint,
        distanceFromStartingPoint,
        lastTurnpoint
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'taskturnpoint';
  @override
  VerificationContext validateIntegrity(Insertable<TaskTurnpoint> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta,
          taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('task_order')) {
      context.handle(_taskOrderMeta,
          taskOrder.isAcceptableOrUnknown(data['task_order']!, _taskOrderMeta));
    } else if (isInserting) {
      context.missing(_taskOrderMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('latitude_deg')) {
      context.handle(
          _latitudeDegMeta,
          latitudeDeg.isAcceptableOrUnknown(
              data['latitude_deg']!, _latitudeDegMeta));
    } else if (isInserting) {
      context.missing(_latitudeDegMeta);
    }
    if (data.containsKey('longitude_deg')) {
      context.handle(
          _longitudeDegMeta,
          longitudeDeg.isAcceptableOrUnknown(
              data['longitude_deg']!, _longitudeDegMeta));
    } else if (isInserting) {
      context.missing(_longitudeDegMeta);
    }
    if (data.containsKey('distance_from_prior_turnpoint')) {
      context.handle(
          _distanceFromPriorTurnpointMeta,
          distanceFromPriorTurnpoint.isAcceptableOrUnknown(
              data['distance_from_prior_turnpoint']!,
              _distanceFromPriorTurnpointMeta));
    } else if (isInserting) {
      context.missing(_distanceFromPriorTurnpointMeta);
    }
    if (data.containsKey('distance_from_starting_point')) {
      context.handle(
          _distanceFromStartingPointMeta,
          distanceFromStartingPoint.isAcceptableOrUnknown(
              data['distance_from_starting_point']!,
              _distanceFromStartingPointMeta));
    } else if (isInserting) {
      context.missing(_distanceFromStartingPointMeta);
    }
    if (data.containsKey('last_turnpoint')) {
      context.handle(
          _lastTurnpointMeta,
          lastTurnpoint.isAcceptableOrUnknown(
              data['last_turnpoint']!, _lastTurnpointMeta));
    } else if (isInserting) {
      context.missing(_lastTurnpointMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskTurnpoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskTurnpoint(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      taskId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}task_id'])!,
      taskOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}task_order'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      latitudeDeg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude_deg'])!,
      longitudeDeg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude_deg'])!,
      distanceFromPriorTurnpoint: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}distance_from_prior_turnpoint'])!,
      distanceFromStartingPoint: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}distance_from_starting_point'])!,
      lastTurnpoint: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}last_turnpoint'])!,
    );
  }

  @override
  $TaskTurnpointsTable createAlias(String alias) {
    return $TaskTurnpointsTable(attachedDatabase, alias);
  }
}

class TaskTurnpoint extends DataClass implements Insertable<TaskTurnpoint> {
  final int id;
  final int taskId;
  final int taskOrder;
  final String title;
  final String code;
  final double latitudeDeg;
  final double longitudeDeg;
  final double distanceFromPriorTurnpoint;
  final double distanceFromStartingPoint;
  final bool lastTurnpoint;
  const TaskTurnpoint(
      {required this.id,
      required this.taskId,
      required this.taskOrder,
      required this.title,
      required this.code,
      required this.latitudeDeg,
      required this.longitudeDeg,
      required this.distanceFromPriorTurnpoint,
      required this.distanceFromStartingPoint,
      required this.lastTurnpoint});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    map['task_order'] = Variable<int>(taskOrder);
    map['title'] = Variable<String>(title);
    map['code'] = Variable<String>(code);
    map['latitude_deg'] = Variable<double>(latitudeDeg);
    map['longitude_deg'] = Variable<double>(longitudeDeg);
    map['distance_from_prior_turnpoint'] =
        Variable<double>(distanceFromPriorTurnpoint);
    map['distance_from_starting_point'] =
        Variable<double>(distanceFromStartingPoint);
    map['last_turnpoint'] = Variable<bool>(lastTurnpoint);
    return map;
  }

  TaskTurnpointsCompanion toCompanion(bool nullToAbsent) {
    return TaskTurnpointsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      taskOrder: Value(taskOrder),
      title: Value(title),
      code: Value(code),
      latitudeDeg: Value(latitudeDeg),
      longitudeDeg: Value(longitudeDeg),
      distanceFromPriorTurnpoint: Value(distanceFromPriorTurnpoint),
      distanceFromStartingPoint: Value(distanceFromStartingPoint),
      lastTurnpoint: Value(lastTurnpoint),
    );
  }

  factory TaskTurnpoint.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskTurnpoint(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      taskOrder: serializer.fromJson<int>(json['taskOrder']),
      title: serializer.fromJson<String>(json['title']),
      code: serializer.fromJson<String>(json['code']),
      latitudeDeg: serializer.fromJson<double>(json['latitudeDeg']),
      longitudeDeg: serializer.fromJson<double>(json['longitudeDeg']),
      distanceFromPriorTurnpoint:
          serializer.fromJson<double>(json['distanceFromPriorTurnpoint']),
      distanceFromStartingPoint:
          serializer.fromJson<double>(json['distanceFromStartingPoint']),
      lastTurnpoint: serializer.fromJson<bool>(json['lastTurnpoint']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'taskOrder': serializer.toJson<int>(taskOrder),
      'title': serializer.toJson<String>(title),
      'code': serializer.toJson<String>(code),
      'latitudeDeg': serializer.toJson<double>(latitudeDeg),
      'longitudeDeg': serializer.toJson<double>(longitudeDeg),
      'distanceFromPriorTurnpoint':
          serializer.toJson<double>(distanceFromPriorTurnpoint),
      'distanceFromStartingPoint':
          serializer.toJson<double>(distanceFromStartingPoint),
      'lastTurnpoint': serializer.toJson<bool>(lastTurnpoint),
    };
  }

  TaskTurnpoint copyWith(
          {int? id,
          int? taskId,
          int? taskOrder,
          String? title,
          String? code,
          double? latitudeDeg,
          double? longitudeDeg,
          double? distanceFromPriorTurnpoint,
          double? distanceFromStartingPoint,
          bool? lastTurnpoint}) =>
      TaskTurnpoint(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        taskOrder: taskOrder ?? this.taskOrder,
        title: title ?? this.title,
        code: code ?? this.code,
        latitudeDeg: latitudeDeg ?? this.latitudeDeg,
        longitudeDeg: longitudeDeg ?? this.longitudeDeg,
        distanceFromPriorTurnpoint:
            distanceFromPriorTurnpoint ?? this.distanceFromPriorTurnpoint,
        distanceFromStartingPoint:
            distanceFromStartingPoint ?? this.distanceFromStartingPoint,
        lastTurnpoint: lastTurnpoint ?? this.lastTurnpoint,
      );
  TaskTurnpoint copyWithCompanion(TaskTurnpointsCompanion data) {
    return TaskTurnpoint(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      taskOrder: data.taskOrder.present ? data.taskOrder.value : this.taskOrder,
      title: data.title.present ? data.title.value : this.title,
      code: data.code.present ? data.code.value : this.code,
      latitudeDeg:
          data.latitudeDeg.present ? data.latitudeDeg.value : this.latitudeDeg,
      longitudeDeg: data.longitudeDeg.present
          ? data.longitudeDeg.value
          : this.longitudeDeg,
      distanceFromPriorTurnpoint: data.distanceFromPriorTurnpoint.present
          ? data.distanceFromPriorTurnpoint.value
          : this.distanceFromPriorTurnpoint,
      distanceFromStartingPoint: data.distanceFromStartingPoint.present
          ? data.distanceFromStartingPoint.value
          : this.distanceFromStartingPoint,
      lastTurnpoint: data.lastTurnpoint.present
          ? data.lastTurnpoint.value
          : this.lastTurnpoint,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskTurnpoint(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('taskOrder: $taskOrder, ')
          ..write('title: $title, ')
          ..write('code: $code, ')
          ..write('latitudeDeg: $latitudeDeg, ')
          ..write('longitudeDeg: $longitudeDeg, ')
          ..write('distanceFromPriorTurnpoint: $distanceFromPriorTurnpoint, ')
          ..write('distanceFromStartingPoint: $distanceFromStartingPoint, ')
          ..write('lastTurnpoint: $lastTurnpoint')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      taskId,
      taskOrder,
      title,
      code,
      latitudeDeg,
      longitudeDeg,
      distanceFromPriorTurnpoint,
      distanceFromStartingPoint,
      lastTurnpoint);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskTurnpoint &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.taskOrder == this.taskOrder &&
          other.title == this.title &&
          other.code == this.code &&
          other.latitudeDeg == this.latitudeDeg &&
          other.longitudeDeg == this.longitudeDeg &&
          other.distanceFromPriorTurnpoint == this.distanceFromPriorTurnpoint &&
          other.distanceFromStartingPoint == this.distanceFromStartingPoint &&
          other.lastTurnpoint == this.lastTurnpoint);
}

class TaskTurnpointsCompanion extends UpdateCompanion<TaskTurnpoint> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<int> taskOrder;
  final Value<String> title;
  final Value<String> code;
  final Value<double> latitudeDeg;
  final Value<double> longitudeDeg;
  final Value<double> distanceFromPriorTurnpoint;
  final Value<double> distanceFromStartingPoint;
  final Value<bool> lastTurnpoint;
  const TaskTurnpointsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.taskOrder = const Value.absent(),
    this.title = const Value.absent(),
    this.code = const Value.absent(),
    this.latitudeDeg = const Value.absent(),
    this.longitudeDeg = const Value.absent(),
    this.distanceFromPriorTurnpoint = const Value.absent(),
    this.distanceFromStartingPoint = const Value.absent(),
    this.lastTurnpoint = const Value.absent(),
  });
  TaskTurnpointsCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    required int taskOrder,
    required String title,
    required String code,
    required double latitudeDeg,
    required double longitudeDeg,
    required double distanceFromPriorTurnpoint,
    required double distanceFromStartingPoint,
    required bool lastTurnpoint,
  })  : taskId = Value(taskId),
        taskOrder = Value(taskOrder),
        title = Value(title),
        code = Value(code),
        latitudeDeg = Value(latitudeDeg),
        longitudeDeg = Value(longitudeDeg),
        distanceFromPriorTurnpoint = Value(distanceFromPriorTurnpoint),
        distanceFromStartingPoint = Value(distanceFromStartingPoint),
        lastTurnpoint = Value(lastTurnpoint);
  static Insertable<TaskTurnpoint> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<int>? taskOrder,
    Expression<String>? title,
    Expression<String>? code,
    Expression<double>? latitudeDeg,
    Expression<double>? longitudeDeg,
    Expression<double>? distanceFromPriorTurnpoint,
    Expression<double>? distanceFromStartingPoint,
    Expression<bool>? lastTurnpoint,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (taskOrder != null) 'task_order': taskOrder,
      if (title != null) 'title': title,
      if (code != null) 'code': code,
      if (latitudeDeg != null) 'latitude_deg': latitudeDeg,
      if (longitudeDeg != null) 'longitude_deg': longitudeDeg,
      if (distanceFromPriorTurnpoint != null)
        'distance_from_prior_turnpoint': distanceFromPriorTurnpoint,
      if (distanceFromStartingPoint != null)
        'distance_from_starting_point': distanceFromStartingPoint,
      if (lastTurnpoint != null) 'last_turnpoint': lastTurnpoint,
    });
  }

  TaskTurnpointsCompanion copyWith(
      {Value<int>? id,
      Value<int>? taskId,
      Value<int>? taskOrder,
      Value<String>? title,
      Value<String>? code,
      Value<double>? latitudeDeg,
      Value<double>? longitudeDeg,
      Value<double>? distanceFromPriorTurnpoint,
      Value<double>? distanceFromStartingPoint,
      Value<bool>? lastTurnpoint}) {
    return TaskTurnpointsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      taskOrder: taskOrder ?? this.taskOrder,
      title: title ?? this.title,
      code: code ?? this.code,
      latitudeDeg: latitudeDeg ?? this.latitudeDeg,
      longitudeDeg: longitudeDeg ?? this.longitudeDeg,
      distanceFromPriorTurnpoint:
          distanceFromPriorTurnpoint ?? this.distanceFromPriorTurnpoint,
      distanceFromStartingPoint:
          distanceFromStartingPoint ?? this.distanceFromStartingPoint,
      lastTurnpoint: lastTurnpoint ?? this.lastTurnpoint,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (taskOrder.present) {
      map['task_order'] = Variable<int>(taskOrder.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (latitudeDeg.present) {
      map['latitude_deg'] = Variable<double>(latitudeDeg.value);
    }
    if (longitudeDeg.present) {
      map['longitude_deg'] = Variable<double>(longitudeDeg.value);
    }
    if (distanceFromPriorTurnpoint.present) {
      map['distance_from_prior_turnpoint'] =
          Variable<double>(distanceFromPriorTurnpoint.value);
    }
    if (distanceFromStartingPoint.present) {
      map['distance_from_starting_point'] =
          Variable<double>(distanceFromStartingPoint.value);
    }
    if (lastTurnpoint.present) {
      map['last_turnpoint'] = Variable<bool>(lastTurnpoint.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskTurnpointsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('taskOrder: $taskOrder, ')
          ..write('title: $title, ')
          ..write('code: $code, ')
          ..write('latitudeDeg: $latitudeDeg, ')
          ..write('longitudeDeg: $longitudeDeg, ')
          ..write('distanceFromPriorTurnpoint: $distanceFromPriorTurnpoint, ')
          ..write('distanceFromStartingPoint: $distanceFromStartingPoint, ')
          ..write('lastTurnpoint: $lastTurnpoint')
          ..write(')'))
        .toString();
  }
}

class $TurnpointsTable extends Turnpoints
    with TableInfo<$TurnpointsTable, Turnpoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TurnpointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _countryMeta =
      const VerificationMeta('country');
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
      'country', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _latitudeDegMeta =
      const VerificationMeta('latitudeDeg');
  @override
  late final GeneratedColumn<double> latitudeDeg = GeneratedColumn<double>(
      'latitude_deg', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _longitudeDegMeta =
      const VerificationMeta('longitudeDeg');
  @override
  late final GeneratedColumn<double> longitudeDeg = GeneratedColumn<double>(
      'longitude_deg', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _elevationMeta =
      const VerificationMeta('elevation');
  @override
  late final GeneratedColumn<String> elevation = GeneratedColumn<String>(
      'elevation', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<String> style = GeneratedColumn<String>(
      'style', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('0'));
  static const VerificationMeta _directionMeta =
      const VerificationMeta('direction');
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
      'direction', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _lengthMeta = const VerificationMeta('length');
  @override
  late final GeneratedColumn<String> length = GeneratedColumn<String>(
      'length', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _frequencyMeta =
      const VerificationMeta('frequency');
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
      'frequency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _runwayWidthMeta =
      const VerificationMeta('runwayWidth');
  @override
  late final GeneratedColumn<String> runwayWidth = GeneratedColumn<String>(
      'runway_width', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        code,
        country,
        latitudeDeg,
        longitudeDeg,
        elevation,
        style,
        direction,
        length,
        frequency,
        description,
        runwayWidth
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'turnpoint';
  @override
  VerificationContext validateIntegrity(Insertable<Turnpoint> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    }
    if (data.containsKey('country')) {
      context.handle(_countryMeta,
          country.isAcceptableOrUnknown(data['country']!, _countryMeta));
    }
    if (data.containsKey('latitude_deg')) {
      context.handle(
          _latitudeDegMeta,
          latitudeDeg.isAcceptableOrUnknown(
              data['latitude_deg']!, _latitudeDegMeta));
    }
    if (data.containsKey('longitude_deg')) {
      context.handle(
          _longitudeDegMeta,
          longitudeDeg.isAcceptableOrUnknown(
              data['longitude_deg']!, _longitudeDegMeta));
    }
    if (data.containsKey('elevation')) {
      context.handle(_elevationMeta,
          elevation.isAcceptableOrUnknown(data['elevation']!, _elevationMeta));
    }
    if (data.containsKey('style')) {
      context.handle(
          _styleMeta, style.isAcceptableOrUnknown(data['style']!, _styleMeta));
    }
    if (data.containsKey('direction')) {
      context.handle(_directionMeta,
          direction.isAcceptableOrUnknown(data['direction']!, _directionMeta));
    }
    if (data.containsKey('length')) {
      context.handle(_lengthMeta,
          length.isAcceptableOrUnknown(data['length']!, _lengthMeta));
    }
    if (data.containsKey('frequency')) {
      context.handle(_frequencyMeta,
          frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('runway_width')) {
      context.handle(
          _runwayWidthMeta,
          runwayWidth.isAcceptableOrUnknown(
              data['runway_width']!, _runwayWidthMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {title, code},
      ];
  @override
  Turnpoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Turnpoint(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      country: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}country'])!,
      latitudeDeg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude_deg'])!,
      longitudeDeg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude_deg'])!,
      elevation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}elevation'])!,
      style: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}style'])!,
      direction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      length: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}length'])!,
      frequency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}frequency'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      runwayWidth: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}runway_width'])!,
    );
  }

  @override
  $TurnpointsTable createAlias(String alias) {
    return $TurnpointsTable(attachedDatabase, alias);
  }
}

class Turnpoint extends DataClass implements Insertable<Turnpoint> {
  final int id;
  final String title;
  final String code;
  final String country;
  final double latitudeDeg;
  final double longitudeDeg;
  final String elevation;
  final String style;
  final String direction;
  final String length;
  final String frequency;
  final String description;
  final String runwayWidth;
  const Turnpoint(
      {required this.id,
      required this.title,
      required this.code,
      required this.country,
      required this.latitudeDeg,
      required this.longitudeDeg,
      required this.elevation,
      required this.style,
      required this.direction,
      required this.length,
      required this.frequency,
      required this.description,
      required this.runwayWidth});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['code'] = Variable<String>(code);
    map['country'] = Variable<String>(country);
    map['latitude_deg'] = Variable<double>(latitudeDeg);
    map['longitude_deg'] = Variable<double>(longitudeDeg);
    map['elevation'] = Variable<String>(elevation);
    map['style'] = Variable<String>(style);
    map['direction'] = Variable<String>(direction);
    map['length'] = Variable<String>(length);
    map['frequency'] = Variable<String>(frequency);
    map['description'] = Variable<String>(description);
    map['runway_width'] = Variable<String>(runwayWidth);
    return map;
  }

  TurnpointsCompanion toCompanion(bool nullToAbsent) {
    return TurnpointsCompanion(
      id: Value(id),
      title: Value(title),
      code: Value(code),
      country: Value(country),
      latitudeDeg: Value(latitudeDeg),
      longitudeDeg: Value(longitudeDeg),
      elevation: Value(elevation),
      style: Value(style),
      direction: Value(direction),
      length: Value(length),
      frequency: Value(frequency),
      description: Value(description),
      runwayWidth: Value(runwayWidth),
    );
  }

  factory Turnpoint.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Turnpoint(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      code: serializer.fromJson<String>(json['code']),
      country: serializer.fromJson<String>(json['country']),
      latitudeDeg: serializer.fromJson<double>(json['latitudeDeg']),
      longitudeDeg: serializer.fromJson<double>(json['longitudeDeg']),
      elevation: serializer.fromJson<String>(json['elevation']),
      style: serializer.fromJson<String>(json['style']),
      direction: serializer.fromJson<String>(json['direction']),
      length: serializer.fromJson<String>(json['length']),
      frequency: serializer.fromJson<String>(json['frequency']),
      description: serializer.fromJson<String>(json['description']),
      runwayWidth: serializer.fromJson<String>(json['runwayWidth']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'code': serializer.toJson<String>(code),
      'country': serializer.toJson<String>(country),
      'latitudeDeg': serializer.toJson<double>(latitudeDeg),
      'longitudeDeg': serializer.toJson<double>(longitudeDeg),
      'elevation': serializer.toJson<String>(elevation),
      'style': serializer.toJson<String>(style),
      'direction': serializer.toJson<String>(direction),
      'length': serializer.toJson<String>(length),
      'frequency': serializer.toJson<String>(frequency),
      'description': serializer.toJson<String>(description),
      'runwayWidth': serializer.toJson<String>(runwayWidth),
    };
  }

  Turnpoint copyWith(
          {int? id,
          String? title,
          String? code,
          String? country,
          double? latitudeDeg,
          double? longitudeDeg,
          String? elevation,
          String? style,
          String? direction,
          String? length,
          String? frequency,
          String? description,
          String? runwayWidth}) =>
      Turnpoint(
        id: id ?? this.id,
        title: title ?? this.title,
        code: code ?? this.code,
        country: country ?? this.country,
        latitudeDeg: latitudeDeg ?? this.latitudeDeg,
        longitudeDeg: longitudeDeg ?? this.longitudeDeg,
        elevation: elevation ?? this.elevation,
        style: style ?? this.style,
        direction: direction ?? this.direction,
        length: length ?? this.length,
        frequency: frequency ?? this.frequency,
        description: description ?? this.description,
        runwayWidth: runwayWidth ?? this.runwayWidth,
      );
  Turnpoint copyWithCompanion(TurnpointsCompanion data) {
    return Turnpoint(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      code: data.code.present ? data.code.value : this.code,
      country: data.country.present ? data.country.value : this.country,
      latitudeDeg:
          data.latitudeDeg.present ? data.latitudeDeg.value : this.latitudeDeg,
      longitudeDeg: data.longitudeDeg.present
          ? data.longitudeDeg.value
          : this.longitudeDeg,
      elevation: data.elevation.present ? data.elevation.value : this.elevation,
      style: data.style.present ? data.style.value : this.style,
      direction: data.direction.present ? data.direction.value : this.direction,
      length: data.length.present ? data.length.value : this.length,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      description:
          data.description.present ? data.description.value : this.description,
      runwayWidth:
          data.runwayWidth.present ? data.runwayWidth.value : this.runwayWidth,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Turnpoint(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('code: $code, ')
          ..write('country: $country, ')
          ..write('latitudeDeg: $latitudeDeg, ')
          ..write('longitudeDeg: $longitudeDeg, ')
          ..write('elevation: $elevation, ')
          ..write('style: $style, ')
          ..write('direction: $direction, ')
          ..write('length: $length, ')
          ..write('frequency: $frequency, ')
          ..write('description: $description, ')
          ..write('runwayWidth: $runwayWidth')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      code,
      country,
      latitudeDeg,
      longitudeDeg,
      elevation,
      style,
      direction,
      length,
      frequency,
      description,
      runwayWidth);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Turnpoint &&
          other.id == this.id &&
          other.title == this.title &&
          other.code == this.code &&
          other.country == this.country &&
          other.latitudeDeg == this.latitudeDeg &&
          other.longitudeDeg == this.longitudeDeg &&
          other.elevation == this.elevation &&
          other.style == this.style &&
          other.direction == this.direction &&
          other.length == this.length &&
          other.frequency == this.frequency &&
          other.description == this.description &&
          other.runwayWidth == this.runwayWidth);
}

class TurnpointsCompanion extends UpdateCompanion<Turnpoint> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> code;
  final Value<String> country;
  final Value<double> latitudeDeg;
  final Value<double> longitudeDeg;
  final Value<String> elevation;
  final Value<String> style;
  final Value<String> direction;
  final Value<String> length;
  final Value<String> frequency;
  final Value<String> description;
  final Value<String> runwayWidth;
  const TurnpointsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.code = const Value.absent(),
    this.country = const Value.absent(),
    this.latitudeDeg = const Value.absent(),
    this.longitudeDeg = const Value.absent(),
    this.elevation = const Value.absent(),
    this.style = const Value.absent(),
    this.direction = const Value.absent(),
    this.length = const Value.absent(),
    this.frequency = const Value.absent(),
    this.description = const Value.absent(),
    this.runwayWidth = const Value.absent(),
  });
  TurnpointsCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.code = const Value.absent(),
    this.country = const Value.absent(),
    this.latitudeDeg = const Value.absent(),
    this.longitudeDeg = const Value.absent(),
    this.elevation = const Value.absent(),
    this.style = const Value.absent(),
    this.direction = const Value.absent(),
    this.length = const Value.absent(),
    this.frequency = const Value.absent(),
    this.description = const Value.absent(),
    this.runwayWidth = const Value.absent(),
  });
  static Insertable<Turnpoint> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? code,
    Expression<String>? country,
    Expression<double>? latitudeDeg,
    Expression<double>? longitudeDeg,
    Expression<String>? elevation,
    Expression<String>? style,
    Expression<String>? direction,
    Expression<String>? length,
    Expression<String>? frequency,
    Expression<String>? description,
    Expression<String>? runwayWidth,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (code != null) 'code': code,
      if (country != null) 'country': country,
      if (latitudeDeg != null) 'latitude_deg': latitudeDeg,
      if (longitudeDeg != null) 'longitude_deg': longitudeDeg,
      if (elevation != null) 'elevation': elevation,
      if (style != null) 'style': style,
      if (direction != null) 'direction': direction,
      if (length != null) 'length': length,
      if (frequency != null) 'frequency': frequency,
      if (description != null) 'description': description,
      if (runwayWidth != null) 'runway_width': runwayWidth,
    });
  }

  TurnpointsCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String>? code,
      Value<String>? country,
      Value<double>? latitudeDeg,
      Value<double>? longitudeDeg,
      Value<String>? elevation,
      Value<String>? style,
      Value<String>? direction,
      Value<String>? length,
      Value<String>? frequency,
      Value<String>? description,
      Value<String>? runwayWidth}) {
    return TurnpointsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      code: code ?? this.code,
      country: country ?? this.country,
      latitudeDeg: latitudeDeg ?? this.latitudeDeg,
      longitudeDeg: longitudeDeg ?? this.longitudeDeg,
      elevation: elevation ?? this.elevation,
      style: style ?? this.style,
      direction: direction ?? this.direction,
      length: length ?? this.length,
      frequency: frequency ?? this.frequency,
      description: description ?? this.description,
      runwayWidth: runwayWidth ?? this.runwayWidth,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (latitudeDeg.present) {
      map['latitude_deg'] = Variable<double>(latitudeDeg.value);
    }
    if (longitudeDeg.present) {
      map['longitude_deg'] = Variable<double>(longitudeDeg.value);
    }
    if (elevation.present) {
      map['elevation'] = Variable<String>(elevation.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(style.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (length.present) {
      map['length'] = Variable<String>(length.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (runwayWidth.present) {
      map['runway_width'] = Variable<String>(runwayWidth.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TurnpointsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('code: $code, ')
          ..write('country: $country, ')
          ..write('latitudeDeg: $latitudeDeg, ')
          ..write('longitudeDeg: $longitudeDeg, ')
          ..write('elevation: $elevation, ')
          ..write('style: $style, ')
          ..write('direction: $direction, ')
          ..write('length: $length, ')
          ..write('frequency: $frequency, ')
          ..write('description: $description, ')
          ..write('runwayWidth: $runwayWidth')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AirportsTable airports = $AirportsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $TaskTurnpointsTable taskTurnpoints = $TaskTurnpointsTable(this);
  late final $TurnpointsTable turnpoints = $TurnpointsTable(this);
  late final Index indexAirportName = Index('index_airport_name',
      'CREATE INDEX index_airport_name ON airport (name)');
  late final Index indexAirportStateName = Index('index_airport_state_name',
      'CREATE INDEX index_airport_state_name ON airport (state, name)');
  late final Index indexAirportMunicipality = Index(
      'index_airport_municipality',
      'CREATE INDEX index_airport_municipality ON airport (municipality)');
  late final Index indexTurnpointCode = Index('index_turnpoint_code',
      'CREATE INDEX index_turnpoint_code ON turnpoint (code)');
  late final AirportsDao airportsDao = AirportsDao(this as AppDatabase);
  late final TasksDao tasksDao = TasksDao(this as AppDatabase);
  late final TaskTurnpointsDao taskTurnpointsDao =
      TaskTurnpointsDao(this as AppDatabase);
  late final TurnpointsDao turnpointsDao = TurnpointsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        airports,
        tasks,
        taskTurnpoints,
        turnpoints,
        indexAirportName,
        indexAirportStateName,
        indexAirportMunicipality,
        indexTurnpointCode
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('task',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('taskturnpoint', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$AirportsTableCreateCompanionBuilder = AirportsCompanion Function({
  Value<int> id,
  required String ident,
  Value<String> type,
  Value<String> name,
  required dynamic latitudeDeg,
  required dynamic longitudeDeg,
  Value<int> elevationFt,
  Value<String> state,
  Value<String> municipality,
});
typedef $$AirportsTableUpdateCompanionBuilder = AirportsCompanion Function({
  Value<int> id,
  Value<String> ident,
  Value<String> type,
  Value<String> name,
  Value<dynamic> latitudeDeg,
  Value<dynamic> longitudeDeg,
  Value<int> elevationFt,
  Value<String> state,
  Value<String> municipality,
});

class $$AirportsTableFilterComposer
    extends Composer<_$AppDatabase, $AirportsTable> {
  $$AirportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ident => $composableBuilder(
      column: $table.ident, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<dynamic, dynamic, double> get latitudeDeg =>
      $composableBuilder(
          column: $table.latitudeDeg,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<dynamic, dynamic, double> get longitudeDeg =>
      $composableBuilder(
          column: $table.longitudeDeg,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get elevationFt => $composableBuilder(
      column: $table.elevationFt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get municipality => $composableBuilder(
      column: $table.municipality, builder: (column) => ColumnFilters(column));
}

class $$AirportsTableOrderingComposer
    extends Composer<_$AppDatabase, $AirportsTable> {
  $$AirportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ident => $composableBuilder(
      column: $table.ident, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitudeDeg => $composableBuilder(
      column: $table.latitudeDeg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitudeDeg => $composableBuilder(
      column: $table.longitudeDeg,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get elevationFt => $composableBuilder(
      column: $table.elevationFt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get municipality => $composableBuilder(
      column: $table.municipality,
      builder: (column) => ColumnOrderings(column));
}

class $$AirportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AirportsTable> {
  $$AirportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ident =>
      $composableBuilder(column: $table.ident, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<dynamic, double> get latitudeDeg =>
      $composableBuilder(
          column: $table.latitudeDeg, builder: (column) => column);

  GeneratedColumnWithTypeConverter<dynamic, double> get longitudeDeg =>
      $composableBuilder(
          column: $table.longitudeDeg, builder: (column) => column);

  GeneratedColumn<int> get elevationFt => $composableBuilder(
      column: $table.elevationFt, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get municipality => $composableBuilder(
      column: $table.municipality, builder: (column) => column);
}

class $$AirportsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AirportsTable,
    Airport,
    $$AirportsTableFilterComposer,
    $$AirportsTableOrderingComposer,
    $$AirportsTableAnnotationComposer,
    $$AirportsTableCreateCompanionBuilder,
    $$AirportsTableUpdateCompanionBuilder,
    (Airport, BaseReferences<_$AppDatabase, $AirportsTable, Airport>),
    Airport,
    PrefetchHooks Function()> {
  $$AirportsTableTableManager(_$AppDatabase db, $AirportsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AirportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AirportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AirportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> ident = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<dynamic> latitudeDeg = const Value.absent(),
            Value<dynamic> longitudeDeg = const Value.absent(),
            Value<int> elevationFt = const Value.absent(),
            Value<String> state = const Value.absent(),
            Value<String> municipality = const Value.absent(),
          }) =>
              AirportsCompanion(
            id: id,
            ident: ident,
            type: type,
            name: name,
            latitudeDeg: latitudeDeg,
            longitudeDeg: longitudeDeg,
            elevationFt: elevationFt,
            state: state,
            municipality: municipality,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String ident,
            Value<String> type = const Value.absent(),
            Value<String> name = const Value.absent(),
            required dynamic latitudeDeg,
            required dynamic longitudeDeg,
            Value<int> elevationFt = const Value.absent(),
            Value<String> state = const Value.absent(),
            Value<String> municipality = const Value.absent(),
          }) =>
              AirportsCompanion.insert(
            id: id,
            ident: ident,
            type: type,
            name: name,
            latitudeDeg: latitudeDeg,
            longitudeDeg: longitudeDeg,
            elevationFt: elevationFt,
            state: state,
            municipality: municipality,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$AirportsTable, Airport>(table),
                    BaseReferences<_$AppDatabase, $AirportsTable, Airport>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AirportsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AirportsTable,
    Airport,
    $$AirportsTableFilterComposer,
    $$AirportsTableOrderingComposer,
    $$AirportsTableAnnotationComposer,
    $$AirportsTableCreateCompanionBuilder,
    $$AirportsTableUpdateCompanionBuilder,
    (Airport, BaseReferences<_$AppDatabase, $AirportsTable, Airport>),
    Airport,
    PrefetchHooks Function()>;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  required String taskName,
  Value<double> distance,
  required int taskOrder,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<String> taskName,
  Value<double> distance,
  Value<int> taskOrder,
});

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TaskTurnpointsTable, List<TaskTurnpoint>>
      _taskTurnpointsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.taskTurnpoints,
              aliasName: 'task__id__taskturnpoint__task_id');

  $$TaskTurnpointsTableProcessedTableManager get taskTurnpointsRefs {
    final manager = $$TaskTurnpointsTableTableManager($_db, $_db.taskTurnpoints)
        .filter((f) => f.taskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskTurnpointsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taskName => $composableBuilder(
      column: $table.taskName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distance => $composableBuilder(
      column: $table.distance, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get taskOrder => $composableBuilder(
      column: $table.taskOrder, builder: (column) => ColumnFilters(column));

  Expression<bool> taskTurnpointsRefs(
      Expression<bool> Function($$TaskTurnpointsTableFilterComposer f) f) {
    final $$TaskTurnpointsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.taskTurnpoints,
        getReferencedColumn: (t) => t.taskId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TaskTurnpointsTableFilterComposer(
              $db: $db,
              $table: $db.taskTurnpoints,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taskName => $composableBuilder(
      column: $table.taskName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distance => $composableBuilder(
      column: $table.distance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get taskOrder => $composableBuilder(
      column: $table.taskOrder, builder: (column) => ColumnOrderings(column));
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get taskName =>
      $composableBuilder(column: $table.taskName, builder: (column) => column);

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumn<int> get taskOrder =>
      $composableBuilder(column: $table.taskOrder, builder: (column) => column);

  Expression<T> taskTurnpointsRefs<T extends Object>(
      Expression<T> Function($$TaskTurnpointsTableAnnotationComposer a) f) {
    final $$TaskTurnpointsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.taskTurnpoints,
        getReferencedColumn: (t) => t.taskId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TaskTurnpointsTableAnnotationComposer(
              $db: $db,
              $table: $db.taskTurnpoints,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, $$TasksTableReferences),
    Task,
    PrefetchHooks Function({bool taskTurnpointsRefs})> {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> taskName = const Value.absent(),
            Value<double> distance = const Value.absent(),
            Value<int> taskOrder = const Value.absent(),
          }) =>
              TasksCompanion(
            id: id,
            taskName: taskName,
            distance: distance,
            taskOrder: taskOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String taskName,
            Value<double> distance = const Value.absent(),
            required int taskOrder,
          }) =>
              TasksCompanion.insert(
            id: id,
            taskName: taskName,
            distance: distance,
            taskOrder: taskOrder,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$TasksTable, Task>(table),
                    $$TasksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({taskTurnpointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (taskTurnpointsRefs) db.taskTurnpoints
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (taskTurnpointsRefs)
                    await $_getPrefetchedData<Task, $TasksTable, TaskTurnpoint>(
                        currentTable: table,
                        referencedTable:
                            $$TasksTableReferences._taskTurnpointsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TasksTableReferences(db, table, p0)
                                .taskTurnpointsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.taskId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, $$TasksTableReferences),
    Task,
    PrefetchHooks Function({bool taskTurnpointsRefs})>;
typedef $$TaskTurnpointsTableCreateCompanionBuilder = TaskTurnpointsCompanion
    Function({
  Value<int> id,
  required int taskId,
  required int taskOrder,
  required String title,
  required String code,
  required double latitudeDeg,
  required double longitudeDeg,
  required double distanceFromPriorTurnpoint,
  required double distanceFromStartingPoint,
  required bool lastTurnpoint,
});
typedef $$TaskTurnpointsTableUpdateCompanionBuilder = TaskTurnpointsCompanion
    Function({
  Value<int> id,
  Value<int> taskId,
  Value<int> taskOrder,
  Value<String> title,
  Value<String> code,
  Value<double> latitudeDeg,
  Value<double> longitudeDeg,
  Value<double> distanceFromPriorTurnpoint,
  Value<double> distanceFromStartingPoint,
  Value<bool> lastTurnpoint,
});

final class $$TaskTurnpointsTableReferences
    extends BaseReferences<_$AppDatabase, $TaskTurnpointsTable, TaskTurnpoint> {
  $$TaskTurnpointsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('taskturnpoint__task_id__task__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<int>('task_id')!;

    final manager = $$TasksTableTableManager($_db, $_db.tasks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TaskTurnpointsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskTurnpointsTable> {
  $$TaskTurnpointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get taskOrder => $composableBuilder(
      column: $table.taskOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitudeDeg => $composableBuilder(
      column: $table.latitudeDeg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitudeDeg => $composableBuilder(
      column: $table.longitudeDeg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceFromPriorTurnpoint => $composableBuilder(
      column: $table.distanceFromPriorTurnpoint,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceFromStartingPoint => $composableBuilder(
      column: $table.distanceFromStartingPoint,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get lastTurnpoint => $composableBuilder(
      column: $table.lastTurnpoint, builder: (column) => ColumnFilters(column));

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.taskId,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableFilterComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TaskTurnpointsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskTurnpointsTable> {
  $$TaskTurnpointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get taskOrder => $composableBuilder(
      column: $table.taskOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitudeDeg => $composableBuilder(
      column: $table.latitudeDeg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitudeDeg => $composableBuilder(
      column: $table.longitudeDeg,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceFromPriorTurnpoint => $composableBuilder(
      column: $table.distanceFromPriorTurnpoint,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceFromStartingPoint => $composableBuilder(
      column: $table.distanceFromStartingPoint,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get lastTurnpoint => $composableBuilder(
      column: $table.lastTurnpoint,
      builder: (column) => ColumnOrderings(column));

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.taskId,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableOrderingComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TaskTurnpointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskTurnpointsTable> {
  $$TaskTurnpointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get taskOrder =>
      $composableBuilder(column: $table.taskOrder, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<double> get latitudeDeg => $composableBuilder(
      column: $table.latitudeDeg, builder: (column) => column);

  GeneratedColumn<double> get longitudeDeg => $composableBuilder(
      column: $table.longitudeDeg, builder: (column) => column);

  GeneratedColumn<double> get distanceFromPriorTurnpoint => $composableBuilder(
      column: $table.distanceFromPriorTurnpoint, builder: (column) => column);

  GeneratedColumn<double> get distanceFromStartingPoint => $composableBuilder(
      column: $table.distanceFromStartingPoint, builder: (column) => column);

  GeneratedColumn<bool> get lastTurnpoint => $composableBuilder(
      column: $table.lastTurnpoint, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.taskId,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableAnnotationComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TaskTurnpointsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TaskTurnpointsTable,
    TaskTurnpoint,
    $$TaskTurnpointsTableFilterComposer,
    $$TaskTurnpointsTableOrderingComposer,
    $$TaskTurnpointsTableAnnotationComposer,
    $$TaskTurnpointsTableCreateCompanionBuilder,
    $$TaskTurnpointsTableUpdateCompanionBuilder,
    (TaskTurnpoint, $$TaskTurnpointsTableReferences),
    TaskTurnpoint,
    PrefetchHooks Function({bool taskId})> {
  $$TaskTurnpointsTableTableManager(
      _$AppDatabase db, $TaskTurnpointsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskTurnpointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskTurnpointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskTurnpointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> taskId = const Value.absent(),
            Value<int> taskOrder = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<double> latitudeDeg = const Value.absent(),
            Value<double> longitudeDeg = const Value.absent(),
            Value<double> distanceFromPriorTurnpoint = const Value.absent(),
            Value<double> distanceFromStartingPoint = const Value.absent(),
            Value<bool> lastTurnpoint = const Value.absent(),
          }) =>
              TaskTurnpointsCompanion(
            id: id,
            taskId: taskId,
            taskOrder: taskOrder,
            title: title,
            code: code,
            latitudeDeg: latitudeDeg,
            longitudeDeg: longitudeDeg,
            distanceFromPriorTurnpoint: distanceFromPriorTurnpoint,
            distanceFromStartingPoint: distanceFromStartingPoint,
            lastTurnpoint: lastTurnpoint,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int taskId,
            required int taskOrder,
            required String title,
            required String code,
            required double latitudeDeg,
            required double longitudeDeg,
            required double distanceFromPriorTurnpoint,
            required double distanceFromStartingPoint,
            required bool lastTurnpoint,
          }) =>
              TaskTurnpointsCompanion.insert(
            id: id,
            taskId: taskId,
            taskOrder: taskOrder,
            title: title,
            code: code,
            latitudeDeg: latitudeDeg,
            longitudeDeg: longitudeDeg,
            distanceFromPriorTurnpoint: distanceFromPriorTurnpoint,
            distanceFromStartingPoint: distanceFromStartingPoint,
            lastTurnpoint: lastTurnpoint,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$TaskTurnpointsTable, TaskTurnpoint>(table),
                    $$TaskTurnpointsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (taskId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.taskId,
                    referencedTable:
                        $$TaskTurnpointsTableReferences._taskIdTable(db),
                    referencedColumn:
                        $$TaskTurnpointsTableReferences._taskIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TaskTurnpointsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TaskTurnpointsTable,
    TaskTurnpoint,
    $$TaskTurnpointsTableFilterComposer,
    $$TaskTurnpointsTableOrderingComposer,
    $$TaskTurnpointsTableAnnotationComposer,
    $$TaskTurnpointsTableCreateCompanionBuilder,
    $$TaskTurnpointsTableUpdateCompanionBuilder,
    (TaskTurnpoint, $$TaskTurnpointsTableReferences),
    TaskTurnpoint,
    PrefetchHooks Function({bool taskId})>;
typedef $$TurnpointsTableCreateCompanionBuilder = TurnpointsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> code,
  Value<String> country,
  Value<double> latitudeDeg,
  Value<double> longitudeDeg,
  Value<String> elevation,
  Value<String> style,
  Value<String> direction,
  Value<String> length,
  Value<String> frequency,
  Value<String> description,
  Value<String> runwayWidth,
});
typedef $$TurnpointsTableUpdateCompanionBuilder = TurnpointsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> code,
  Value<String> country,
  Value<double> latitudeDeg,
  Value<double> longitudeDeg,
  Value<String> elevation,
  Value<String> style,
  Value<String> direction,
  Value<String> length,
  Value<String> frequency,
  Value<String> description,
  Value<String> runwayWidth,
});

class $$TurnpointsTableFilterComposer
    extends Composer<_$AppDatabase, $TurnpointsTable> {
  $$TurnpointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get country => $composableBuilder(
      column: $table.country, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitudeDeg => $composableBuilder(
      column: $table.latitudeDeg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitudeDeg => $composableBuilder(
      column: $table.longitudeDeg, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get elevation => $composableBuilder(
      column: $table.elevation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get style => $composableBuilder(
      column: $table.style, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get length => $composableBuilder(
      column: $table.length, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get runwayWidth => $composableBuilder(
      column: $table.runwayWidth, builder: (column) => ColumnFilters(column));
}

class $$TurnpointsTableOrderingComposer
    extends Composer<_$AppDatabase, $TurnpointsTable> {
  $$TurnpointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get country => $composableBuilder(
      column: $table.country, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitudeDeg => $composableBuilder(
      column: $table.latitudeDeg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitudeDeg => $composableBuilder(
      column: $table.longitudeDeg,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get elevation => $composableBuilder(
      column: $table.elevation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get style => $composableBuilder(
      column: $table.style, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get length => $composableBuilder(
      column: $table.length, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get runwayWidth => $composableBuilder(
      column: $table.runwayWidth, builder: (column) => ColumnOrderings(column));
}

class $$TurnpointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TurnpointsTable> {
  $$TurnpointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<double> get latitudeDeg => $composableBuilder(
      column: $table.latitudeDeg, builder: (column) => column);

  GeneratedColumn<double> get longitudeDeg => $composableBuilder(
      column: $table.longitudeDeg, builder: (column) => column);

  GeneratedColumn<String> get elevation =>
      $composableBuilder(column: $table.elevation, builder: (column) => column);

  GeneratedColumn<String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get length =>
      $composableBuilder(column: $table.length, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get runwayWidth => $composableBuilder(
      column: $table.runwayWidth, builder: (column) => column);
}

class $$TurnpointsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TurnpointsTable,
    Turnpoint,
    $$TurnpointsTableFilterComposer,
    $$TurnpointsTableOrderingComposer,
    $$TurnpointsTableAnnotationComposer,
    $$TurnpointsTableCreateCompanionBuilder,
    $$TurnpointsTableUpdateCompanionBuilder,
    (Turnpoint, BaseReferences<_$AppDatabase, $TurnpointsTable, Turnpoint>),
    Turnpoint,
    PrefetchHooks Function()> {
  $$TurnpointsTableTableManager(_$AppDatabase db, $TurnpointsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TurnpointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TurnpointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TurnpointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> country = const Value.absent(),
            Value<double> latitudeDeg = const Value.absent(),
            Value<double> longitudeDeg = const Value.absent(),
            Value<String> elevation = const Value.absent(),
            Value<String> style = const Value.absent(),
            Value<String> direction = const Value.absent(),
            Value<String> length = const Value.absent(),
            Value<String> frequency = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> runwayWidth = const Value.absent(),
          }) =>
              TurnpointsCompanion(
            id: id,
            title: title,
            code: code,
            country: country,
            latitudeDeg: latitudeDeg,
            longitudeDeg: longitudeDeg,
            elevation: elevation,
            style: style,
            direction: direction,
            length: length,
            frequency: frequency,
            description: description,
            runwayWidth: runwayWidth,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> country = const Value.absent(),
            Value<double> latitudeDeg = const Value.absent(),
            Value<double> longitudeDeg = const Value.absent(),
            Value<String> elevation = const Value.absent(),
            Value<String> style = const Value.absent(),
            Value<String> direction = const Value.absent(),
            Value<String> length = const Value.absent(),
            Value<String> frequency = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> runwayWidth = const Value.absent(),
          }) =>
              TurnpointsCompanion.insert(
            id: id,
            title: title,
            code: code,
            country: country,
            latitudeDeg: latitudeDeg,
            longitudeDeg: longitudeDeg,
            elevation: elevation,
            style: style,
            direction: direction,
            length: length,
            frequency: frequency,
            description: description,
            runwayWidth: runwayWidth,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$TurnpointsTable, Turnpoint>(table),
                    BaseReferences<_$AppDatabase, $TurnpointsTable, Turnpoint>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TurnpointsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TurnpointsTable,
    Turnpoint,
    $$TurnpointsTableFilterComposer,
    $$TurnpointsTableOrderingComposer,
    $$TurnpointsTableAnnotationComposer,
    $$TurnpointsTableCreateCompanionBuilder,
    $$TurnpointsTableUpdateCompanionBuilder,
    (Turnpoint, BaseReferences<_$AppDatabase, $TurnpointsTable, Turnpoint>),
    Turnpoint,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AirportsTableTableManager get airports =>
      $$AirportsTableTableManager(_db, _db.airports);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$TaskTurnpointsTableTableManager get taskTurnpoints =>
      $$TaskTurnpointsTableTableManager(_db, _db.taskTurnpoints);
  $$TurnpointsTableTableManager get turnpoints =>
      $$TurnpointsTableTableManager(_db, _db.turnpoints);
}
