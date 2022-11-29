import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/data/forecast_graph_data.dart';

@immutable
abstract class GraphState extends Equatable {}

class GraphicInitialState extends GraphState {
  @override
  List<Object?> get props => [];
}

class GraphDataState extends GraphState {
  final ForecastGraphData forecastData;

  GraphDataState({required this.forecastData});

  @override
  List<Object?> get props => [forecastData.toString()];
}

class GraphErrorMsgState extends GraphState {
  final String error;

  GraphErrorMsgState(this.error);

  @override
  List<Object?> get props => [error];
}

class GraphWorkingState extends GraphState {
  final bool working;
  GraphWorkingState({required this.working});

  @override
  List<Object?> get props => [working];
}
