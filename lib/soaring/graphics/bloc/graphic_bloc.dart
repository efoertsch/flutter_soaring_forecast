import 'dart:async';

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
  var _requestParams = "";
  var _altitudeForecastList = <Forecast>[];
  var _thermalForecastList = <Forecast>[];
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
    await _getForecastList();
    _requestParams =
        _altitudeParmList.join(" ") + " " + _thermalParmList.join(" ");
    // loop through the forecast times
    await Future.forEach(inputData.times, (time) async {
      await _getForecastInfo(
              region: inputData.region,
              date: inputData.date,
              model: inputData.model,
              time: time.toString(),
              lat: inputData.lat.toString(),
              lng: inputData.lng.toString())
          .then((forecastGraphData) {
        altitudeForecastData
            .addAll(forecastGraphData.altitudeData ?? <Map<String, Object>>[]);
        thermalForecastData
            .addAll(forecastGraphData.thermalData ?? <Map<String, Object>>[]);
        allData.addAll(forecastGraphData.allData ?? <Map<String, Object>>[]);
      }).onError((error, stackTrace) {
        emit(GraphErrorMsgState(error.toString()));
      });
    });
    emit(GraphWorkingState(working: false));
    _sortAltitudeDataByCodeAndTime(altitudeForecastData);
    // create grid data
    var hours = inputData.times;
    var descriptions = _getForecastDescriptions(allData);
    var gridData = _createGridData(allData, hours, descriptions);
    _forecastGraphData = ForecastGraphData(
        date: inputData.date,
        model: inputData.model,
        turnpointTitle: event.localForecastGraphData.turnpointName,
        lat: inputData.lat,
        lng: inputData.lng,
        altitudeData: altitudeForecastData,
        thermalData: thermalForecastData,
        hours: hours,
        descriptions: descriptions,
        gridData: gridData);
    emit(GraphDataState(forecastData: _forecastGraphData!));
  }

  void _sortAltitudeDataByCodeAndTime(
      List<Map<String, Object>> altitudeForecastData) {
    altitudeForecastData.sort((m1, m2) {
      var r = ((m1['code'] as String)).compareTo((m2['code'] as String));
      if (r != 0) return r;
      return (m1["time"] as String).compareTo(m2["time"] as String);
    });
  }

  List<Forecast> _getForecastDescriptions(List<Map<String, Object>> gridData) {
    // get list of unique forecast descriptions
    final descriptions = <Forecast>[];
    descriptions.addAll(
      _altitudeForecastList,
    );
    descriptions.addAll(_thermalForecastList);
    return descriptions;
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

  //

  FutureOr<void> _getForecastList() async {
    if (_options.isEmpty) {
      _options.addAll(await repository.getForecastList());
    }
    _altitudeForecastList.clear();
    _altitudeParmList.forEach((element) {
      _altitudeForecastList.add(
          _options.singleWhere((forecast) => forecast.forecastName == element));
    });

    _thermalForecastList.clear();
    _thermalParmList.forEach((element) {
      _thermalForecastList.add(
          _options.singleWhere((forecast) => forecast.forecastName == element));
    });
  }

  ///For each forecast time, call the local forecast api
  Future<ForecastData> _getForecastInfo(
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
      // collect all the altitude values for the specified time in one list
      var altitudeGraphValues = _getAltitudeForecast(time, responseList);
      // prune out altitude values if needed
      var prunedAltitudeGraphValues = _pruneAltitudeMap(altitudeGraphValues);
      // collect all the thermal values for the specified time in one list
      var thermalGraphValues = _getThermalForecast(time, responseList);
      // construct complete list  for grid
      var allData = <Map<String, Object>>[];
      allData.addAll(altitudeGraphValues);
      allData.addAll(thermalGraphValues);
      forecastData = ForecastData(
        altitudeData: prunedAltitudeGraphValues,
        thermalData: thermalGraphValues,
        allData: allData,
      );
    });
    return forecastData;
  }

  Future<List<String>> _getLatLongForecast(String region, String date,
      String model, String time, String lat, String lng) async {
    final forecastList = <String>[];
    await repository
        .getLatLngForecast(region, date, model, time, lat, lng, _requestParams)
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

  List<Map<String, Object>> _getAltitudeForecast(
      String time, List<String> response) {
    final listMap = <Map<String, Object>>[];
    // For each forecast name (e.g. OD Cloudbase (BL CL) MSL)
    _altitudeForecastList.forEach((forecast) {
      final forecastMap = Map<String, Object>();
      // find the line in the response with that name
      final forecastString = response
          .firstWhere((line) => line.contains(forecast.forecastNameDisplay));
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
    });
    return listMap;
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

  _getThermalForecast(String time, List<String> response) {
    final listMap = <Map<String, Object>>[];
    // For each forecast name (e.g. Thermal Updraft Velocity (W*))
    _thermalForecastList.forEach((forecast) {
      final forecastMap = Map<String, Object>();
      // find the line in the response with that name
      final forecastString = response
          .firstWhere((line) => line.contains(forecast.forecastNameDisplay));
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
    });
    return listMap;
  }
}
