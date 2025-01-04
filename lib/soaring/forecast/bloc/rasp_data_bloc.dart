import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';

import '../../local_forecast/data/local_forecast_graph.dart';
import 'rasp_bloc.dart';

enum _DisplayType { forecast, sounding }

/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
class RaspDataBloc extends Bloc<RaspDataEvent, RaspDataState> {
  final Repository repository;
  String _regionName = "";
  String _selectedModelName = ""; // nam
  String _selectedForecastDate = ""; // selected date  2019-12-19

  List<String> _forecastTimes = [];
  int _selectedForecastTimeIndex = 0;

  ///TODO break out forecasts to separate block
  List<Forecast>? _forecasts;
  Forecast? _selectedForecast;
  List<SoaringForecastImageSet> _forecastImageSets = [];
  List<SoaringForecastImageSet> _soundingsImageSets = [];
  LatLngBounds? _regionLatLngBounds;

  _DisplayType _displayType = _DisplayType.forecast;

  // index into list of soundings
  int _soundingPosition = 0;

  int _taskId = -1;

  bool _displayTurnpoints = false;

  RaspDataBloc({required this.repository}) : super(RaspInitialState()) {
    on<InitialRaspRegionEvent>(_processInitialRaspRegionEvent);
    on<MapReadyEvent>(_processMapReadyEvent);
    on<SelectedRegionModelDetailEvent>(_processSelectedRegionModelDetail);
    on<IncrDecrRaspForecastHourEvent>(_processIncrDecrRaspForecastHourEvent);
    on<SelectedRaspForecastEvent>(_processSelectedForecastEvent);
    on<DisplayCurrentForecastEvent>(_processDisplayCurrentForecast);
    on<GetTaskTurnpointsEvent>(_getTurnpointsForTaskId);
    on<ClearTaskEvent>(_clearTask);
    on<SwitchedRegionEvent>(_processSwitchedRegion);
    on<DisplayTaskTurnpointEvent>(_displayTaskTurnpoint);
    on<DisplayLocalForecastEvent>(_displayLocalForecast);
    on<RedisplayMarkersEvent>(_redisplayMarkers);
    on<RaspDisplayOptionEvent>(_processRaspDisplayOptionEvent);
    on<ViewBoundsEvent>(_processViewBounds);
    on<DisplayRaspSoundingsEvent>(_processSoundingsEvent);
    on<SetForecastOverlayOpacityEvent>(_setForecastOverlayOpacity);
    on<LoadForecastTypesEvents>(_reloadForecastTypes);
    on<RefreshTaskEvent>(_refreshTask);
    on<ListTypesOfForecastsEvent>(_listTypesOfForecasts);
    on<CheckIfForecastRefreshNeededEvent>(_checkIfForecastRefreshNeeded);
    on<RaspDisplayOptionsEvent>(_processRaspDisplayOptionsEvent);
  }

  Future<void> _processInitialRaspRegionEvent(
      InitialRaspRegionEvent event, Emitter<RaspDataState> emit) async {
    await _emitTypesOfForecasts(emit);
  }

  FutureOr<void> _processSelectedRegionModelDetail(
      SelectedRegionModelDetailEvent event, Emitter<RaspDataState> emit) {
    _regionName = event.region;
    _selectedModelName = event.modelName; // nam
    _selectedForecastDate = event.modelDate; // selected date  2019-12-19
    _forecastTimes = event.localTimes;
    _selectedForecastTimeIndex = event.localTimes.indexOf(event.localTime);
    _emitForecastSoundingImageSets(emit);
  }

  void _emitForecastSoundingImageSets(Emitter<RaspDataState> emit) {
    if (_displayType == _DisplayType.forecast) {
      _getForecastImages();
      _emitRaspForecastImageSet(emit);
    } else {
      _getSoundingImages(_soundingPosition);
      _emitSoundingImageSet(emit);
    }
  }

  Future<void> _emitTypesOfForecasts(Emitter<RaspDataState> emit) async {
    emit(RaspWorkingState(working: true));

    try {
      await _loadForecastTypes();
      _emitForecasts(emit);
      emit(RaspWorkingState(working: false));
      repository.saveLastForecastTime(DateTime.now().millisecondsSinceEpoch);
    } catch (e, stackTrace) {
      print("Error:  ${e.toString()} \n${stackTrace.toString()}");
      emit(RaspWorkingState(working: false));
      emit(RaspErrorState(
          "Unexpected error occurred executing to get forecast model/date/time data :\n${e.toString()}"));
    }
  }

  void _processMapReadyEvent(
      MapReadyEvent event, Emitter<RaspDataState> emit) async {
     await _emitForecastMapInfo(emit);
    await _sendInitialForecastOverlayOpacity(emit);
  }

