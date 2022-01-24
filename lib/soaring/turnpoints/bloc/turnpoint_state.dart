import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';

@immutable
abstract class TurnpointState extends Equatable {}

class TurnpointsLoadingState extends TurnpointState {
  @override
  List<Object?> get props => [];
}

class TurnpointErrorState extends TurnpointState {
  final String errorMsg;
  TurnpointErrorState(String this.errorMsg);
  @override
  List<Object?> get props => [errorMsg];
}

class TurnpointShortMessageState extends TurnpointState {
  final String shortMsg;
  TurnpointShortMessageState(String this.shortMsg);
  @override
  List<Object?> get props => [shortMsg];
}

class TurnpointsDownloadingState extends TurnpointState {
  TurnpointsDownloadingState();
  @override
  List<Object?> get props => [];
}

class TurnpointsLoadedState extends TurnpointState {
  final List<Turnpoint> turnpoints;
  TurnpointsLoadedState(this.turnpoints);
  @override
  List<Object?> get props => [turnpoints];
}

class TurnpointViewState extends TurnpointState {
  final Turnpoint turnpoint;
  TurnpointViewState(this.turnpoint);

  @override
  List<Object?> get props => [turnpoint];
}

// Turnpoints Search States
class SearchingTurnpointsState extends TurnpointState {
  @override
  List<Object?> get props => [];
}

class TurnpointSearchErrorState extends TurnpointState {
  final String errorMsg;
  TurnpointSearchErrorState(String this.errorMsg);
  @override
  List<Object?> get props => [errorMsg];
}

class TurnpointsFoundState extends TurnpointState {
  final List<Turnpoint> turnpoints;
  TurnpointsFoundState(this.turnpoints);
  @override
  List<Object?> get props => [turnpoints];
}
