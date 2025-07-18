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
  TurnpointErrorState(this.errorMsg);
  @override
  List<Object?> get props => [errorMsg];
}

class TurnpointShortMessageState extends TurnpointState {
  final String shortMsg;
  TurnpointShortMessageState(this.shortMsg);
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
  final List<CupStyle> cupStyles;
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
  TurnpointSearchErrorState(this.errorMsg);
  @override
  List<Object?> get props => [errorMsg];
}

class TurnpointSearchMessageState extends TurnpointState {
  final String msg;
  TurnpointSearchMessageState(this.msg);
  @override
  List<Object?> get props => [msg];
}

// For turnpoint file download/import
class TurnpointFileLoadingState extends TurnpointState {
  TurnpointFileLoadingState();
  @override
  List<Object?> get props => [];
}

class TurnpointCupStylesState extends TurnpointState {
  final List<CupStyle> cupStyles;
  TurnpointCupStylesState(this.cupStyles);
  @override
  List<Object?> get props => [cupStyles];
}

class TurnpointDuplicateCodeState extends TurnpointState {
  @override
  List<Object?> get props => [];
}

class EditTurnpointState extends TurnpointState {
  final Turnpoint turnpoint;
  EditTurnpointState(this.turnpoint);
  @override
  List<Object?> get props => [turnpoint];
}

class UpdatedTurnpointState extends TurnpointState {
  final Turnpoint turnpoint;
  UpdatedTurnpointState(this.turnpoint);
  @override
  List<Object?> get props => [turnpoint];
}

class TurnpointDeletedState extends TurnpointState {
  @override
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

class CustomTurnpointFileListState extends TurnpointState {
  final List<File> customTurnpointFiles;
  CustomTurnpointFileListState(this.customTurnpointFiles);
  @override
  List<Object?> get props => [customTurnpointFiles];
}

class TempTurnpointsDownloadDirectory extends TurnpointState {
  final File tempFile;
  TempTurnpointsDownloadDirectory(this.tempFile);
  @override
  List<Object?> get props => [tempFile.toString()];


}
