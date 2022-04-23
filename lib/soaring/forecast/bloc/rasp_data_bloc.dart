import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/LatLngForecast.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';

import 'rasp_bloc.dart';

/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
/// Bloc processes Events and outputs State
class RaspDataBloc extends Bloc<RaspDataEvent, RaspDataState> {
  final Repository repository;
  Regions? _regions;
  Region? _region;
  List<String>? _modelNames; // gfs, nam, rap, hrr
  String? _selectedModelname; // nam
  ModelDates? _selectedModelDates; // all dates/times for the selected model
  List<String>? _forecastDates; // array of dates like  2019-12-19
  String? _selectedForecastDate; // selected date  2019-12-19
  List<String>? _forecastTimes;
  int _selectedForecastTimeIndex = 4; // start at to 1300 forecast
  int _startingForecastTimeIndex = 4;

  List<Forecast>? _forecasts;
  Forecast? _selectedForecast;
  List<SoaringForecastImageSet> _imageSets = [];
  LatLngBounds? _latLngBounds;
  AnimationController? _forecastImageAnimationController;
  Animation<double>? _forecastImageAnimation;
  bool _runAnimation = true;

  RaspDataBloc({required this.repository}) : super(RaspInitialState()) {
    on<InitialRaspRegionEvent>(_processInitialRaspRegionEvent);
    on<SelectedRaspModelEvent>(_processSelectedModelEvent);
    on<SelectRaspForecastDateEvent>(_processSelectedDateEvent);
    on<NextTimeEvent>(_processNextTimeEvent);
    on<PreviousTimeEvent>(_processPreviousTimeEvent);
    on<SelectedRaspForecastEvent>(_processSelectedForecastEvent);
    on<GetTaskTurnpointsEvent>(_getTurnpointsForTaskId);
    on<ClearTaskEvent>(_clearTask);
    on<MapReadyEvent>(_checkForPreviouslySelectedTask);
    on<DisplayTaskTurnpointEvent>(_displayTaskTurnpoint);
    on<DisplayLocalForecastEvent>(_displayLocalForecast);
    on<RemoveLocalForecastEvent>(_removeLatLngForecast);
  }

  void _processInitialRaspRegionEvent(
      InitialRaspRegionEvent event, Emitter<RaspDataState> emit) async {
    try {
      await _loadForecastTypes();
      _emitForecasts(emit);

      if (_regions == null) {
        _regions = await this.repository.getRegions();
      }
      if (_regions != null) {
        // TODO - get last region displayed from repository and if in list of regions
        _region = _regions!.regions!.firstWhereOrNull(
            (region) => (region.name == _regions!.initialRegion))!;
        // Now get the model (gfs/etc)
        await _loadRaspValuesForRegion();
        await _getSelectedModelDates();
        // need to get all dates before you can generate the list of models
        _setRegionModelNames();
        _emitRaspModels(emit);
        _emitRaspModelDates(emit);
        _emitRaspLatLngBounds(emit);
        _getForecastImages();
        _emitRaspImageSet(emit);
      }
    } catch (_) {
      emit(RaspDataLoadErrorState("Error getting regions."));
    }
  }

  void _processSelectedModelEvent(
      SelectedRaspModelEvent event, Emitter<RaspDataState> emit) {
    _selectedModelname = event.modelName;
    print('Selected model: $_selectedModelname');
    // emits same list of models with new selected model
    _emitRaspModels(emit);
    _getDatesForSelectedModel();
    _emitRaspModelDates(emit);
    _getForecastImages();
    _emitRaspImageSet(emit);
  }

  void _processSelectedForecastEvent(
      SelectedRaspForecastEvent event, Emitter<RaspDataState> emit) async {
    _selectedForecast = event.forecast;
    _emitForecasts(emit);
    _getForecastImages();
    _emitRaspImageSet(emit);
  }

  void _processSelectedDateEvent(
      SelectRaspForecastDateEvent event, Emitter<RaspDataState> emit) {
    _selectedForecastDate = event.forecastDate;
    _emitRaspModelDates(emit);
    // update times and images for new date
    _setForecastTimesForDate();
    _getForecastImages();
    _emitRaspImageSet(emit);
  }

  void _emitRaspModels(Emitter<RaspDataState> emit) {
    emit(RaspForecastModels(_modelNames!, _selectedModelname!));
    print('emitted RaspForecastModels');
  }

  void _emitRaspModelDates(Emitter<RaspDataState> emit) {
    emit(RaspModelDates(_forecastDates!, _selectedForecastDate!));
    print('emitted RaspForecastDates');
  }

  void _emitForecasts(Emitter<RaspDataState> emit) {
    emit(RaspForecasts(_forecasts!, _selectedForecast!));
    print('emitted RaspForecasts');
  }

