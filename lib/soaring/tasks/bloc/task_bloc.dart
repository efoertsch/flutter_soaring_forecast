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
    on<SwitchOrderOfTaskTurnpointsEvent>(_switchOrderOfTaskTurnpoints);
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
    turnpoints.forEach((turnpoint) {
      _addTurnpointToTask(turnpoint);
    });
    _updateTaskDetails(emit);
  }

  _addTurnpointToTask(Turnpoint turnpoint) {
    final taskTurnpoint = TaskTurnpoint(
        taskId: currentTask.id,
        taskOrder: taskTurnpoints.length,
        title: turnpoint.title,
        code: turnpoint.code,
        latitudeDeg: turnpoint.latitudeDeg,
        longitudeDeg: turnpoint.longitudeDeg);
    taskTurnpoints.add(taskTurnpoint);
  }

  void _switchOrderOfTaskTurnpoints(
      SwitchOrderOfTaskTurnpointsEvent event, Emitter<TaskState> emit) {
    if (event.oldIndex <= taskTurnpoints.length &&
        event.newIndex <= taskTurnpoints.length) {
      var taskTurnpoint = taskTurnpoints[event.oldIndex];
      taskTurnpoints.removeAt(event.oldIndex);
      taskTurnpoints.insert(event.newIndex, taskTurnpoint);
      _updateTaskDetails(emit);
    }
  }

  void _updateTaskDetails(Emitter<TaskState> emit) {
    _calculateDistances();
    _createTaskName();
    emit(TasksTurnpointsLoadedState(
        task: currentTask, taskTurnpoints: taskTurnpoints));
    emit(TaskModifiedState());
  }

  void _calculateDistances() {
    int taskLength = 0;
    TaskTurnpoint? priorTaskTurnpoint;
    for (int i = 0; i < taskTurnpoints.length; i++) {
      if (i == 0) {
        priorTaskTurnpoint = taskTurnpoints[0];
        priorTaskTurnpoint.distanceFromPriorTurnpoint = 0;
        priorTaskTurnpoint.distanceFromStartingPoint = 0;
        priorTaskTurnpoint.taskOrder = 0;
        priorTaskTurnpoint.lastTurnpoint = false;
      } else {
        TaskTurnpoint currentTaskTurnpoint = taskTurnpoints[i];
        double dist = calculateDistance(
            priorTaskTurnpoint!.latitudeDeg,
            priorTaskTurnpoint.longitudeDeg,
            currentTaskTurnpoint.latitudeDeg,
            currentTaskTurnpoint.longitudeDeg);
        currentTaskTurnpoint.distanceFromPriorTurnpoint = dist;
        currentTaskTurnpoint.distanceFromStartingPoint =
            priorTaskTurnpoint.distanceFromStartingPoint + dist;
        currentTaskTurnpoint.taskOrder = i;
        currentTaskTurnpoint.lastTurnpoint = i == taskTurnpoints.length - 1;
        priorTaskTurnpoint = currentTaskTurnpoint;
      }
    }
    currentTask.distance = (taskTurnpoints.length > 0)
        ? taskTurnpoints.last.distanceFromStartingPoint
        : 0;
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
    _checkForTaskName();

    if (currentTask.id == 0) {
      int? taskId = await repository.saveTask(currentTask);
      if (taskId == null) {
        emit(TaskErrorState('Oops. For some reason the task was not saved'));
      }
      currentTask.id = taskId!;
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
      if (taskTurnpoint.id == 0) {
        turnpointId = await repository.insertTaskTurnpoint(taskTurnpoint);
        if (turnpointId == null) {
          emit(TaskErrorState(
              'Oops. For some reason the task turnpoint was not saved'));
          return;
        }
        taskTurnpoint.id = turnpointId!;
      } else {
        int? updatedRow = await repository.updateTaskTurnpoint(taskTurnpoint);
        if (updatedRow == null || updatedRow <= 0) {
          emit(TaskErrorState(
              'Oops. For some reason the task turnpoint was not updated'));
          return;
        }
      }
    });
    emit(TaskSavedState());
    emit(TasksTurnpointsLoadedState(
        task: currentTask, taskTurnpoints: taskTurnpoints));
  }

  void _checkForTaskName() {
    if (currentTask.taskName.isEmpty) {
      _createTaskName();
    }
    ;
  }

  void _createTaskName() {
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
}
