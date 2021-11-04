import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';

class TurnpointBloc extends Bloc<TurnpointEvent, TurnpointState> {
  final Repository repository;

  TurnpointBloc({required this.repository}) : super(TurnpointInitialState()) {
    on<TurnpointSearchInitialEvent>(_showAllTurnpoints);
    on<SearchTurnpointsEvent>(_SearchTurnpointsEvent);
  }

  void _SearchTurnpointsEvent(
      SearchTurnpointsEvent event, Emitter<TurnpointState> emit) {
    emit(TurnpointSearchResults(['none found']));
  }

  void _showAllTurnpoints(
      TurnpointSearchInitialEvent event, Emitter<TurnpointState> emit) {}
}
