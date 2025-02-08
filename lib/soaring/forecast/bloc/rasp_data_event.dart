import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';
import 'package:latlong2/latlong.dart';

/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
/// Event In - State Out
///
//TODO consolidate with GraphicEvent
@immutable
abstract class RaspDataEvent {}

// All the events that can trigger getting a rasp forecast

class InitialRaspRegionEvent extends RaspDataEvent {
  InitialRaspRegionEvent();
}

class SwitchedRegionEvent extends RaspDataEvent {
  SwitchedRegionEvent();
}

class SelectedRegionModelDetailEvent extends RaspDataEvent {
  final String region;
  final String modelName;
  final String modelDate;
  final List<String> localTimes;
  final String localTime;

  SelectedRegionModelDetailEvent(
      {required this.region,
      required this.modelName,
      required this.modelDate,
      required this.localTimes,
      required this.localTime});
}

class IncrDecrRaspForecastHourEvent extends RaspDataEvent{
  final int incrDecrIndex;

  IncrDecrRaspForecastHourEvent(this.incrDecrIndex);
}


class SelectedRaspForecastEvent extends RaspDataEvent {
  final Forecast forecast;
  final bool resendForecasts;

  SelectedRaspForecastEvent(this.forecast, {this.resendForecasts = false});
}

class SetRaspForecastType extends RaspDataEvent {
  final ForecastType forecastType;

  SetRaspForecastType(this.forecastType);
}

/// Tell bloc to load all forecast types
class LoadForecastTypesEvents extends RaspDataEvent {
  LoadForecastTypesEvents();
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
}

class DisplayLocalForecastEvent extends RaspDataEvent {
  final LatLng latLng;
  final String? turnpointName;
  final String? turnpointCode;
  final bool forTask;

  DisplayLocalForecastEvent(
      {required this.latLng,
      this.turnpointName,
      this.turnpointCode,
      this.forTask = false});
}

class RedisplayMarkersEvent extends RaspDataEvent {
  RedisplayMarkersEvent();
}

class RaspDisplayOptionsEvent extends RaspDataEvent {
  final List<PreferenceOption> displayOptions;

  RaspDisplayOptionsEvent(this.displayOptions);
}

class RaspDisplayOptionEvent extends RaspDataEvent {
  final PreferenceOption displayOption;

  RaspDisplayOptionEvent(this.displayOption);
}

class ViewBoundsEvent extends RaspDataEvent {
  final LatLngBounds latLngBounds;

  ViewBoundsEvent(this.latLngBounds);
}

class DisplayRaspSoundingsEvent extends RaspDataEvent {
  final Soundings sounding;

  DisplayRaspSoundingsEvent(this.sounding);
}

// Used when closing soundings display and go back to displaying forecast images
class DisplayCurrentForecastEvent extends RaspDataEvent {
  DisplayCurrentForecastEvent();
}

class GetForecastOverlayOpacityEvent extends RaspDataEvent {
  GetForecastOverlayOpacityEvent();
}

class SetForecastOverlayOpacityEvent extends RaspDataEvent {
  final double forecastOverlayOpacity;

  SetForecastOverlayOpacityEvent(this.forecastOverlayOpacity);
}

class RefreshTaskEvent extends RaspDataEvent {}

class ListTypesOfForecastsEvent extends RaspDataEvent {
  ListTypesOfForecastsEvent();
}

class CheckIfForecastRefreshNeededEvent extends RaspDataEvent {
  CheckIfForecastRefreshNeededEvent();
}

//

class ForecastBoundsEvent extends RaspDataEvent {
  final LatLngBounds latLngBounds;

  ForecastBoundsEvent(this.latLngBounds);
}



