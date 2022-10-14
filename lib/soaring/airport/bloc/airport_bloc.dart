import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/airport/bloc/airport_event.dart';
import 'package:flutter_soaring_forecast/soaring/airport/bloc/airport_state.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/floor/airport/airport.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';

class AirportBloc extends Bloc<AirportEvent, AirportState> {
  final Repository repository;

//TaskState get initialState => TasksLoadingState();

  AirportBloc({required this.repository}) : super(AirportsInitialState()) {
    on<GetAirportMetarAndTafs>(_getAirportMetarAndTafs);
    on<SearchAirportsEvent>(_searchForAirports);
    on<GetSelectedAirportsList>(_getSelectedAirports);
    on<AddAirportToSelectList>(_addAirportToSelectList);
    on<SwitchOrderOfSelectedAirportsEvent>(_switchOrderOfSelectedAirports);
    on<SwipeDeletedAirportEvent>(_deleteAirport);
    on<AddBackAirportEvent>(_addBackAirportToList);
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

  FutureOr<void> _deleteAirport(
      SwipeDeletedAirportEvent event, Emitter<AirportState> emit) async {
    final airportIdents = await repository.getSelectedAirportCodesList();
    airportIdents.remove(event.airport.ident);
    repository.saveSelectedAirportCodes(airportIdents.join(" "));
  }

  FutureOr<void> _addBackAirportToList(
      AddBackAirportEvent event, Emitter<AirportState> emit) async {
    final airportIdents = await repository.getSelectedAirportCodesList();
    airportIdents.insert(event.index, event.airport.ident);
    repository.saveSelectedAirportCodes(airportIdents.join(" "));
  }

  FutureOr<void> _getAirportMetarAndTafs(
      GetAirportMetarAndTafs event, Emitter<AirportState> emit) async {
    final airportIdents = await repository.getSelectedAirportCodesList();
    _emitSelectedAirports(airportIdents, emit);
    final List<Future> futureFunctions = [];
    airportIdents.forEach((airport) {
      futureFunctions.add(
          _getAirportMetarOrTaf(location: airport, type: MetarOrTAF.METAR));
      futureFunctions
          .add(_getAirportMetarOrTaf(location: airport, type: MetarOrTAF.TAF));
    });
    await Future.wait(futureFunctions).then((airportMetarTafState) {
      emit(airportMetarTafState as AirportMetarTafState);
    });
  }

  Future<AirportMetarTafState> _getAirportMetarOrTaf(
      {required final String location, required final String type}) async {
    if (type == MetarOrTAF.METAR) {
      final metar = await repository.getMetar(location: location);
      return AirportMetarTafState(location, type, metar);
    } else {
      // (type == MetarOrTAF.TAF)
      final taf = await repository.getTaf(location: location);
      return (AirportMetarTafState(location, type, taf));
    }
  }
}
