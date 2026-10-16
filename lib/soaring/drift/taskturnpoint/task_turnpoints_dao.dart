import 'package:drift/drift.dart';

import '../app_database.dart';
import '../base_dao.dart';
import 'task_turnpoints.dart';

part 'task_turnpoints_dao.g.dart';

//TODO if any changes run  -  dart run build_runner build --delete-conflicting-outputs
@DriftAccessor(tables: [TaskTurnpoints])
class TaskTurnpointsDao extends DatabaseAccessor<AppDatabase>
    with _$TaskTurnpointsDaoMixin , BaseDao<TaskTurnpoints, TaskTurnpoint, TaskTurnpointsCompanion>{
  TaskTurnpointsDao(AppDatabase db) : super(db);

  @override
  TableInfo<TaskTurnpoints, TaskTurnpoint> get table => taskTurnpoints;

  @override
  GeneratedDatabase get db => attachedDatabase;

  // @Query("Select * from taskturnpoint where taskId = :taskId order by taskOrder")
  Future<List<TaskTurnpoint>> getTaskTurnpoints(int taskId) async {
    return await (select(taskTurnpoints)
      ..where((tbl) => tbl.taskId.equals(taskId))
      ..orderBy([(t) => OrderingTerm(expression: t.taskOrder)])).get();
  }

  //@Query("Select max(taskOrder) from taskturnpoint where taskId = :taskId")
  Future<int?> getMaxTaskOrderForTask(int taskId) async {
    final maxTaskOrder = taskTurnpoints.taskOrder.max();
    final query = (selectOnly(taskTurnpoints)
      ..addColumns([taskTurnpoints.taskOrder,
        taskTurnpoints.taskId])
      ..where(taskTurnpoints.taskId.equals(taskId)));
    final result = await query
        .map((row) => row.read(maxTaskOrder))
        .getSingleOrNull();
    return result;
  }
  // @Query("Delete from taskturnpoint where taskId = :taskId")
  Future<int?> deleteTaskTurnpoints(int taskId) async {
    return (delete(taskTurnpoints)..where((tbl) => tbl.taskId.equals(taskId)))
        .go();
  }

  //@Query("Delete from taskturnpoint where id = :id ")
  Future<int?> deleteTaskTurnpoint(int id) async {
    return (delete(taskTurnpoints)..where((tbl) => tbl.id.equals(id))).go();
  }
}

