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
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/view_bounds.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';

import '../../local_forecast/bloc/local_forecast_graph.dart';
import 'rasp_bloc.dart';

enum _DisplayType { forecast, sounding }

/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
class RaspDataBloc extends Bloc<RaspDataEvent, RaspDataState> {
  final Repository repository;
  String _regionName = "";
  String _selectedModelName = ""; // nam
  String _selectedForecastDate = ""; // selected date  2019-12-19
  String _selectedForecastTime = "";

  List<String> _forecastTimes = [];
  int _selectedForecastTimeIndex = 4; // start at   1300 forecast

  ///TODO break out forecasts to separate block
  List<Forecast>? _forecasts;
  Forecast? _selectedForecast;
  List<SoaringForecastImageSet> _forecastImageSets = [];
  List<SoaringForecastImageSet> _soundingsImageSets = [];
  LatLngBounds? _regionLatLngBounds;
  ViewBounds? _viewMapBoundsAndZoom;

  _DisplayType _displayType = _DisplayType.forecast;

  ModelDateDetail? _beginnerModeModelDataDetail;
  List<ModelDateDetail> _beginnerModelDateDetailList = [];

  // index into list of soundings
  int _soundingPosition = 0;

  int _taskId = -1;

  RaspDataBloc({required this.repository}) : super(RaspInitialState()) {
    on<InitialRaspRegionEvent>(_processInitialRaspRegionEvent);
    on<MapReadyEvent>(_processMapReadyEvent);
    on<SelectedRegionModelDetailEvent>(_processSelectedRegionModelDetail);
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
    on<RefreshForecastEvent>(_refreshForecast);
    on<CheckIfForecastRefreshNeededEvent>(_checkIfForecastRefreshNeeded);
    on<GetEstimatedFlightAvgEvent>(_getEstimatedFlightAvg);
    on<RunForecastAnimationEvent>(_processRunAnimationEvent);
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
    _selectedForecastTime = event.localTime;
    _emitForecastSoundingImageSets(emit);
    emit (RunForecastAnimationState(false));
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
    await _emitDisplayOptions(emit);
  }

