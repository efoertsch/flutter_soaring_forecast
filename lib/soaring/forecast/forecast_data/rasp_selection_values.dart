import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/json/forecast_types.dart';

class RaspSelectionValues {
  List<String>? modelNames;
  String? selectedModelName;
  List<String>? forecastDates;
  String? selectedForecastDate;
  List<String>? forecastTimes;
  int? selectedForecastTimeIndex;
  List<Forecast>? forecasts;
  Forecast? selectedForecast;
  LatLngBounds? latLngBounds;
  RaspSelectionValues({
    this.modelNames,
    this.selectedModelName,
    this.forecastDates,
    this.selectedForecastDate,
    this.forecastTimes,
    this.selectedForecastTimeIndex,
    this.forecasts,
    this.selectedForecast,
    this.latLngBounds,
  });
}