  Future<void> _emitForecastMapInfo(Emitter<RaspDataState> emit) async {
    try {
      emit(RaspWorkingState(working: true));
      await _emitCurrentTask(emit);
      _emitRaspForecastImageSet(emit);
      emit(RaspWorkingState(working: false));
    } catch (e, stackTrace) {
      log("Error: ${e.toString()} \n${stackTrace.toString()}");
      emit(RaspWorkingState(working: false));
      emit(RaspErrorState(
          "Unexpected error occurred gathering forecast map data: \n${e.toString()}}"));
    }
  }

  Future<void> _processSwitchedRegion(
      SwitchedRegionEvent event, Emitter<RaspDataState> emit) async {
    repository.setCurrentTaskId(-1);
  }

  Future<void> _listTypesOfForecasts(_, Emitter<RaspDataState> emit) async {
    await _emitTypesOfForecasts(emit);

  }

  void _processSelectedForecastEvent(
      SelectedRaspForecastEvent event, Emitter<RaspDataState> emit) async {
    _selectedForecast = event.forecast;
    await repository.saveSelectedForecast(_selectedForecast!);
    if (event.resendForecasts) {
      _emitForecasts(emit);
    }
    _getForecastImages();
    _emitRaspForecastImageSet(emit);
  }

  void _emitForecasts(Emitter<RaspDataState> emit) {
    emit(RaspForecasts(_forecasts!, _selectedForecast!));
    //print('emitted RaspForecasts');
  }

  void _emitRaspForecastImageSet(Emitter<RaspDataState> emit) {
    if (_forecastImageSets.length ==0) {
      return;
    }
    emit(RaspForecastImageSet(_forecastImageSets[_selectedForecastTimeIndex],
        _selectedForecastTimeIndex, _forecastImageSets.length));
    emit(RaspTimeState(
        _forecastImageSets[_selectedForecastTimeIndex].localTime, _selectedForecastTimeIndex));
  }

