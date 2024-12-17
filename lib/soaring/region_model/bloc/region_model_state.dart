import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../repository/rasp/regions.dart';

@immutable
abstract class RegionModelState extends Equatable {}

class RegionModelInitialState extends RegionModelState {
  @override
  // TODO: implement props
  List<Object?> get props =>[ ""];
}

// GFS, NAM, etc and the default (or previously saved selected model
// This is for 'expert' model/date dropdown lists
class ForecastModelsAndDates extends RegionModelState {
  final bool beginnerMode;
  final String regionName;
  final List<String> modelNames;
  final int modelNameIndex;
  final List<String> forecastDates; // array of dates like  2019-12-19
  // dates for the selected modelName
  final int forecastDateIndex;

  // time for the selected modelName/date
  final List<String> localTimes;
  final int localTimeIndex;

  ForecastModelsAndDates(
      {required this.beginnerMode,
        required this.regionName,
      required this.modelNames,
      required this.modelNameIndex,
      required this.forecastDates,
      required this.forecastDateIndex,
      required this.localTimes,
      required this.localTimeIndex});

  @override
  List<Object?> get props => [beginnerMode, regionName, modelNames.toString(), modelNameIndex,forecastDates.toString(), forecastDateIndex, localTimes.toString(), localTimeIndex];
}

class RegionLatLngBoundsState extends RegionModelState {
  final LatLngBounds latLngBounds;

  RegionLatLngBoundsState(this.latLngBounds);
  @override
  // TODO: implement props
  List<Object?> get props =>[ latLngBounds];
}

class CenterOfMapState extends RegionModelState {
  final LatLng latLng;

  CenterOfMapState(this.latLng);

  @override
  // TODO: implement props
  List<Object?> get props => [latLng];
}

class ErrorState extends RegionModelState {
  final String error;

  ErrorState(this.error);

  @override
  // TODO: implement props
  List<Object?> get props => [error];
}

class WorkingState extends RegionModelState {
  final bool working;

  WorkingState({required this.working});

  @override
  // TODO: implement props
  List<Object?> get props => [working];
}

class RegionSoundingsState extends RegionModelState {
  final List<Soundings> soundings;

  RegionSoundingsState(this.soundings);

  @override
  // TODO: implement props
  List<Object?> get props => [soundings];
}

class SuaDetailsState extends RegionModelState {
  //final SUA suaDetails;
  final String suaDetails;

  SuaDetailsState(this.suaDetails);

  @override
  // TODO: implement props
  List<Object?> get props => [suaDetails];
}

