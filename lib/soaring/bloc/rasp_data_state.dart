import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/rasp_data.dart';
import 'package:flutter_soaring_forecast/soaring/json/forecast_types.dart';

@immutable
abstract class RaspDataState {}

class InitialRaspDataState extends RaspDataState {}

class RaspDataLoading extends RaspDataState {
  @override
  String toString() => 'RaspDataLoading';
}

// Only the RaspDataLoaded event needs to contain data
class RaspDataLoaded extends RaspDataState {
  final RaspData raspData;
  RaspDataLoaded(this.raspData);
}

class RaspDataNotLoaded extends RaspDataState {
  @override
  String toString() => 'RaspNotLoaded';
}

class ForecastTypesLoaded extends RaspDataState{
  final ForecastTypes forecastTypes;
  ForecastTypesLoaded(this.forecastTypes);
}
