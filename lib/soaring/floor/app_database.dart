// database.dart

import 'dart:async';

import 'package:floor/floor.dart';
import 'package:flutter_soaring_forecast/soaring/floor/airport.dart';
import 'package:flutter_soaring_forecast/soaring/floor/airport_dao.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task_dao.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task_turnpoint_dao.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'app_database.g.dart'; // the generated code will be there

//TODO if any changes run  -  flutter packages pub run build_runner build

@Database(version: 2, entities: [Airport, Task, TaskTurnpoint]) //
abstract class AppDatabase extends FloorDatabase {
  AirportDao get airportDao;
  TaskDao get taskDao;
  TaskTurnpointDao get taskTurnpointDao;
}
