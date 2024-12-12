import 'package:flutter/foundation.dart';

import '../../app/constants.dart';

@immutable
abstract class RegionModelEvent {}

// All the events that can trigger getting a rasp forecast

class InitialRegionModelEvent extends RegionModelEvent {
  InitialRegionModelEvent();
}

class ModelChangeEvent extends RegionModelEvent {
  final String modelName;

  ModelChangeEvent(this.modelName);
}

// to a specific date
class DateChangeEvent extends RegionModelEvent {
  final String forecastDate;

  DateChangeEvent(this.forecastDate);
}

// for beginner mode, go to next or previous model/date
class BeginnerDateSwitchEvent extends RegionModelEvent {
  final ForecastDateChange forecastDateSwitch;

  BeginnerDateSwitchEvent(this.forecastDateSwitch);
}

class BeginnerModeEvent extends RegionModelEvent {
  final bool beginnerMode;

  BeginnerModeEvent(this.beginnerMode);
}


class RegionChangedEvent extends RegionModelEvent {
  RegionChangedEvent();
}


class CheckIfForecastRefreshNeededEvent extends RegionModelEvent {
  CheckIfForecastRefreshNeededEvent();
}


class LocalForecastStartupEvent extends RegionModelEvent {
}

