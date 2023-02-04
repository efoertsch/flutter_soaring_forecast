import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/bloc/graphic_event.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/bloc/graphic_state.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/data/forecast_graph_data.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';

//  For following forecasts, you actually need to combine values from 2 other forecasts to determine display
//  zsfclclmask - Cu Cloudbase where CuPotential > 0  requires:
//        zsfclcldif (Cu Potential)  - this value must be positive to display zsfclcl
//        zsfclcl (Cu Cloudbase (Sfc.LCL) MSL)
//  zblclmask   - OD Cloudbase where ODpotential > 0 requires:
//        zblcldif  (OD Potential)
//        zblcl (OD Cloudbase (BL CL) MSL)

class GraphicBloc extends Bloc<GraphicEvent, GraphState> {
  final Repository repository;

  // Note there is special logic to prune off some of the forecast values as
  // they don't get used in graph
  static const _altitudeParmList = [
    "experimental1",
    "zsfclcldif",
    "zsfclcl",
    "zblcldif",
    "zblcl"
  ];
  static const _thermalParmList = [
    "wstar",
  ];

  static const _windParmList = [
    "sfcwind0spd",
    "sfcwind0dir",
    "sfcwindspd",
    "sfcwinddir",
    "blwindspd",
    "blwinddir",
    "bltopwindspd",
    "bltopwinddir"
  ];

  String _forecastParams = "";
  String _forecastTimesParams = "";
  var _altitudeForecastList = <Forecast>[];
  var _thermalForecastList = <Forecast>[];
  var _combinedForecastList = <Forecast>[];
  String? _selectedModelName;
  String? _selectedForecastDate;
  Region? _region;
  String? _regionName;
  List<String>? _modelNames;
  ModelDates? _selectedModelDates;
  List<String>? _forecastDates;
  List<String>? _forecastTimes;
  double? _lat;
  double? _lng;
  String? _turnpointName;

  static final _options = <Forecast>[];
  ForecastGraphData? _forecastGraphData;

  GraphicBloc({required this.repository}) : super(GraphicInitialState()) {
    on<LocalForecastDataEvent>(_getLocalForecastData);
    on<SelectedModelEvent>(_processSelectedModelEvent);
    on<SelectedForecastDateEvent>(_processSelectedDateEvent);
  }

  FutureOr<void> _getLocalForecastData(
      LocalForecastDataEvent event, Emitter<GraphState> emit) async {
    emit(GraphWorkingState(working: true));
    _assignInitialForecastFields(event.localForecastGraphData);
    _setRegionModelNames();
    _getSelectedModelDates();
    _emitModelDates(emit);
    _emitRaspModels(emit);
    _composeRequestParamsString();
    await _getForecastList();
    await _generateGraphDataAndEmit(emit);
    emit(GraphWorkingState(working: false));
  }

  void _assignInitialForecastFields(ForecastInputData inputData) {
    _region = inputData.region;
    _selectedModelName = inputData.model;
    _selectedForecastDate = inputData.date;
    _regionName = inputData.region.name;
    _lat = inputData.lat;
    _lng = inputData.lng;
    _turnpointName = inputData.turnpointName;
  }

