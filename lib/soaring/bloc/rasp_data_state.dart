import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/json/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/json/regions.dart';

@immutable
abstract class RaspDataState {}

class InitialRaspDataState extends RaspDataState {
  @override
  String toString() => "IntialRaspDataState";
}

class RaspRegionsLoaded extends RaspDataState {
  final Regions regions;
  RaspRegionsLoaded(this.regions);
}

class RaspRegionLoaded extends RaspDataState {
  final Region region;
  RaspRegionLoaded(this.region);
}

class RaspRegionsNotLoaded extends RaspDataState {
  @override
  String toString() => 'RegionsNotLoaded';
}

class RaspRegionNotLoaded extends RaspDataState {
  final String region;
  RaspRegionNotLoaded(this.region);
  @override
  String toString() => '$region could not be loaded.';
}

class RaspModelDatesSelected extends RaspDataState {
  final ModelDates modelDates;
  RaspModelDatesSelected(this.modelDates);
}

class RaspDataLoading extends RaspDataState {
  @override
  String toString() => 'RaspDataLoading';
}

class RaspForecastTypesLoaded extends RaspDataState {
  final List<Forecast> forecasts;
  RaspForecastTypesLoaded(this.forecasts);
}
