import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/LatLngForecast.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';

import '../forecast_data/LatLngForecast.dart';

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

// GFS, NAM, etc and the default (or previously saved selected model
class RaspForecastModels extends RaspDataState {
  final List<String> modelNames;
  final String selectedModelName;
  RaspForecastModels(this.modelNames, this.selectedModelName);

  @override
  List<Object?> get props => [modelNames, selectedModelName];
}

//  list of forecast dates available for hte selected forecast model and the
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

class RaspMapLatLngBounds extends RaspDataState {
  final LatLngBounds latLngBounds;
  RaspMapLatLngBounds(this.latLngBounds);

  @override
  List<Object?> get props => [latLngBounds];
}

class RaspForecastTime extends RaspDataState {
  final String forecastTime;
  RaspForecastTime(this.forecastTime);

  @override
  List<Object?> get props => [forecastTime];
}

class RaspDataLoadErrorState extends RaspDataState {
  final String error;
  RaspDataLoadErrorState(this.error);

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

class RaspForecastImageDisplay extends RaspDataState {
  final SoaringForecastImageSet soaringForecastImageSet;
  RaspForecastImageDisplay(this.soaringForecastImageSet);

  @override
  List<Object?> get props => [soaringForecastImageSet];
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
  // TODO: implement props
  List<Object?> get props => [soundings];
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
  // TODO: implement props
  List<Object?> get props => [displayOptions];
}