  Future<void> _generateGraphDataAndEmit(Emitter<GraphState> emit) async {
    final List<Map<String, Object>> altitudeForecastData = [];
    final List<Map<String, Object>> thermalForecastData = [];
    final List<Map<String, Object>> allData = [];
    await _getLatLongForecast(
            _regionName!,
            _selectedForecastDate!,
            _selectedModelName!,
            _forecastTimesParams,
            _lat.toString(),
            _lng.toString())
        .then((response) {
      // The dailyForecast should consist of
      // 1st line spaces
      // 2nd and subsequent lines
      // space separated list forecast param , forecast for each hour
      // eg. experimental1   1000  2000 3000
      allData.addAll(_extractDailyForecastValues(response));
      // allData contains a map of all hourly forecasts for the day
      // so now we need to extract the forecas ts used for the graphing
      // thermal height, Cu and OD cloud base and thermal strength
      altitudeForecastData.addAll(_getAltitudeForecasts(allData));
      thermalForecastData.addAll(_getThermalForecast(allData));
    }).onError((error, stackTrace) {
      emit(GraphErrorMsgState(error.toString()));
    });
    // Wheew! Now we have maps that contain the data for all forecast times
    // We need to sort altitude data so it can be properly graphed
    _sortAltitudeDataByCodeAndTime(altitudeForecastData);
    // and finally combine it all
    final forecastGraphData = ForecastGraphData(
        date: _selectedForecastDate!,
        model: _selectedModelName!,
        turnpointTitle: _turnpointName,
        lat: _lat,
        lng: _lng,
        altitudeData: altitudeForecastData,
        thermalData: thermalForecastData,
        hours: _forecastTimes!,
        descriptions: _combinedForecastList,
        gridData:
            _createGridData(allData, _forecastTimes!, _combinedForecastList));
    // allData.forEach((map) {
    //   map.entries.forEach((element) {
    //     print("${element.key} : ${element.value.toString()}");
    //   });
    // });
    emit(GraphDataState(forecastData: forecastGraphData));
  }

  // Compose space separated list of forecast parameters for sending to RASP api
  void _composeRequestParamsString() {
    _forecastParams = _altitudeParmList.join("@") +
        "@" +
        _thermalParmList.join("@") +
        "@" +
        _windParmList.join("@");

    _forecastTimesParams = _forecastTimes!.join("@");
  }

  /// Need to sort the forecasts so that graphing routine can properly assign point colors
  /// if say for instance, no OD was forecast for the day
  void _sortAltitudeDataByCodeAndTime(
      List<Map<String, Object>> altitudeForecastData) {
    altitudeForecastData.sort((m1, m2) {
      var r = ((m1['code'] as String)).compareTo((m2['code'] as String));
      if (r != 0) return r;
      return (m1["time"] as String).compareTo(m2["time"] as String);
    });
  }

  List<List<String>> _createGridData(List<Map<String, Object>> gridData,
      List<String> hours, List<Forecast> descriptions) {
    var dataGrid = _createGridMatrix(descriptions.length, hours.length);
    gridData.forEach((element) {
      var col = hours.indexOf(element["time"] as String);
      var row = descriptions.indexWhere(
          (forecast) => forecast.forecastName == element["code"] as String);
      var value = element["value"];
      // debugPrint(" row: $row  col: $col");
      dataGrid[row][col] = (value as double).toStringAsFixed(0);
    });
    return dataGrid;
  }

  List<List<String>> _createGridMatrix(int rows, int cols) {
    return Iterable<List<String>>.generate(
        rows, (i) => new List<String>.filled(cols, " ")).toList();
  }

  /// Create various lists of forecasts used eventually for graph or data table
  /// Depends on prior logic creating _requestParams
  FutureOr<void> _getForecastList() async {
    if (_options.isEmpty) {
      _options.addAll(await repository.getFullForecastList());
    }
    // Create list of all forecasts you will be requesting from api
    _combinedForecastList.clear();
    _forecastParams.split("@").forEach((element) {
      _combinedForecastList.add(
          _options.singleWhere((forecast) => forecast.forecastName == element));
    });

    // Create the forecast list needed for the altitude graph
    _altitudeForecastList.clear();
    _altitudeParmList.forEach((element) {
      _altitudeForecastList.add(_combinedForecastList
          .singleWhere((forecast) => forecast.forecastName == element));
    });

    // Create the list needed for the thermal graph
    _thermalForecastList.clear();
    _thermalParmList.forEach((element) {
      _thermalForecastList.add(
          _options.singleWhere((forecast) => forecast.forecastName == element));
    });
  }

