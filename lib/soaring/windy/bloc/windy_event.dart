import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
abstract class WindyEvent extends Equatable {}

// All the events related to Tasks

class WindyInitEvent extends WindyEvent {
  WindyInitEvent();
  @override
  List<Object?> get props => [];
}

class WindyModelEvent extends WindyEvent {
  final int index;
  WindyModelEvent(this.index);
  @override
  List<Object?> get props => [index];
}

class WindyAltitudeEvent extends WindyEvent {
  final int index;
  WindyAltitudeEvent(this.index);
  @override
  List<Object?> get props => [index];
}

class WindyLayerEvent extends WindyEvent {
  final int index;
  WindyLayerEvent(this.index);
  @override
  List<Object?> get props => [index];
}

class LoadWindyHTMLEvent extends WindyEvent {
  @override
  List<Object?> get props => [];
}

class DisplayTaskIfAnyEvent extends WindyEvent {
  DisplayTaskIfAnyEvent();
  @override
  List<Object?> get props => [];
}

class SelectTaskEvent extends WindyEvent {
  final int taskId;
  SelectTaskEvent(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class ClearTaskEvent extends WindyEvent {
  ClearTaskEvent();
  @override
  List<Object?> get props => [];
}

class WindyWidgetSizeEvent extends WindyEvent {
  final Size size;
  WindyWidgetSizeEvent(this.size);
  @override
  List<Object?> get props => [size];
}
