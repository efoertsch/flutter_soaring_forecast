import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';

@immutable
abstract class TurnpointEvent extends Equatable {}

// All the events related to turnpoints

class TurnpointListEvent extends TurnpointEvent {
  TurnpointListEvent();
  @override
  List<Object?> get props => [];
}

class SearchTurnpointsEvent extends TurnpointEvent {
  final String searchString;
  SearchTurnpointsEvent(this.searchString);

  @override
  List<Object?> get props => [searchString];
}

class TurnpointViewEvent extends TurnpointEvent {
  final Turnpoint turnpoint;
  TurnpointViewEvent(this.turnpoint);

  @override
  List<Object?> get props => [turnpoint];
}

class AddTurnpointToTask extends TurnpointEvent {
  final Turnpoint turnpoint;
  AddTurnpointToTask(this.turnpoint);

  @override
  List<Object?> get props => [turnpoint];
}
