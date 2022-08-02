import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';
import 'package:latlong2/latlong.dart';

/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
/// Event In - State Out
@immutable
abstract class RaspDataEvent {}

// All the events that can trigger getting a rasp forecast

class InitialRaspRegionEvent extends RaspDataEvent {
  InitialRaspRegionEvent();
}

class SelectedRaspModelEvent extends RaspDataEvent {
  final String modelName;
  SelectedRaspModelEvent(this.modelName);
}

class SelectedRaspRegion extends RaspDataEvent {
  final Region region;
  SelectedRaspRegion(this.region);
}

class SelectRaspForecastDateEvent extends RaspDataEvent {
  final String forecastDate;
  SelectRaspForecastDateEvent(this.forecastDate);
}

class SetRaspForecastTime extends RaspDataEvent {
  final String forecastTime;
  SetRaspForecastTime(this.forecastTime);
}

class SelectedRaspForecastEvent extends RaspDataEvent {
  final Forecast forecast;
  SelectedRaspForecastEvent(this.forecast);
}

class SetRaspForecastType extends RaspDataEvent {
  final ForecastType forecastType;
  SetRaspForecastType(this.forecastType);
}

// Used to flip through forecasts based on the time
class NextTimeEvent extends RaspDataEvent {
  NextTimeEvent();
}

// Go back to previous time
class PreviousTimeEvent extends RaspDataEvent {
  PreviousTimeEvent();
}

/// Tell bloc to load all forecast types
class LoadForecastTypes extends RaspDataEvent {
  LoadForecastTypes();
}

class RunAnimationEvent extends RaspDataEvent {
  final bool runAnimation;
  RunAnimationEvent(this.runAnimation);
}

// Ask bloc to get the task turnpoints for plotting on map
class GetTaskTurnpointsEvent extends RaspDataEvent {
  final int taskId;
  GetTaskTurnpointsEvent(this.taskId);
}

// clear task/turnpoints from map
class ClearTaskEvent extends RaspDataEvent {
  ClearTaskEvent();
}

class MapReadyEvent extends RaspDataEvent {
  MapReadyEvent();
}

class DisplayTaskTurnpointEvent extends RaspDataEvent {
  final TaskTurnpoint taskTurnpoint;
  DisplayTaskTurnpointEvent(this.taskTurnpoint);
  @override
  List<Object?> get props => [taskTurnpoint];
}

class DisplayLocalForecastEvent extends RaspDataEvent {
  final LatLng latLng;
  DisplayLocalForecastEvent(this.latLng);
  @override
  List<Object?> get props => [latLng];
}

class RedisplayMarkersEvent extends RaspDataEvent {
  RedisplayMarkersEvent();
  @override
  List<Object?> get props => [];
}

class SaveRaspDisplayOptionsEvent extends RaspDataEvent {
  final PreferenceOption displayOption;
  SaveRaspDisplayOptionsEvent(this.displayOption);
  @override
  List<Object?> get props => [displayOption];
}

class NewLatLngBoundsEvent extends RaspDataEvent {
  final LatLngBounds latLngBounds;
  NewLatLngBoundsEvent(LatLngBounds this.latLngBounds);
  @override
  List<Object?> get props => [latLngBounds];
}

class DisplayTurnointsEvent extends RaspDataEvent {
  final LatLngBounds latLngBounds;

  DisplayTurnointsEvent(this.latLngBounds);

  @override
  List<Object?> get props => [latLngBounds];
}

class DisplaySoundingsEvent extends RaspDataEvent {
  final Soundings sounding;

  DisplaySoundingsEvent(this.sounding);
  @override
  List<Object?> get props => [sounding];
}

// Used when closing soundings display and go back to displaying forecast images
class DisplayCurrentForecastEvent extends RaspDataEvent {
  DisplayCurrentForecastEvent();
  @override
  List<Object?> get props => [];
}
