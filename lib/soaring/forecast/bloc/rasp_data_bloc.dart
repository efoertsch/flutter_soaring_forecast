import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/rasp_selection_values.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/json/forecast_models.dart';
import 'package:flutter_soaring_forecast/soaring/json/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/json/regions.dart';
import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'rasp_bloc.dart';

/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
/// Bloc processes Events and outputs State
class RaspDataBloc extends Bloc<RaspDataEvent, RaspDataState>
    implements TickerProvider {
  final Repository repository;
  Regions _regions;
  Region _region;
  String _selectedModelname;
  ModelDates _selectedModelDates;
  List<String> _forecastDates; // array of dates like  2019-12-19
  String _selectedForecastDate; // selected date  2019-12-19
  List<Forecast> _forecasts;
  Forecast _selectedForecast;

  List<String> _forecastTimes;
  int _selectedForecastTimeIndex = 0;
  List<SoaringForecastImageSet> _imageSets = List();
  LatLngBounds _latLngBounds;
  AnimationController _forecastImageAnimationController;
  Animation<double> _forecastImageAnimation;
  bool _runAnimation = true;

  RaspDataBloc({@required this.repository});

  @override
  RaspDataState get initialState => InitialRaspDataState();

  @override
  Stream<RaspDataState> mapEventToState(
    RaspDataEvent event,
  ) async* {
    // TODO: Add Logic
    if (event is GetInitialRaspSelections) {
      yield* _getDefaultRaspRegion();
      return;
    }
    if (event is SelectedRaspRegion) {
      _region = event.region;
      yield* _getRaspRegion();
      return;
    }
    if (event is SelectedRaspModel) {
      _selectedModelname = event.modelName;
      _updateModelNamesAndTimes();
      return;
    }

    if (event is SetRaspForecastDate) {
      _selectedForecastDate = event.forecastDate;
      updateForecastTimesList();
      return;
    }

    if (event is LoadForecastTypes) {
      yield* _getForecastTypes();
      return;
    }
    if (event is RunAnimationEvent) {
      _updateAnimationControl(event.runAnimation);
    }
  }

  /// Potential series of calls
  /// 1. If regions not yet found, get the list
  /// 2. See if preferences has a region and select that, if not then pick
  ///    first on list
  /// 3. Fill in all models/dates/times for that region then return that
  Stream<RaspDataState> _getDefaultRaspRegion() async* {
    try {
      if (_regions == null) {
        _regions = await this.repository.getRegions();
      }
      if (_regions != null) {
        // TODO - get last region displayed from repository and if in list of regions
        _region = _regions.regions
            .firstWhere((region) => (region.name == _regions.initialRegion));
        // Now get the model (gfs/etc)
        yield* _getRaspRegion();
      }
    } catch (_) {
      yield RaspDataLoadErrorState("Error getting regions.");
    }
  }

  Stream<RaspDataState> _getRaspRegion() async* {
    try {
      _updateAnimationControl(false);
      await _loadRaspValuesForRegion(_region);
      // Get models for each forecast date
      await _getSelectedModelDates();
      //yield RaspModelDatesSelected(_selectedModelDates);
      await _loadForecastTypes();
      yield* _createRaspSelectionValues();
      yield* _getMapLatLngBounds();
    } catch (_) {
      yield RaspDataLoadErrorState("Error getting region.");
    }
  }

  Future<Region> _loadRaspValuesForRegion(Region region) async {
    return await this.repository.loadForecastModelsByDateForRegion(region);
  }

  Future _getSelectedModelDates() async {
    await repository.loadForecastModelsByDateForRegion(_region);
    // TODO - get last model (gfs, name) from repository and display
    _selectedModelDates = _region.getModelDates().first;
    _updateForecastDates();
  }

  Stream<RaspDataState> _getForecastTypes() async* {
    try {
      await _loadForecastTypes();
      yield RaspForecastTypesLoaded(_forecasts);
    } catch (_) {
      yield RaspDataLoadErrorState("Error getting forecastTypes");
    }
  }

  /// wstar_bsratio, wstar, ...
  Future _loadForecastTypes() async {
    _forecasts = (await this.repository.getForecastTypes()).forecasts;
    _selectedForecast = _forecasts.first;
  }

  // Dependent on having _selectedModelDates assigned
  void _updateForecastDates() {
    _setForecastDates();
    // stay on same date if new model has forecast for that date
    if (_selectedForecastDate == null ||
        !_forecastDates.contains(_selectedForecastDate)) {
      _selectedForecastDate = _forecastDates.first;
    }
    updateForecastTimesList();
  }

  /// Get a list of both display dates (printDates November 12, 2019)
  /// and dates for constructing calls to rasp (dates 2019-11-12)
  void _setForecastDates() {
    List<ModelDateDetails> modelDateDetails =
        _selectedModelDates.getModelDateDetailList();
    _forecastDates = modelDateDetails
        .map((modelDateDetails) => modelDateDetails.date)
        .toList();
  }

  void updateForecastTimesList() {
    var model = _selectedModelDates
        .getModelDateDetailList()
        .firstWhere((modelDateDetails) =>
            modelDateDetails.date == _selectedForecastDate)
        .model;
    _forecastTimes = model.times;

    // Stay on same time if new forecastTimes has same time as previous
    // Making reasonable assumption that times in same order across models/dates
    if (_selectedForecastTimeIndex > _forecastTimes.length - 1) {
      _selectedForecastTimeIndex = 0;
    }
    // While we are here
    _latLngBounds = model.latLngBounds;
  }

  Stream<RaspDataState> _getMapLatLngBounds() async* {
    try {
      Model model =
          _region.getModelDates().first.getModelDateDetailList().first.model;
      yield RaspMapLatLngBounds(model.latLngBounds);
    } catch (_) {
      //TODO why isn't RaspMapLatLngBoundsError valid?
      yield RaspMapLatLngBoundsError();
    }
  }

  Stream<RaspDataState> _createRaspSelectionValues() async* {
    List<String> modelNames = _region
        .getModelDates()
        .map((modelDates) => modelDates.modelName)
        .toList();
    _selectedModelname = _selectedModelDates.modelName;
    _setForecastDates();
    yield RaspSelectionsState(RaspSelectionValues(
        modelNames: modelNames,
        selectedModelName: _selectedModelname,
        forecastDates: _forecastDates,
        selectedForecastDate: _selectedForecastDate,
        forecastTimes: _forecastTimes,
        selectedForecastTimeIndex: _selectedForecastTimeIndex,
        forecasts: _forecasts,
        selectedForecast: _selectedForecast,
        latLngBounds: _latLngBounds));
    _getForecastImages();
  }

  Stream<RaspDataState> _updateModelNamesAndTimes() async* {
    _selectedModelDates = _region.getModelDates().firstWhere(
        ((modelDates) => modelDates.modelName == _selectedModelname));
    _updateForecastDates();
    updateForecastTimesList();
    _selectedModelname = _selectedModelDates.modelName;
    yield (RaspSelectionsState(RaspSelectionValues(
        forecastDates: _forecastDates,
        selectedForecastDate: _selectedForecastDate,
        forecastTimes: _forecastTimes,
        selectedForecastTimeIndex: _selectedForecastTimeIndex,
        latLngBounds: _latLngBounds)));
    _getForecastImages();
  }

  /// Following values must be assigned before calling
  /// _region.name  - NewEngland
  /// _selectedForecastDate  2019-12-12
  /// _selectedModelName  gfs
  /// _selectedForecast  wstart
  /// _forecastTimes   [0900,1000,...]
  void _getForecastImages() async {
    String imageUrl;
    SoaringForecastImage soaringForecastBodyImage;
    SoaringForecastImage soaringForecastSideImage;

    _imageSets.clear();
    var soaringForecastImages = [];
    var futures = <Future>[];
    for (var time in _forecastTimes) {
      // Get forecast overlay
      imageUrl = _createImageUrl(_region.name, _selectedForecastDate,
          _selectedModelname, _selectedForecast.forecastName, time, 'body');
      soaringForecastBodyImage = SoaringForecastImage(imageUrl, time);
      soaringForecastImages.add(soaringForecastBodyImage);

      // Get scale image
      imageUrl = _createImageUrl(_region.name, _selectedForecastDate,
          _selectedModelname, _selectedForecast.forecastName, time, 'side');
      soaringForecastSideImage = SoaringForecastImage(imageUrl, time);
      soaringForecastImages.add(soaringForecastSideImage);

      var soaringForecastImageSet = SoaringForecastImageSet(
          localTime: time,
          bodyImage: soaringForecastBodyImage,
          sideImage: soaringForecastSideImage);

      _imageSets.add(soaringForecastImageSet);
      for (var soaringForecastImage in soaringForecastImages) {
        futures.add(_getRaspForecastImage(soaringForecastImage));
      }
      await Future.wait(futures);

      startImageAnimation();
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
    return "/$regionName/$forecastDate/$model/$forecastType.${forecastTime}local.d2.$imageType.png";
  }

  void _updateAnimationControl(bool runAnimation) {
    _runAnimation = runAnimation;
    if (_runAnimation) {
      startImageAnimation();
    } else {
      if (_forecastImageAnimationController != null &&
          _forecastImageAnimationController.isAnimating) {
        _forecastImageAnimationController.stop();
        _forecastImageAnimationController.dispose();
      }
    }
  }

  void startImageAnimation() {
    if (_forecastImageAnimationController != null &&
        _forecastImageAnimationController.isAnimating) {
      print("Already animating!");
      return;
    }
    print("Starting Image Animation");
    _forecastImageAnimationController = AnimationController(
        value: 0,
        duration: Duration(milliseconds: 15000),
        lowerBound: 0,
        upperBound: _forecastTimes.length.toDouble(),
        vsync: this);
    _forecastImageAnimationController.repeat();
    _forecastImageAnimationController.addListener(imageListener());
    _forecastImageAnimationController.forward();
  }

  @override
  Ticker createTicker(onTick) {
    print('Creating Ticker');
    return Ticker(tickerDuration);
  }

  tickerDuration(Duration elapsed) {
    print('Ticker duration:  $elapsed.inMilliseconds');
  }

  VoidCallback imageListener() {
    _postForecastImageSet(_forecastImageAnimationController.value);
  }

  Stream<RaspDataState> _postForecastImageSet(double value) async* {
    print("Animation value: $_forecastImageAnimationController.value");
    var imageIndex = value.toInt();
    if (imageIndex < _imageSets.length) {
      print("Posting imageSet[$imageIndex]");
      yield new RaspForecastImageDisplay(_imageSets[imageIndex]);
    }
  }
}
