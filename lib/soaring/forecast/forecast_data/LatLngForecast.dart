import 'dart:core';

import 'package:google_maps_flutter/google_maps_flutter.dart';

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
