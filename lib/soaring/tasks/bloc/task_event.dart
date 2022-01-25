import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';

@immutable
abstract class TaskEvent extends Equatable {}

// All the events related to Tasks

class TaskListEvent extends TaskEvent {
  TaskListEvent();
  @override
  List<Object?> get props => [];
}

class TaskTurnpointsEvent extends TaskEvent {
  final Task task;
  TaskTurnpointsEvent(this.task);
  @override
  List<Object?> get props => [task];
}

class SaveTaskTurnpointsEvent extends TaskEvent {
  SaveTaskTurnpointsEvent();
  @override
  List<Object?> get props => [];
}
