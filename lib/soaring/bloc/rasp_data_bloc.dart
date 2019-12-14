import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/bloc/rasp_data_event.dart';
import 'package:flutter_soaring_forecast/soaring/json/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/json/regions.dart';
import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';

import 'rasp_bloc.dart';

/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
/// Bloc processes Events and outputs State
class RaspDataBloc extends Bloc<RaspDataEvent, RaspDataState> {
  final Repository repository;
  Regions _regions;

  RaspDataBloc({@required this.repository});

  @override
  RaspDataState get initialState => InitialRaspDataState();

  @override
  Stream<RaspDataState> mapEventToState(
    RaspDataEvent event,
  ) async* {
    // TODO: Add Logic
    if (event is GetDefaultRaspRegion) {
      yield* _getDefaultRaspRegion();
      return;
    }
    if (event is GetRaspRegion) {
      yield* _getRaspRegion(event.region);
      return;
    }

    if (event is LoadForecastTypes) {
      yield* _getForecastTypes();
    }
  }

  /// Potential series of calls
  /// 1. If regions not yet found, get the list
  /// 2. See if preferences has a region and select that, if not then pick
  ///    first on list
  /// 3. Fill in all models/dates/times for that region then return that
  Stream<RaspDataState> _getDefaultRaspRegion() async* {
    try {
      if (_regions == null) {
        _regions = await this.repository.getRegions();
      }
      if (_regions != null) {
        // TODO - get last region displayed from repository and if in list of regions
        Region region = _regions.regions
            .firstWhere((region) => (region.name == _regions.initialRegion));
        yield RaspRegionLoaded(region);
        // Get models for each forecast date
        await repository.loadForecastModelsByDateForRegion(region);
        // TODO - get last model (gfs, name) from repository and display
        yield RaspModelDatesSelected(region.getModelDates().first);
      }
    } catch (_) {
      yield RaspRegionsNotLoaded();
    }
  }

  Stream<RaspDataState> _getRaspRegion(Region region) async* {
    try {
      await _loadRaspValuesForRegion(region);
    } catch (_) {
      yield RaspRegionNotLoaded(region.name);
    }
  }

  Future<Region> _loadRaspValuesForRegion(Region region) async {
    return await this.repository.loadForecastModelsByDateForRegion(region);
  }

  Stream<RaspDataState> _getForecastTypes() async* {
    try {
      ForecastTypes forecastTypes = await this.repository.getForecastTypes();
      yield RaspForecastTypesLoaded(forecastTypes.forecasts);
    } catch (_) {
      yield null;
    }
  }
}
