import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/region_model/data/region_model_data.dart';

import '../data/local_forecast_graph.dart';

@immutable
abstract class LocalForecastEvent {}

class LocalForecastGraphEvent extends LocalForecastEvent {
  final LocalForecastInputData localForecastGraphData;

  LocalForecastGraphEvent({
    required this.localForecastGraphData,
  });
}

class LocalModelDateChangeEvent extends LocalForecastEvent{
  final RaspModelDateChange localModelDateChange;

  LocalModelDateChangeEvent(this.localModelDateChange);
}


class SetLocationAsFavoriteEvent extends LocalForecastEvent {}

class LocationTabIndexEvent extends LocalForecastEvent {
  final int index;

  LocationTabIndexEvent(this.index);
}
