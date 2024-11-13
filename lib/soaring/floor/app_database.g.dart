// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  AirportDao? _airportDaoInstance;

  TaskDao? _taskDaoInstance;

  TaskTurnpointDao? _taskTurnpointDaoInstance;

  TurnpointDao? _turnpointDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 2,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `airport` (`ident` TEXT NOT NULL, `type` TEXT NOT NULL, `name` TEXT NOT NULL, `latitudeDeg` REAL NOT NULL, `longitudeDeg` REAL NOT NULL, `elevationFt` INTEGER NOT NULL, `state` TEXT NOT NULL, `municipality` TEXT NOT NULL, PRIMARY KEY (`ident`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `task` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `taskName` TEXT NOT NULL, `distance` REAL NOT NULL, `taskOrder` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `taskturnpoint` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `taskId` INTEGER, `taskOrder` INTEGER NOT NULL, `title` TEXT NOT NULL, `code` TEXT NOT NULL, `latitudeDeg` REAL NOT NULL, `longitudeDeg` REAL NOT NULL, `distanceFromPriorTurnpoint` REAL NOT NULL, `distanceFromStartingPoint` REAL NOT NULL, `lastTurnpoint` INTEGER NOT NULL, FOREIGN KEY (`taskId`) REFERENCES `task` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `turnpoint` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `title` TEXT NOT NULL, `code` TEXT NOT NULL, `country` TEXT NOT NULL, `latitudeDeg` REAL NOT NULL, `longitudeDeg` REAL NOT NULL, `elevation` TEXT NOT NULL, `style` TEXT NOT NULL, `direction` TEXT NOT NULL, `length` TEXT NOT NULL, `frequency` TEXT NOT NULL, `description` TEXT NOT NULL, `runwayWidth` TEXT NOT NULL)');
        await database
            .execute('CREATE INDEX `index_airport_name` ON `airport` (`name`)');
        await database.execute(
            'CREATE INDEX `index_airport_state_name` ON `airport` (`state`, `name`)');
        await database.execute(
            'CREATE INDEX `index_airport_municipality` ON `airport` (`municipality`)');
        await database.execute(
            'CREATE INDEX `index_turnpoint_code` ON `turnpoint` (`code`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_turnpoint_title_code` ON `turnpoint` (`title`, `code`)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  AirportDao get airportDao {
    return _airportDaoInstance ??= _$AirportDao(database, changeListener);
  }

  @override
  TaskDao get taskDao {
    return _taskDaoInstance ??= _$TaskDao(database, changeListener);
  }

  @override
  TaskTurnpointDao get taskTurnpointDao {
    return _taskTurnpointDaoInstance ??=
        _$TaskTurnpointDao(database, changeListener);
  }

  @override
  TurnpointDao get turnpointDao {
    return _turnpointDaoInstance ??= _$TurnpointDao(database, changeListener);
  }
}

