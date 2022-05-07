import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/options/turnpoint_regions.dart';

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

// For getting list of files from soargbsc.com/soaringforecast/turnpoint_regions.json
class GetTurnpointFileNamesEvent extends TurnpointEvent {
  GetTurnpointFileNamesEvent();
  @override
  List<Object?> get props => [];
}

// For getting list of files from soargbsc.com/soaringforecast/turnpoint_regions.json
class LoadTurnpointFileEvent extends TurnpointEvent {
  late final TurnpointFile turnpointFile;
  LoadTurnpointFileEvent(this.turnpointFile);
  @override
  List<Object?> get props => [turnpointFile];
}

class DeleteAllTurnpointsEvent extends TurnpointEvent {
  @override
  List<Object?> get props => [];
}

class GetCustomImportFileNamesEvent extends TurnpointEvent {
  @override
  List<Object?> get props => [];
}
