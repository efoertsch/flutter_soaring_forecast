import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';

@immutable
abstract class ForecastState extends Equatable {}

class ForecastsLoadingState extends ForecastState {
  @override
  List<Object?> get props => [];
}

class ForecastErrorState extends ForecastState {
  final String errorMsg;
  ForecastErrorState(String this.errorMsg);
  @override
  List<Object?> get props => [errorMsg];
}

class ForecastShortMessageState extends ForecastState {
  final String shortMsg;
  ForecastShortMessageState(String this.shortMsg);
  @override
  List<Object?> get props => [shortMsg];
}

class ListOfForecastsState extends ForecastState {
  final List<Forecast> forecasts;
  ListOfForecastsState(this.forecasts);
  @override
  List<Object?> get props => [forecasts.toString()];

  // Needed to override as when forecasts reordered and new forecastlist state sent
  // the bloc was thinking the state contained the same list as originally sent and
  // therefor didn't pass on the reordered list
  @override
  bool operator ==(Object other) => false;
}
