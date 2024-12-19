class TaskRegionModel {
  final String regionName;
  final String date;
  final String model;
  final List<String> times;
  final int selectedTimeIndex;

  TaskRegionModel(
      {required this.regionName,
      required this.date,
      required this.model,
      required this.times,
      required this.selectedTimeIndex});
}
