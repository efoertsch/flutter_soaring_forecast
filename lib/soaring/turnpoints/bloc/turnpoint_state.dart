import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/options/turnpoint_regions.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/cup/cup_styles.dart';

@immutable
abstract class TurnpointState extends Equatable {}

class TurnpointsInitialState extends TurnpointState {
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
  final List<Style> cupStyles;
  TurnpointsLoadedState(this.turnpoints, this.cupStyles);
  @override
  List<Object?> get props => [turnpoints, cupStyles];
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

class TurnpointSearchMessage extends TurnpointState {
  final String msg;
  TurnpointSearchMessage(String this.msg);
  @override
  List<Object?> get props => [msg];
}

// For turnpoint file download/import
class TurnpointFileLoadingState extends TurnpointState {
  TurnpointFileLoadingState();
  @override
  List<Object?> get props => [];
}

class TurnpointCupStyles extends TurnpointState {
  List<Style> cupStyles;
  TurnpointCupStyles(this.cupStyles);
  @override
  List<Object?> get props => [cupStyles];
}

class TurnpointDuplicateCode extends TurnpointState {
  @override
  List<Object?> get props => [];
}

class EditTurnpoint extends TurnpointState {
  final Turnpoint turnpoint;
  EditTurnpoint(this.turnpoint);
  @override
  List<Object?> get props => [turnpoint];
}

class UpdatedTurnpoint extends TurnpointState {
  final Turnpoint turnpoint;
  UpdatedTurnpoint(this.turnpoint);
  @override
  List<Object?> get props => [turnpoint];
}

class TurnpointDeletedState extends TurnpointState {
  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();
}

class CurrentLocationState extends TurnpointState {
  // decimal degrees
  final double latitude;
  final double longitude;
  // altitude in meters
  final double altitude;

  CurrentLocationState(this.latitude, this.longitude, this.altitude);

  @override
  List<Object?> get props => [latitude, longitude];
}

class LatLongElevationState extends TurnpointState {
  final double latitude;
  final double longitude;
  final double elevation;
  LatLongElevationState(this.latitude, this.longitude, this.elevation);
  @override
  List<Object?> get props => [latitude, longitude, elevation];
}

//----------------------------------------------------------------
// For loading turnpoint file names
class TurnpointFilesFoundState extends TurnpointState {
  final List<TurnpointFile> turnpointFiles;
  TurnpointFilesFoundState(this.turnpointFiles);
  @override
  List<Object?> get props => [turnpointFiles];
}

class CustomTurnpointFileList extends TurnpointState {
  final List<File> customTurnpointFiles;
  CustomTurnpointFileList(List<File> this.customTurnpointFiles);
  @override
  // TODO: implement props
  List<Object?> get props => [customTurnpointFiles];
}