  void _emitRaspLatLngBounds(Emitter<RaspDataState> emit) {
    emit(RaspMapLatLngBounds(_latLngBounds!));
    print('emitted RaspMapLatLngBounds');
  }

  void _emitRaspImageSet(Emitter<RaspDataState> emit) {
    emit(RaspForecastImageSet(_imageSets[_selectedForecastTimeIndex],
        _selectedForecastTimeIndex, _imageSets.length));
    print(
        'emitted RaspForecastImageSet  ${_imageSets[_selectedForecastTimeIndex]}');
  }

  Future<Region> _loadRaspValuesForRegion() async {
    return await this.repository.loadForecastModelsByDateForRegion(_region!);
  }

  void _setRegionModelNames() {
    _modelNames = _region!
        .getModelDates()
        .map((modelDates) => modelDates.modelName!)
        .toList();
    _selectedModelname = _selectedModelDates!.modelName!;
  }

  /// wstar_bsratio, wstar, ...
  Future _loadForecastTypes() async {
    _forecasts = (await this.repository.getForecastTypes()).forecasts!;
    _selectedForecast = _forecasts!.first;
  }

  Future _getSelectedModelDates() async {
    await repository.loadForecastModelsByDateForRegion(_region!);
    // TODO - get last model (gfs, name) from repository and display
    _selectedModelDates = _region!.getModelDates().first;
    _updateForecastDates();
  }

  // A new model (e.g. nam) has been selected so get new dates and times
  // for selected model
  void _getDatesForSelectedModel() {
    // first get the set of dates available for the model
    _selectedModelDates = _region!
        .getModelDates()
        .firstWhere((modelDate) => modelDate.modelName == _selectedModelname);
    // then get the display dates, the date to initially display for the model
    // (and also set the forecast times for that date)
    _updateForecastDates();
  }

