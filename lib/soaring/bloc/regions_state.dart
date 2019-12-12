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

class RegionLoaded extends RegionsState {
  final Region region;
  RegionLoaded(this.region);
}

class RegionsNotLoaded extends RegionsState {
  @override
  String toString() => 'RegionsNotLoaded';
}

class RegionNotLoaded extends RegionsState {
  final String region;
  RegionNotLoaded(this.region);
  @override
  String toString() => '$region could not be loaded.';
}
