import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/airport/bloc/airport_event.dart';
import 'package:flutter_soaring_forecast/soaring/airport/bloc/airport_state.dart';
import 'package:flutter_soaring_forecast/soaring/floor/airport/airport.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';

class AirportBloc extends Bloc<AirportEvent, AirportState> {
  final Repository repository;

//TaskState get initialState => TasksLoadingState();

  AirportBloc({required this.repository}) : super(AirportsInitialState()) {
    on<SearchAirportsEvent>(_searchForAirports);
    on<GetSelectedAirportsList>(_getSelectedAirports);
    on<AddAirportToSelectList>(_addAirportToSelectList);
  }

  FutureOr<void> _searchForAirports(
      SearchAirportsEvent event, Emitter<AirportState> emit) async {
    final airports = <Airport>[];
    final results = await repository.findAirports(event.searchString);
    airports.addAll(results ?? <Airport>[]);
    emit(AirportsLoadedState(airports));
  }

  void _getSelectedAirports(
      GetSelectedAirportsList event, Emitter<AirportState> emit) async {
    final airports = <Airport>[];
    final airportIdents = await repository.getSelectedAirportCodesList();
    airports.addAll(
        await repository.getSelectedAirports(airportIdents) ?? <Airport>[]);
    emit(AirportsLoadedState(airports));
  }

  FutureOr<void> _addAirportToSelectList(
      AddAirportToSelectList event, Emitter<AirportState> emit) {
    repository.addAirportCodeToSelectedIcaoCodes(event.airport.ident);
  }
}