class _$AirportDao extends AirportDao {
  _$AirportDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _airportInsertionAdapter = InsertionAdapter(
            database,
            'airport',
            (Airport item) => <String, Object?>{
                  'ident': item.ident,
                  'type': item.type,
                  'name': item.name,
                  'latitudeDeg': item.latitudeDeg,
                  'longitudeDeg': item.longitudeDeg,
                  'elevationFt': item.elevationFt,
                  'state': item.state,
                  'municipality': item.municipality
                }),
        _airportUpdateAdapter = UpdateAdapter(
            database,
            'airport',
            ['ident'],
            (Airport item) => <String, Object?>{
                  'ident': item.ident,
                  'type': item.type,
                  'name': item.name,
                  'latitudeDeg': item.latitudeDeg,
                  'longitudeDeg': item.longitudeDeg,
                  'elevationFt': item.elevationFt,
                  'state': item.state,
                  'municipality': item.municipality
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Airport> _airportInsertionAdapter;

  final UpdateAdapter<Airport> _airportUpdateAdapter;

  @override
  Future<List<Airport>?> findAirports(String searchTerm) async {
    return _queryAdapter.queryList(
        'SELECT * FROM airport WHERE ident like ?1 or name like ?1  or municipality like ?1  collate nocase',
        mapper: (Map<String, Object?> row) => Airport(ident: row['ident'] as String, type: row['type'] as String, name: row['name'] as String, latitudeDeg: row['latitudeDeg'] as double, longitudeDeg: row['longitudeDeg'] as double, elevationFt: row['elevationFt'] as int, state: row['state'] as String, municipality: row['municipality'] as String),
        arguments: [searchTerm]);
  }

  @override
  Future<Airport?> getAirportByIdent(String ident) async {
    return _queryAdapter.query(
        'SELECT * FROM airport WHERE ident = ?1  collate nocase',
        mapper: (Map<String, Object?> row) => Airport(
            ident: row['ident'] as String,
            type: row['type'] as String,
            name: row['name'] as String,
            latitudeDeg: row['latitudeDeg'] as double,
            longitudeDeg: row['longitudeDeg'] as double,
            elevationFt: row['elevationFt'] as int,
            state: row['state'] as String,
            municipality: row['municipality'] as String),
        arguments: [ident]);
  }

  @override
  Future<List<Airport>?> listAllAirports() async {
    return _queryAdapter.queryList('Select * from airport order by state, name',
        mapper: (Map<String, Object?> row) => Airport(
            ident: row['ident'] as String,
            type: row['type'] as String,
            name: row['name'] as String,
            latitudeDeg: row['latitudeDeg'] as double,
            longitudeDeg: row['longitudeDeg'] as double,
            elevationFt: row['elevationFt'] as int,
            state: row['state'] as String,
            municipality: row['municipality'] as String));
  }

  @override
  Future<List<Airport>?> selectIcaoIdAirports(List<String> iacoAirports) async {
    const offset = 1;
    final _sqliteVariablesForIacoAirports =
        Iterable<String>.generate(iacoAirports.length, (i) => '?${i + offset}')
            .join(',');
    return _queryAdapter.queryList(
        'Select * from airport where ident in (' +
            _sqliteVariablesForIacoAirports +
            ')',
        mapper: (Map<String, Object?> row) => Airport(
            ident: row['ident'] as String,
            type: row['type'] as String,
            name: row['name'] as String,
            latitudeDeg: row['latitudeDeg'] as double,
            longitudeDeg: row['longitudeDeg'] as double,
            elevationFt: row['elevationFt'] as int,
            state: row['state'] as String,
            municipality: row['municipality'] as String),
        arguments: [...iacoAirports]);
  }

  @override
  Future<int?> deleteAll() async {
    return _queryAdapter.query('Delete from airport',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<int> insert(Airport obj) {
    return _airportInsertionAdapter.insertAndReturnId(
        obj, OnConflictStrategy.replace);
  }

  @override
  Future<List<int>> insertAll(List<Airport> obj) {
    return _airportInsertionAdapter.insertListAndReturnIds(
        obj, OnConflictStrategy.replace);
  }

  @override
  Future<int> update(Airport obj) {
    return _airportUpdateAdapter.updateAndReturnChangedRows(
        obj, OnConflictStrategy.abort);
  }
}

class _$TaskDao extends TaskDao {
  _$TaskDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _taskInsertionAdapter = InsertionAdapter(
            database,
            'task',
            (Task item) => <String, Object?>{
                  'id': item.id,
                  'taskName': item.taskName,
                  'distance': item.distance,
                  'taskOrder': item.taskOrder
                }),
        _taskUpdateAdapter = UpdateAdapter(
            database,
            'task',
            ['id'],
            (Task item) => <String, Object?>{
                  'id': item.id,
                  'taskName': item.taskName,
                  'distance': item.distance,
                  'taskOrder': item.taskOrder
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Task> _taskInsertionAdapter;

  final UpdateAdapter<Task> _taskUpdateAdapter;

  @override
  Future<List<Task>> listAllTasks() async {
    return _queryAdapter.queryList('Select * from task order by taskOrder',
        mapper: (Map<String, Object?> row) => Task(
            id: row['id'] as int?,
            taskName: row['taskName'] as String,
            distance: row['distance'] as double,
            taskOrder: row['taskOrder'] as int));
  }

  @override
  Future<Task?> getTask(int taskId) async {
    return _queryAdapter.query('Select * from task where id = ?1',
        mapper: (Map<String, Object?> row) => Task(
            id: row['id'] as int?,
            taskName: row['taskName'] as String,
            distance: row['distance'] as double,
            taskOrder: row['taskOrder'] as int),
        arguments: [taskId]);
  }

  @override
  Future<int?> deleteTask(int taskId) async {
    return _queryAdapter.query('Delete from task where id = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [taskId]);
  }

  @override
  Future<int> insert(Task obj) {
    return _taskInsertionAdapter.insertAndReturnId(
        obj, OnConflictStrategy.replace);
  }

  @override
  Future<List<int>> insertAll(List<Task> obj) {
    return _taskInsertionAdapter.insertListAndReturnIds(
        obj, OnConflictStrategy.replace);
  }

  @override
  Future<int> update(Task obj) {
    return _taskUpdateAdapter.updateAndReturnChangedRows(
        obj, OnConflictStrategy.abort);
  }
}

class _$TaskTurnpointDao extends TaskTurnpointDao {
  _$TaskTurnpointDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _taskTurnpointInsertionAdapter = InsertionAdapter(
            database,
            'taskturnpoint',
            (TaskTurnpoint item) => <String, Object?>{
                  'id': item.id,
                  'taskId': item.taskId,
                  'taskOrder': item.taskOrder,
                  'title': item.title,
                  'code': item.code,
                  'latitudeDeg': item.latitudeDeg,
                  'longitudeDeg': item.longitudeDeg,
                  'distanceFromPriorTurnpoint': item.distanceFromPriorTurnpoint,
                  'distanceFromStartingPoint': item.distanceFromStartingPoint,
                  'lastTurnpoint': item.lastTurnpoint ? 1 : 0
                }),
        _taskTurnpointUpdateAdapter = UpdateAdapter(
            database,
            'taskturnpoint',
            ['id'],
            (TaskTurnpoint item) => <String, Object?>{
                  'id': item.id,
                  'taskId': item.taskId,
                  'taskOrder': item.taskOrder,
                  'title': item.title,
                  'code': item.code,
                  'latitudeDeg': item.latitudeDeg,
                  'longitudeDeg': item.longitudeDeg,
                  'distanceFromPriorTurnpoint': item.distanceFromPriorTurnpoint,
                  'distanceFromStartingPoint': item.distanceFromStartingPoint,
                  'lastTurnpoint': item.lastTurnpoint ? 1 : 0
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<TaskTurnpoint> _taskTurnpointInsertionAdapter;

  final UpdateAdapter<TaskTurnpoint> _taskTurnpointUpdateAdapter;

  @override
  Future<List<TaskTurnpoint>> getTaskTurnpoints(int taskId) async {
    return _queryAdapter.queryList(
        'Select * from taskturnpoint where taskId = ?1 order by taskOrder',
        mapper: (Map<String, Object?> row) => TaskTurnpoint(
            id: row['id'] as int?,
            taskId: row['taskId'] as int?,
            taskOrder: row['taskOrder'] as int,
            title: row['title'] as String,
            code: row['code'] as String,
            latitudeDeg: row['latitudeDeg'] as double,
            longitudeDeg: row['longitudeDeg'] as double,
            distanceFromPriorTurnpoint:
                row['distanceFromPriorTurnpoint'] as double,
            distanceFromStartingPoint:
                row['distanceFromStartingPoint'] as double,
            lastTurnpoint: (row['lastTurnpoint'] as int) != 0),
        arguments: [taskId]);
  }

  @override
  Future<int?> getMaxTaskOrderForTask(int taskId) async {
    return _queryAdapter.query(
        'Select max(taskOrder) from taskturnpoint where taskId = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [taskId]);
  }

  @override
  Future<int?> deleteTaskTurnpoints(int taskId) async {
    return _queryAdapter.query('Delete from taskturnpoint where taskId = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [taskId]);
  }

  @override
  Future<int?> deleteTaskTurnpoint(int id) async {
    return _queryAdapter.query('Delete from taskturnpoint where id = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [id]);
  }

  @override
  Future<int> insert(TaskTurnpoint obj) {
    return _taskTurnpointInsertionAdapter.insertAndReturnId(
        obj, OnConflictStrategy.replace);
  }

  @override
  Future<List<int>> insertAll(List<TaskTurnpoint> obj) {
    return _taskTurnpointInsertionAdapter.insertListAndReturnIds(
        obj, OnConflictStrategy.replace);
  }

  @override
  Future<int> update(TaskTurnpoint obj) {
    return _taskTurnpointUpdateAdapter.updateAndReturnChangedRows(
        obj, OnConflictStrategy.abort);
  }
}

class _$TurnpointDao extends TurnpointDao {
  _$TurnpointDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _turnpointInsertionAdapter = InsertionAdapter(
            database,
            'turnpoint',
            (Turnpoint item) => <String, Object?>{
                  'id': item.id,
                  'title': item.title,
                  'code': item.code,
                  'country': item.country,
                  'latitudeDeg': item.latitudeDeg,
                  'longitudeDeg': item.longitudeDeg,
                  'elevation': item.elevation,
                  'style': item.style,
                  'direction': item.direction,
                  'length': item.length,
                  'frequency': item.frequency,
                  'description': item.description,
                  'runwayWidth': item.runwayWidth
                }),
        _turnpointUpdateAdapter = UpdateAdapter(
            database,
            'turnpoint',
            ['id'],
            (Turnpoint item) => <String, Object?>{
                  'id': item.id,
                  'title': item.title,
                  'code': item.code,
                  'country': item.country,
                  'latitudeDeg': item.latitudeDeg,
                  'longitudeDeg': item.longitudeDeg,
                  'elevation': item.elevation,
                  'style': item.style,
                  'direction': item.direction,
                  'length': item.length,
                  'frequency': item.frequency,
                  'description': item.description,
                  'runwayWidth': item.runwayWidth
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Turnpoint> _turnpointInsertionAdapter;

  final UpdateAdapter<Turnpoint> _turnpointUpdateAdapter;

  @override
  Future<List<Turnpoint>> listAllTurnpoints() async {
    return _queryAdapter.queryList('Select * from turnpoint order by title',
        mapper: (Map<String, Object?> row) => Turnpoint(
            id: row['id'] as int?,
            title: row['title'] as String,
            code: row['code'] as String,
            country: row['country'] as String,
            latitudeDeg: row['latitudeDeg'] as double,
            longitudeDeg: row['longitudeDeg'] as double,
            elevation: row['elevation'] as String,
            style: row['style'] as String,
            direction: row['direction'] as String,
            length: row['length'] as String,
            frequency: row['frequency'] as String,
            description: row['description'] as String,
            runwayWidth: row['runwayWidth'] as String));
  }

  @override
  Future<int?> deleteAllTurnpoints() async {
    return _queryAdapter.query('Delete from turnpoint',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<int?> deleteTurnpoint(int id) async {
    return _queryAdapter.query('Delete from turnpoint where id = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [id]);
  }

  @override
  Future<List<Turnpoint>> findTurnpoints(String searchTerm) async {
    return _queryAdapter.queryList(
        'Select * from turnpoint where title like ?1 or code like ?1  order by title, code collate nocase',
        mapper: (Map<String, Object?> row) => Turnpoint(id: row['id'] as int?, title: row['title'] as String, code: row['code'] as String, country: row['country'] as String, latitudeDeg: row['latitudeDeg'] as double, longitudeDeg: row['longitudeDeg'] as double, elevation: row['elevation'] as String, style: row['style'] as String, direction: row['direction'] as String, length: row['length'] as String, frequency: row['frequency'] as String, description: row['description'] as String, runwayWidth: row['runwayWidth'] as String),
        arguments: [searchTerm]);
  }

  @override
  Future<List<Turnpoint>> selectAllTurnpointsForDownload() async {
    return _queryAdapter.queryList('Select * from turnpoint  order by id',
        mapper: (Map<String, Object?> row) => Turnpoint(
            id: row['id'] as int?,
            title: row['title'] as String,
            code: row['code'] as String,
            country: row['country'] as String,
            latitudeDeg: row['latitudeDeg'] as double,
            longitudeDeg: row['longitudeDeg'] as double,
            elevation: row['elevation'] as String,
            style: row['style'] as String,
            direction: row['direction'] as String,
            length: row['length'] as String,
            frequency: row['frequency'] as String,
            description: row['description'] as String,
            runwayWidth: row['runwayWidth'] as String));
  }

  @override
  Future<Turnpoint?> getTurnpointByCode(String code) async {
    return _queryAdapter.query(
        'Select * from turnpoint where code = ?1 collate nocase',
        mapper: (Map<String, Object?> row) => Turnpoint(
            id: row['id'] as int?,
            title: row['title'] as String,
            code: row['code'] as String,
            country: row['country'] as String,
            latitudeDeg: row['latitudeDeg'] as double,
            longitudeDeg: row['longitudeDeg'] as double,
            elevation: row['elevation'] as String,
            style: row['style'] as String,
            direction: row['direction'] as String,
            length: row['length'] as String,
            frequency: row['frequency'] as String,
            description: row['description'] as String,
            runwayWidth: row['runwayWidth'] as String),
        arguments: [code]);
  }

  @override
  Future<Turnpoint?> getTurnpoint(
    String title,
    String code,
  ) async {
    return _queryAdapter.query(
        'Select * from turnpoint where title = ?1 and code = ?2 collate nocase',
        mapper: (Map<String, Object?> row) => Turnpoint(
            id: row['id'] as int?,
            title: row['title'] as String,
            code: row['code'] as String,
            country: row['country'] as String,
            latitudeDeg: row['latitudeDeg'] as double,
            longitudeDeg: row['longitudeDeg'] as double,
            elevation: row['elevation'] as String,
            style: row['style'] as String,
            direction: row['direction'] as String,
            length: row['length'] as String,
            frequency: row['frequency'] as String,
            description: row['description'] as String,
            runwayWidth: row['runwayWidth'] as String),
        arguments: [title, code]);
  }

  @override
  Future<Turnpoint?> getTurnpointById(int id) async {
    return _queryAdapter.query('Select * from turnpoint where id = ?1',
        mapper: (Map<String, Object?> row) => Turnpoint(
            id: row['id'] as int?,
            title: row['title'] as String,
            code: row['code'] as String,
            country: row['country'] as String,
            latitudeDeg: row['latitudeDeg'] as double,
            longitudeDeg: row['longitudeDeg'] as double,
            elevation: row['elevation'] as String,
            style: row['style'] as String,
            direction: row['direction'] as String,
            length: row['length'] as String,
            frequency: row['frequency'] as String,
            description: row['description'] as String,
            runwayWidth: row['runwayWidth'] as String),
        arguments: [id]);
  }

  @override
  Future<Turnpoint?> checkForAtLeastOneTurnpoint() async {
    return _queryAdapter.query(
        'Select * from turnpoint  ORDER BY id ASC LIMIT 1',
        mapper: (Map<String, Object?> row) => Turnpoint(
            id: row['id'] as int?,
            title: row['title'] as String,
            code: row['code'] as String,
            country: row['country'] as String,
            latitudeDeg: row['latitudeDeg'] as double,
            longitudeDeg: row['longitudeDeg'] as double,
            elevation: row['elevation'] as String,
            style: row['style'] as String,
            direction: row['direction'] as String,
            length: row['length'] as String,
            frequency: row['frequency'] as String,
            description: row['description'] as String,
            runwayWidth: row['runwayWidth'] as String));
  }

  @override
  Future<List<Turnpoint>> getTurnpointsWithinBounds(
    double swLatitudeDeg,
    double swLongitudeDeg,
    double neLatitudeDeg,
    double neLongitudeDeg,
  ) async {
    return _queryAdapter.queryList(
        'Select * from turnpoint where latitudeDeg between ?1 and ?3  and longitudeDeg between ?2 and ?4',
        mapper: (Map<String, Object?> row) => Turnpoint(id: row['id'] as int?, title: row['title'] as String, code: row['code'] as String, country: row['country'] as String, latitudeDeg: row['latitudeDeg'] as double, longitudeDeg: row['longitudeDeg'] as double, elevation: row['elevation'] as String, style: row['style'] as String, direction: row['direction'] as String, length: row['length'] as String, frequency: row['frequency'] as String, description: row['description'] as String, runwayWidth: row['runwayWidth'] as String),
        arguments: [
          swLatitudeDeg,
          swLongitudeDeg,
          neLatitudeDeg,
          neLongitudeDeg
        ]);
  }

  @override
  Future<List<Turnpoint>> getLandableTurnpointsWithinBounds(
    double swLatitudeDeg,
    double swLongitudeDeg,
    double neLatitudeDeg,
    double neLongitudeDeg,
  ) async {
    return _queryAdapter.queryList(
        'Select * from turnpoint where latitudeDeg between ?1 and ?3  and longitudeDeg between ?2 and ?4 and style between \'2\' and \'5\'',
        mapper: (Map<String, Object?> row) => Turnpoint(id: row['id'] as int?, title: row['title'] as String, code: row['code'] as String, country: row['country'] as String, latitudeDeg: row['latitudeDeg'] as double, longitudeDeg: row['longitudeDeg'] as double, elevation: row['elevation'] as String, style: row['style'] as String, direction: row['direction'] as String, length: row['length'] as String, frequency: row['frequency'] as String, description: row['description'] as String, runwayWidth: row['runwayWidth'] as String),
        arguments: [
          swLatitudeDeg,
          swLongitudeDeg,
          neLatitudeDeg,
          neLongitudeDeg
        ]);
  }

  @override
  Future<int> insert(Turnpoint obj) {
    return _turnpointInsertionAdapter.insertAndReturnId(
        obj, OnConflictStrategy.replace);
  }

  @override
  Future<List<int>> insertAll(List<Turnpoint> obj) {
    return _turnpointInsertionAdapter.insertListAndReturnIds(
        obj, OnConflictStrategy.replace);
  }

  @override
  Future<int> update(Turnpoint obj) {
    return _turnpointUpdateAdapter.updateAndReturnChangedRows(
        obj, OnConflictStrategy.abort);
  }
}
