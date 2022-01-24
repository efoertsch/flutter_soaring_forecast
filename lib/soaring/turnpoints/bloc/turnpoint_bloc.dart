import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';

class TurnpointBloc extends Bloc<TurnpointEvent, TurnpointState> {
  final Repository repository;

  //TurnpointState get initialState => TurnpointsLoadingState();

  TurnpointBloc({required this.repository}) : super(TurnpointsLoadingState()) {
    on<TurnpointListEvent>(_showAllTurnpoints);
    on<SearchTurnpointsEvent>(_searchTurnpointsEvent);
    on<TurnpointViewEvent>(_showTurnpointView);
  }

  void _searchTurnpointsEvent(
      SearchTurnpointsEvent event, Emitter<TurnpointState> emit) async {
    emit(SearchingTurnpointsState());
    try {
      var turnpoints = await repository.findTurnpoints(event.searchString);
      emit(TurnpointsFoundState(turnpoints));
    } catch (e) {
      emit(TurnpointSearchErrorState(e.toString()));
    }
  }

  void _showAllTurnpoints(
      TurnpointListEvent event, Emitter<TurnpointState> emit) async {
    emit(TurnpointsLoadingState());
    List<Turnpoint> turnpoints = [];
    try {
      var turnpointCount = await repository.getCountOfTurnpoints();
      if (turnpointCount == 0) {
        // TODO return state to see if want to import turnpoints
        turnpoints = await _addSterlingTurnpoints();
      } else {
        turnpoints.addAll(await repository.getAllTurnpoints());
      }
      emit(TurnpointsLoadedState(turnpoints));
    } catch (e) {
      emit(TurnpointErrorState(e.toString()));
    }
  }

  Future<List<Turnpoint>> _addSterlingTurnpoints() async {
    return _getTurnpointsFromTurnpointExchange(
        'Sterling/Sterling, Massachusetts 2021 SeeYou.cup.txt');
  }

  Future<List<Turnpoint>> _getTurnpointsFromTurnpointExchange(
      String filename) async {
    return await repository.downloadTurnpointsFromTurnpointExchange(filename);
  }

  void _showTurnpointView(
      TurnpointViewEvent event, Emitter<TurnpointState> emit) {
    emit(TurnpointViewState(event.turnpoint));
  }
}
