import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_event.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_state.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoint_utils.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final Repository repository;
  Task _currentTask = Task();
  List<Task> _tasks = [];
  List<TaskTurnpoint> _taskTurnpoints = [];
  List<TaskTurnpoint> _deletedTaskTurnpoints = [];

//TaskState get initialState => TasksLoadingState();

  TaskBloc({required this.repository}) : super(TasksLoadingState()) {
    on<TaskListEvent>(_showAllTasks);
    on<SwitchOrderOfTasksEvent>(_switchOrderOfTasks);
    on<SwipeDeletedTaskEvent>(_removeTaskFromTaskList);
    on<AddBackTaskEvent>(_addBackTaskToList);
    on<TaskNamedChangedEvent>(_updateTaskName);
    on<LoadTaskTurnpointsEvent>(_showTaskTurnpoints);
    on<TurnpointsAddedToTaskEvent>(_addTurnpointsToTask);
    on<SaveTaskTurnpointsEvent>(_saveTask);
    on<DisplayTaskTurnpointEvent>(_displayTaskTurnpoint);
    on<SwitchOrderOfTaskTurnpointsEvent>(_switchOrderOfTaskTurnpoints);
    on<SwipeDeletedTaskTurnpointEvent>(_removeTaskTurnpointFromTask);
    on<AddBackTaskTurnpointEvent>(_addBackTaskTurnpoint);
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
    _tasks.clear();
    try {
      _tasks.addAll(await repository.getAlltasks());
      List<Task> tasksForState = [];
      tasksForState.addAll(_tasks);
      emit(TasksLoadedState(tasksForState));
    } catch (e) {
      emit(TaskErrorState(e.toString()));
    }
  }

  void _switchOrderOfTasks(
      SwitchOrderOfTasksEvent event, Emitter<TaskState> emit) {
    if (event.oldIndex <= _tasks.length && event.newIndex <= _tasks.length) {
      var task = _tasks[event.oldIndex];
      _tasks.removeAt(event.oldIndex);
      _tasks.insert(event.newIndex, task);
      _updateTaskList(emit);
    }
  }

  void _removeTaskFromTaskList(
      SwipeDeletedTaskEvent event, Emitter<TaskState> emit) async {
    Task task = _tasks[event.index];
    // save task details in case of undo
    _currentTask = task;
    _taskTurnpoints = await repository.getTaskTurnpoints(_currentTask.id!);
    _deletedTaskTurnpoints.clear();
    try {
      // cascade delete of task turnpoints also
      await repository.deleteTask(task.id!);
    } catch (e) {
      debugPrint("Delete task exception: ${e.toString()}");
    }
    _tasks.removeAt(event.index);
    _updateTaskList(emit);
  }

  void _addBackTaskToList(
      AddBackTaskEvent event, Emitter<TaskState> emit) async {
    // Add it back into list in original position.
    Task task = event.task;
    _tasks.insert(event.task.taskOrder, task);
    // since task deleted from database, set id to null so it gets inserted rather
    // than attempting update.
    task.id = null;
    // also going to null out taskturnpoint ids and re-add them
    _taskTurnpoints.forEach((taskTurnpoint) {
      taskTurnpoint.id = null;
    });
    await _saveCurrentTaskAndTurnpoints(emit);
    // and update task order for all tasks
    _updateTaskList(emit);
  }

  void _updateTaskList(Emitter<TaskState> emit) async {
    List<Task> tasksForState = [];
    try {
      int index = 0;
      _tasks.forEach((task) {
        task.taskOrder = index++;
        tasksForState.add(task);
      });
      _tasks.forEach((task) async {
        await repository.updateTask(task);
      });
      emit(TasksLoadedState(tasksForState));
    } catch (e) {
      emit(TaskErrorState(e.toString()));
    }
  }

  void _showTaskTurnpoints(
      LoadTaskTurnpointsEvent event, Emitter<TaskState> emit) async {
    _taskTurnpoints.clear();
    _deletedTaskTurnpoints.clear();
    emit(TasksTurnpointsLoadingState());
    if (event.taskId == -1) {
      _currentTask = Task();
    } else {
      try {
        _currentTask = await repository.getTask(event.taskId);
        _taskTurnpoints
            .addAll(await repository.getTaskTurnpoints(event.taskId));
        for (var taskTurnpoint in _taskTurnpoints) {
          taskTurnpoint.turnpointColor =
              await repository.getColorForTurnpoint(taskTurnpoint.code);
        }
      } catch (e) {
        emit(TaskErrorState(e.toString()));
      }
    }
    emit(TasksTurnpointsLoadedState(
        task: _currentTask, taskTurnpoints: _taskTurnpoints));
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
        taskId: _currentTask.id,
        taskOrder: _taskTurnpoints.length,
        title: turnpoint.title,
        code: turnpoint.code,
        latitudeDeg: turnpoint.latitudeDeg,
        longitudeDeg: turnpoint.longitudeDeg);
    taskTurnpoint.turnpointColor =
        TurnpointUtils.getColorForTurnpointIcon(turnpoint.style);
    _taskTurnpoints.add(taskTurnpoint);
  }

  void _switchOrderOfTaskTurnpoints(
      SwitchOrderOfTaskTurnpointsEvent event, Emitter<TaskState> emit) {
    if (event.oldIndex <= _taskTurnpoints.length &&
        event.newIndex <= _taskTurnpoints.length) {
      var taskTurnpoint = _taskTurnpoints[event.oldIndex];
      _taskTurnpoints.removeAt(event.oldIndex);
      _taskTurnpoints.insert(event.newIndex, taskTurnpoint);
      _updateTaskDetails(emit);
    }
  }

  void _removeTaskTurnpointFromTask(
      SwipeDeletedTaskTurnpointEvent event, Emitter<TaskState> emit) {
    _deletedTaskTurnpoints.add(_taskTurnpoints[event.index]);
    _taskTurnpoints.removeAt(event.index);
    _updateTaskDetails(emit);
  }

  void _addBackTaskTurnpoint(
      AddBackTaskTurnpointEvent event, Emitter<TaskState> emit) {
    _taskTurnpoints.insert(event.taskTurnpoint.taskOrder, event.taskTurnpoint);
    _deletedTaskTurnpoints.remove(event.taskTurnpoint);
    _updateTaskDetails(emit);
  }

  void _updateTaskDetails(Emitter<TaskState> emit) {
    _calculateDistances();
    //_createTaskName();
    emit(TasksTurnpointsLoadedState(
        task: _currentTask, taskTurnpoints: _taskTurnpoints));
    emit(TaskModifiedState());
  }

  void _calculateDistances() {
    TaskTurnpoint? priorTaskTurnpoint;
    for (int i = 0; i < _taskTurnpoints.length; i++) {
      if (i == 0) {
        priorTaskTurnpoint = _taskTurnpoints[0];
        priorTaskTurnpoint.distanceFromPriorTurnpoint = 0;
        priorTaskTurnpoint.distanceFromStartingPoint = 0;
        priorTaskTurnpoint.taskOrder = 0;
        priorTaskTurnpoint.lastTurnpoint = false;
      } else {
        TaskTurnpoint currentTaskTurnpoint = _taskTurnpoints[i];
        double dist = calculateDistance(
            priorTaskTurnpoint!.latitudeDeg,
            priorTaskTurnpoint.longitudeDeg,
            currentTaskTurnpoint.latitudeDeg,
            currentTaskTurnpoint.longitudeDeg);
        currentTaskTurnpoint.distanceFromPriorTurnpoint = dist;
        currentTaskTurnpoint.distanceFromStartingPoint =
            priorTaskTurnpoint.distanceFromStartingPoint + dist;
        currentTaskTurnpoint.taskOrder = i;
        currentTaskTurnpoint.lastTurnpoint = i == _taskTurnpoints.length - 1;
        priorTaskTurnpoint = currentTaskTurnpoint;
      }
    }
    _currentTask.distance = (_taskTurnpoints.length > 0)
        ? _taskTurnpoints.last.distanceFromStartingPoint
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
    _currentTask.taskName = event.taskName;
    emit(TaskModifiedState());
  }

  // Save task and task turnpoints
  void _saveTask(SaveTaskTurnpointsEvent event, Emitter<TaskState> emit) async {
    _checkForTaskName();
    await _saveCurrentTaskAndTurnpoints(emit);
    emit(TaskSavedState());
    emit(TasksTurnpointsLoadedState(
        task: _currentTask, taskTurnpoints: _taskTurnpoints));
  }

  Future<void> _saveCurrentTaskAndTurnpoints(Emitter<TaskState> emit) async {
    bool isTaskUpdate = true;
    if (_currentTask.id == null) {
      isTaskUpdate = false;
      int? taskNumber = await repository.getCountOfTasks();
      _currentTask.taskOrder = taskNumber!;
      int? taskId = await repository.saveTask(_currentTask);
      if (taskId == null) {
        emit(TaskErrorState('Oops. For some reason the task was not saved'));
      }
      _currentTask.id = taskId!;
    } else {
      int rowUpdated = await repository.updateTask(_currentTask);
      if (rowUpdated != 1) {
        emit(TaskErrorState('Oops. For some reason the task was not updated.'));
      }
    }
    int? turnpointId;

    for (int turnpointOrder = 0;
        turnpointOrder < _taskTurnpoints.length;
        turnpointOrder++) {
      // taskTurnpoints.forEach((taskTurnpoint) {
      TaskTurnpoint taskTurnpoint = _taskTurnpoints[turnpointOrder];
      taskTurnpoint.taskId = _currentTask.id!;
      taskTurnpoint.taskOrder = turnpointOrder;
      if (taskTurnpoint.id == null) {
        turnpointId = await repository.insertTaskTurnpoint(taskTurnpoint);
        if (turnpointId == null) {
          emit(TaskErrorState(
              'Oops. For some reason the task turnpoint was not saved'));
          return;
        }
        taskTurnpoint.id = turnpointId;
      } else {
        int? updatedRow = await repository.updateTaskTurnpoint(taskTurnpoint);
        if (updatedRow == null || updatedRow <= 0) {
          emit(TaskErrorState(
              'Oops. For some reason the task turnpoint was not updated'));
          return;
        }
      }
    }

    //if update make sure to delete any  turnpoints no longer in task
    if (isTaskUpdate) {
      _deletedTaskTurnpoints.forEach((taskTurnpoint) async {
        await repository.deleteTaskTurnpoint(taskTurnpoint.id!);
      });
    }
  }

  void _checkForTaskName() {
    if (_currentTask.taskName.isEmpty) {
      StringBuffer defaultTaskName = StringBuffer();
      String shortName = "";
      _taskTurnpoints.forEach((taskTurnpoint) {
        shortName = taskTurnpoint.title.length >= 5
            ? taskTurnpoint.title.substring(0, 5)
            : taskTurnpoint.title;
        defaultTaskName
            .write(defaultTaskName.isEmpty ? shortName : '-' + shortName);
      });
      _currentTask.taskName = defaultTaskName.toString();
    }
  }
}