  /// wstar_bsratio, wstar, ...
  Future _loadForecastTypes() async {
    _forecasts = (await this.repository.getDisplayableForecastList());
    _selectedForecast = await repository.getSelectedForecast();
    if (_selectedForecast == null) {
      _selectedForecast = _forecasts!.first;
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
    for (var time in _forecastTimes) {
      // Get forecast overlay
      imageUrl = _createForecastImageUrl(_regionName, _selectedForecastDate,
          _selectedModelName, _selectedForecast!.forecastName, time, 'body');
      soaringForecastBodyImage = SoaringForecastImage(imageUrl, time);
      soaringForecastImages.add(soaringForecastBodyImage);

      // Get scale image
      imageUrl = _createForecastImageUrl(_regionName, _selectedForecastDate,
          _selectedModelName, _selectedForecast!.forecastName, time, 'side');
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
    for (var time in _forecastTimes) {
      // Get forecast overlay
      imageUrl = _createSoundingImageUrl(_regionName, _selectedForecastDate,
          _selectedModelName, soundingPosition.toString(), time);
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
  String _createForecastImageUrl(
      String regionName,
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

  Future<void> _processIncrDecrRaspForecastHourEvent(IncrDecrRaspForecastHourEvent event, Emitter<RaspDataState> emit)async{
    _updateTimeIndex(event.incrDecrIndex, emit);
  }


  void _updateTimeIndex(int incOrDec, Emitter<RaspDataState> emit) {
    // print('Current _selectedForecastTimeIndex $_selectedForecastTimeIndex'
    //     '  incOrDec $incOrDec');
    if (incOrDec > 0) {
      _selectedForecastTimeIndex =
          (_selectedForecastTimeIndex == _forecastTimes.length - 1)
              ? 0
              : _selectedForecastTimeIndex + incOrDec;
    } else {
      _selectedForecastTimeIndex = (_selectedForecastTimeIndex == 0)
          ? _forecastTimes.length - 1
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
    emit(RaspTaskTurnpoints(<TaskTurnpoint>[]));
    //emit(ViewBoundsState(_viewMapBoundsAndZoom!));
  }

  // If just starting up, see if task was previously saved
  Future<void> _emitCurrentTask(Emitter<RaspDataState> emit) async {
    _taskId = await repository.getCurrentTaskId();
    await _emitTaskTurnpoints(emit, _taskId);
    await _emitEstimatedFlightButtonVisibility(emit);
  }

  Future<void> _emitEstimatedFlightButtonVisibility(Emitter<RaspDataState> emit) async {
    bool showEstimatedFlightButton =
        await repository.getDisplayEstimatedFlightButton();
    emit(ShowEstimatedFlightButton(showEstimatedFlightButton));
  }

  //new task selected
  void _getTurnpointsForTaskId(
      GetTaskTurnpointsEvent event, Emitter<RaspDataState> emit) async {
    _taskId = event.taskId;
    repository.setCurrentTaskId(_taskId);
    await _emitTaskTurnpoints(emit, _taskId);
    await _emitEstimatedFlightButtonVisibility(emit);
  }

  FutureOr<void> _emitTaskTurnpoints(
      Emitter<RaspDataState> emit, int taskId) async {
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

  Future<List<TaskTurnpoint>> _addTaskTurnpointDetails(int taskId) async {
    List<TaskTurnpoint> taskTurnpoints =
        await repository.getTaskTurnpoints(taskId);
    return taskTurnpoints;
  }

  void _displayTaskTurnpoint(
      DisplayTaskTurnpointEvent event, Emitter<RaspDataState> emit) async {
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

  void _displayLocalForecast(
      DisplayLocalForecastEvent event, Emitter<RaspDataState> emit) async {
    List<LocalForecastPoint> localForecastPoints = [];
    int startIndex = 0;
    if (event.forTask && _taskId > -1) {
      // ok - a task is displayed and a local forecast was requested on one of the
      // task turnpoints so get list of all turnpoints
      List<TaskTurnpoint> taskTurnpoints = await _getTaskTurnpoints(_taskId);
      localForecastPoints.addAll(taskTurnpoints
          .map((taskTurnpoint) => LocalForecastPoint(
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
        regionName: _regionName,
        date: _selectedForecastDate,
        model: _selectedModelName,
        times: _forecastTimes,
        localForecastPoints: localForecastPoints,
        startIndex: startIndex);
    emit(DisplayLocalForecastGraphState(localForecastGraphData));
  }

// Can't get flutter_map to display updated markers without issuing state
  void _redisplayMarkers(
      RedisplayMarkersEvent event, Emitter<RaspDataState> emit) {
    emit(RedisplayMarkersState());
  }

// check new bounds and if needed send turnpoints and soundings within those bounds
  FutureOr<void> _processViewBounds(
      ViewBoundsEvent event, Emitter<RaspDataState> emit) async {
    _regionLatLngBounds = event.latLngBounds;
    await _emitTurnpoints(emit);
  }

  FutureOr<void> _processRaspDisplayOptionsEvent(
      RaspDisplayOptionsEvent event, Emitter<RaspDataState> emit) async {
    await Future.forEach(event.displayOptions, (preferenceOption)  async {
      switch (preferenceOption.key) {
        case (turnpointsDisplayOption):
          {
            _displayTurnpoints = preferenceOption.selected;
            await _emitTurnpoints(emit);
          }
      }
    });
  }

  // This should only occur when user requests this particular option to be displayed.
  FutureOr<void> _processRaspDisplayOptionEvent(
      RaspDisplayOptionEvent event, Emitter<RaspDataState> emit) async {
    switch (event.displayOption.key)  {
      case (turnpointsDisplayOption):
        {
          _displayTurnpoints = event.displayOption.selected;
          await _emitTurnpoints(emit);
        }
        break;
    }
  }

  Future<void> _emitTurnpoints(Emitter<RaspDataState> emit) async {
    if (_displayTurnpoints) {
      // only send turnpoints based on current lat/long corners of map
      List<Turnpoint> turnpoints =
          await repository.getTurnpointsWithinBounds(_regionLatLngBounds!);
      emit(TurnpointsInBoundsState(turnpoints));
    } else {
      emit(TurnpointsInBoundsState(<Turnpoint>[]));
    }
  }

  FutureOr<void> _processSoundingsEvent(
      DisplayRaspSoundingsEvent event, Emitter<RaspDataState> emit) {
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
    emit(RaspTimeState(
        _soundingsImageSets[_selectedForecastTimeIndex].localTime,_selectedForecastTimeIndex));
  }

  FutureOr<void> _processDisplayCurrentForecast(
      DisplayCurrentForecastEvent event, Emitter<RaspDataState> emit) {
    _displayType = _DisplayType.forecast;
    _getForecastImages();
    _emitRaspForecastImageSet(emit);
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

  FutureOr<void> _reloadForecastTypes(
      LoadForecastTypesEvents event, Emitter<RaspDataState> emit) async {
    await _loadForecastTypes();
    _emitForecasts(emit);
  }

  FutureOr<void> _refreshTask(
      RefreshTaskEvent event, Emitter<RaspDataState> emit) {
    _emitCurrentTask(emit);
  }

  FutureOr<void> _checkIfForecastRefreshNeeded(
      CheckIfForecastRefreshNeededEvent event,
      Emitter<RaspDataState> emit) async {
    var lastForecast = await repository.getLastForecastTime();
    // 1800000 millisecs equals 30 minutes
    if (lastForecast == 0 ||
        (DateTime.now().millisecondsSinceEpoch - lastForecast) > 1800000) {
      // Last time forecast model date/times obtained from server was over 30 minutes ago, so refresh
      // (there might be newer model forecasts available)
      await _listTypesOfForecasts(event, emit);
    }
  }
}
