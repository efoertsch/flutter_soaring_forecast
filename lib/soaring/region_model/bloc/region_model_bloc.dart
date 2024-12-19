import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/region_model/data/region_model_data.dart';
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
  Model? _selectedModel;
  ModelDates? _selectedModelDates; // all dates/times for the selected model
  List<String> _forecastDates = []; // array of dates like  2019-12-19
  String? _selectedForecastDate; // selected date  2019-12-19
  List<String> _forecastTimes = [];
  int _selectedForecastTimeIndex = 4; // 1300?

  // region determines lat/lng bounds
  LatLngBounds? _regionLatLngBounds;
  LatLng? _centerOfRegion = NewEnglandMapCenter;

  // For a 'simple' forecast where forecast model selected based on date and best(?) model
  // available for the date
  // Models selected should be in order of hrrr, rap, nam, gfs
  bool _beginnerMode = true;
  ModelDateDetail? _beginnerModeModelDataDetail;
  List<ModelDateDetail> _beginnerModelDateDetailList = [];
  bool _displaySoundings = false;
  bool _displaySua = false;

  RegionModelBloc({required this.repository})
      : super(RegionModelInitialState()) {
    on<InitialRegionModelEvent>(_processInitialRegionModelEvent);
    on<BeginnerDateSwitchEvent>(_processBeginnerDateSwitch);
    on<RegionChangedEvent>(_processRegionChangedEvent);
    on<ModelChangeEvent>(_processModelChangeEvent);
    on<DateChangeEvent>(_processDateChangeEvent);
    on<BeginnerModeEvent>(_processBeginnerModeEvent);
    on<LocalForecastStartupEvent>(_processLocalForecastStartupEvent);
    on<LocalForecastUpdateEvent>(_processLocalForecastUpdateEvent);
    on<RegionDisplayOptionEvent>(_processRegionDisplayOptionEvent);
    on<RegionDisplayOptionsEvent>(_processRegionDisplayOptionsEvent);
    on<EstimatedTaskStartupEvent>(_processEstimatedTaskStartupEvent);
    on<ForecastHourSyncEvent>(_processForecastHourSyncEvent);
  }

  // I am sure this logic to find the appropriate model/dates/times/center/bounds etc.
  // can be simplified
  Future<void> _processInitialRegionModelEvent(
      _, Emitter<RegionModelState> emit) async {
    emit(WorkingState(working: true));
    try {
      if (_regions == null) {
        _regions = await this.repository.getRegions();
      }
      if (_regions != null) {
        await _loadSelectRegionInfo();
        // Now get the models (gfs/etc)
        await _loadForecastInfoForRegion();
        await _getSelectedModelDates();
        _beginnerMode = await repository.isBeginnerForecastMode();
        if (_beginnerMode) {
          _selectedForecastDate = _region?.dates?.first;
          _getBeginnerModeDateDetails();
          _getSelectedModelBasedOnForecastDate();
          _setForecastTimesBasedOnSelectedModel();
          if (_beginnerModeModelDataDetail == null) {
            emit(WorkingState(working: false));
            emit(ErrorState(
                "Hmmm. No forecast models available! Please check main RASP site to see if issue there also"));
            return;
          }
        } else {
          _getSelectedModelBasedOnForecastDate();
          _setForecastTimesBasedOnSelectedModel();
        }
        await _getDefaultForecastTime();
        _setSelectedTimeIndex();
        _emitRaspModelsAndDates(emit);
        _setLatLngAndCenter();
        _emitCenterOfRegion(emit);
        _emitRegionBounds(emit);
        emit(WorkingState(working: false));
        repository.saveLastForecastTime(DateTime.now().millisecondsSinceEpoch);
      }
    } catch (e, stackTrace) {
      print("Error:  ${e.toString()} \n${stackTrace.toString()}");
      emit(WorkingState(working: false));
      emit(ErrorState(
          "Unexpected error occurred executing to get forecast model/date/time data :\n${e.toString()}"));
    }
  }

  void _emitRegionBounds(Emitter<RegionModelState> emit) =>
      emit(RegionLatLngBoundsState(_regionLatLngBounds!));

  Future<void> _loadSelectRegionInfo() async {
    final selectedRegionName = await repository.getSelectedRegionName();
    _region = _regions!.regions!
        .firstWhereOrNull((region) => (region.name == selectedRegionName))!;
    _regionName = _region?.name ?? "";
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

  Future<void> _loadForecastInfoForRegion() async {
    _region = await this.repository.loadForecastModelsByDateForRegion(_region!);
    _setRegionModelNames();
  }

  Future<void> _getSelectedModelDates() async {
    _region = await repository.loadForecastModelsByDateForRegion(_region!);
    // Get the first model on the list
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
  }

// A new date has been selected, so get the times for that date
// Set the time for the new date the same as the previous date if possible
//   void _setForecastTimesForDate() {
//     var modelDateDetail = _selectedModelDates!
//         .getModelDateDetailList()
//         .firstWhere((modelDateDetails) =>
//             modelDateDetails.date == _selectedForecastDate);
//     _forecastTimes = modelDateDetail.model!.times;
//     _setSelectedTimeIndex();
//   }

  /// Get a list of dates for constructing calls to rasp (dates 2019-11-12)
  void _setForecastDates() {
    List<ModelDateDetail> modelDateDetails =
        _selectedModelDates!.getModelDateDetailList();
    _forecastDates.clear();
    _forecastDates.addAll(modelDateDetails
        .map((modelDateDetails) => modelDateDetails.date!)
        .toList());
  }

  Future<void> _processDateChangeEvent(
      event, Emitter<RegionModelState> emit) async {
    if (_forecastDates.contains(event.forecastDate) &&
        event.forecastDate != _selectedForecastDate) {
      _selectedForecastDate = event.forecastDate;
      _emitRaspModelsAndDates(emit);
    }
  }

  // Dependent on having selectedModel assigned
  void _setForecastTimesBasedOnSelectedModel() {
    _forecastTimes = _selectedModel!.times;
  }

  // This assigns the first model based for the selected date, in other places the
  // selectedModel is assigned based on some other criteria
  void _getSelectedModelBasedOnForecastDate() {
    ModelDateDetail? modelDateDetail = _selectedModelDates!
        .getModelDateDetailList()
        .firstWhereOrNull((modelDateDetails) =>
            modelDateDetails.date == _selectedForecastDate);
    _selectedModel = modelDateDetail != null ? modelDateDetail.model : null;
    _selectedModelName = _selectedModel != null ? _selectedModel!.name : "";
  }

  void _setSelectedTimeIndex() {
    if (_selectedForecastTimeIndex > _forecastTimes.length - 1) {
      _selectedForecastTimeIndex = 0;
    }
  }

  // Go to either previous or next model/date for beginner mode
  FutureOr<void> _processBeginnerDateSwitch(
      BeginnerDateSwitchEvent event, Emitter<RegionModelState> emit) async {
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
      _emitCenterOfRegion(emit);
      _emitRegionBounds(emit);
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
        _selectedModel = modelDateDetails.model!;
        _selectedModelName = _selectedModel!.name;
        _beginnerModeModelDataDetail = modelDateDetails;
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

  // selectedModel must of course be assigned first
  void _setLatLngAndCenter() {
    if (_selectedModel == null) {
      _centerOfRegion = LatLng(43.1394043, -72.0759888);
      _regionLatLngBounds = NewEnglandMapLatLngBounds;
    } else {
      _regionLatLngBounds = _selectedModel!.latLngBounds;
      _centerOfRegion =
          LatLng(_selectedModel!.center[0], _selectedModel!.center[1]);
    }
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

  FutureOr<void> _processRegionChangedEvent(
      RegionChangedEvent event, Emitter<RegionModelState> emit) async {
    await _processInitialRegionModelEvent(event, emit);
  }

  FutureOr<void> _processModelChangeEvent(
      ModelChangeEvent event, Emitter<RegionModelState> emit) async {
    if (_modelNames.contains(event.modelName) &&
        event.modelName != _selectedModelName) {
      _selectedModelName = event.modelName;
      // print('Selected model: $_selectedModelname');
      // emits same list of models with new selected model
      _getDatesForSelectedModel();
      _selectedModel = _selectedModelDates?.modelDateDetailList
          .firstWhereOrNull((modelDateDetail) =>
              modelDateDetail.model?.name == event.modelName)
          ?.model;
      _setForecastTimesBasedOnSelectedModel();
      _setLatLngAndCenter();
      _emitRaspModelsAndDates(emit);
    }
  }

  FutureOr<void> _processBeginnerModeEvent(
      BeginnerModeEvent event, Emitter<RegionModelState> emit) async {
    _beginnerMode = event.beginnerMode;
    await repository.setBeginnerForecastMode(_beginnerMode);
    if (_beginnerMode) {
      //  switched from expert to beginner
      // keep same date but might need to change the model
      _getBeginnerModeDateDetails();
      _emitCenterOfRegion(emit);
      _emitRegionBounds(emit);
    } else {
      //  switched from beginner to expert
      // stay on same model and date so just send info to update ui
      // Still need to update available dates/times for the model that you are on
      _getDatesForSelectedModel();
    }
    _emitRaspModelsAndDates(emit);
  }

  Future<void> _refreshForecast(
      RegionChangedEvent event, Emitter<RegionModelState> emit) async {
    await _processInitialRegionModelEvent(event, emit);
  }

  // This is called when the bloc is added for Local Forcast. Local Forecast was passed the same bloc as
  // used on RASP screen, so already have the region/model/...
  // So just need to send existing data to populate whatever the region/model widgets there are
  FutureOr<void> _processLocalForecastStartupEvent(
      LocalForecastStartupEvent event, Emitter<RegionModelState> emit) {
    _emitRaspModelsAndDates(emit);
  }

  //Event set after coming back from Local Forecast. Resend model/date/etc to make sure to sync RASP display.
  FutureOr<void> _processLocalForecastUpdateEvent(
      LocalForecastUpdateEvent event, Emitter<RegionModelState> emit) {
    _emitRaspModelsAndDates(emit);
  }

  // When you get a list of display options
  FutureOr<void> _processRegionDisplayOptionsEvent(
      RegionDisplayOptionsEvent event, Emitter<RegionModelState> emit) async {
    await Future.forEach(event.displayOptions, (preferenceOption) async {
      switch (preferenceOption.key) {
        case (soundingsDisplayOption):
          {
            _emitSoundings(preferenceOption.selected, emit);
            break;
          }
        case (suaDisplayOption):
          {
            await _emitSuaDetails(preferenceOption.selected, emit);
            break;
          }
      }
    });
  }

  Future<void> _emitSuaDetails(
      bool display, Emitter<RegionModelState> emit) async {
    _displaySua = display;
    if (_displaySua) {
      String? sua = await repository.getGeoJsonSUAForRegion(_regionName);
      if (sua != null) {
        // print("repository returned sua so emitting");
        emit(SuaDetailsState(sua));
      } else {
        emit(SuaDetailsState("{}"));
      }
    } else {
      emit(SuaDetailsState("{}"));
    }
  }

  void _emitSoundings(bool display, Emitter<RegionModelState> emit) {
    _displaySoundings = display;
    if (_displaySoundings) {
      if (_region!.soundings != null) {
        emit(RegionSoundingsState(
            _region!.soundings != null ? _region!.soundings! : <Soundings>[]));
      }
    } else {
      emit(RegionSoundingsState((<Soundings>[])));
    }
  }

  // When you get an update to a display option
  FutureOr<void> _processRegionDisplayOptionEvent(
      RegionDisplayOptionEvent event, Emitter<RegionModelState> emit) async {
    switch (event.displayOption.key) {
      case (soundingsDisplayOption):
        {
          _emitSoundings(event.displayOption.selected, emit);
          break;
        }
      case (suaDisplayOption):
        {
          await _emitSuaDetails(event.displayOption.selected, emit);
          break;
        }
    }
  }

  // Send Rasp parms needed for estimated task
  FutureOr<void> _processEstimatedTaskStartupEvent(
      EstimatedTaskStartupEvent event, Emitter<RegionModelState> emit) {
    EstimatedTaskRegionModel estimatedTaskRegionModel =
        EstimatedTaskRegionModel(
            regionName: _regionName,
            selectedModelName: _selectedModelName ?? "",
            selectedDate: _selectedForecastDate ?? "",
            selectedHour: _forecastTimes[_selectedForecastTimeIndex],
        );
    emit(EstimatedTaskRegionModelState(estimatedTaskRegionModel));
  }

  FutureOr<void> _processForecastHourSyncEvent(
      ForecastHourSyncEvent event, Emitter<RegionModelState> emit) {
    _selectedForecastTimeIndex = event.selectedTimeIndex;
  }
}
