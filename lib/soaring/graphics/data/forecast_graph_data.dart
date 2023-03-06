import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';

class ForecastInputData {
  final Region region;
  final String date;
  final String model;
  final List<String> times;
  final double lat;
  final double lng;
  final String? turnpointName;
  final String? turnpointCode;

  ForecastInputData(
      {required this.region,
      required this.date,
      required this.model,
      required this.times,
      required this.lat,
      required this.lng,
      this.turnpointName = null,
      this.turnpointCode = null}
      );
}

class ForecastData {
  final List<Map<String, Object>> altitudeData;
  final List<Map<String, Object>> thermalData;
  final List<Map<String, Object>> allData;

  ForecastData(
      {required this.altitudeData,
      required this.thermalData,
      required this.allData});
}

class ForecastGraphData {
  final String model;
  final String date;
  final String? turnpointTitle;
  final String? turnpointCode;
  final double? lat;
  final double? lng;
  final List<Map<String, Object>> altitudeData;
  final List<Map<String, Object>> thermalData;
  final List<String> hours;
  final List<Forecast> descriptions;
  final List<List<String>> gridData;

  ForecastGraphData(
      {required this.model,
      required this.date,
      this.turnpointTitle = null,
      this.turnpointCode = null,
      required this.altitudeData,
      required this.thermalData,
      required this.hours,
      required this.descriptions,
      required this.gridData,
      this.lat,
      this.lng});
}