  /// Call the RASP api and return response parsed into lines
  Future<List<String>> _getLatLongForecast(String region, String date,
      String model, String time, String lat, String lng) async {
    final forecastList = <String>[];
    await repository
        .getDaysForecastForLatLong(
            region, date, model, time, lat, lng, _forecastParams)
        .then((httpResponse) {
      if (httpResponse.response.statusCode! >= 200 &&
          httpResponse.response.statusCode! < 300) {
        //print('LatLngForecast text ${httpResponse.response.data.toString()}');
        forecastList.addAll(httpResponse.response.data.toString().split('\n'));
      } else {
        throw Exception(
            "Error occurred in getting local forecast:  ${httpResponse.response.statusMessage}");
      }
    }, onError: (error, stackTrace) {
      debugPrint(
          "Getting forecast info for ${region}  ${date}  ${model}  ${time}  ${_lat.toString()}  ${_lng.toString()} ");
      debugPrint(error.toString());
      debugPrint(stackTrace.toString());
    });
    return forecastList;
  }

  List<Map<String, Object>> _extractDailyForecastValues(List<String> response) {
    final listMap = <Map<String, Object>>[];
    for (int i = 0; i < response.length; ++i) {
      // first row of response should be string
      var forecastValues = response[i].trim().split(" ");
      // The size of the forecastValues list should equal  the param name + the number of forecast times
      if (forecastValues.length == 1 + (_forecastTimes?.length ?? 0)) {
        // Get the param name and remove from list (so list size equals the number of times requested)
        var param = forecastValues.removeAt(0);
        var forecastNameDisplay = _combinedForecastList
            .firstWhere((forecast) => forecast.forecastName == param)
            .forecastNameDisplay;
        for (int j = 0; j < forecastValues.length; ++j) {
          final forecastMap = Map<String, Object>();
          forecastMap.addAll({
            "time": _forecastTimes![j],
            "code": param,
            "value": (double.tryParse(forecastValues[j]) ?? 0),
            "name": forecastNameDisplay
          });
          listMap.addAll({forecastMap});
        }
      }
    }
    return listMap;
  }

  /// Extract all forecast values needed for the altitude graph
  /// Note that some time/forecast values may be removed
  List<Map<String, Object>> _getAltitudeForecasts(
      List<Map<String, Object>> listMap) {
    final altitudeListMap = <Map<String, Object>>[];
    // For each forecast name (e.g. OD Cloudbase (BL CL) MSL)
    _altitudeForecastList.forEach((forecastCode) {
      // The listmap contains hourly forecasts for each forecast parm so need to add each one
      listMap.forEach((element) {
        if (element["code"] == forecastCode.forecastName) {
          altitudeListMap.add(element);
        }
      });
    });
    // Ok, got all altitude parms but we need to prune the map of values we don't want
    // to display on graph
    if (altitudeListMap.isNotEmpty) {
      return _pruneAltitudeMap(altitudeListMap);
    } else {
      return <Map<String, Object>>[];
    }
  }

  /// Prune map
  /// Always add MSL Ht of Critical Updraft Strength (175fpm) (hcrit)
  /// If Cu Potential (zsfclcldif) >0 , add  Cu Cloudbase (Sfc.LCL) MSL (zsfclcl) to the prunedMap
  /// If OD Potential (zblcldif) > 0, add  OD Cloudbase (BL CL) MSL (zblcl) to the prunedMap

