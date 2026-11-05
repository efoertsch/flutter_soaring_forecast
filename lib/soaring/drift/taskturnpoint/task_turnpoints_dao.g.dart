// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_turnpoints_dao.dart';

// ignore_for_file: type=lint
mixin _$TaskTurnpointsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TasksTable get tasks => attachedDatabase.tasks;
  $TaskTurnpointsTable get taskTurnpoints => attachedDatabase.taskTurnpoints;
  TaskTurnpointsDaoManager get managers => TaskTurnpointsDaoManager(this);
}

class TaskTurnpointsDaoManager {
  final _$TaskTurnpointsDaoMixin _db;
  TaskTurnpointsDaoManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
  $$TaskTurnpointsTableTableManager get taskTurnpoints =>
      $$TaskTurnpointsTableTableManager(
        _db.attachedDatabase,
        _db.taskTurnpoints,
      );
}
