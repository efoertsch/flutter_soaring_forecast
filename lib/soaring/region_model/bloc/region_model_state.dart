import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../repository/rasp/regions.dart';
import '../data/region_model_data.dart';

@immutable
abstract class RegionModelState {}

class RegionModelInitialState extends RegionModelState {}

// GFS, NAM, etc and the default (or previously saved selected model
// This is for 'expert' model/date dropdown lists
class ForecastModelsAndDates extends RegionModelState {
  final bool beginnerMode;
  final String regionName;
  final List<String> modelNames;
  final int modelNameIndex;
  final List<String> forecastDates; // array of dates like  2019-12-19
  final int forecastDateIndex;
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
}

class RegionLatLngBoundsState extends RegionModelState {
  final LatLngBounds latLngBounds;

  RegionLatLngBoundsState(this.latLngBounds);
}

class CenterOfMapState extends RegionModelState {
  final LatLng latLng;

  CenterOfMapState(this.latLng);
}

class ErrorState extends RegionModelState {
  final String error;

  ErrorState(this.error);
}

class WorkingState extends RegionModelState {
  final bool working;

  WorkingState({required this.working});
}

class RegionSoundingsState extends RegionModelState {
  final List<Soundings> soundings;

  RegionSoundingsState(this.soundings);
}

class SuaDetailsState extends RegionModelState {
  //final SUA suaDetails;
  final String suaDetails;

  SuaDetailsState(this.suaDetails);
}

class EstimatedTaskRegionModelState extends RegionModelState {
  final EstimatedTaskRegionModel estimatedTaskRegionModel;

  EstimatedTaskRegionModelState(this.estimatedTaskRegionModel);

}
