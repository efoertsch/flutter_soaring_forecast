import 'package:flutter_soaring_forecast/soaring/json/regions.dart';

/// Various tutorials on Bloc implementation
/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
/// Event In - State Out
abstract class RegionsEvent {}
// All the events that can trigger getting a rasp forecast

class GetRegions extends RegionsEvent {
  final Regions regions;
  GetRegions(this.regions);
}
