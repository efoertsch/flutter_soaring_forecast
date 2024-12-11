import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/LatLngForecast.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/estimated_flight_avg_summary.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:latlong2/latlong.dart';

import '../../local_forecast/bloc/local_forecast_graph.dart';
import '../../repository/rasp/regions.dart';


@immutable
abstract class RaspDataState {}

class RaspInitialState extends RaspDataState {
  final state = "RaspInitialState";

  @override
  String toString() => state;
}

// List of forecast model (eg. 'Thermal updraft velocity & B/S Ratio', 'B/L Top', etc )
class RaspForecasts extends RaspDataState {
  final List<Forecast> forecasts;
  final Forecast selectedForecast;

  RaspForecasts(this.forecasts, this.selectedForecast);
}


class RaspTimeState extends RaspDataState {
  final String forecastTime;

  RaspTimeState(this.forecastTime);
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

class DisplayLocalForecastGraphState extends RaspDataState {
  final LocalForecastInputData localForecastGraphData;

  DisplayLocalForecastGraphState(this.localForecastGraphData);
}

class RaspWorkingState extends RaspDataState {
  final bool working;

  RaspWorkingState({required this.working});
}


class RunForecastAnimationState extends RaspDataState{
  final bool runAnimation;

  RunForecastAnimationState(this.runAnimation);
}

class BeginnerForecastDateModelState extends RaspDataState {
  final String date;
  final String model;

  BeginnerForecastDateModelState(this.date, this.model);
}

class EstimatedFlightSummaryState extends RaspDataState {
  final EstimatedFlightSummary? estimatedFlightSummary;

  EstimatedFlightSummaryState(this.estimatedFlightSummary);
}

class ShowEstimatedFlightButton extends RaspDataState {
  final bool showEstimatedFlightButton;

  ShowEstimatedFlightButton(this.showEstimatedFlightButton);
}

class ForecastBoundsState extends RaspDataState  {
  final LatLngBounds latLngBounds;

  ForecastBoundsState(this.latLngBounds);
}