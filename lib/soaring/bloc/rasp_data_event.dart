import 'package:flutter_soaring_forecast/soaring/json/regions.dart';

/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
/// Event In - State Out
abstract class RaspDataEvent {}

// All the events that can trigger getting a rasp forecast

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

//
class GetRastForecastType extends RaspDataEvent {
  final String forecastType;
  GetRastForecastType(this.forecastType);
}
