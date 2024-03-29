import 'package:floor/floor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';

//TODO if any changes run  -  flutter packages pub run build_runner build
@Entity(tableName: 'taskturnpoint', foreignKeys: [
  ForeignKey(
    childColumns: ['taskId'],
    parentColumns: ['id'],
    entity: Task,
    onDelete: ForeignKeyAction.cascade,
  )
])
class TaskTurnpoint {
  @PrimaryKey(autoGenerate: true)
  late int? id;
  late int? taskId;

  // Order in which the turnpoint is in the task
  late int taskOrder;

  // Following 2 fields refer back to same fields as in Turnpoint
  // Doing this rather than turnpoint.id due to  OnConflictStrategy.REPLACE stategy
  // used for any turnpoint updates.
  late String title;
  late String code;

  // For convenience store lat/long so can recalc distances w/o having to get it from turnpoint table
  // Also in case turnpoints deleted still can plot task
  late double latitudeDeg;
  late double longitudeDeg;

  late double distanceFromPriorTurnpoint;
  late double distanceFromStartingPoint;

  // used for taskTurnpoint display
  late bool lastTurnpoint;

  // Option color for turnpoint icon - green grass, black asphalt, red everything else
  @ignore
  Color turnpointColor = Colors.red;

  TaskTurnpoint(
      {this.id,
      this.taskId,
      this.taskOrder = 0,
      this.title = "",
      this.code = "",
      this.latitudeDeg = 0,
      this.longitudeDeg = 0,
      this.distanceFromPriorTurnpoint = 0.0,
      this.distanceFromStartingPoint = 0.0,
      this.lastTurnpoint = false});

  Map toJson() => {
        'id': id,
        "taskId": taskId,
        "taskOrder": taskOrder,
        "title": title,
        "code": code,
        "latitudeDeg": latitudeDeg,
        "longitudeDeg": longitudeDeg,
        "distanceFromPriorTurnpoint": distanceFromPriorTurnpoint,
        "distanceFromStartingPoint": distanceFromStartingPoint,
        "lastTurnpoint": lastTurnpoint
      };
}
