import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/forecast_graph_data.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_models.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/view_bounds.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:latlong2/latlong.dart';

import 'rasp_bloc.dart';

enum _DisplayType { forecast, sounding }

/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
class RaspDataBloc extends Bloc<RaspDataEvent, RaspDataState> {
  final Repository repository;
  Regions? _regions;
  Region? _region;
  List<String> _modelNames = []; // gfs, nam, rap, hrr
  String? _selectedModelName; // nam
  ModelDates? _selectedModelDates; // all dates/times for the selected model
  List<String> _forecastDates = []; // array of dates like  2019-12-19
  String? _selectedForecastDate; // selected date  2019-12-19
  List<String>? _forecastTimes;
  int _selectedForecastTimeIndex = 4; // start at   1300 forecast
  //int _beginnerDateIndex = 0;

  List<Forecast>? _forecasts;
  Forecast? _selectedForecast;
  List<SoaringForecastImageSet> _forecastImageSets = [];
  List<SoaringForecastImageSet> _soundingsImageSets = [];
  LatLngBounds? _regionLatLngBounds;
  LatLng? _centerOfRegion;
  ViewBounds? _viewMapBoundsAndZoom;

  _DisplayType _displayType = _DisplayType.forecast;

  // For a 'simple' forecast where forecast model selected based on date and best(?) model
  // available for the date
  // Models selected should be in order of hrrr, rap, nam, gfs
  bool _beginnerMode = true;
  ModelDateDetail? _beginnerModeModelDataDetail;
  List<ModelDateDetail> _beginnerModelDateDetailList = [];

  // index into list of soundings
  int _soundingPosition = 0;

  int _taskId = -1;

  RaspDataBloc({required this.repository}) : super(RaspInitialState()) {
    on<InitialRaspRegionEvent>(_processInitialRaspRegionEvent);
    on<MapReadyEvent>(_processMapReadyEvent);
    on<SelectedModelEvent>(_processSelectedModelEvent);
    on<SelectForecastDateEvent>(_processSelectedDateEvent);
    on<NextTimeEvent>(_processNextTimeEventAndEmitImage);
    on<PreviousTimeEvent>(_processPreviousTimeEventAndEmitImage);
    on<SelectedRaspForecastEvent>(_processSelectedForecastEvent);
    on<DisplayCurrentForecastEvent>(_processDisplayCurrentForecast);
    on<GetTaskTurnpointsEvent>(_getTurnpointsForTaskId);
    on<ClearTaskEvent>(_clearTask);
    on<SwitchedRegionEvent>(_processSwitchedRegion);
    on<DisplayTaskTurnpointEvent>(_displayTaskTurnpoint);
    on<DisplayLocalForecastEvent>(_displayLocalForecast);
    on<RedisplayMarkersEvent>(_redisplayMarkers);
    on<SaveRaspDisplayOptionsEvent>(_processSaveRaspDisplayOptions);
    on<ViewBoundsEvent>(_processViewBounds);
    on<DisplaySoundingsEvent>(_processSoundingsEvent);
    on<SetForecastOverlayOpacityEvent>(_setForecastOverlayOpacity);
    on<LoadForecastTypesEvents>(_reloadForecastTypes);
    on<RefreshTaskEvent>(_refreshTask);
    on<ForecastDateSwitchEvent>(_processBeginnerDateSwitch);
    on<BeginnerModeEvent>(_processBeginnerModeEvent);
    on<RefreshForecastEvent>(_refreshForecast);
    on<CheckIfForecastRefreshNeededEvent>(_checkIfForecastRefreshNeeded);
    on<GetEstimatedFlightAvgEvent>(_getEstimatedFlightAvg);
    on<LocalForecastOutputDataEvent>(_processLocalForecastOutputData);
  }

  void _processInitialRaspRegionEvent(InitialRaspRegionEvent event,
      Emitter<RaspDataState> emit) async {
    await _emitForecastRegionInfo(emit);
  }

