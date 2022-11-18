class LocalForecastGraphData {
  final String region;
  final String date;
  final String model;
  final List<String> times;
  final double lat;
  final double lng;

  LocalForecastGraphData(
      {required this.region,
      required this.date,
      required this.model,
      required this.times,
      required this.lat,
      required this.lng});
}
