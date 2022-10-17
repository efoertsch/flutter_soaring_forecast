import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/floor/airport/airport.dart';

@immutable
abstract class AirportEvent extends Equatable {}

class SearchAirportsEvent extends AirportEvent {
  final String searchString;

  SearchAirportsEvent(this.searchString);

  @override
  List<Object?> get props => [searchString];
}

class SeeIfAirportDownloadNeededEvent extends AirportEvent {
  @override
  List<Object?> get props => [];
}

class GetSelectedAirportsListEvent extends AirportEvent {
  @override
  List<Object?> get props => [];
}

class GetAirportMetarAndTafsEvent extends AirportEvent {
  @override
  List<Object?> get props => [];
}

class AddAirportToSelectListEvent extends AirportEvent {
  final Airport airport;

  AddAirportToSelectListEvent(this.airport);

  @override
  List<Object?> get props => [airport];
}

class SwitchOrderOfSelectedAirportsEvent extends AirportEvent {
  final int oldIndex;
  final int newIndex;
  SwitchOrderOfSelectedAirportsEvent(this.oldIndex, this.newIndex);
  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class SwipeDeletedAirportEvent extends AirportEvent {
  final Airport airport;

  SwipeDeletedAirportEvent(this.airport);
  @override
  List<Object?> get props => [airport];
}

class AddBackAirportEvent extends AirportEvent {
  final Airport airport;
  final int index;
  AddBackAirportEvent(this.airport, this.index);
  @override
  List<Object?> get props => [airport];
}

class DownloadAirportsNowEvent extends AirportEvent {
  @override
  List<Object?> get props => [];
}
