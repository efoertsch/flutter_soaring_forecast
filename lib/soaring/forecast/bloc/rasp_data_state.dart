import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/LatLngForecast.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/data/forecast_graph_data.dart';
import 'package:flutter_soaring_forecast/soaring/repository/options/special_use_airspace.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/view_bounds.dart';
import 'package:latlong2/latlong.dart';

/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
/// Event In - State Out
///
@immutable
abstract class RaspDataState extends Equatable {}

class RaspInitialState extends RaspDataState {
  final state = "RaspInitialState";

  @override
  String toString() => state;

  @override
  List<Object?> get props => [state];
}

class SelectedRegionNameState extends RaspDataState {
  final String selectedRegionName;

  SelectedRegionNameState(this.selectedRegionName);

  @override
  List<Object?> get props => [selectedRegionName];
}

// GFS, NAM, etc and the default (or previously saved selected model
class RaspForecastModels extends RaspDataState {
  final List<String> modelNames;
  final String selectedModelName;

  RaspForecastModels(this.modelNames, this.selectedModelName);

  @override
  List<Object?> get props => [modelNames, selectedModelName];
}

//  list of forecast dates available for the selected forecast model and the
//  default selected date.
class RaspModelDates extends RaspDataState {
  final List<String> forecastDates; // array of dates like  2019-12-19
  final String selectedForecastDate;

  RaspModelDates(this.forecastDates, this.selectedForecastDate);

  @override
  List<Object?> get props => [forecastDates, selectedForecastDate];
}

// List of forecast model (eg. 'Thermal updraft velocity & B/S Ratio', 'B/L Top', etc )
class RaspForecasts extends RaspDataState {
  final List<Forecast> forecasts;
  final Forecast selectedForecast;

  RaspForecasts(this.forecasts, this.selectedForecast);

  @override
  List<Object?> get props => [forecasts, selectedForecast];
}

class ForecastBoundsState extends RaspDataState {
  final LatLngBounds latLngBounds;

  ForecastBoundsState(this.latLngBounds);

  @override
  List<Object?> get props => [latLngBounds];
}

class CenterOfMapState extends RaspDataState {
  final LatLng latLng;

  CenterOfMapState(this.latLng);

  @override
  List<Object?> get props => [latLng];
}

class ViewBoundsState extends RaspDataState {
  final ViewBounds viewBounds;

  ViewBoundsState(this.viewBounds);

  @override
  List<Object?> get props => [viewBounds];
}

class RaspForecastTime extends RaspDataState {
  final String forecastTime;

  RaspForecastTime(this.forecastTime);

  @override
  List<Object?> get props => [forecastTime];
}

class RaspErrorState extends RaspDataState {
  final String error;

  RaspErrorState(this.error);

  @override
  List<Object?> get props => [error];
}

class RaspForecastTypesLoaded extends RaspDataState {
  final List<Forecast> forecasts;

  RaspForecastTypesLoaded(this.forecasts);

  @override
  List<Object?> get props => [forecasts];
}

//TODO add stacktrace?
class RaspMapLatLngBoundsError extends RaspDataState {
  static const boundsError = 'Error creating Google Map Lat/Lng bounds';

  @override
  String toString() => boundsError;

  @override
  List<Object?> get props => [boundsError];
}

class RaspForecastImageSet extends RaspDataState {
  final SoaringForecastImageSet soaringForecastImageSet;
  final int displayIndex;
  final int numberImages;

  RaspForecastImageSet(
      this.soaringForecastImageSet, this.displayIndex, this.numberImages);

  @override
  List<Object?> get props =>
      [soaringForecastImageSet, displayIndex, numberImages];
}

class RaspTaskTurnpoints extends RaspDataState {
  final List<TaskTurnpoint> taskTurnpoints;

  RaspTaskTurnpoints(this.taskTurnpoints);

  @override
  List<Object?> get props => [taskTurnpoints];
}

// Turnpoint based on TaskTurnpoint
class TurnpointFoundState extends RaspDataState {
  final Turnpoint turnpoint;

  TurnpointFoundState(this.turnpoint);

  @override
  List<Object?> get props => [turnpoint];
}

class LocalForecastState extends RaspDataState {
  final LatLngForecast latLngForecast;

  LocalForecastState(this.latLngForecast);

  @override
  List<Object?> get props => [latLngForecast];
}

class RedisplayMarkersState extends RaspDataState {
  RedisplayMarkersState();

  @override
  List<Object?> get props => [];
}

class RaspSoundingsState extends RaspDataState {
  final List<Soundings> soundings;

  RaspSoundingsState(this.soundings);

  @override
  List<Object?> get props => [soundings];
}

class SoundingForecastImageSet extends RaspDataState {
  final SoaringForecastImageSet soaringForecastImageSet;
  final int displayIndex;
  final int numberImages;

  SoundingForecastImageSet(
      this.soaringForecastImageSet, this.displayIndex, this.numberImages);

  @override
  List<Object?> get props =>
      [soaringForecastImageSet, displayIndex, numberImages];
}

class TurnpointsInBoundsState extends RaspDataState {
  final List<Turnpoint> turnpoints;

  TurnpointsInBoundsState(this.turnpoints);

  @override
  List<Object?> get props => [turnpoints];
}

class RaspDisplayOptionsState extends RaspDataState {
  final List<PreferenceOption> displayOptions;

  RaspDisplayOptionsState(this.displayOptions);

  @override
  List<Object?> get props => [displayOptions];
}

class SuaDetailsState extends RaspDataState {
  final SUA suaDetails;

  SuaDetailsState(this.suaDetails);

  @override
  List<Object?> get props => [suaDetails.toString()];
}

class ForecastOverlayOpacityState extends RaspDataState {
  final double opacity;

  ForecastOverlayOpacityState(this.opacity);

  @override
  List<Object?> get props => [opacity];
}

class RegionsLoadedState extends RaspDataState {
  final List<String> regions;

  RegionsLoadedState(this.regions);

  @override
  List<Object?> get props => [regions];
}

class DisplayLocalForecastGraphState extends RaspDataState {
  final ForecastInputData localForecastGraphData;
  DisplayLocalForecastGraphState(this.localForecastGraphData);
  @override
  List<Object?> get props => [localForecastGraphData];
}

class RaspWorkingState extends RaspDataState {
  final bool working;
  RaspWorkingState({required this.working});

  @override
  List<Object?> get props => [working];
}
