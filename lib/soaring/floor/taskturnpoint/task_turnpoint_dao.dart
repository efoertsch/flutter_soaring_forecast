import 'package:floor/floor.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';

import '../base_dao.dart';

//TODO if any changes run  -  flutter packages pub run build_runner build
@dao
abstract class TaskTurnpointDao extends BaseDao<TaskTurnpoint> {
  @Query(
      "Select * from taskturnpoint where taskId = :taskId order by taskOrder")
  Future<List<TaskTurnpoint>> getTaskTurnpoints(int taskId);

  @Query("Select max(taskOrder) from taskturnpoint where taskId = :taskId")
  Future<int?> getMaxTaskOrderForTask(int taskId);

  @Query("Delete from taskturnpoint where taskId = :taskId")
  Future<int?> deleteTaskTurnpoints(int taskId);

  @Query("Delete from taskturnpoint where id = :id ")
  Future<int?> deleteTaskTurnpoint(int id);

  @Query(
      "Delete from taskturnpoint where taskId = :taskId and taskOrder > :taskOrder ")
  Future<int?> deleteAnyTaskTurnpointsOver(int taskId, int taskOrder);
}
