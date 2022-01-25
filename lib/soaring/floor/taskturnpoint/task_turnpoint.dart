import 'package:floor/floor.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';

//TODO if any changes run  -  flutter packages pub run build_runner build
@Entity(tableName: 'taskturnpoint', foreignKeys: [
  ForeignKey(
    childColumns: ['taskId'],
    parentColumns: ['id'],
    entity: Task,
  )
])
class TaskTurnpoint {
  @PrimaryKey(autoGenerate: true)
  int id = -1;
  int taskId;

  // Order in which the turnpoint is in the task
  int taskOrder = 0;

  // Following 2 fields refer back to same fields as in Turnpoint
  // Doing this rather than turnpoint.id due to  OnConflictStrategy.REPLACE stategy
  // used for any turnpoint updates.
  String title = "";

  String code = "";

  // For convenience store lat/long so can recalc distances w/o having to get it from turnpoint table
  // Also in case turnpoints deleted still can plot task
  double latitudeDeg;

  double longitudeDeg;

  double distanceFromPriorTurnpoint = 0.0;

  double distanceFromStartingPoint = 0.0;
  // used for taskTurnpoint display
  bool lastTurnpoint = false;

  TaskTurnpoint(
      {required this.taskId,
      required this.title,
      required this.code,
      required this.latitudeDeg,
      required this.longitudeDeg});
}
