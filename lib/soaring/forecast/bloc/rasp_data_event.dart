import 'package:flutter_soaring_forecast/soaring/json/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/json/regions.dart';

/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
/// Event In - State Out
abstract class RaspDataEvent {}

// All the events that can trigger getting a rasp forecast

class GetInitialRaspSelections extends RaspDataEvent {
  GetInitialRaspSelections();
}

class SelectedRaspModel extends RaspDataEvent {
  final String modelName;
  SelectedRaspModel(this.modelName);
}

class SelectedRaspRegion extends RaspDataEvent {
  final Region region;
  SelectedRaspRegion(this.region);
}

class SetRaspForecastDate extends RaspDataEvent {
  final String forecastDate;
  SetRaspForecastDate(this.forecastDate);
}

class SetRaspForecastTime extends RaspDataEvent {
  final String forecastTime;
  SetRaspForecastTime(this.forecastTime);
}

class SetRaspForecastType extends RaspDataEvent {
  final ForecastType forecastType;
  SetRaspForecastType(this.forecastType);
}

/// Tell bloc to load all forecast types
class LoadForecastTypes extends RaspDataEvent {
  LoadForecastTypes();
}

/// Tell bloc to retrieve the forecast for given parms
class LoadRaspForecast extends RaspDataEvent {
  final String regionName;
  final String forecastModel;
  final String forecastDate;
  final String forecastType;
  LoadRaspForecast(this.regionName, this.forecastModel, this.forecastDate,
      this.forecastType);
}
