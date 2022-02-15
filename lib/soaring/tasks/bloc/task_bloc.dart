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
    on<TaskNamedChangedEvent>(_updateTaskName);
    on<LoadTaskTurnpointsEvent>(_showTaskTurnpoints);
    on<TurnpointsAddedToTaskEvent>(_addTurnpointsToTask);
    on<SaveTaskTurnpointsEvent>(_saveTask);
    on<DisplayTaskTurnpointEvent>(_displayTaskTurnpoint);
  }

  void _displayTaskTurnpoint(
      DisplayTaskTurnpointEvent event, Emitter<TaskState> emit) async {
    // emit(TasksLoadingState()); // if used need to resend event to redisplay task
    Turnpoint? turnpoint = await repository.getTurnpoint(
        event.taskTurnpoint.title, event.taskTurnpoint.code);
    if (turnpoint != null) {
      emit(TurnpointFoundState(turnpoint));
    } else {
      emit(TaskErrorState("Oops. Turnpoint not found based on TaskTurnpoint"));
    }
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
    taskTurnpoints.clear();
    emit(TasksTurnpointsLoadingState());
    if (event.taskId == 0) {
      currentTask = Task();
    } else {
      try {
        currentTask = await repository.getTask(event.taskId);
        taskTurnpoints.addAll(await repository.getTaskTurnpoints(event.taskId));
      } catch (e) {
        emit(TaskErrorState(e.toString()));
      }
    }
    emit(TasksTurnpointsLoadedState(
        task: currentTask, taskTurnpoints: taskTurnpoints));
  }

  void _addTurnpointsToTask(
      TurnpointsAddedToTaskEvent event, Emitter<TaskState> emit) {
    final turnpoints = event.turnpoints;
    try {
      turnpoints.forEach((turnpoint) {
        _addTurnpointToTask(turnpoint);
      });
      if (taskTurnpoints.length > 0) {
        currentTask.distance = (taskTurnpoints.length > 0)
            ? taskTurnpoints.last.distanceFromStartingPoint
            : 0;
      }
      _checkForTaskTItle();
      emit(TasksTurnpointsLoadedState(
          task: currentTask, taskTurnpoints: taskTurnpoints));
      emit(TaskModifiedState());
    } catch (e) {
      emit(TaskErrorState(e.toString()));
    }
  }

  _addTurnpointToTask(Turnpoint turnpoint) {
    TaskTurnpoint priorTaskTurnpoint;
    final taskTurnpoint = TaskTurnpoint(
        taskId: currentTask.id,
        taskOrder: taskTurnpoints.length,
        title: turnpoint.title,
        code: turnpoint.code,
        latitudeDeg: turnpoint.latitudeDeg,
        longitudeDeg: turnpoint.longitudeDeg);
    if (taskTurnpoints.length != 0) {
      priorTaskTurnpoint = taskTurnpoints[taskTurnpoints.length - 1];
      priorTaskTurnpoint.lastTurnpoint = false;
      double dist = calculateDistance(
          priorTaskTurnpoint.latitudeDeg,
          priorTaskTurnpoint.longitudeDeg,
          taskTurnpoint.latitudeDeg,
          taskTurnpoint.longitudeDeg);
      taskTurnpoint.distanceFromPriorTurnpoint = dist;
      taskTurnpoint.distanceFromStartingPoint =
          priorTaskTurnpoint.distanceFromStartingPoint + dist;
      taskTurnpoint.lastTurnpoint = true;
    }
    taskTurnpoints.add(taskTurnpoint);
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _updateTaskName(TaskNamedChangedEvent event, Emitter<TaskState> emit) {
    currentTask.taskName = event.taskName;
    emit(TaskModifiedState());
  }

  // Save task and task turnpoints
  void _saveTask(SaveTaskTurnpointsEvent event, Emitter<TaskState> emit) async {
    _checkForTaskTItle();

    if (currentTask.id == null) {
      int? taskId = await repository.saveTask(currentTask);
      if (taskId == null) {
        emit(TaskErrorState('Oops. For some reason the task was not saved'));
      }
      currentTask.id = taskId;
    } else {
      int rowUpdated = await repository.updateTask(currentTask);
      if (rowUpdated != 1) {
        emit(TaskErrorState('Oops. For some reason the task was not updated.'));
      }
    }
    int i = 0;
    int? turnpointId;

    taskTurnpoints.forEach((taskTurnpoint) async {
      taskTurnpoint.taskId = currentTask.id;
      taskTurnpoint.taskOrder = i++;
      if (taskTurnpoint.id == null) {
        turnpointId = await repository.insertTaskTurnpoint(taskTurnpoint);
        if (turnpointId == null) {
          emit(TaskErrorState(
              'Oops. For some reason the task turnpoint was not saved'));
        }
        taskTurnpoint.id = turnpointId;
      } else {
        int? updatedRow = await repository.updateTaskTurnpoint(taskTurnpoint);
        if (updatedRow == null || updatedRow <= 0) {
          emit(TaskErrorState(
              'Oops. For some reason the task turnpoint was not updated'));
        }
      }
    });
    emit(TaskSavedState());
    emit(TasksTurnpointsLoadedState(
        task: currentTask, taskTurnpoints: taskTurnpoints));
  }

  void _checkForTaskTItle() {
    if (currentTask.taskName.isEmpty) {
      StringBuffer defaultTaskName = StringBuffer();
      String shortName = "";
      taskTurnpoints.forEach((taskTurnpoint) {
        shortName = taskTurnpoint.title.length >= 3
            ? taskTurnpoint.title.substring(0, 3)
            : taskTurnpoint.title;
        defaultTaskName
            .write(defaultTaskName.isEmpty ? shortName : '-' + shortName);
      });
      currentTask.taskName = defaultTaskName.toString();
    }
    ;
  }
}
