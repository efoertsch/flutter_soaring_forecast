import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_event.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final Repository repository;
  Task currentTask = Task();
  List<TaskTurnpoint> taskTurnpoints = [];

//TaskState get initialState => TasksLoadingState();

  TaskBloc({required this.repository}) : super(TasksLoadingState()) {
    on<TaskListEvent>(_showAllTasks);

    on<LoadTaskTurnpointsEvent>(_showTaskTurnpoints);
    on<TurnpointsAddedToTaskEvent>(_addTurnpointsToTask);
  }

  void _showAllTasks(TaskListEvent event, Emitter<TaskState> emit) async {
    emit(TasksLoadingState());
    List<Task> tasks = [];
    try {
      tasks.addAll(await repository.getAlltasks());
      emit(TasksLoadedState(tasks));
    } catch (e) {
      emit(TaskErrorState(e.toString()));
    }
  }


  void _showTaskTurnpoints(
      LoadTaskTurnpointsEvent event, Emitter<TaskState> emit) async {
    emit(TasksTurnpointsLoadingState());
    taskTurnpoints.clear();
    try {
      currentTask = await repository.getTask(event.taskId);
      taskTurnpoints.addAll(await repository.getTaskTurnpoints(event.taskId));
      emit(TasksTurnpointsLoadedState(task: currentTask, taskTurnpoints: taskTurnpoints));
    } catch (e) {
      emit(TaskErrorState(e.toString()));
    }
  }

  FutureOr<void> _addTurnpointsToTask(
      TurnpointsAddedToTaskEvent event, Emitter<TaskState> emit) {
    final turnpoints = event.turnpoints;
    try {
      turnpoints.forEach((turnpoint) {
        _addTurnpointToTask(turnpoint);
      });
      if (taskTurnpoints.length > 0) {
        currentTask.distance = (taskTurnpoints.length > 0) ?
        taskTurnpoints.last.distanceFromStartingPoint : 0;
      }
      emit(TasksTurnpointsLoadedState(
          task: currentTask, taskTurnpoints: taskTurnpoints));
      emit(TaskUpdatedState());
    } catch (e) {
      emit(TaskErrorState(e.toString()));
    }
  }

  _addTurnpointToTask(Turnpoint turnpoint) {
    TaskTurnpoint priorTaskTurnpoint;
    final taskTurnpoint = TaskTurnpoint(taskId: currentTask.id,
        taskOrder: taskTurnpoints.length,
      title: turnpoint.title,
      code: turnpoint.code,
      latitudeDeg: turnpoint.latitudeDeg,
      longitudeDeg: turnpoint.longitudeDeg
    );
    if (taskTurnpoints.length != 0){
      priorTaskTurnpoint = taskTurnpoints[taskTurnpoints.length - 1];
      priorTaskTurnpoint.lastTurnpoint = false;
      double dist = calculateDistance(priorTaskTurnpoint.latitudeDeg,
          priorTaskTurnpoint.longitudeDeg,
          taskTurnpoint.latitudeDeg,
          taskTurnpoint.longitudeDeg);
      taskTurnpoint.distanceFromPriorTurnpoint = dist;
      taskTurnpoint.distanceFromStartingPoint = priorTaskTurnpoint.distanceFromStartingPoint
          + dist;
      taskTurnpoint.lastTurnpoint = true;
    }
      taskTurnpoints.add(taskTurnpoint);
  }

  double calculateDistance(lat1, lon1, lat2, lon2){
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
  }


}
