import 'package:flutter/foundation.dart';

import '../../app/constants.dart';
import '../../repository/rasp/regions.dart';

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
class PreviousNextDateSwitchEvent extends RegionModelEvent {
  final int incrDecr ;  // 1 to go to next date -1 to go to previous
  PreviousNextDateSwitchEvent(this.incrDecr);
}

class RegionChangeEvent extends RegionModelEvent {}

class BeginnerModeEvent extends RegionModelEvent {
  final bool beginnerMode;

  BeginnerModeEvent(this.beginnerMode);
}

class RegionChangedEvent extends RegionModelEvent {
}


class LocalForecastStartupEvent extends RegionModelEvent {}

class RefreshModelDateEvent extends RegionModelEvent {}

class DisplaySoundingsEvent extends RegionModelEvent {
  final Soundings sounding;

  DisplaySoundingsEvent(this.sounding);
}

class ForecastHourSyncEvent extends RegionModelEvent{
  final int selectedTimeIndex;

  ForecastHourSyncEvent(this.selectedTimeIndex);
}

class EstimatedTaskStartupEvent extends RegionModelEvent {}


class RegionDisplayOptionEvent extends RegionModelEvent {
  final PreferenceOption displayOption;

  RegionDisplayOptionEvent(this.displayOption);
}


class RegionDisplayOptionsEvent extends RegionModelEvent {
  final List<PreferenceOption> displayOptions;

  RegionDisplayOptionsEvent(this.displayOptions);
}