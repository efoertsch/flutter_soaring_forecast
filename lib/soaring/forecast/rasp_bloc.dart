import 'dart:async';

import 'package:flutter_soaring_forecast/soaring/json/regions.dart';
import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';

/// Based on https://www.raywenderlich.com/4074597-getting-started-with-the-bloc-pattern
///
/// 1. Call .../rasp/current.json to get regions, forecast dates and soundings
///    for which forecasts available
/// 2. For selected region (either default to 'initialRegion' or region stored
///    in preferences and first forecast date call (for example)
///    .../raps/NewEngland/2019-10-09/status.jon to get the forecast models
///    and forecast hours for each model that are available for that date region
///    and date
/// 3. Independent of the above, get the list of forecast types, e.g.
///    Thermal Updraft velocity that are(should be) available for each model.

class RaspBlocOld {
  Repository repository;

  RaspBlocOld() {
    repository = Repository.repository;
  }

  Regions _regions;
  Region _selectedRegion;
  String _selectedRegionName;
  String _selectedForecastModelName;
  List<String> _forecastDates;

  /// Get which region to display forecasts for
  /// If not yet defined call rasp
  String get selectedRegionName {
    if (_selectedRegionName == null) {
      getRaspCurrentJson();
    }
    return _selectedRegionName;
  }

  List<String> _forecastModels;

  /// List of forecast models, e.g. GFS, NAM, ...
  List<String> get forecastModelsList {
    if (_forecastModels == null) {
      getForecastModelsFromRasp(_selectedRegion);
    }
    return List<String>();
  }

  /// Selected forecast model, e.g. GFS
  String get selectedForecastModelName {
    if (_selectedForecastModelName == null) {
      getSelectedForecastModelPreference();
    }
    return _selectedForecastModelName;
  }

  // For each 'reactive' variable above create StreamController, public Stream getter
  // and variable setter and sink

  final _forecastModelsController = StreamController<List<String>>();

  Stream<List<String>> get forecastModelsStream =>
      _forecastModelsController.stream;

  void setForecastModels(List<String> forecastModels) {
    _forecastModels = forecastModels;
    _forecastModelsController.sink.add(forecastModels);
  }

  final _selectedForecastModelController = StreamController<String>();

  Stream<String> get selectedForecastModelStream =>
      _selectedForecastModelController.stream;

  void setSelectedForecastModel(String forecastModelName) {
    _selectedForecastModelName = forecastModelName;
    _selectedForecastModelController.sink.add(forecastModelName);
  }

  @override
  void dispose() {
    _forecastModelsController.close();
    _selectedForecastModelController.close();
  }

  String getSelectedForecastModelPreference() {
    // get selected from shared preferences
    return 'GFS';
  }

  Future<Region> getForecastModelsFromRasp(Region region) async {
    await repository.loadForecastModelsByDateForRegion(region);
    return new Future<Region>.value(region);
  }

  String getSelectedRegionNamePreference() {
    // get region from repository/shared preferences
    return 'NewEngland';
  }

  void getRaspCurrentJson() async {
    _regions = await repository.getRegions();
    _selectedRegionName = getSelectedRegionNamePreference();
    if (_selectedRegionName == null) {
      _selectedRegionName = _regions.initialRegion;
    }
    for (Region region in _regions.regions) {
      if (region.name == _selectedRegionName) {
        getForecastModelsForSelectedRegionDate(region);
        break;
      }
    }
  }

  /// For each date, get forecast models for that date
  void getForecastModelsForSelectedRegionDate(Region region) async {
    _selectedRegion =
        await repository.loadForecastModelsByDateForRegion(region);
    // get list of models for the first date
    setForecastModels(_selectedRegion.getForecastModelNames(0));
  }
}
