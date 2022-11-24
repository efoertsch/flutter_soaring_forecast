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

class ForecastGraphData {
  final String? turnpointTitle;
  final double? lat;
  final double? lng;
  final List<Map<String, Object>>? altitudeData;
  final List<Map<String, Object>>? thermalData;
  ForecastGraphData(
      {this.turnpointTitle = null,
      this.altitudeData,
      this.thermalData,
      this.lat,
      this.lng});
}