  // Dependent on having _selectedModelDates assigned
  void _updateForecastDates() {
    _setForecastDates();
    // stay on same date if new model has forecast for that date
    if (_selectedForecastDate == null ||
        !_forecastDates!.contains(_selectedForecastDate)) {
      _selectedForecastDate = _forecastDates!.first;
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
    List<ModelDateDetails> modelDateDetails =
        _selectedModelDates!.getModelDateDetailList();
    _forecastDates = modelDateDetails
        .map((modelDateDetails) => modelDateDetails.date!)
        .toList();
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
    _latLngBounds = modelDateDetail.latLngBounds;
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
  /// _forecastTimes   [0900,1000,...]
  void _getForecastImages() {
    String imageUrl;
    SoaringForecastImage soaringForecastBodyImage;
    SoaringForecastImage soaringForecastSideImage;

    _imageSets.clear();
    var soaringForecastImages = [];
    var futures = <Future>[];
    for (var time in _forecastTimes!) {
      // Get forecast overlay
      imageUrl = _createImageUrl(_region!.name!, _selectedForecastDate!,
          _selectedModelname!, _selectedForecast!.forecastName, time, 'body');
      soaringForecastBodyImage = SoaringForecastImage(imageUrl, time);
      soaringForecastImages.add(soaringForecastBodyImage);

      // Get scale image
      imageUrl = _createImageUrl(_region!.name!, _selectedForecastDate!,
          _selectedModelname!, _selectedForecast!.forecastName, time, 'side');
      soaringForecastSideImage = SoaringForecastImage(imageUrl, time);
      soaringForecastImages.add(soaringForecastSideImage);

      var soaringForecastImageSet = SoaringForecastImageSet(
          localTime: time,
          bodyImage: soaringForecastBodyImage,
          sideImage: soaringForecastSideImage);

      _imageSets.add(soaringForecastImageSet);
    }
    //Start getting images to try to make initial UI animation smoother
    // Start at first image to be displayed
    // for (int i = _selectedForecastTimeIndex; i < _imageSets.length; ++i) {
    //   futures.add(Future<NetworkImage>.value(NetworkImage(
    //       Constants.RASP_BASE_URL + _imageSets[i].bodyImage!.imageUrl)));
    //   futures.add(Future<NetworkImage>.value(NetworkImage(
    //       Constants.RASP_BASE_URL + _imageSets[i].sideImage!.imageUrl)));
    // }
    // for (int i = 0; i < _selectedForecastTimeIndex; ++i) {
    //   futures.add(Future<NetworkImage>.value(NetworkImage(
    //       Constants.RASP_BASE_URL + _imageSets[i].bodyImage!.imageUrl)));
    //   futures.add(Future<NetworkImage>.value(NetworkImage(
    //       Constants.RASP_BASE_URL + _imageSets[i].sideImage!.imageUrl)));
    // }
    // //unawaited(Future.wait(futures));
    // getImagesAheadOfTime(futures);
  }

  void getImagesAheadOfTime(List<Future> imageFutures) async {
    for (var imageFuture in imageFutures) {
      await imageFuture.then((resp) {
        print("Image future complete");
      });
    }
  }

  Future<SoaringForecastImage> _getRaspForecastImage(
      SoaringForecastImage soaringForecastImage) {
    return repository.getRaspForecastImageByUrl(soaringForecastImage);
  }

  /// Create url for fetching forecast overly
  /// eg. "/NewEngland/2019-12-19/gfs/wstar_bsratio.1500local.d2.body.png"
  String _createImageUrl(String regionName, String forecastDate, String model,
      String forecastType, String forecastTime, String imageType) {
    var stripOld = forecastTime.startsWith("old")
        ? forecastTime.substring(4)
        : forecastTime;
    return "/$regionName/$forecastDate/$model/$forecastType.${stripOld}local.d2.$imageType.png";
  }

  void _processNextTimeEvent(_, Emitter<RaspDataState> emit) {
    _updateTimeIndex(1, emit);
  }

  void _processPreviousTimeEvent(_, Emitter<RaspDataState> emit) {
    _updateTimeIndex(-1, emit);
  }

  void _updateTimeIndex(int incOrDec, Emitter<RaspDataState> emit) {
    print('Current _selectedForecastTimeIndex $_selectedForecastTimeIndex'
        '  incOrDec $incOrDec');
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
    print('New _selectedForecastTimeIndex $_selectedForecastTimeIndex');

    emit(RaspForecastImageSet(_imageSets[_selectedForecastTimeIndex],
        _selectedForecastTimeIndex, _imageSets.length));
  }

  void _clearTask(ClearTaskEvent event, Emitter<RaspDataState> emit) async {
    repository.setCurrentTaskId(-1);
    emit(RaspTaskTurnpoints(<TaskTurnpoint>[]));
  }

  void _showTaskIfSelected(Emitter<RaspDataState> emit) async {
    var taskId = await repository.getCurrentTaskId();
    _emitTaskTurnpoints(emit, taskId);
  }

  void _checkForPreviouslySelectedTask(
      MapReadyEvent event, Emitter<RaspDataState> emit) async {
    var taskId = await repository.getCurrentTaskId();
    await _emitTaskTurnpoints(emit, taskId);
  }

  void _getTurnpointsForTaskId(
      GetTaskTurnpointsEvent event, Emitter<RaspDataState> emit) async {
    repository.setCurrentTaskId(event.taskId);
    await _emitTaskTurnpoints(emit, event.taskId);
  }

  FutureOr<void> _emitTaskTurnpoints(
      Emitter<RaspDataState> emit, int taskId) async {
    if (taskId > -1) {
      final List<TaskTurnpoint> taskTurnpoints =
          await _addTaskTurnpointDetails(taskId);
      print('emitting taskturnpoints');
      emit(RaspTaskTurnpoints(taskTurnpoints));
    }
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
      emit(RaspDataLoadErrorState(
          "Oops. Turnpoint not found based on TaskTurnpoint"));
    }
  }

  void _displayLocalForecast(
      DisplayLocalForecastEvent event, Emitter<RaspDataState> emit) async {
    String latLngForecastParms;
    switch (_selectedForecast!.forecastCategory) {
      case ForecastCategory.WAVE:
        latLngForecastParms =
            "press1000 press1000wspd press1000wdir press950 press950wspd press950wdir press850 press850wspd press850wdir" +
                " press700 press700wspd press700wdir press500 press500wspd press500wdir";
        break;
      default:
        latLngForecastParms =
            "wstar bsratio zsfclcldif zsfclcl zblcldif zblcl  sfcwind0spd sfcwind0dir sfcwindspd sfcwinddir blwindspd blwinddir bltopwindspd bltopwinddir";
    }
    try {
      final httpResponse = await repository.getLatLngForecast(
          _region!.name!,
          _selectedForecastDate!,
          _selectedModelname!,
          _imageSets[_selectedForecastTimeIndex].localTime,
          event.latLng.latitude.toString(),
          event.latLng.longitude.toString(),
          latLngForecastParms);
      if (httpResponse.response.statusCode! >= 200 &&
          httpResponse.response.statusCode! < 300) {
        print('LatLngForecast text ${httpResponse.response.data.toString()}');
        emit(LocalForecastState(LatLngForecast(
            latLng: event.latLng,
            forecastText: httpResponse.response.data.toString())));
      }
    } catch (e) {
      emit(RaspDataLoadErrorState(
          "Oops. An error occurred getting the location forecast"));
      print(e.toString());
    }
  }

  void _removeLatLngForecast(
      RemoveLocalForecastEvent event, Emitter<RaspDataState> emit) {
    emit(RemoveLocalForecastState());
  }
}
