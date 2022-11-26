class ForecastInputData {
  final String region;
  final String date;
  final String model;
  final List<String> times;
  final double lat;
  final double lng;
  final String? turnpointName;

  ForecastInputData(
      {required this.region,
      required this.date,
      required this.model,
      required this.times,
      required this.lat,
      required this.lng,
      this.turnpointName = null});
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
  final String? turnpointTitle;
  final double? lat;
  final double? lng;
  final List<Map<String, Object>> altitudeData;
  final List<Map<String, Object>> thermalData;
  final List<String> hours;
  final List<String> descriptions;
  final List<List<String>> gridData;

  ForecastGraphData(
      {this.turnpointTitle = null,
      required this.altitudeData,
      required this.thermalData,
      required this.hours,
      required this.descriptions,
      required this.gridData,
      this.lat,
      this.lng});
}
