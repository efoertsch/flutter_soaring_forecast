import 'package:drift/drift.dart';
import '../task/tasks.dart';

//TODO if any changes run  -  dart run build_runner build --delete-conflicting-outputs
@DataClassName('TaskTurnpoint')
class TaskTurnpoints extends Table {
  late final id = integer().autoIncrement()();
  late final taskId = integer().references(Tasks, #id,onDelete: KeyAction.cascade,)();
  // Order in which the turnpoint is in the task
  late final taskOrder = integer()();
  // Following 2 fields refer back to same fields as in Turnpoint
  // Doing this rather than turnpoint.id due to  OnConflictStrategy.REPLACE stategy
  // used for any turnpoint updates.
  late final title = text()();
  late final code = text()();
  // For convenience store lat/long so can recalc distances w/o having to get it from turnpoint table
  // Also in case turnpoints deleted still can plot task
  late final latitudeDeg = real()();
  late final longitudeDeg = real()();
  late final distanceFromPriorTurnpoint = real()();
  late final distanceFromStartingPoint = real()();
  // used for taskTurnpoint display
  late final  lastTurnpoint  = boolean()();

  String get tableName => 'taskturnpoint';


  // // Option color for turnpoint icon - green grass, black asphalt, red everything else
  // TODO @ignore.  --
  // Color turnpointColor = Colors.red;
  //
  // TODO @ignore
  // bool isAirport = false;
}
