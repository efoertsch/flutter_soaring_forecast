import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_types/bloc/forecast_event.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_types/bloc/forecast_state.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';

class ForecastBloc extends Bloc<ForecastEvent, ForecastState> {
  final Repository repository;
  var _forecasts = <Forecast>[];

  ForecastBloc({required this.repository}) : super(ForecastsLoadingState()) {
    on<ListForecastsEvent>(_listForecasts);
    on<ResetForecastListToDefaultEvent>(_deleteCustomForecastList);
    on<SwitchOrderOfForecastsEvent>(_switchOrderOfForecasts);
  }

  void _listForecasts(
      ListForecastsEvent event, Emitter<ForecastState> emit) async {
    _forecasts = await this.repository.getDisplayableForecastList();
    emit(ListOfForecastsState(_forecasts));
  }

  FutureOr<void> _deleteCustomForecastList(
      ResetForecastListToDefaultEvent event,
      Emitter<ForecastState> emit) async {
    final deletedOK = await repository.deleteCustomForecastList();
    emit(ForecastShortMessageState(
        deletedOK ? "Reset To Default Order" : "Oops. Error on resetting!"));
    _forecasts = await this.repository.getDisplayableForecastList();
    emit(ListOfForecastsState(_forecasts));
  }

  FutureOr<void> _switchOrderOfForecasts(
      SwitchOrderOfForecastsEvent event, Emitter<ForecastState> emit) async {
    if (event.oldIndex <= _forecasts.length &&
        event.newIndex <= _forecasts.length) {
      var forecast = _forecasts[event.oldIndex];
      _forecasts.removeAt(event.oldIndex);
      _forecasts.insert(event.newIndex, forecast);
      final savedOK = await repository.saveForecasts(_forecasts);
      if (savedOK) {
        emit(ListOfForecastsState(_forecasts));
      } else {
        emit(ForecastErrorState("Hmmm. Error in saving reorderdd list!"));
      }
    }
  }
}
