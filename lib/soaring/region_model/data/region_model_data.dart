class RaspModelDateChange {
  final String regionName;
  final String model;
  final String date;
  final List<String> times;

  RaspModelDateChange(this.regionName, this.model, this.date, this.times);
}

class EstimatedTaskRegionModel {
  final String regionName;
  final String selectedModelName;
  final String selectedDate;
  final String selectedHour ;

  EstimatedTaskRegionModel(
      {required this.regionName,
      required this.selectedModelName,
      required this.selectedDate,
      required this.selectedHour,
      });

  @override
  List<Object?> get props => [
        regionName,
        selectedModelName,
        selectedDate,
        selectedHour,

      ];
}
