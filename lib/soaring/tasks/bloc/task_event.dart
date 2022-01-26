import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';

@immutable
abstract class TaskEvent extends Equatable {}

// All the events related to Tasks

class TaskListEvent extends TaskEvent {
  TaskListEvent();
  @override
  List<Object?> get props => [];
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
