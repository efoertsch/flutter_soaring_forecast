import 'package:drift/drift.dart';
import '../app_database.dart';
import '../base_dao.dart';
import 'tasks.dart';

part 'tasks_dao.g.dart';

//TODO if any changes run  -  dart run build_runner build --delete-conflicting-outputs
@DriftAccessor(tables: [Tasks])
class TasksDao extends DatabaseAccessor<AppDatabase>
    with _$TasksDaoMixin, BaseDao<Tasks, Task, TasksCompanion> {
  TasksDao(AppDatabase db) : super(db);

  @override
  TableInfo<Tasks, Task> get table => tasks;

  @override
  GeneratedDatabase get db => attachedDatabase;

//  @Query("Select * from task order by taskOrder")
  Future<List<Task>> listAllTasks() async {
    return await (select(tasks)
      ..orderBy([(t) => OrderingTerm(expression: t.taskOrder)]))
        .get();
  }

//@Query("Select * from task where id = :taskId")
  Future<Task?> getTask(int taskId) async {
    return await (select(tasks)
      ..where((tbl) => tbl.id.equals(taskId)))
        .getSingleOrNull();
  }

//@Query("Delete from task where id = :taskId")
  Future<int?> deleteTask(int taskId) async {
    return await (delete(tasks)
      ..where((tbl) => tbl.id.equals(taskId))).go();
  }

// @Query("Select count(*) from task")
  Future<int> getNumberOfTasks() async {
    return await getCount();
  }
}
