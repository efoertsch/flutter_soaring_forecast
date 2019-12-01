import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/json/regions.dart';

@immutable
abstract class RegionsState {}

class InitialRegionsState extends RegionsState {
  @override
  String toString() => "IntialRegionsState";
}

class RegionsLoading extends RegionsState {
  @override
  String toString() => 'RegionsLoading';
}

// Only the RegionsLoaded event needs to contain data
class RegionsLoaded extends RegionsState {
  final Regions regions;

  RegionsLoaded(this.regions);
}

class RegionsNotLoaded extends RegionsState {
  @override
  String toString() => 'RegionsNotLoaded';
}
