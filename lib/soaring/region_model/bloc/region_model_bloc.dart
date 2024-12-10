import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/constants.dart';
import '../../repository/rasp/forecast_models.dart';
import '../../repository/rasp/regions.dart';
import '../../repository/repository.dart';
import 'region_model_event.dart';
import 'region_model_state.dart';

class RegionModelBloc extends Bloc<RegionModelEvent, RegionModelState> {
  final Repository repository;
  Regions? _regions;
  Region? _region;
  String _regionName = "";
  List<String> _modelNames = []; // gfs, nam, rap, hrr
  String? _selectedModelName; // nam
  ModelDates? _selectedModelDates; // all dates/times for the selected model
  List<String> _forecastDates = []; // array of dates like  2019-12-19
  String? _selectedForecastDate; // selected date  2019-12-19
  List<String> _forecastTimes = [];
  int _selectedForecastTimeIndex = 4; // 1300?
  String? _selectedTime;

  // region determines lat/lng bounds
  LatLngBounds? _regionLatLngBounds;
  LatLng? _centerOfRegion = NewEnglandMapCenter;

  // For a 'simple' forecast where forecast model selected based on date and best(?) model
  // available for the date
  // Models selected should be in order of hrrr, rap, nam, gfs
  bool _beginnerMode = true;
  ModelDateDetail? _beginnerModeModelDataDetail;

  List<ModelDateDetail> _beginnerModelDateDetailList = [];

  RegionModelBloc({required this.repository})
      : super(RegionModelInitialState()) {
    on<InitialRegionModelEvent>(_processInitialRegionModelEvent);
    on<RegionChangedEvent>(_processRegionChangedEvent);
    on<ModelChangeEvent>(_processModelChangeEvent);
    on<DateChangeEvent>(_processDateChangeEvent);
    on<BeginnerModeEvent>(_processBeginnerModeEvent);
  }

