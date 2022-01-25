import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';

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

class TasksTurnpointsLoadiedState extends TaskState {
  final List<TaskTurnpoint> taskTurnpoints;
  TasksTurnpointsLoadiedState(this.taskTurnpoints);
  @override
  List<Object?> get props => [taskTurnpoints];
}

class TaskTurnpointErrorState extends TaskState {
  final String errorMsg;
  TaskTurnpointErrorState(String this.errorMsg);
  @override
  List<Object?> get props => [errorMsg];
}
