import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
abstract class TurnpointState extends Equatable {}

class TurnpointInitialState extends TurnpointState {
  final state = " TurnpointInitialState";
  @override
  String toString() => state;

  @override
  List<Object?> get props => [state];
}

class TurnpointsLoadingState extends TurnpointState {
  TurnpointsLoadingState();
  @override
  List<Object?> get props => [];
}

class TurnpointsLoadErrorState extends TurnpointState {
  final String error;
  TurnpointsLoadErrorState(this.error);

  @override
  List<Object?> get props => [error];
}

class TurnpointSearchResults extends TurnpointState {
  final List<String> turnpoints;

  TurnpointSearchResults(this.turnpoints);

  @override
  List<Object?> get props => [turnpoints];
}