  List<Map<String, Object>> _pruneAltitudeMap(
      List<Map<String, Object>> listMap) {
    final prunedMap = <Map<String, Object>>[];
    final allCuPotential = <Map<String, Object>>[];
    final allCu = <Map<String, Object>>[];
    final allOdPotential = <Map<String, Object>>[];
    final allOd = <Map<String, Object>>[];

    listMap.forEach((element) {
      if (element["code"] == "experimental1") {
        // All thermal height get added directly
        prunedMap.add(element);
      } else if (element["code"] == "zsfclcldif") {
        allCuPotential.add(element);
      } else if (element["code"] == "zsfclcl") {
        allCu.add(element);
      } else if (element["code"] == "zblcldif") {
        allOdPotential.add(element);
      } else if (element["code"] == "zblcl") {
        allOd.add(element);
      }
    });

    // If CuPotential > 0 then take the Cu value
    if (allCuPotential.length == allCu.length) {
      for (int i = 0; i < allCuPotential.length; ++i) {
        if ((allCuPotential[i]["value"] as double ) > 0) {
          prunedMap.add(allCu[i]);
        }
      }
    }

    // If OD Potential > 0 then take the OD value
    if (allOdPotential.length == allOd.length) {
      for (int i = 0; i < allOdPotential.length; ++i) {
        if ((allOdPotential[i]["value"] as double ) > 0) {
          prunedMap.add(allOd[i]);
        }
      }
    }
    return prunedMap;
  }

  List<Map<String, Object>> _getThermalForecast(
      List<Map<String, Object>> listMap) {
    final thermalListMap = <Map<String, Object>>[];
    // For each thermal forecast (e.g. wstar)
    _thermalForecastList.forEach((forecast) {
      listMap.forEach((element) {
        if (element["code"] == forecast.forecastName) {
          thermalListMap.add(element);
        }
      });
    });
    return thermalListMap;
  }

  void _processSelectedModelEvent(
      SelectedModelEvent event, Emitter<GraphState> emit) async {
    emit(GraphWorkingState(working: true));
    _selectedModelName = event.modelName;
    // print('Selected model: $_selectedModelname');
    // emits same list of models with new selected model
    _emitRaspModels(emit);
    _getSelectedModelDates();
    _emitModelDates(emit);
    await _generateGraphDataAndEmit(emit);
    emit(GraphWorkingState(working: false));
  }

  void _processSelectedDateEvent(
      SelectedForecastDateEvent event, Emitter<GraphState> emit) async {
    emit(GraphWorkingState(working: true));
    _selectedForecastDate = event.forecastDate;
    _emitModelDates(emit);
    // update times and images for new date
    _setForecastTimesForDate();
    await _generateGraphDataAndEmit(emit);
    emit(GraphWorkingState(working: false));
  }

  void _emitModelDates(Emitter<GraphState> emit) {
    emit(GraphModelDatesState(_forecastDates!, _selectedForecastDate!));
    //debugPrint('emitted GraphModelDates');
  }

  void _getSelectedModelDates() {
    _selectedModelDates = _region!
        .getModelDates()
        .firstWhere((modelDates) => modelDates.modelName == _selectedModelName);
    _updateForecastDates();
  }

  //TODO DRY - Lots of common/similar code in RaspDataBloc
  /// Get a list of both display dates (printDates November 12, 2019)
  /// and dates for constructing calls to rasp (dates 2019-11-12)
  void _updateForecastDates() {
    _setForecastDates();
    // stay on same date if new model has forecast for that date
    if (_selectedForecastDate == null ||
        !_forecastDates!.contains(_selectedForecastDate)) {
      _selectedForecastDate = _forecastDates!.first;
    }
    _updateForecastTimesList();
  }

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
  }

// A new date has been selected, so get the times for that date
  void _setForecastTimesForDate() {
    var modelDateDetail = _selectedModelDates!
        .getModelDateDetailList()
        .firstWhere((modelDateDetails) =>
            modelDateDetails.date == _selectedForecastDate);
    _forecastTimes = modelDateDetail.model!.times;
  }

  //
  void _setRegionModelNames() {
    _modelNames = _region!
        .getModelDates()
        .map((modelDates) => modelDates.modelName!)
        .toList();
  }

  void _emitRaspModels(Emitter<GraphState> emit) {
    emit(GraphModelsState(_modelNames!, _selectedModelName!));
    // debugPrint('emitted GraphModelsState');
  }
}
