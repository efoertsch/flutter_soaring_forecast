import 'dart:core';

import 'package:latlong2/latlong.dart';

class LatLngForecast {
  final LatLng latLng;
  final String forecastText;

  LatLngForecast({required this.latLng, required this.forecastText}) {}

  LatLng getLatLng() {
    return latLng;
  }

  String getForecastText() {
    return forecastText;
  }
}