  Future<void> _emitForecastMapInfo(Emitter<RaspDataState> emit) async {
    try {
      emit(RaspWorkingState(working: true));
      await _emitDisplayOptions(emit);
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
    await _refreshForecast(event, emit);
  }

  Future<void> _refreshForecast(_, Emitter<RaspDataState> emit) async {
    await _emitTypesOfForecasts(emit);
    await _emitForecastMapInfo(emit);
  }

  Future<void> _processModelChange(
      String modelName, Emitter<RaspDataState> emit) async {
    _selectedModelName = modelName;
    _emitForecastSoundingImageSets(emit);
    emit(EstimatedFlightSummaryState(null));
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

  Future<void> _processSelectedDateChange(
      String forecastDate, Emitter<RaspDataState> emit) async {
    _selectedForecastDate = forecastDate;
    _emitForecastSoundingImageSets(emit);
    emit(EstimatedFlightSummaryState(null));
  }

  void _emitForecasts(Emitter<RaspDataState> emit) {
    emit(RaspForecasts(_forecasts!, _selectedForecast!));
    //print('emitted RaspForecasts');
  }

  void _emitRaspForecastImageSet(Emitter<RaspDataState> emit) {
    emit(RaspForecastImageSet(_forecastImageSets[_selectedForecastTimeIndex],
        _selectedForecastTimeIndex, _forecastImageSets.length));
    emit(RaspTimeState(
        _forecastImageSets[_selectedForecastTimeIndex].localTime));
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
    for (var time in _forecastTimes!) {
      // Get forecast overlay
      imageUrl = _createSoundingImageUrl(_regionName, _selectedForecastDate,
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
    _viewMapBoundsAndZoom = ViewBounds(_regionLatLngBounds!);
    repository.saveViewBounds(_viewMapBoundsAndZoom!); // 7 default zoom
    emit(RaspTaskTurnpoints(<TaskTurnpoint>[]));
    emit(EstimatedFlightSummaryState(null));
    //emit(ViewBoundsState(_viewMapBoundsAndZoom!));
  }

  Future<void> _emitCurrentTask(Emitter<RaspDataState> emit) async {
    _taskId = await repository.getCurrentTaskId();
    await _emitTaskTurnpoints(emit, _taskId);
    bool showEstimatedFlightButton =
        await repository.getDisplayEstimatedFlightButton();
    emit(ShowEstimatedFlightButton(showEstimatedFlightButton));
  }

  void _getTurnpointsForTaskId(
      GetTaskTurnpointsEvent event, Emitter<RaspDataState> emit) async {
    emit(EstimatedFlightSummaryState(null));
    _taskId = event.taskId;
    repository.setCurrentTaskId(_taskId);
    await _emitTaskTurnpoints(emit, _taskId);
  }

  void _getEstimatedFlightAvg(
      GetEstimatedFlightAvgEvent event, Emitter<RaspDataState> emit) async {
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
        _regionName,
        _selectedForecastDate,
        _selectedModelName,
        'd2',
        _forecastTimes[_selectedForecastTimeIndex] + 'x',
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
      // task turnpoints so get assemble list of all turnpoints
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

// This should only occur when user requests this particular option to be displayed.
  FutureOr<void> _processSaveRaspDisplayOptions(
      SaveRaspDisplayOptionsEvent event, Emitter<RaspDataState> emit) async {
    switch (event.displayOption.key) {
      // case (soundingsDisplayOption):
      //   {
      //     if (event.displayOption.selected) {
      //       if (_region!.soundings != null) {
      //         emit(RaspSoundingsState(event.displayOption.selected
      //             ? _region!.soundings!
      //             : <Soundings>[]));
      //       }
      //     } else {
      //       emit(RaspSoundingsState((<Soundings>[])));
      //     }
      //     break;
      //   }
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
  FutureOr<void> _processViewBounds(
      ViewBoundsEvent event, Emitter<RaspDataState> emit) async {
    repository.saveViewBounds(ViewBounds(event.latLngBounds));
    await _emitDisplayOptions(emit);
    // emit(RedisplayMarkersState());
  }

// initial check for display options (soundings, turnpoints, sua) and send them if needed
  FutureOr<void> _emitDisplayOptions(Emitter<RaspDataState> emit) async {
    final preferenceOptions = await repository.getRaspDisplayOptions();
    for (var option in preferenceOptions) {
      switch (option.key) {
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

  FutureOr<void> _processSoundingsEvent(
      DisplaySoundingsEvent event, Emitter<RaspDataState> emit) {
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
        _soundingsImageSets[_selectedForecastTimeIndex].localTime));
  }

  FutureOr<void> _processDisplayCurrentForecast(
      DisplayCurrentForecastEvent event, Emitter<RaspDataState> emit) {
    _displayType = _DisplayType.forecast;
    _getForecastImages();
    _emitRaspForecastImageSet(emit);
  }

  _getSuaDetails(Emitter<RaspDataState> emit) async {
    // var sua = await repository.getSuaForRegion(_region!.name!);
    String? sua = await repository.getGeoJsonSUAForRegion(_regionName);
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
      await _refreshForecast(event, emit);
    }
  }

  // returned from Local forecast screen where model/date may have changed from original RASP
  FutureOr<void> _processLocalForecastOutputData(
      ReturnedFromLocalForecastEvent event, Emitter<RaspDataState> emit) async {
    if (event.modelName != _selectedModelName) {
      // process modelName change
      await _processModelChange(event.modelName, emit);
    }
    if (event.date != _selectedForecastDate) {
      await _processSelectedDateChange(event.date, emit);
    }
  }


  // Just inform any other widgets dependent on the state of the forecast animation
  FutureOr<void> _processRunAnimationEvent(RunForecastAnimationEvent event, Emitter<RaspDataState> emit) {
    emit (RunForecastAnimationState(event.runAnimation));
  }
}