  Future<void> _processInitialRegionModelEvent(_,
      Emitter<RegionModelState> emit) async {
    emit(WorkingState(working: true));
    try {
      if (_regions == null) {
        _regions = await this.repository.getRegions();
      }
      if (_regions != null) {
        await _loadSelectRegionInfo();
        // Now get the model (gfs/etc)
        await _loadForecastInfoForRegion();
        await _getSelectedModelDates();
        // need to get all dates before you can generate the list of models
        _setRegionModelNames();
        // on startup default mode is first on list
        _selectedModelName = _selectedModelDates!.modelName!;
        // get default time to start displaying forecast
        await _getDefaultForecastTime();
        _beginnerMode = await repository.isBeginnerForecastMode();
        _emitRaspModelsAndDates(emit);
        _emitCenterOfRegion(emit);
        emit(WorkingState(working: false));
        repository.saveLastForecastTime(DateTime
            .now()
            .millisecondsSinceEpoch);
      }
    } catch (e, stackTrace) {
      print("Error:  ${e.toString()} \n${stackTrace.toString()}");
      emit(WorkingState(working: false));
      emit(ErrorState(
          "Unexpected error occurred executing to get forecast model/date/time data :\n${e
              .toString()}"));
    }
  }

  Future<void> _loadSelectRegionInfo() async {
    final selectedRegionName = await repository.getSelectedRegionName();
    _region = _regions!.regions!
        .firstWhereOrNull((region) => (region.name == selectedRegionName))!;
    _regionName = _region?.name ?? "";
  }

  void _processDateEvent(DateChangeEvent event,
      Emitter<RegionModelState> emit) async {
    if (_forecastDates.contains(event.forecastDate) &&
        event.forecastDate != _selectedForecastDate) {
      _selectedForecastDate = event.forecastDate;
      _emitRaspModelsAndDates(emit);
      // update times and images for new date
      _setForecastTimesForDate();
      _emitRaspModelsAndDates(emit);
    }
  }

  Future<void> _processModelChange(String modelName,
      Emitter<RegionModelState> emit) async {
    if (_modelNames.contains(modelName) && modelName != _selectedModelName) {
      _selectedModelName = modelName;
      // print('Selected model: $_selectedModelname');
      // emits same list of models with new selected model
      _getDatesForSelectedModel();
      _emitRaspModelsAndDates(emit);
    }
  }

  // A new model (e.g. nam) has been selected OR switched from beginner to expert
  // and need to update list of dates for the model
  // so get new dates and times for selected model
  void _getDatesForSelectedModel() {
    // first get the set of dates available for the model
    _selectedModelDates = _region!
        .getModelDates()
        .firstWhere((modelDate) => modelDate.modelName == _selectedModelName);
    // then get the display dates, the date to initially display for the model
    // (and also set the forecast times for that date)
    _updateForecastDates();
  }

  Future<Region> _loadForecastInfoForRegion() async {
    return await this.repository.loadForecastModelsByDateForRegion(_region!);
  }

  Future<void> _getSelectedModelDates() async {
    _region = await repository.loadForecastModelsByDateForRegion(_region!);
    // TODO - get last model (gfs, name) from repository and display
    _selectedModelDates = _region!.getModelDates().first;
    _updateForecastDates();
  }

  void _setRegionModelNames() {
    _modelNames.clear();
    _modelNames.addAll(_region!
        .getModelDates()
        .map((modelDates) => modelDates.modelName!)
        .toList());
  }

  Future<void> _getDefaultForecastTime() async {
    String defaultTime = await repository.getDefaultForecastTime();
    _selectedForecastTimeIndex = _forecastTimes.isNotEmpty
        ? (_forecastTimes.contains(defaultTime)
        ? _forecastTimes.indexOf(defaultTime)
        : 0)
        : 0;
  }

// Dependent on having _selectedModelDates assigned
  void _updateForecastDates() {
    _setForecastDates();
    // stay on same date if new model has forecast for that date
    if (_selectedForecastDate == null ||
        !_forecastDates.contains(_selectedForecastDate)) {
      _selectedForecastDate = _forecastDates.first;
    }
    _updateForecastTimesList();
  }

// A new date has been selected, so get the times for that date
// Set the time for the new date the same as the previous date if possible
  void _setForecastTimesForDate() {
    var modelDateDetail = _selectedModelDates!
        .getModelDateDetailList()
        .firstWhere((modelDateDetails) =>
    modelDateDetails.date == _selectedForecastDate);
    _forecastTimes = modelDateDetail.model!.times;
    _setSelectedTimeIndex();
  }

  /// Get a list of both display dates (printDates November 12, 2019)
  /// and dates for constructing calls to rasp (dates 2019-11-12)
  void _setForecastDates() {
    List<ModelDateDetail> modelDateDetails =
    _selectedModelDates!.getModelDateDetailList();
    _forecastDates.clear();
    _forecastDates.addAll(modelDateDetails
        .map((modelDateDetails) => modelDateDetails.date!)
        .toList());
  }

  Future<void> _processDateChangeEvent(event,
      Emitter<RegionModelState> emit) async {
    if (_forecastDates.contains(event.forecastDate) &&
        event.forecastDate != _selectedForecastDate) {
      _selectedForecastDate = event.forecastDate;
      _emitRaspModelsAndDates(emit);
      // update times and images for new date
      _setForecastTimesForDate();
      _emitRaspModelsAndDates(emit);
    }
  }

  void _updateForecastTimesList() {
    var modelDateDetail = _selectedModelDates!
        .getModelDateDetailList()
        .firstWhere((modelDateDetails) =>
    modelDateDetails.date == _selectedForecastDate)
        .model;
    _forecastTimes = modelDateDetail!.times;
    // Stay on same time if new forecastTimes has same time as previous
    // Making reasonable assumption that times in same order across models/dates
    _setSelectedTimeIndex();
    // While we are here
    _setLatLngAndCenter(modelDateDetail);
  }

  void _setSelectedTimeIndex() {
    if (_selectedForecastTimeIndex > _forecastTimes!.length - 1) {
      _selectedForecastTimeIndex = 0;
    }
    if (_forecastTimes.length != 0) {
      _selectedTime = _forecastTimes[_selectedForecastTimeIndex];
    } else {
      _selectedTime = "";
    }
  }

  // Go to either previous or next model/date for beginner mode
  FutureOr<void> _processBeginnerDateSwitch(BeginnerDateSwitchEvent event,
      Emitter<RegionModelState> emit) async {
    int? dateIndex = _region?.dates?.indexOf(_selectedForecastDate!);
    if (dateIndex != null) {
      if (event.forecastDateSwitch == ForecastDateChange.previous) {
        _selectedForecastDate = (dateIndex - 1 >= 0)
            ? _region!.dates![dateIndex - 1]
            : _region!.dates!.last;
      } else {
        _selectedForecastDate = (dateIndex + 1 < _region!.dates!.length)
            ? _region!.dates![dateIndex + 1]
            : _region!.dates!.first;
      }
    }
    _getBeginnerModeDateDetails();
    _selectedModelName = _beginnerModeModelDataDetail?.model?.name ?? "Unknown";
    if (_beginnerModeModelDataDetail != null) {
      _emitRaspModelsAndDates(emit);
    }
    // we need to keep values in sync for 'expert' mode if user switches to that mode
    _getDatesForSelectedModel();
  }

  // Set the forecast date (yyyy-mm-dd)
  // Search in order for HRRR, RAP, NAM, GFS
  void _getBeginnerModeDateDetails() {
    ModelDateDetail? modelDateDetails;
    // iterate through models to  to see if forecast ex
    for (var model in ModelsEnum.values) {
      modelDateDetails =
          _region?.doModelDateDetailsExist(model.name, _selectedForecastDate!);
      if (modelDateDetails != null) {
        // okay the 'best' model for that date has been found
        // get the times available for that model
        _forecastTimes = modelDateDetails.model!.times;
        _setSelectedTimeIndex();
        // While we are here
        _setLatLngAndCenter(modelDateDetails.model!);
        break;
      }
    }
  }


  // Implement if you want a horizontal scrollable list of 'beginner' models/dates
  // Untested - likely needing some debugging.
  // get a complete list of model/dates for 'beginner mode'
  // Eg, should get a list of ModelDateDetails something like:
  // hrrr, current date  (or rap, current date if hrrr not available yet
  // nam,  current date + 1
  //nam, current date + 2
  //gfs, current date + 3,4,...
  void _getAllBeginnerForecastDates() {
    _beginnerModelDateDetailList.clear();
    // get all the gfs model dates
    List<ModelDateDetail>? gfsModelDateDetails = _region!
        .getModelDates()
        .firstWhereOrNull(
            (modeldate) => modeldate.modelName == ModelsEnum.gfs.toString())
        ?.modelDateDetailList;
    // for each date in gfs, find the first one available in order from hrr, rap, nam
    for (var gfsModelDateDetail in gfsModelDateDetails!) {
      // this loop should look first for hrr, rap, nam, then gfs for the specified date
      for (var model in ModelsEnum.values) {
        // first get the list of model date details for the model
        ModelDateDetail? modelDateDetail = _region!
            .getModelDates()
            .firstWhereOrNull((modeldate) => modeldate.modelName == model)
            ?.modelDateDetailList
            .firstWhereOrNull((modelDateDetail) =>
        modelDateDetail.printDate == gfsModelDateDetail.printDate);
        if (modelDateDetail != null) {
          _beginnerModelDateDetailList.add(modelDateDetail);
          break;
        }
      }
    }
  }

  void _setLatLngAndCenter(Model modelDateDetail) {
    _regionLatLngBounds = modelDateDetail.latLngBounds;
    _centerOfRegion =
        LatLng(modelDateDetail.center[0], modelDateDetail.center[1]);
    emit(ForecastBoundsState(_regionLatLngBounds!));
  }

  void _emitRaspModelsAndDates(Emitter<RegionModelState> emit) {
    int modelNameIndex = _modelNames.indexOf(_selectedModelName!);
    int forecastDateIndex = _forecastDates.indexOf(_selectedForecastDate!);

    emit(ForecastModelsAndDates(
        beginnerMode: _beginnerMode,
        regionName: _regionName,
        modelNames: _modelNames,
        modelNameIndex: modelNameIndex >= 0 ? modelNameIndex : 0,
        forecastDates: _forecastDates,
        forecastDateIndex: forecastDateIndex >= 0 ? forecastDateIndex : 0,
        localTimes: _forecastTimes,
        localTimeIndex: _selectedForecastTimeIndex));
  }


  void _emitCenterOfRegion(Emitter<RegionModelState> emit) {
    emit(CenterOfMapState(_centerOfRegion!));
  }


  FutureOr<void> _processRegionChangedEvent(RegionChangedEvent event,
      Emitter<RegionModelState> emit) async {
    repository.setCurrentTaskId(-1);
    await _refreshForecast(event, emit);
  }

  FutureOr<void> _processModelChangeEvent(ModelChangeEvent event,
      Emitter<RegionModelState> emit) async {
    if (_modelNames.contains(event.modelName) &&
        event.modelName != _selectedModelName) {
      _selectedModelName = event.modelName;
      // print('Selected model: $_selectedModelname');
      // emits same list of models with new selected model
      _getDatesForSelectedModel();
      _emitRaspModelsAndDates(emit);
    }
  }

  FutureOr<void> _processBeginnerModeEvent(BeginnerModeEvent event,
      Emitter<RegionModelState> emit) async {
    _beginnerMode = event.beginnerMode;
    await repository.setBeginnerForecastMode(_beginnerMode);
    if (_beginnerMode) {
      //  switched from expert to beginner
      // keep same date but might need to change the model
      _getBeginnerModeDateDetails();
    } else {
      //  switched from beginner to expert
      // stay on same model and date so just send info to update ui
      // Still need to update available dates/times for the model that you are on
      _getDatesForSelectedModel();
      _emitRaspModelsAndDates(emit);
    }
  }


  Future<void> _refreshForecast(RegionChangedEvent event,
      Emitter<RegionModelState> emit) async {
    await _processInitialRegionModelEvent(event, emit);
  }

  void _emitSoundings(Emitter<RegionModelState> emit) async {
    final preferenceOptions = await repository.getRaspDisplayOptions();
    for (var option in preferenceOptions) {
      switch (option.key) {
        case (soundingsDisplayOption):
          if (option.selected) {
            emit(RegionSoundingsState(_region?.soundings ?? <Soundings>[]));
          } else {
            emit(RegionSoundingsState(<Soundings>[]));
          }
          print('emitted RaspSoundingsState');
          break;
      }
    }
  }
}
