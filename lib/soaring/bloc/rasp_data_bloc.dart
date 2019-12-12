import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/bloc/rasp_data_event.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/rasp_data.dart';
import 'package:flutter_soaring_forecast/soaring/json/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/json/regions.dart';
import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';

import 'bloc.dart';

/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
/// Bloc processes Events and outputs State
class RaspDataBloc extends Bloc<RaspDataEvent, RaspDataState> {
  final Repository repository;

  RaspDataBloc({@required this.repository});

  @override
  RaspDataState get initialState => InitialRaspDataState();

  @override
  Stream<RaspDataState> mapEventToState(
    RaspDataEvent event,
  ) async* {
    // TODO: Add Logic
    if (event is GetRaspForecastOptions) {
      yield* _mapGetRaspModelToState(event.region);
    }
    if (event is LoadForecastTypes){
      yield* _getForecastTypes();
    }

  }

  Stream<RaspDataState> _mapGetRaspModelToState(Region region) async* {
    try {
      await this.repository.loadForecastModelsByDateForRegion(region);
      RaspData raspData = createRaspData(region);
      yield RaspDataLoaded(raspData);
    } catch (_) {
      yield RaspDataNotLoaded();
    }
  }

  RaspData createRaspData(Region region) {
    if (region.getForecastModels() != null) {
      var forecastModelsModels = region.getForecastModel(0);

      /// TODO return intial Raspdata based on stored preferences
      return RaspData(
          forecastModelsModels.getModelNames(),
          forecastModelsModels.getModelNames()[0],
          region.printDates,
          region.printDates[0],
          List<String>(),
          ' ',
          forecastModelsModels.getModel(0).times,
          forecastModelsModels.getModel(0).times[0]);
    }
    return null;
  }

  Stream<RaspDataState> _getForecastTypes() async* {
    try {
      ForecastTypes forecastTypes = await this.repository.getForecastTypes();
      yield ForecastTypesLoaded(forecastTypes);
    } catch(_) {
      yield null;
    }
  }
}
