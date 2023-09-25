import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/LatLngForecast.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/data/forecast_graph_data.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/optimized_task_route.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/view_bounds.dart';
import 'package:latlong2/latlong.dart';

/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
/// Event In - State Out
///
@immutable
abstract class RaspDataState {}

class RaspInitialState extends RaspDataState {
  final state = "RaspInitialState";

  @override
  String toString() => state;
}

class SelectedRegionNameState extends RaspDataState {
  final String selectedRegionName;

  SelectedRegionNameState(this.selectedRegionName);
}

// GFS, NAM, etc and the default (or previously saved selected model
class RaspForecastModels extends RaspDataState {
  final List<String> modelNames;
  final String selectedModelName;

  RaspForecastModels(this.modelNames, this.selectedModelName);
}

//  list of forecast dates available for the selected forecast model and the
//  default selected date.
class RaspModelDates extends RaspDataState {
  final List<String> forecastDates; // array of dates like  2019-12-19
  final String selectedForecastDate;

  RaspModelDates(this.forecastDates, this.selectedForecastDate);
}

// List of forecast model (eg. 'Thermal updraft velocity & B/S Ratio', 'B/L Top', etc )
class RaspForecasts extends RaspDataState {
  final List<Forecast> forecasts;
  final Forecast selectedForecast;

  RaspForecasts(this.forecasts, this.selectedForecast);
}

class ForecastBoundsState extends RaspDataState {
  final LatLngBounds latLngBounds;

  ForecastBoundsState(this.latLngBounds);
}

class CenterOfMapState extends RaspDataState {
  final LatLng latLng;

  CenterOfMapState(this.latLng);
}

class ViewBoundsState extends RaspDataState {
  final ViewBounds viewBounds;

  ViewBoundsState(this.viewBounds);
}

class RaspForecastTime extends RaspDataState {
  final String forecastTime;

  RaspForecastTime(this.forecastTime);
}

class RaspErrorState extends RaspDataState {
  final String error;

  RaspErrorState(this.error);
}

class RaspForecastTypesLoaded extends RaspDataState {
  final List<Forecast> forecasts;

  RaspForecastTypesLoaded(this.forecasts);
}

//TODO add stacktrace?
class RaspMapLatLngBoundsError extends RaspDataState {
  static const boundsError = 'Error creating Google Map Lat/Lng bounds';

  @override
  String toString() => boundsError;
}

class RaspForecastImageSet extends RaspDataState {
  final SoaringForecastImageSet soaringForecastImageSet;
  final int displayIndex;
  final int numberImages;

  RaspForecastImageSet(
      this.soaringForecastImageSet, this.displayIndex, this.numberImages);
}

class RaspTaskTurnpoints extends RaspDataState {
  final List<TaskTurnpoint> taskTurnpoints;

  RaspTaskTurnpoints(this.taskTurnpoints);
}

// Turnpoint based on TaskTurnpoint
class TurnpointFoundState extends RaspDataState {
  final Turnpoint turnpoint;

  TurnpointFoundState(this.turnpoint);
}

class LocalForecastState extends RaspDataState {
  final LatLngForecast latLngForecast;

  LocalForecastState(this.latLngForecast);
}

class RedisplayMarkersState extends RaspDataState {
  RedisplayMarkersState();
}

class RaspSoundingsState extends RaspDataState {
  final List<Soundings> soundings;

  RaspSoundingsState(this.soundings);
}

class SoundingForecastImageSet extends RaspDataState {
  final SoaringForecastImageSet soaringForecastImageSet;
  final int displayIndex;
  final int numberImages;

  SoundingForecastImageSet(
      this.soaringForecastImageSet, this.displayIndex, this.numberImages);
}

class TurnpointsInBoundsState extends RaspDataState {
  final List<Turnpoint> turnpoints;

  TurnpointsInBoundsState(this.turnpoints);
}

class RaspDisplayOptionsState extends RaspDataState {
  final List<PreferenceOption> displayOptions;

  RaspDisplayOptionsState(this.displayOptions);
}

class SuaDetailsState extends RaspDataState {
  //final SUA suaDetails;
  final String suaDetails;

  //SuaDetailsState(this.suaDetails);
  SuaDetailsState(this.suaDetails);
}

class ForecastOverlayOpacityState extends RaspDataState {
  final double opacity;

  ForecastOverlayOpacityState(this.opacity);
}

class RegionsLoadedState extends RaspDataState {
  final List<String> regions;

  RegionsLoadedState(this.regions);
}

class DisplayLocalForecastGraphState extends RaspDataState {
  final LocalForecastInputData localForecastGraphData;
  DisplayLocalForecastGraphState(this.localForecastGraphData);
}

class RaspWorkingState extends RaspDataState {
  final bool working;
  RaspWorkingState({required this.working});
}

class BeginnerModeState extends RaspDataState{
  final bool beginnerMode ;

  BeginnerModeState(this.beginnerMode);
}

class BeginnerForecastDateModelState extends RaspDataState {
  final String date;
  final String model;
  BeginnerForecastDateModelState (this.date, this.model);
}

class OptimizedTaskRouteState extends RaspDataState {
  final  OptimizedTaskRoute optimizedTaskRoute;
  OptimizedTaskRouteState (this.optimizedTaskRoute);
}
