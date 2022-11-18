import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/bloc/graphic_event.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/bloc/graphic_state.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';

class GraphicBloc extends Bloc<GraphicEvent, GraphState> {
  final Repository repository;
  static const forecastParmList = ["wstar", "dwcrit", "bsratio", "zsfclcl"];
  final options = <Forecast>[];

  GraphicBloc({required this.repository}) : super(GraphicInitialState()) {
    on<LocalForecastGraphEvent>(_graphLocalForecast);
  }

  FutureOr<void> _graphLocalForecast(
      LocalForecastGraphEvent event, Emitter<GraphState> emit) async {
    emit(GraphWorkingState(working: true));
    final inputData = event.localForecastGraphData;
    final forecastParmString = forecastParmList.join(" ");
    final List<Map<String, Object>> forecastData = [];
    await _getForecastList();
    await Future.forEach(inputData.times, (time) async {
      var forecastMap = Map<String, Object>();
      forecastMap.addAll({"Time": time.toString()});
      await getForecastInfo(
          region: inputData.region,
          date: inputData.date,
          model: inputData.model,
          time: time.toString(),
          lat: inputData.lat.toString(),
          lng: inputData.lng.toString(),
          forecastParmString: forecastParmString,
          forecastParmList: forecastParmList,
          options: options,
          forecastMap: forecastMap);
      forecastData.add(forecastMap);
    });
    emit(GraphWorkingState(working: false));
    emit(GraphDataState(forecastData: forecastData));
  }

  FutureOr<void> _getForecastList() async {
    if (options.isEmpty) {
      options.addAll(await repository.getForecastList());
    }
  }

  FutureOr<void> getForecastInfo(
      {required String region,
      required String date,
      required String model,
      required String time,
      required String lat,
      required String lng,
      required String forecastParmString,
      required List<String> forecastParmList,
      required List<Forecast> options,
      required Map<String, Object> forecastMap}) async {
    await repository
        .getLatLngForecast(
            region, date, model, time, lat, lng, forecastParmString)
        .then((httpResponse) {
      if (httpResponse.response.statusCode! >= 200 &&
          httpResponse.response.statusCode! < 300) {
        print('LatLngForecast text ${httpResponse.response.data.toString()}');
        var response = httpResponse.response.data.toString().split('\n');
        // for each forecast in list e.g. "wstar", "dwcrit"
        forecastParmList.forEach((element) {
          // find the forecast details (parm nanme, display name etc);
          final forecast = options
              .singleWhere((forecast) => forecast.forecastName == element);
          // and use the display name to get that particular forecast from the string array
          final forecastString = response.firstWhere(
              (line) => line.contains(forecast.forecastNameDisplay));
          // print(forecastString);
          var forecastValue = double.parse(forecastString
              .trim()
              .substring(forecast.forecastNameDisplay.length)
              .trim());
          // and then add the display name and forecasted value to the map
          forecastMap.addAll({forecast.forecastNameDisplay: forecastValue});
        });
        // print(forecastMap);
      }
    });
  }
}
