import 'package:flutter_soaring_forecast/soaring/json/regions.dart';

/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
/// Event In - State Out
abstract class RaspDataEvent {}

// All the events that can trigger getting a rasp forecast

class GetDefaultRaspRegion extends RaspDataEvent {
  GetDefaultRaspRegion();
}

class GetRaspRegion extends RaspDataEvent {
  final Region region;
  GetRaspRegion(this.region);
}

class GetRaspModel extends RaspDataEvent {
  final String raspModel;
  GetRaspModel(this.raspModel);
}

class GetRaspForecastOptions extends RaspDataEvent {
  final Region region;
  GetRaspForecastOptions(this.region);
}

class GetRaspForecastDate extends RaspDataEvent {
  final String forecastDate;
  GetRaspForecastDate(this.forecastDate);
}

class GetRaspForecastTime extends RaspDataEvent {
  final String forecastTime;
  GetRaspForecastTime(this.forecastTime);
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