  Future<void> _emitForecastRegionInfo(Emitter<RaspDataState> emit) async {
    emit(RaspWorkingState(working: true));

    try {
      await _loadForecastTypes();
      _emitForecasts(emit);
      if (_regions == null) {
        _regions = await this.repository.getRegions();
      }
      if (_regions != null) {
        final selectedRegionName = await repository.getSelectedRegionName();
        _region = _regions!.regions!
            .firstWhereOrNull((region) => (region.name == selectedRegionName))!;
        emit(SelectedRegionNameState(selectedRegionName));
        // Now get the model (gfs/etc)
        await _loadRaspValuesForRegion();
        await _getSelectedModelDates();
        // need to get all dates before you can generate the list of models
        _setRegionModelNames();
        // on startup default mode is first on list
        _selectedModelName = _selectedModelDates!.modelName!;
        // get default time to start displaying forecast
        await _getDefaultForecastTime();
        _beginnerMode = await repository.isBeginnerForecastMode();
        emit(BeginnerModeState(_beginnerMode));
        // A 'beginner' forecast is one where the app selected the 'best' forecast for the date
        // So forecast (if available) goes in order of hrrr, rap, nam, gfs
        if (_beginnerMode) {
          _getBeginnerModeStartup(emit);
        } else {
          // expert forecast selections
          _emitRaspModelsAndDates(emit);
        }
        _emitCenterOfMap(emit);
        emit(RaspWorkingState(working: false));
        repository.saveLastForecastTime(DateTime
            .now()
            .millisecondsSinceEpoch);
      }
    } catch (e, stackTrace) {
      print("Error:  ${e.toString()} \n${stackTrace.toString()}");
      emit(RaspWorkingState(working: false));
      emit(RaspErrorState(
          "Unexpected error occurred executing to get forecast model/date/time data :\n${e
              .toString()}"));
    }
  }

  void _processMapReadyEvent(MapReadyEvent event,
      Emitter<RaspDataState> emit) async {
    await _emitForecastMapInfo(emit);
  }

  Future<void> _emitForecastMapInfo(Emitter<RaspDataState> emit) async {
    try {
      emit(RaspWorkingState(working: true));
      await _emitForecastBounds(emit);
      _getForecastImages();
      await _sendInitialForecastOverlayOpacity(emit);
      await _emitDisplayOptions(emit);
      //await _emitRaspDisplayOptions(emit);
      await _emitCurrentTask(emit);
      emit(RaspWorkingState(working: false));
      _emitRaspForecastImageSet(emit);
    } catch (e, stackTrace) {
      log("Error: ${e.toString()} \n${stackTrace.toString()}");
      emit(RaspWorkingState(working: false));
      emit(RaspErrorState(
          "Unexpected error occurred gathering forecast map data: \n${e
              .toString()}}"));
    }
  }

  Future<void> _processSwitchedRegion(SwitchedRegionEvent event,
      Emitter<RaspDataState> emit) async {
    repository.setCurrentTaskId(-1);
    await _refreshForecast(event, emit);
  }

  Future<void> _refreshForecast(_, Emitter<RaspDataState> emit) async {
    await _emitForecastRegionInfo(emit);
    await _emitForecastMapInfo(emit);
  }

  void _processSelectedModelEvent(SelectedModelEvent event,
      Emitter<RaspDataState> emit) {
    _processModelChange(event.modelName, emit);
  }

  Future<void> _processModelChange(String modelName, Emitter<RaspDataState> emit) async {
    if (_modelNames.contains(modelName) &&
        modelName != _selectedModelName) {
      _selectedModelName = modelName;
      // print('Selected model: $_selectedModelname');
      // emits same list of models with new selected model
      _getDatesForSelectedModel();
      _emitRaspModelsAndDates(emit);
      if (_displayType == _DisplayType.forecast) {
        _getForecastImages();
        _emitRaspForecastImageSet(emit);
      } else {
        _getSoundingImages(_soundingPosition);
        _emitSoundingImageSet(emit);
      }
    }
    emit(EstimatedFlightSummaryState(null));
  }

  void _processSelectedForecastEvent(SelectedRaspForecastEvent event,
      Emitter<RaspDataState> emit,
      {bool resendForecasts = false}) async {
    _selectedForecast = event.forecast;
    await repository.saveSelectedForecast(_selectedForecast!);
    if (resendForecasts) {
      _emitForecasts(emit);
    }
    _getForecastImages();
    _emitRaspForecastImageSet(emit);
  }

  void _processSelectedDateEvent(SelectForecastDateEvent event,
      Emitter<RaspDataState> emit) {
    _processSelectedDateChange(event.forecastDate, emit);
  }

  Future<void> _processSelectedDateChange(String forecastDate,
      Emitter<RaspDataState> emit) async {
    if (_forecastDates.contains(forecastDate) &&
        forecastDate != _selectedForecastDate) {
      _selectedForecastDate = forecastDate;
      _emitRaspModelsAndDates(emit);
      // update times and images for new date
      _setForecastTimesForDate();
      if (_displayType == _DisplayType.forecast) {
        _getForecastImages();
        _emitRaspForecastImageSet(emit);
      } else {
        _getSoundingImages(_soundingPosition);
        _emitSoundingImageSet(emit);
      }
      emit(EstimatedFlightSummaryState(null));
    }
  }

  void _emitRaspModelsAndDates(Emitter<RaspDataState> emit) {
    emit(RaspForecastModelsAndDates(
        modelNames: _modelNames,
        selectedModelName: _selectedModelName!,
        forecastDates: _forecastDates,
        selectedForecastDate: _selectedForecastDate!));
  }

  void _emitForecasts(Emitter<RaspDataState> emit) {
    emit(RaspForecasts(_forecasts!, _selectedForecast!));
    //print('emitted RaspForecasts');
  }

  // Note that _regionLatLngBounds must be previously defined
  Future<void> _emitForecastBounds(Emitter<RaspDataState> emit) async {
    emit(ForecastBoundsState(_regionLatLngBounds!));
    // _viewMapBoundsAndZoom = await repository.getViewBoundsAndZoom();
    // if (_viewMapBoundsAndZoom != null) {
    //   emit(ViewBoundsState(
    //       _viewMapBoundsAndZoom ?? ViewBounds(_regionLatLngBounds!)));
    //   print('emitted ViewBoundsAndZoomState');
    // }
  }

  void _emitRaspForecastImageSet(Emitter<RaspDataState> emit) {
    emit(RaspForecastImageSet(_forecastImageSets[_selectedForecastTimeIndex],
        _selectedForecastTimeIndex, _forecastImageSets.length));
    //print(
    //    'emitted RaspForecastImageSet  ${_forecastImageSets[_selectedForecastTimeIndex]}');
  }

  Future<Region> _loadRaspValuesForRegion() async {
    return await this.repository.loadForecastModelsByDateForRegion(_region!);
  }

  void _setRegionModelNames() {
    _modelNames.clear();
    _modelNames.addAll(_region!
        .getModelDates()
        .map((modelDates) => modelDates.modelName!)
        .toList());
  }

  /// wstar_bsratio, wstar, ...
  Future _loadForecastTypes() async {
    _forecasts = (await this.repository.getDisplayableForecastList());
    _selectedForecast = await repository.getSelectedForecast();
    if (_selectedForecast == null) {
      _selectedForecast = _forecasts!.first;
    }
  }

  Future _getSelectedModelDates() async {
    _region = await repository.loadForecastModelsByDateForRegion(_region!);
    // TODO - get last model (gfs, name) from repository and display
    _selectedModelDates = _region!.getModelDates().first;
    _updateForecastDates();
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

  void _setLatLngAndCenter(Model modelDateDetail) {
    _regionLatLngBounds = modelDateDetail.latLngBounds;
    _centerOfRegion =
        LatLng(modelDateDetail.center[0], modelDateDetail.center[1]);
  }

  void _setSelectedTimeIndex() {
    if (_selectedForecastTimeIndex > _forecastTimes!.length - 1) {
      _selectedForecastTimeIndex = 0;
    }
  }

  /// Following values must be assigned before calling
  /// _region.name  - NewEngland
  /// _selectedForecastDate  2019-12-12
  /// _selectedModelName  gfs
  /// _selectedForecast  wstart
  /// _forecastTimes   [1000,1100,...]
  void _getForecastImages() {
    String imageUrl;
    SoaringForecastImage soaringForecastBodyImage;
    SoaringForecastImage soaringForecastSideImage;

    _forecastImageSets.clear();
    var soaringForecastImages = [];
    for (var time in _forecastTimes!) {
      // Get forecast overlay
      imageUrl = _createForecastImageUrl(_region!.name!, _selectedForecastDate!,
          _selectedModelName!, _selectedForecast!.forecastName, time, 'body');
      soaringForecastBodyImage = SoaringForecastImage(imageUrl, time);
      soaringForecastImages.add(soaringForecastBodyImage);

      // Get scale image
      imageUrl = _createForecastImageUrl(_region!.name!, _selectedForecastDate!,
          _selectedModelName!, _selectedForecast!.forecastName, time, 'side');
      soaringForecastSideImage = SoaringForecastImage(imageUrl, time);
      soaringForecastImages.add(soaringForecastSideImage);

      var soaringForecastImageSet = SoaringForecastImageSet(
          localTime: time,
          bodyImage: soaringForecastBodyImage,
          sideImage: soaringForecastSideImage);

      _forecastImageSets.add(soaringForecastImageSet);
    }
  }

  void _getSoundingImages(final int soundingPosition) {
    String imageUrl;
    SoaringForecastImage soaringForecastBodyImage;
    _soundingsImageSets.clear();
    var soundingImages = [];
    for (var time in _forecastTimes!) {
      // Get forecast overlay
      imageUrl = _createSoundingImageUrl(_region!.name!, _selectedForecastDate!,
          _selectedModelName!, soundingPosition.toString(), time);
      soaringForecastBodyImage = SoaringForecastImage(imageUrl, time);
      soundingImages.add(soaringForecastBodyImage);

      var soaringForecastImageSet = SoaringForecastImageSet(
          localTime: time, bodyImage: soaringForecastBodyImage);

      _soundingsImageSets.add(soaringForecastImageSet);
    }
  }

  void getImagesAheadOfTime(List<Future> imageFutures) async {
    for (var imageFuture in imageFutures) {
      await imageFuture.then((resp) {
        print("Image future complete");
      });
    }
  }

  /// Create url for fetching forecast overly
  /// eg. "/NewEngland/2019-12-19/gfs/wstar_bsratio.1500local.d2.body.png"
  String _createForecastImageUrl(String regionName,
      String forecastDate,
      String model,
      String forecastType,
      String forecastTime,
      String imageType) {
    var stripOld = forecastTime.startsWith("old")
        ? forecastTime.substring(4)
        : forecastTime;
    return "$regionName/$forecastDate/$model/$forecastType.${stripOld}local.d2.$imageType.png";
  }

  /// Create url for fetching sounding image
  /// eg. "/NewEngland/2022-08-01/gfs/sounding2.1100local.d2.png"
  String _createSoundingImageUrl(String regionName, String forecastDate,
      String model, String soundingIndex, String forecastTime) {
    var stripOld = forecastTime.startsWith("old")
        ? forecastTime.substring(4)
        : forecastTime;
    return "/$regionName/$forecastDate/$model/sounding$soundingIndex.${stripOld}local.d2.png";
  }

  void _processNextTimeEventAndEmitImage(_, Emitter<RaspDataState> emit) {
    emit(EstimatedFlightSummaryState(null));
    _updateTimeIndex(1, emit);
  }

  void _processPreviousTimeEventAndEmitImage(_, Emitter<RaspDataState> emit) {
    emit(EstimatedFlightSummaryState(null));
    _updateTimeIndex(-1, emit);
  }

  void _updateTimeIndex(int incOrDec, Emitter<RaspDataState> emit) {
    // print('Current _selectedForecastTimeIndex $_selectedForecastTimeIndex'
    //     '  incOrDec $incOrDec');
    if (incOrDec > 0) {
      _selectedForecastTimeIndex =
      (_selectedForecastTimeIndex == _forecastTimes!.length - 1)
          ? 0
          : _selectedForecastTimeIndex + incOrDec;
    } else {
      _selectedForecastTimeIndex = (_selectedForecastTimeIndex == 0)
          ? _forecastTimes!.length - 1
          : _selectedForecastTimeIndex + incOrDec;
    }
    //print('New _selectedForecastTimeIndex $_selectedForecastTimeIndex');

    switch (_displayType) {
      case _DisplayType.forecast:
        _emitRaspForecastImageSet(emit);
        break;
      case _DisplayType.sounding:
        _emitSoundingImageSet(emit);
        break;
    }
  }

  void _clearTask(ClearTaskEvent event, Emitter<RaspDataState> emit) async {
    repository.setCurrentTaskId(-1);
    _taskId = -1;
    _viewMapBoundsAndZoom = ViewBounds(_regionLatLngBounds!);
    repository.saveViewBounds(_viewMapBoundsAndZoom!); // 7 default zoom
    emit(RaspTaskTurnpoints(<TaskTurnpoint>[]));
    emit(EstimatedFlightSummaryState(null));
    //emit(ViewBoundsState(_viewMapBoundsAndZoom!));
  }

  // void _checkForPreviouslySelectedTask(
  //     MapReadyEvent event, Emitter<RaspDataState> emit) async {
  //   await _emitRaspDisplayOptions(emit);
  //   await _emitCurrentTask(emit);
  // }

  Future<void> _emitCurrentTask(Emitter<RaspDataState> emit) async {
    _taskId = await repository.getCurrentTaskId();
    await _emitTaskTurnpoints(emit, _taskId);
    bool showEstimatedFlightButton =
    await repository.getDisplayEstimatedFlightButton();
    emit(ShowEstimatedFlightButton(showEstimatedFlightButton));
  }

  void _getTurnpointsForTaskId(GetTaskTurnpointsEvent event,
      Emitter<RaspDataState> emit) async {
    emit(EstimatedFlightSummaryState(null));
    _taskId = event.taskId;
    repository.setCurrentTaskId(_taskId);
    await _emitTaskTurnpoints(emit, _taskId);
  }

  void _getEstimatedFlightAvg(GetEstimatedFlightAvgEvent event,
      Emitter<RaspDataState> emit) async {
    emit(RaspWorkingState(working: true));
    List<TaskTurnpoint> taskTurnpoints = await _getTaskTurnpoints(_taskId);
    StringBuffer turnpointLatLons = StringBuffer();
    String latLonString = "";
    int index = 1;
    for (var taskTurnpoints in taskTurnpoints) {
      turnpointLatLons.write(index.toString());
      turnpointLatLons.write(",");
      turnpointLatLons.write(taskTurnpoints.latitudeDeg.toString());
      turnpointLatLons.write(",");
      turnpointLatLons.write(taskTurnpoints.longitudeDeg.toString());
      turnpointLatLons.write(",");
      turnpointLatLons.write(taskTurnpoints.title.substring(0,
          taskTurnpoints.title.length > 4 ? 4 : taskTurnpoints.title.length));
      turnpointLatLons.write(",");
      index++;
    }
    if (turnpointLatLons.length > 0) {
      latLonString =
          turnpointLatLons.toString().substring(0, turnpointLatLons.length - 1);
    }
    //Note per Dr Jack. thermalMultiplier was a fudge factor that could be added if you want to bump up or down
    // wstar value used in sink rate calc. For now just use 1
    var optimizedTaskRoute = await repository.getEstimatedFlightSummary(
        _region!.name!,
        _selectedForecastDate!,
        _selectedModelName!,
        'd2',
        _forecastTimes![_selectedForecastTimeIndex] + 'x',
        event.glider.glider,
        event.glider.polarWeightAdjustment,
        event.glider.getPolarCoefficientsAsString(),
        // string of a,b,c
        event.glider.ballastAdjThermalingSinkRate,
        1,
        latLonString);
    if (optimizedTaskRoute?.routeSummary?.error != null) {
      emit(RaspErrorState(optimizedTaskRoute!.routeSummary!.error!));
      emit(RaspWorkingState(working: false));
    } else {
      emit(RaspWorkingState(working: false));
      emit(EstimatedFlightSummaryState(optimizedTaskRoute!));
    }
  }

  FutureOr<void> _emitTaskTurnpoints(Emitter<RaspDataState> emit,
      int taskId) async {
    List<TaskTurnpoint> taskTurnpoints = await _getTaskTurnpoints(taskId);
    emit(RaspTaskTurnpoints(taskTurnpoints));
  }

  Future<List<TaskTurnpoint>> _getTaskTurnpoints(int taskId) async {
    final List<TaskTurnpoint> taskTurnpoints = <TaskTurnpoint>[];
    if (taskId > -1) {
      taskTurnpoints.addAll(await _addTaskTurnpointDetails(taskId));
      // print('emitting taskturnpoints');
    }
    return taskTurnpoints;
  }

  // _emitRaspDisplayOptions(Emitter<RaspDataState> emit) async {
  //   final preferenceOptions = await repository.getRaspDisplayOptions();
  //   print('emitting RaspDisplayOptionsState (to provision dialog dropdown)');
  //   emit(RaspDisplayOptionsState(preferenceOptions));
  // }

  Future<List<TaskTurnpoint>> _addTaskTurnpointDetails(int taskId) async {
    List<TaskTurnpoint> taskTurnpoints =
    await repository.getTaskTurnpoints(taskId);
    return taskTurnpoints;
  }

  void _displayTaskTurnpoint(DisplayTaskTurnpointEvent event,
      Emitter<RaspDataState> emit) async {
    // emit(TasksLoadingState()); // if used need to resend event to redisplay task
    Turnpoint? turnpoint = await repository.getTurnpoint(
        event.taskTurnpoint.title, event.taskTurnpoint.code);
    if (turnpoint != null) {
      emit(TurnpointFoundState(turnpoint));
    } else {
      emit(RaspWorkingState(working: false));
      emit(RaspErrorState("Oops. Turnpoint not found based on TaskTurnpoint"));
    }
  }

  void _displayLocalForecast(DisplayLocalForecastEvent event,
      Emitter<RaspDataState> emit) async {
    List<LocalForecastPoint> localForecastPoints = [];
    int startIndex = 0;
    if (event.forTask && _taskId > -1) {
      // ok - a task is displayed and a local forecast was requested on one of the
      // task turnpoints so get assemble list of all turnpoints
      List<TaskTurnpoint> taskTurnpoints = await _getTaskTurnpoints(_taskId);
      localForecastPoints.addAll(taskTurnpoints
          .map((taskTurnpoint) =>
          LocalForecastPoint(
              lat: taskTurnpoint.latitudeDeg,
              lng: taskTurnpoint.longitudeDeg,
              turnpointName: taskTurnpoint.title,
              turnpointCode: taskTurnpoint.code))
          .toList());
      // set the turnpoint index to mark the tapped turnpoint;
      startIndex = localForecastPoints.indexWhere((localForecastPoint) =>
      localForecastPoint.lat == event.latLng.latitude &&
          localForecastPoint.lng == event.latLng.longitude);
    } else {
      localForecastPoints.add(LocalForecastPoint(
          lat: event.latLng.latitude,
          lng: event.latLng.longitude,
          turnpointName: event.turnpointName,
          turnpointCode: event.turnpointCode));
    }
    final localForecastGraphData = LocalForecastInputData(
        region: _region!,
        date: _selectedForecastDate!,
        model: _selectedModelName!,
        times: _forecastTimes!,
        localForecastPoints: localForecastPoints,
        startIndex: startIndex);
    emit(DisplayLocalForecastGraphState(localForecastGraphData));
  }

// Can't get flutter_map to display updated markers without issuing state
  void _redisplayMarkers(RedisplayMarkersEvent event,
      Emitter<RaspDataState> emit) {
    emit(RedisplayMarkersState());
  }

// This should only occur when user requests this particular option to be displayed.
  FutureOr<void> _processSaveRaspDisplayOptions(
      SaveRaspDisplayOptionsEvent event, Emitter<RaspDataState> emit) async {
    switch (event.displayOption.key) {
      case (soundingsDisplayOption):
        {
          if (event.displayOption.selected) {
            if (_region!.soundings != null) {
              emit(RaspSoundingsState(event.displayOption.selected
                  ? _region!.soundings!
                  : <Soundings>[]));
            }
          } else {
            emit(RaspSoundingsState((<Soundings>[])));
          }
          break;
        }
      case (suaDisplayOption):
        {
          if (event.displayOption.selected) {
            await _getSuaDetails(emit);
          } else {
            emit(SuaDetailsState("{}"));
          }
          break;
        }
      case (turnpointsDisplayOption):
        {
          if (event.displayOption.selected) {
            // only send turnpoints based on current lat/long corners of map
            List<Turnpoint> turnpoints = await repository
                .getTurnpointsWithinBounds(_regionLatLngBounds!);
            emit(TurnpointsInBoundsState(turnpoints));
          } else {
            emit(TurnpointsInBoundsState(<Turnpoint>[]));
          }
        }
        break;
    }
    repository.saveRaspDisplayOption(event.displayOption);
  }

// check new bounds and if needed send turnpoints and soundings within those bounds
  FutureOr<void> _processViewBounds(ViewBoundsEvent event,
      Emitter<RaspDataState> emit) async {
    repository.saveViewBounds(ViewBounds(event.latLngBounds));
    await _emitDisplayOptions(emit);
    // emit(RedisplayMarkersState());
  }

// initial check for display options (soundings, turnpoints, sua) and send them if needed
  FutureOr<void> _emitDisplayOptions(Emitter<RaspDataState> emit) async {
    final preferenceOptions = await repository.getRaspDisplayOptions();
    for (var option in preferenceOptions) {
      switch (option.key) {
        case (soundingsDisplayOption):
          if (option.selected) {
            emit(RaspSoundingsState(_region?.soundings ?? <Soundings>[]));
          } else {
            emit(RaspSoundingsState(<Soundings>[]));
          }
          print('emitted RaspSoundingsState');
          break;
        case (turnpointsDisplayOption):
          if (option.selected) {
            final turnpoints = await repository
                .getTurnpointsWithinBounds(_regionLatLngBounds!);
            emit(TurnpointsInBoundsState(turnpoints));
          } else {
            emit(TurnpointsInBoundsState(<Turnpoint>[]));
          }
          // print('emitted TurnpointsInBoundsState');
          break;
        case (suaDisplayOption):
          if (option.selected) {
            await _getSuaDetails(emit);
          } else {
            // nada
          }
          break;
      }
    }
    emit(RaspDisplayOptionsState(preferenceOptions));
  }

  // Used to allow prior emitted state to be process by Flutter before another
  // emit fired
  // Future<void> waitAFrame() async {
  //   await Future.delayed(Duration(milliseconds: 100));
  // }

  FutureOr<void> _processSoundingsEvent(DisplaySoundingsEvent event,
      Emitter<RaspDataState> emit) {
    _displayType = _DisplayType.sounding;
    _soundingPosition = event.sounding.position!;
    _getSoundingImages(_soundingPosition);
    _emitSoundingImageSet(emit);
  }

  Future<void> _emitSoundingImageSet(Emitter<RaspDataState> emit) async {
    emit(SoundingForecastImageSet(
        _soundingsImageSets[_selectedForecastTimeIndex],
        _selectedForecastTimeIndex,
        _soundingsImageSets.length));
    // print(
    //     'emitted SoundingsImageSet  ${_soundingsImageSets[_selectedForecastTimeIndex]}');
  }

  FutureOr<void> _processDisplayCurrentForecast(
      DisplayCurrentForecastEvent event, Emitter<RaspDataState> emit) {
    _displayType = _DisplayType.forecast;
    _getForecastImages();
    _emitRaspForecastImageSet(emit);
  }

  _getSuaDetails(Emitter<RaspDataState> emit) async {
    // var sua = await repository.getSuaForRegion(_region!.name!);
    String? sua = await repository.getGeoJsonSUAForRegion(_region!.name!);
    if (sua != null) {
      // print("repository returned sua so emitting");
      emit(SuaDetailsState(sua));
    } else {
      // print("repository returned null sua");
    }
  }

  FutureOr<void> _sendInitialForecastOverlayOpacity(
      Emitter<RaspDataState> emit) async {
    var opacity = await repository.getForecastOverlayOpacity();
    emit(ForecastOverlayOpacityState(opacity));
  }

  FutureOr<void> _setForecastOverlayOpacity(
      SetForecastOverlayOpacityEvent event, Emitter<RaspDataState> emit) async {
    await repository.setForecastOverlayOpacity(event.forecastOverlayOpacity);
    emit(ForecastOverlayOpacityState(event.forecastOverlayOpacity));
  }

  FutureOr<void> _reloadForecastTypes(LoadForecastTypesEvents event,
      Emitter<RaspDataState> emit) async {
    await _loadForecastTypes();
    _emitForecasts(emit);
  }

  FutureOr<void> _refreshTask(RefreshTaskEvent event,
      Emitter<RaspDataState> emit) {
    _emitCurrentTask(emit);
  }

  void _emitCenterOfMap(Emitter<RaspDataState> emit) {
    emit(CenterOfMapState(_centerOfRegion!));
  }

  // For simple startup, get the 'best' model available for the current date
  void _getBeginnerModeStartup(Emitter<RaspDataState> emit) {
    _selectedForecastDate = _region?.dates?.first;
    _getBeginnerModeDateDetails();
    _emitBeginnerModelDateState(emit);
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
    _beginnerModeModelDataDetail = modelDateDetails;
    _selectedModelName = modelDateDetails?.model?.name;
    if (_modelNames.isEmpty) {
      _setRegionModelNames();
    }
  }

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

  void _emitBeginnerModelDateState(Emitter<RaspDataState> emit) {
    if (_beginnerModeModelDataDetail == null) {
      emit(RaspWorkingState(working: false));
      emit(RaspErrorState(
          "Hmmm. No forecast models available! Please check main RASP site to see if issue there also"));
    }
    emit(BeginnerForecastDateModelState(
      _selectedForecastDate!,
      _beginnerModeModelDataDetail!.model!.name,
    ));
  }

  // Go to either previous or next date for beginner mode
  FutureOr<void> _processBeginnerDateSwitch(ForecastDateSwitchEvent event,
      Emitter<RaspDataState> emit) async {
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
      emit(BeginnerForecastDateModelState(
          _selectedForecastDate!, _selectedModelName!));
    }
    // we need to keep values in sync for 'expert' mode if user switches to that mode
    _getDatesForSelectedModel();
    if (_displayType == _DisplayType.forecast) {
      _getForecastImages();
      _emitRaspForecastImageSet(emit);
    } else {
      _getSoundingImages(_soundingPosition);
      _emitSoundingImageSet(emit);
    }
    emit(EstimatedFlightSummaryState(null));
  }

  // Switch display from beginner to expert or visa-versa
  // if switching from expert to simple may switch models (to get most 'accurate' for day)
  // if switched from simple to expert stay on current model but resend dates
  void _processBeginnerModeEvent(BeginnerModeEvent event,
      Emitter<RaspDataState> emit) async {
    await _processBeginnerModeChange(event.beginnerMode, emit);
  }

  Future<void> _processBeginnerModeChange(bool beginnerMode,
      Emitter<RaspDataState> emit) async {
    _beginnerMode = beginnerMode;
    await repository.setBeginnerForecastMode(_beginnerMode);
    emit(BeginnerModeState(beginnerMode));
    if (_beginnerMode) {
      //  switched from expert to beginner
      // keep same date but might need to change the model
      _getBeginnerModeDateDetails();
      emit(BeginnerForecastDateModelState(
          _selectedForecastDate ?? '', _selectedModelName!));
      _getForecastImages();
      _emitRaspForecastImageSet(emit);
      emit(EstimatedFlightSummaryState(null));
    } else {
      //  switched from beginner to expert
      // stay on same model and date so just send info to update ui
      // Still need to update available dates/times for the model that you are on
      _getDatesForSelectedModel();
      _emitRaspModelsAndDates(emit);
    }
  }

  Future<void> _getDefaultForecastTime() async {
    String defaultTime = await repository.getDefaultForecastTime();
    _selectedForecastTimeIndex = _forecastTimes != null
        ? (_forecastTimes!.contains(defaultTime)
        ? _forecastTimes!.indexOf(defaultTime)
        : 0)
        : 0;
  }

  FutureOr<void> _checkIfForecastRefreshNeeded(
      CheckIfForecastRefreshNeededEvent event,
      Emitter<RaspDataState> emit) async {
    var lastForecast = await repository.getLastForecastTime();
    // 1800000 millisecs equals 30 minutes
    if (lastForecast == 0 ||
        (DateTime
            .now()
            .millisecondsSinceEpoch - lastForecast) > 1800000) {
      // Last time forecast model date/times obtained from server was over 30 minutes ago, so refresh
      // (there might be newer model forecasts available)
      await _refreshForecast(event, emit);
    }
  }

  // returned from Local forecast screen where model/date may have changed from original RASP
  FutureOr<void> _processLocalForecastOutputData(
      LocalForecastOutputDataEvent event, Emitter<RaspDataState> emit) async{
    LocalForecastOutputData outputData = event.localForecastOutputData;

    if (outputData.modelName != _selectedModelName) {
      // process modelName change
      await _processModelChange(outputData.modelName, emit);
    }
    if (outputData.date != _selectedForecastDate) {
      await _processSelectedDateChange(outputData.date, emit);
    }
    if (outputData.beginnerMode != _beginnerMode) {
      await  _processBeginnerModeChange(outputData.beginnerMode, emit);
    }
  }
}
