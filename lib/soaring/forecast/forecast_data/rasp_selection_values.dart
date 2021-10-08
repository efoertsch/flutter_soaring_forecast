import 'package:flutter_soaring_forecast/soaring/json/forecast_types.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
