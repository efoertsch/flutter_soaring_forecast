import 'package:flutter/foundation.dart';

import 'local_forecast_graph.dart';

@immutable
abstract class LocalForecastEvent {}

class LocalForecastGraphEvent extends LocalForecastEvent {
  final LocalForecastInputData localForecastGraphData;

  LocalForecastGraphEvent({
    required this.localForecastGraphData,
  });
}

class LocalModelDateChangeEvent extends LocalForecastEvent{
  final LocalModelDateChange localModelDateChange;

  LocalModelDateChangeEvent(this.localModelDateChange);
}


class SetLocationAsFavoriteEvent extends LocalForecastEvent {}

class LocationTabIndexEvent extends LocalForecastEvent {
  final int index;

  LocationTabIndexEvent(this.index);
}
