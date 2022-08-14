import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/LatLngForecast.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/repository/options/special_use_airspace.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';

import 'rasp_bloc.dart';

class DelayEmitState {
  final Emitter<RaspDataState> emit;
  final RaspDataState state;

  DelayEmitState(this.emit, this.state);
}

enum _DisplayType { forecast, sounding }

/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
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
  int _selectedForecastTimeIndex = 4; // start at   1300 forecast

  List<Forecast>? _forecasts;
  Forecast? _selectedForecast;
  List<SoaringForecastImageSet> _forecastImageSets = [];
  List<SoaringForecastImageSet> _soundingsImageSets = [];
  LatLngBounds? _latLngBounds;

  _DisplayType _displayType = _DisplayType.forecast;

  RaspDataBloc({required this.repository}) : super(RaspInitialState()) {
    on<InitialRaspRegionEvent>(_processInitialRaspRegionEvent);
    on<SelectedRaspModelEvent>(_processSelectedModelEvent);
    on<SelectRaspForecastDateEvent>(_processSelectedDateEvent);
    on<NextTimeEvent>(_processNextTimeEventAndEmitImage);
    on<PreviousTimeEvent>(_processPreviousTimeEventAndEmitImage);
    on<SelectedRaspForecastEvent>(_processSelectedForecastEvent);
    on<DisplayCurrentForecastEvent>(_processDisplayCurrentForecast);
    on<GetTaskTurnpointsEvent>(_getTurnpointsForTaskId);
    on<ClearTaskEvent>(_clearTask);
    on<MapReadyEvent>(_checkForPreviouslySelectedTask);
    on<DisplayTaskTurnpointEvent>(_displayTaskTurnpoint);
    on<DisplayLocalForecastEvent>(_displayLocalForecast);
    on<RedisplayMarkersEvent>(_redisplayMarkers);
    on<SaveRaspDisplayOptionsEvent>(_processSaveRaspDisplayOptions);
    on<NewLatLngBoundsEvent>(_processNewLatLongBounds);
    on<DisplaySoundingsEvent>(_processSoundingsEvent);
    on<SetForecastOverlayOpacityEvent>(_setForecastOverlayOpacity);
    on<LoadForecastTypesEvents>(_reloadForecastTypes);
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
        await _sendInitialForecastOverlayOpacity(emit);
        await _emitDisplayOptions(emit);
        await waitAFrame();
        _emitRaspForecastImageSet(emit);
      }
    } catch (e) {
      print("Error: ${e.toString()}");
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
    _emitRaspForecastImageSet(emit);
  }

  void _processSelectedForecastEvent(
      SelectedRaspForecastEvent event, Emitter<RaspDataState> emit) async {
    _selectedForecast = event.forecast;
    _emitForecasts(emit);
    _getForecastImages();
    _emitRaspForecastImageSet(emit);
  }

  void _processSelectedDateEvent(
      SelectRaspForecastDateEvent event, Emitter<RaspDataState> emit) {
    _selectedForecastDate = event.forecastDate;
    _emitRaspModelDates(emit);
    // update times and images for new date
    _setForecastTimesForDate();
    _getForecastImages();
    _emitRaspForecastImageSet(emit);
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

  void _emitRaspForecastImageSet(Emitter<RaspDataState> emit) {
    emit(RaspForecastImageSet(_forecastImageSets[_selectedForecastTimeIndex],
        _selectedForecastTimeIndex, _forecastImageSets.length));
    print(
        'emitted RaspForecastImageSet  ${_forecastImageSets[_selectedForecastTimeIndex]}');
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
    _forecasts = (await this.repository.getForecastList());
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

    _forecastImageSets.clear();
    var soaringForecastImages = [];
    for (var time in _forecastTimes!) {
      // Get forecast overlay
      imageUrl = _createForecastImageUrl(_region!.name!, _selectedForecastDate!,
          _selectedModelname!, _selectedForecast!.forecastName, time, 'body');
      soaringForecastBodyImage = SoaringForecastImage(imageUrl, time);
      soaringForecastImages.add(soaringForecastBodyImage);

      // Get scale image
      imageUrl = _createForecastImageUrl(_region!.name!, _selectedForecastDate!,
          _selectedModelname!, _selectedForecast!.forecastName, time, 'side');
      soaringForecastSideImage = SoaringForecastImage(imageUrl, time);
      soaringForecastImages.add(soaringForecastSideImage);

      var soaringForecastImageSet = SoaringForecastImageSet(
          localTime: time,
          bodyImage: soaringForecastBodyImage,
          sideImage: soaringForecastSideImage);

      _forecastImageSets.add(soaringForecastImageSet);
    }
  }

  void _getSoundingImages(final int soundingIndex) {
    String imageUrl;
    SoaringForecastImage soaringForecastBodyImage;

    _soundingsImageSets.clear();
    var soundingImages = [];
    for (var time in _forecastTimes!) {
      // Get forecast overlay
      imageUrl = _createSoundingImageUrl(_region!.name!, _selectedForecastDate!,
          _selectedModelname!, soundingIndex.toString(), time);
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
    return "/$regionName/$forecastDate/$model/$forecastType.${stripOld}local.d2.$imageType.png";
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
    _updateTimeIndex(1, emit);
  }

  void _processPreviousTimeEventAndEmitImage(_, Emitter<RaspDataState> emit) {
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
    emit(RaspTaskTurnpoints(<TaskTurnpoint>[]));
  }

  void _checkForPreviouslySelectedTask(
      MapReadyEvent event, Emitter<RaspDataState> emit) async {
    var taskId = await repository.getCurrentTaskId();
    await _emitTaskTurnpoints(emit, taskId);
    await _emitRaspDisplayOptions(emit);
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

  _emitRaspDisplayOptions(Emitter<RaspDataState> emit) async {
    final preferenceOptions = await repository.getRaspDisplayOptions();
    emit(RaspDisplayOptionsState(preferenceOptions));
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
          _forecastImageSets[_selectedForecastTimeIndex].localTime,
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

// Can't get flutter_map to display updated markers without issuing state
  void _redisplayMarkers(
      RedisplayMarkersEvent event, Emitter<RaspDataState> emit) {
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
            emit(SuaDetailsState(SUA()));
          }
          break;
        }
      case (turnpointsDisplayOption):
        {
          if (event.displayOption.selected) {
            // only send turnpoints based on current lat/long corners of map
            List<Turnpoint> turnpoints =
                await repository.getTurnpointsWithinBounds(_latLngBounds!);
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
  FutureOr<void> _processNewLatLongBounds(
      NewLatLngBoundsEvent event, Emitter<RaspDataState> emit) {}

// initial check for display options (soundings, turnpoints, sua) and send them if needed
  FutureOr<void> _emitDisplayOptions(Emitter<RaspDataState> emit) async {
    final preferenceOptions = await repository.getRaspDisplayOptions();
    for (var option in preferenceOptions) {
      switch (option.key) {
        case (soundingsDisplayOption):
          if (option.selected) {
            await waitAFrame();
            emit(RaspSoundingsState(_region?.soundings ?? <Soundings>[]));
          } else {
            await waitAFrame();
            emit(RaspSoundingsState(<Soundings>[]));
          }
          print('emitted RaspSoundingsState');
          break;
        case (turnpointsDisplayOption):
          if (option.selected) {
            final turnpoints =
                await repository.getTurnpointsWithinBounds(_latLngBounds!);
            await waitAFrame();
            emit(TurnpointsInBoundsState(turnpoints));
          } else {
            await waitAFrame();
            emit(TurnpointsInBoundsState(<Turnpoint>[]));
          }
          print('emitted TurnpointsInBoundsState');
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
  }

  Future<void> waitAFrame() async {
    await Future.delayed(Duration(milliseconds: 100));
  }

  FutureOr<void> _processSoundingsEvent(
      DisplaySoundingsEvent event, Emitter<RaspDataState> emit) {
    _displayType = _DisplayType.sounding;
    _getSoundingImages(event.sounding.position!);
    _emitSoundingImageSet(emit);
  }

  Future<void> _emitSoundingImageSet(Emitter<RaspDataState> emit) async {
    emit(SoundingForecastImageSet(
        _soundingsImageSets[_selectedForecastTimeIndex],
        _selectedForecastTimeIndex,
        _soundingsImageSets.length));
    print(
        'emitted SoundingsImageSet  ${_soundingsImageSets[_selectedForecastTimeIndex]}');
  }

  FutureOr<void> _processDisplayCurrentForecast(
      DisplayCurrentForecastEvent event, Emitter<RaspDataState> emit) {
    _displayType = _DisplayType.forecast;
    _emitRaspForecastImageSet(emit);
  }

  _getSuaDetails(Emitter<RaspDataState> emit) async {
    var sua = await repository.getSuaForRegion(_region!.name!);
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
    var currentSelectedForecast = _selectedForecast;
    await _loadForecastTypes();
    _selectedForecast = currentSelectedForecast;
    _emitForecasts(emit);
  }
}
