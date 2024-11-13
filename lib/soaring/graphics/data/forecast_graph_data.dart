import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';

class LocalForecastInputData {
  final Region region;
  final String date;
  final String model;
  final List<String> times;
  List<LocalForecastPoint> localForecastPoints;
  final int startIndex;

  LocalForecastInputData(
      {required this.region,
      required this.date,
      required this.model,
      required this.times,
      required this.localForecastPoints,
      this.startIndex = -1});
}

class LocalForecastPoint {
  final double lat;
  final double lng;
  final String? turnpointName;
  final String? turnpointCode;

  LocalForecastPoint(
      {required this.lat,
      required this.lng,
      this.turnpointName,
      this.turnpointCode});
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
  List<PointForecastGraphData> pointForecastsGraphData;
  final int startIndex;
  final double maxAltitude;
  final double maxThermalStrength;

  ForecastGraphData(
      {required this.model,
      required this.date,
      required this.pointForecastsGraphData,
      required this.startIndex,
      required this.maxAltitude,
      required this.maxThermalStrength});
}

class PointForecastGraphData {
  final String? turnpointTitle;
  final String? turnpointCode;
  final double? lat;
  final double? lng;
  final List<Map<String, Object>> altitudeData;
  final List<Map<String, Object>> thermalData;
  final List<String> hours;
  final List<Forecast> descriptions;
  final List<List<String>> gridData;

  PointForecastGraphData(
      {this.turnpointTitle = null,
      this.turnpointCode = null,
      required this.altitudeData,
      required this.thermalData,
      required this.hours,
      required this.descriptions,
      required this.gridData,
      this.lat,
      this.lng});
}

class LocalForecastOutputData {
  final String model;
  final String date;

  LocalForecastOutputData({
    required this.model,
    required this.date,
  });
}
