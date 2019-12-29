import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/rasp_selection_values.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/json/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/json/regions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// https://medium.com/flutter-community/flutter-bloc-pattern-for-dummies-like-me-c22d40f05a56
/// Event In - State Out
///
@immutable
abstract class RaspDataState {}

class InitialRaspDataState extends RaspDataState {
  @override
  String toString() => "IntialRaspDataState";
}

class RaspSelectionsState extends RaspDataState {
  final RaspSelectionValues raspSelectionValues;
  RaspSelectionsState(this.raspSelectionValues);
}

class RaspDataLoadErrorState extends RaspDataState {
  final String error;
  RaspDataLoadErrorState(this.error);
}

class RaspModelDatesSelected extends RaspDataState {
  final ModelDates modelDates;
  RaspModelDatesSelected(this.modelDates);
}

class RaspForecastTypesLoaded extends RaspDataState {
  final List<Forecast> forecasts;
  RaspForecastTypesLoaded(this.forecasts);
}

class RaspMapLatLngBounds extends RaspDataState {
  final LatLngBounds regionLatLngBounds;
  RaspMapLatLngBounds(this.regionLatLngBounds);
}

//TODO add stacktrace?
class RaspMapLatLngBoundsError extends RaspDataState {
  @override
  String toString() => 'Error creating Google Map Lat/Lng bounds';
}

class RaspForecastImageDisplay extends RaspDataState {
  final SoaringForecastImageSet soaringForecastImageSet;
  RaspForecastImageDisplay(this.soaringForecastImageSet);
}
