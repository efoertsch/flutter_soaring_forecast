import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/data/forecast_graph_data.dart';

@immutable
abstract class GraphState {}

class GraphicInitialState extends GraphState {
}

class BeginnerModeState extends GraphState{
  final bool beginnerMode ;

  BeginnerModeState(this.beginnerMode);
}

class BeginnerForecastDateModelState extends GraphState {
  final String date;
  final String model;
  BeginnerForecastDateModelState (this.date, this.model);
}

class GraphDataState extends GraphState {
  final ForecastGraphData forecastData;

  GraphDataState({required this.forecastData});

}

class GraphErrorState extends GraphState {
  final String error;

  GraphErrorState(this.error);

}

class GraphWorkingState extends GraphState {
  final bool working;
  GraphWorkingState({required this.working});

}

//  list of forecast dates available for the selected forecast model and the
//  default selected date.
class GraphModelDatesState extends GraphState {
  final List<String> forecastDates; // array of dates like  2019-12-19
  final String selectedForecastDate;

  GraphModelDatesState(this.forecastDates, this.selectedForecastDate);

}

// GFS, NAM, etc and the default (or previously saved selected model
class GraphModelsState extends GraphState {
  final List<String> modelNames;
  final String selectedModelName;

  GraphModelsState(this.modelNames, this.selectedModelName);

}
