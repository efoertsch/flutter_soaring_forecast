import 'package:flutter/foundation.dart';
import '../data/local_forecast_graph.dart';

@immutable
abstract class LocalForecastState {}

class LocalForecastInitialState extends LocalForecastState {}

class GraphInitialState extends LocalForecastState {
  final state = "GraphInitialState";

  @override
  String toString() => state;
}

class GraphDataState extends LocalForecastState {
  final ForecastGraphData forecastData;

  GraphDataState({required this.forecastData});
}

class LocalForecastWorkingState extends LocalForecastState {
  final bool working;

  LocalForecastWorkingState({required this.working});
}

class LocalForecastErrorState extends LocalForecastState {
  final String error;

  LocalForecastErrorState(this.error);
}
