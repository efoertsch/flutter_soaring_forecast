import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/json/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/json/regions.dart';

/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
/// Event In - State Out
@immutable
abstract class RaspDataEvent {}

// All the events that can trigger getting a rasp forecast

class GetInitialRaspSelections extends RaspDataEvent {
  GetInitialRaspSelections();
}

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
