import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';

class TurnpointBloc extends Bloc<TurnpointEvent, TurnpointState> {
  final Repository repository;

  TurnpointBloc({required this.repository}) : super(TurnpointInitialState()) {
    on<TurnpointSearchInitialEvent>(_showAllTurnpoints);
    on<SearchTurnpointsEvent>(_searchTurnpointsEvent);
  }

  void _searchTurnpointsEvent(
      SearchTurnpointsEvent event, Emitter<TurnpointState> emit) {
    emit(TurnpointSearchResultsState([]));
  }

  void _showAllTurnpoints(
      TurnpointSearchInitialEvent event, Emitter<TurnpointState> emit) async {
    List<Turnpoint> turnpoints = [];
    var turnpointCount = await repository.getCountOfTurnpoints();
    if (turnpointCount == 0) {
      turnpoints.addAll(
          await repository.downloadTurnpointsFromTurnpointExchange(
              'Sterling/Sterling, Massachusetts 2021 SeeYou.cup.txt'));
    } else {
      turnpoints.addAll(await repository.getAllTurnpoints());
    }
    emit(TurnpointSearchResultsState(turnpoints));
  }
}
