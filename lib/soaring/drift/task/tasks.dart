import 'package:drift/drift.dart';
import '../app_database.dart';

//TODO if any changes run  -  dart run build_runner build --delete-conflicting-outputs

@UseRowClass(Task)
class Tasks extends Table {
  late final id = integer().autoIncrement()();
  late final taskName = text().withDefault(const Constant(''))();
  late final distance =
      real().withDefault(const Constant(0.0))(); //In Kilometers
  late final taskOrder = integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'task';
}

class Task {
  int? id;
  String taskName;
  double distance; //In Kilometers
  int taskOrder;

  Task({
    required this.id,
    this.taskName = "",
    this.distance = 0.0,
    this.taskOrder = 0,
  });

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id!),
      taskName: Value(taskName),
      distance: Value(distance),
      taskOrder: Value(taskOrder),
    );
  }

  TasksCompanion copyToCompanion({bool nullToAbsent = false}) {
    return toCompanion(nullToAbsent);
  }
}
