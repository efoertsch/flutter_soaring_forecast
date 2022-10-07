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
    on<SwitchOrderOfSelectedAirportsEvent>(_switchOrderOfSelectedAirports);
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
    final airportIdents = await repository.getSelectedAirportCodesList();
    await _emitSelectedAirports(airportIdents, emit);
  }

  Future<void> _emitSelectedAirports(
      List<String> airportIdents, Emitter<AirportState> emit) async {
    final airports = <Airport>[];
    airports.addAll(
        await repository.getSelectedAirports(airportIdents) ?? <Airport>[]);
    // airports may not be returned in same order as the list, so sort into proper order
    // before returning
    for (int i = 0; i < airportIdents.length; ++i) {
      for (int j = 0; j < airports.length; ++j) {
        if (airportIdents[i] == (airports[j].ident) && i < j) {
          final swappedAirport = airports[j];
          airports.removeAt(j);
          airports.insert(i, swappedAirport);
        }
      }
    }
    emit(AirportsLoadedState(airports));
  }

  FutureOr<void> _addAirportToSelectList(
      AddAirportToSelectList event, Emitter<AirportState> emit) {
    repository.addAirportCodeToSelectedIcaoCodes(event.airport.ident);
  }

  FutureOr<void> _switchOrderOfSelectedAirports(
      SwitchOrderOfSelectedAirportsEvent event,
      Emitter<AirportState> emit) async {
    final airportIdents = await repository.getSelectedAirportCodesList();
    if (event.newIndex < airportIdents.length &&
        event.oldIndex < airportIdents.length) {
      var switchedAirport = airportIdents[event.oldIndex];
      airportIdents.removeAt(event.oldIndex);
      airportIdents.insert(event.newIndex, switchedAirport);
      repository.saveSelectedAirportCodes(airportIdents.join(" "));
    }
    await _emitSelectedAirports(airportIdents, emit);
  }
}
