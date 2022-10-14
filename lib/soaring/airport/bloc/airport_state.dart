import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/floor/airport/airport.dart';
import 'package:flutter_soaring_forecast/soaring/repository/one800wxbrief/metar_taf_response.dart';

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

class AirportMetarTafState extends AirportState {
  final String location;
  final String type; // Metar or Taf
  final MetarTafResponse metarTafResponse;
  AirportMetarTafState(this.location, this.type, this.metarTafResponse);
  @override
  List<Object?> get props => [location, type, metarTafResponse.toString()];
}
