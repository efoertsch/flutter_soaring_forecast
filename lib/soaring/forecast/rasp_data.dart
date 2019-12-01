class RaspData {
  final List<String> modelNames;
  final String selectedModelName;
  final List<String> forecastDates;
  final String selectedForecastDate;
  final List<String> forecastTypes;
  final String selectedForecastType;
  final List<String> forecastTimes;
  final String selectedForecastTime;

  RaspData(
      this.modelNames,
      this.selectedModelName,
      this.forecastDates,
      this.selectedForecastDate,
      this.forecastTypes,
      this.selectedForecastType,
      this.forecastTimes,
      this.selectedForecastTime);
}
