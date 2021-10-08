import 'package:floor/floor.dart';
import 'package:flutter_soaring_forecast/soaring/floor/base_dao.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task.dart';

//TODO if any changes run  -  flutter packages pub run build_runner build

@dao
abstract class TaskDao extends BaseDao<Task> {
  @Query("Select * from task order by taskOrder")
  Future<List<Task?>> listAllTasks();

  @Query("Select * from task where id = :taskId")
  Future<Task?> getTask(int taskId);

  @Query("Delete from task where id = :taskId")
  Future<int?> deleteTask(int taskId);
}