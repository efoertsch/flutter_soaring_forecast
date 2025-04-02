
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:flutter_soaring_forecast/soaring/floor/airport/airport.dart';
import 'package:flutter_soaring_forecast/soaring/floor/airport/airport_dao.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task_dao.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint_dao.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoints_dao.dart';
import 'dart:async';
part 'app_database.g.dart'; // the generated code will be there

//TODO if any changes run  - flutter packages pub run build_runner build --delete-conflicting-outputs

@Database(version: 2, entities: [Airport, Task, TaskTurnpoint, Turnpoint]) //
abstract class AppDatabase extends FloorDatabase {
  AirportDao get airportDao;
  TaskDao get taskDao;
  TaskTurnpointDao get taskTurnpointDao;
  TurnpointDao get turnpointDao;
}
