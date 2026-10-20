import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'airport/airports.dart';
import 'airport/airports_dao.dart';
import 'converter/latlng_converter.dart';
import 'task/tasks.dart';
import 'task/tasks_dao.dart';
import 'taskturnpoint/task_turnpoints.dart';
import 'taskturnpoint/task_turnpoints_dao.dart';
import 'turnpoint/turnpoints.dart';
import 'turnpoint/turnpoints_dao.dart';

part 'app_database.g.dart';

//TODO if any changes run  - dart run build_runner build --delete-conflicting-outputs
@DriftDatabase(tables: [Airports, Tasks, TaskTurnpoints, Turnpoints],
    daos: [AirportsDao, TasksDao, TaskTurnpointsDao, TurnpointsDao])
class AppDatabase extends _$AppDatabase {
  // After generating code, this class needs to define a `schemaVersion` getter
  // and a constructor telling drift where the database should be stored.
  // These are described in the getting started guide: https://drift.simonbinder.eu/setup/
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  // Constructor to use an in-memory database for testing
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 2;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'app_database',
      native: const DriftNativeOptions(
        // By default, `driftDatabase` from `package:drift_flutter` stores the
        // database files in `getApplicationDocumentsDirectory()`.
        databaseDirectory: getApplicationSupportDirectory,
        shareAcrossIsolates: true,  // share database between workmanager and app
      ),
      // If you need web support, see https://drift.simonbinder.eu/platforms/web/
    );
  }


}
