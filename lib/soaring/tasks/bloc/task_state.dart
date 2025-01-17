import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';

@immutable
abstract class TaskState extends Equatable {}

class TasksLoadingState extends TaskState {
  @override
  List<Object?> get props => [];
}

class TaskErrorState extends TaskState {
  final String errorMsg;

  TaskErrorState(String this.errorMsg);

  @override
  List<Object?> get props => [errorMsg];
}

class TaskShortMessageState extends TaskState {
  final String shortMsg;

  TaskShortMessageState(String this.shortMsg);

  @override
  List<Object?> get props => [shortMsg];
}

class TasksLoadedState extends TaskState {
  final List<Task> tasks;

  TasksLoadedState(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class TaskDetailState extends TaskState {
  final Task task;

  TaskDetailState(this.task);

  @override
  List<Object?> get props => [task];
}

//-------   Task Turnpoints --------------------
class TasksTurnpointsLoadingState extends TaskState {
  TasksTurnpointsLoadingState();

  @override
  List<Object?> get props => [];
}

class TasksTurnpointsLoadedState extends TaskState {
  final Task task;
  final List<TaskTurnpoint> taskTurnpoints;

  TasksTurnpointsLoadedState(
      {required this.task, required this.taskTurnpoints});

  @override
  List<Object?> get props => [task, taskTurnpoints];
}

class TaskTurnpointErrorState extends TaskState {
  final String errorMsg;

  TaskTurnpointErrorState(String this.errorMsg);

  @override
  List<Object?> get props => [errorMsg];
}

class TaskModifiedState extends TaskState {
  TaskModifiedState();

  @override
  List<Object?> get props => [];
}

class TaskSavedState extends TaskState {
  TaskSavedState();

  @override
  List<Object?> get props => [];
}

// Turnpoint based on TaskTurnpoint
class TurnpointFoundState extends TaskState {
  final Turnpoint turnpoint;

  TurnpointFoundState(this.turnpoint);

  @override
  List<Object?> get props => [turnpoint];
}

class ValidTaskState extends TaskState {
  final bool validTask;
  final String invalidTaskMsg;

  ValidTaskState(this.validTask, { this.invalidTaskMsg = ""});

  @override
  List<Object?> get props => [validTask, invalidTaskMsg];
}
