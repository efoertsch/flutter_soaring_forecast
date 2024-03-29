import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';

@immutable
abstract class TaskEvent extends Equatable {}

// All the events related to Tasks

class TaskListEvent extends TaskEvent {
  TaskListEvent();
  @override
  List<Object?> get props => [];
}

// for when a task is moved up or down in the task list
class SwitchOrderOfTasksEvent extends TaskEvent {
  final int oldIndex;
  final int newIndex;
  SwitchOrderOfTasksEvent(this.oldIndex, this.newIndex);
  @override
  List<Object?> get props => [oldIndex, newIndex];
}

// For when a task is swiped to delete it from the task list
class SwipeDeletedTaskEvent extends TaskEvent {
  final int index;
  SwipeDeletedTaskEvent(this.index);
  @override
  List<Object?> get props => [index];
}

// For when task is undeleted
class AddBackTaskEvent extends TaskEvent {
  final Task task;
  AddBackTaskEvent(this.task);
  @override
  List<Object?> get props => [task];
}

class LoadTaskTurnpointsEvent extends TaskEvent {
  final int taskId;
  LoadTaskTurnpointsEvent(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class TurnpointsAddedToTaskEvent extends TaskEvent {
  final List<Turnpoint> turnpoints;
  TurnpointsAddedToTaskEvent(this.turnpoints);
  @override
  List<Object?> get props => [turnpoints];
}

class SaveTaskTurnpointsEvent extends TaskEvent {
  SaveTaskTurnpointsEvent();
  @override
  List<Object?> get props => [];
}

class TaskNamedChangedEvent extends TaskEvent {
  final String taskName;
  TaskNamedChangedEvent(String this.taskName);
  @override
  List<Object?> get props => [taskName];
}

class DisplayTaskTurnpointEvent extends TaskEvent {
  final TaskTurnpoint taskTurnpoint;
  DisplayTaskTurnpointEvent(this.taskTurnpoint);
  @override
  List<Object?> get props => [taskTurnpoint];
}

class SwitchOrderOfTaskTurnpointsEvent extends TaskEvent {
  final int oldIndex;
  final int newIndex;
  SwitchOrderOfTaskTurnpointsEvent(this.oldIndex, this.newIndex);
  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class SwipeDeletedTaskTurnpointEvent extends TaskEvent {
  final int index;
  SwipeDeletedTaskTurnpointEvent(this.index);
  @override
  List<Object?> get props => [index];
}

class AddBackTaskTurnpointEvent extends TaskEvent {
  final TaskTurnpoint taskTurnpoint;
  AddBackTaskTurnpointEvent(this.taskTurnpoint);
  @override
  List<Object?> get props => [taskTurnpoint];
}
