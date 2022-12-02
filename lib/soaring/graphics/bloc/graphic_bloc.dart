import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/bloc/graphic_event.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/bloc/graphic_state.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/data/forecast_graph_data.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
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

  var _requestParms = "";
  var _altitudeForecastList = <Forecast>[];
  var _thermalForecastList = <Forecast>[];
  var _combinedForecastList = <Forecast>[];

  static final _options = <Forecast>[];
  ForecastGraphData? _forecastGraphData;

  GraphicBloc({required this.repository}) : super(GraphicInitialState()) {
    on<LocalForecastDataEvent>(_getLocalForecastData);
  }

  FutureOr<void> _getLocalForecastData(
      LocalForecastDataEvent event, Emitter<GraphState> emit) async {
    emit(GraphWorkingState(working: true));
    final inputData = event.localForecastGraphData;
    final List<Map<String, Object>> altitudeForecastData = [];
    final List<Map<String, Object>> thermalForecastData = [];
    final List<Map<String, Object>> allData = [];
    _composeRequestParamsString();
    await _getForecastList();

    // loop through the forecast times
    await Future.forEach(inputData.times, (time) async {
      // and for each time call the RASP api and process response
      await _getForecastInfo(
              region: inputData.region,
              date: inputData.date,
              model: inputData.model,
              time: time.toString(),
              lat: inputData.lat.toString(),
              lng: inputData.lng.toString())
          ?.then((hourlyForecastData) {
        if (hourlyForecastData != null) {
          // And combine the hourly forecast with prior hourly forecasts
          altitudeForecastData.addAll(
              hourlyForecastData.altitudeData ?? <Map<String, Object>>[]);
          thermalForecastData.addAll(
              hourlyForecastData.thermalData ?? <Map<String, Object>>[]);
          allData.addAll(hourlyForecastData.allData ?? <Map<String, Object>>[]);
        }
      }).onError((error, stackTrace) {
        emit(GraphErrorMsgState(error.toString()));
      });
    });
    // Wheew! Now have maps that contain the data for all forecast times
    // We need to sort altitude data so it can be properly graphed
    _sortAltitudeDataByCodeAndTime(altitudeForecastData);
    final forecastGraphData = ForecastGraphData(
        date: inputData.date,
        model: inputData.model,
        turnpointTitle: event.localForecastGraphData.turnpointName,
        lat: inputData.lat,
        lng: inputData.lng,
        altitudeData: altitudeForecastData,
        thermalData: thermalForecastData,
        hours: inputData.times,
        descriptions: _combinedForecastList,
        gridData:
            _createGridData(allData, inputData.times, _combinedForecastList));
    // allData.forEach((map) {
    //   map.entries.forEach((element) {
    //     print("${element.key} : ${element.value.toString()}");
    //   });
    // });
    emit(GraphWorkingState(working: false));
    emit(GraphDataState(forecastData: forecastGraphData));
  }

  // Compose space separated list of forecast parameters for sending to RASP api
  void _composeRequestParamsString() {
    _requestParms = _altitudeParmList.join(" ") +
        " " +
        _thermalParmList.join(" ") +
        " " +
        _windParmList.join(" ");
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
    _requestParms.split(" ").forEach((element) {
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

  ///For each forecast time, call the local forecast api
  Future<ForecastData>? _getForecastInfo(
      {required String region,
      required String date,
      required String model,
      required String time,
      required String lat,
      required String lng}) async {
    var forecastData;
    // call the api and process the response
    await _getLatLongForecast(region, date, model, time, lat, lng)
        .then((responseList) {
      var allData = _extractAllForecastValues(time, responseList);
      // collect all the altitude values for the specified time in one list
      var altitudeGraphValues = _getAltitudeForecasts(allData);
      // collect all the thermal values for the specified time in one list
      var thermalGraphValues = _getThermalForecast(allData);
      // return all the forecast data needed for the specified time
      forecastData = ForecastData(
        altitudeData: altitudeGraphValues,
        thermalData: thermalGraphValues,
        allData: allData,
      );
    });
    return forecastData;
  }

  /// Call the RASP api and return response parsed into lines
  Future<List<String>> _getLatLongForecast(String region, String date,
      String model, String time, String lat, String lng) async {
    final forecastList = <String>[];
    await repository
        .getLatLngForecast(region, date, model, time, lat, lng, _requestParms)
        .then((httpResponse) {
      if (httpResponse.response.statusCode! >= 200 &&
          httpResponse.response.statusCode! < 300) {
        //print('LatLngForecast text ${httpResponse.response.data.toString()}');
        forecastList.addAll(httpResponse.response.data.toString().split('\n'));
      } else {
        throw Exception(
            "Error occurred in getting local forecast:  ${httpResponse.response.statusMessage}");
      }
    });
    return forecastList;
  }

  List<Map<String, Object>> _extractAllForecastValues(
      String time, List<String> response) {
    final listMap = <Map<String, Object>>[];
    // For each forecast name (e.g. OD Cloudbase (BL CL) MSL)
    _combinedForecastList.forEach((forecast) {
      final forecastMap = Map<String, Object>();
      // find the line in the response with that name
      final forecastString = response.firstWhereOrNull(
          (line) => line.contains(forecast.forecastNameDisplay));
      if (forecastString != null) {
        // and get the associated value
        final forecastValue = forecastString
            .trim()
            .substring(forecast.forecastNameDisplay.length)
            .trim();
        var value = (forecastValue == "-") ? 0.0 : double.parse(forecastValue);
        // and then add the display name and forecasted value to the map
        // forecastMap.addAll({forecast.forecastNameDisplay: value});
        forecastMap.addAll({
          "time": time,
          "code": forecast.forecastName,
          "value": value,
          "name": forecast.forecastNameDisplay
        });
        listMap.addAll({forecastMap});
      }
    });
    return listMap;
  }

  /// Extract all forecast values needed for the altitude graph
  /// Note that some time/forecast values may be removed
  List<Map<String, Object>> _getAltitudeForecasts(
      List<Map<String, Object>> listMap) {
    final altitudeListMap = <Map<String, Object>>[];
    // For each forecast name (e.g. OD Cloudbase (BL CL) MSL)
    _altitudeForecastList.forEach((forecastCode) {
      var altitudeMap = listMap.firstWhereOrNull(
          (element) => element["code"] == forecastCode.forecastName);
      // find the line in the response with that name
      if (altitudeMap != null) {
        altitudeListMap.add(altitudeMap);
      }
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
    var thermalMap =
        listMap.firstWhere((element) => element["code"] == "experimental1");
    prunedMap.add(thermalMap);
    var cuPotential =
        listMap.firstWhere((element) => element["code"] == "zsfclcldif");
    var cuMsl = listMap.firstWhere((element) => element["code"] == "zsfclcl");
    if (cuPotential["value"] as double > 0) {
      prunedMap.add(cuMsl);
    }
    var odPotential =
        listMap.firstWhere((element) => element["code"] == "zblcldif");
    var odMsl = listMap.firstWhere((element) => element["code"] == "zblcl");
    if (odPotential["value"] as double > 0) {
      prunedMap.add(odMsl);
    }
    return prunedMap;
  }

  List<Map<String, Object>> _getThermalForecast(
      List<Map<String, Object>> listMap) {
    final thermalListMap = <Map<String, Object>>[];
    // For each forecast name (e.g. OD Cloudbase (BL CL) MSL)
    _thermalForecastList.forEach((forecast) {
      var altitudeMap = listMap.firstWhereOrNull(
          (element) => element["code"] == forecast.forecastName);
      // find the line in the response with that name
      if (altitudeMap != null) {
        thermalListMap.add(altitudeMap);
      }
    });
    return thermalListMap;
  }
}