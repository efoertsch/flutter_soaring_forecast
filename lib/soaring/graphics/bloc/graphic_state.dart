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

//  list of forecast dates available for the selected forecast model and the
//  default selected date.
class GraphModelDatesState extends GraphState {
  final List<String> forecastDates; // array of dates like  2019-12-19
  final String selectedForecastDate;

  GraphModelDatesState(this.forecastDates, this.selectedForecastDate);

  @override
  List<Object?> get props => [forecastDates, selectedForecastDate];
}

// GFS, NAM, etc and the default (or previously saved selected model
class GraphModelsState extends GraphState {
  final List<String> modelNames;
  final String selectedModelName;

  GraphModelsState(this.modelNames, this.selectedModelName);

  @override
  List<Object?> get props => [modelNames, selectedModelName];
}
