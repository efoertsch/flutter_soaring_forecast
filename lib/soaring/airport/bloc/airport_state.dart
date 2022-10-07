import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/floor/airport/airport.dart';

@immutable
abstract class AirportState extends Equatable {}

class AirportsInitialState extends AirportState {
  @override
  List<Object?> get props => [];
}

class AirportShortMessageState extends AirportState {
  final String shortMsg;

  AirportShortMessageState(String this.shortMsg);

  @override
  List<Object?> get props => [shortMsg];
}

class AirportsLoadedState extends AirportState {
  final List<Airport> airports;

  AirportsLoadedState(this.airports);

  @override
  List<Object?> get props => [airports];
}

class AirportsErrorState extends AirportState {
  final String errorMsg;

  AirportsErrorState(String this.errorMsg);

  @override
  List<Object?> get props => [errorMsg];
}
