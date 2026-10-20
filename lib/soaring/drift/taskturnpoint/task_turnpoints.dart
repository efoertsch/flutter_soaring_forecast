import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show Colors, Color;
import '../app_database.dart';
import '../task/tasks.dart';


//TODO if any changes run  -  dart run build_runner build --delete-conflicting-outputs

@UseRowClass(TaskTurnpoint)
class TaskTurnpoints extends Table {
  late final id = integer().autoIncrement()();
  late final taskId = integer().references(
        Tasks,
        #id,
        onDelete: KeyAction.cascade,
      )();

  // Order in which the turnpoint is in the task
  late final taskOrder = integer().withDefault(const Constant(0))();

  // Following 2 fields refer back to same fields as in Turnpoint
  // Doing this rather than turnpoint.id due to  OnConflictStrategy.REPLACE stategy
  // used for any turnpoint updates.
  late final title = text().withDefault(const Constant(''))();
  late final code = text().withDefault(const Constant(''))();

  // For convenience store lat/long so can recalc distances w/o having to get it from turnpoint table
  // Also in case turnpoints deleted still can plot task
  late final latitudeDeg = real().withDefault(const Constant(0.0))();
  late final longitudeDeg = real().withDefault(const Constant(0.0))();
  late final distanceFromPriorTurnpoint =
      real().withDefault(const Constant(0.0))();
  late final distanceFromStartingPoint =
      real().withDefault(const Constant(0.0))();

  // used for taskTurnpoint display
  late final lastTurnpoint = boolean().withDefault(const Constant(false))();

  @override
  String get tableName => 'taskturnpoint';
}

class TaskTurnpoint {
  int id;
  int taskId;
  int taskOrder;
  String title;
  String code;

// For convenience store lat/long so can recalc distances w/o having to get it from turnpoint table
// Also in case turnpoints deleted still can plot task
  double latitudeDeg;
  double longitudeDeg;
  double distanceFromPriorTurnpoint;
  double distanceFromStartingPoint;

// used for taskTurnpoint display
  bool lastTurnpoint;

// Following are fields not in database
// Option color for turnpoint icon - green grass, black asphalt, red everything else
  Color turnpointColor = Colors.red;
  bool isAirport = false;

  TaskTurnpoint(
      {this.id = -1,
      this.taskId = -1 ,
      this.taskOrder = 0,
      this.title = "",
      this.code = "",
      this.latitudeDeg = 0,
      this.longitudeDeg = 0,
      this.distanceFromPriorTurnpoint = 0.0,
      this.distanceFromStartingPoint = 0.0,
      this.lastTurnpoint = false});

  TaskTurnpointsCompanion toCompanion(bool nullToAbsent) {
    return TaskTurnpointsCompanion(
      id: id == -1 && nullToAbsent ? const Value.absent() : Value(id),
      taskId: taskId == -1 && nullToAbsent ? const Value.absent() : Value(taskId),
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

  TaskTurnpointsCompanion copyToCompanion({bool nullToAbsent = true}) {
    return toCompanion(nullToAbsent);
  }
}
