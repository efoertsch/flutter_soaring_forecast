import 'package:drift/drift.dart';

//TODO if any changes run  -  dart run build_runner build --delete-conflicting-outputs
@DataClassName('Task')
class Tasks extends Table {
  late final id = integer().autoIncrement()();
  late final  taskName = text()();
  late final  distance = real().withDefault(const Constant(0.0))(); //In Kilometers
  late final  taskOrder = integer()();

  String get tableName => 'task';
} 