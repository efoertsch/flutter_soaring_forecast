import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/data/forecast_graph_data.dart';

@immutable
abstract class GraphicEvent {}

class SelectedModelEvent extends GraphicEvent {
  final String modelName;

  SelectedModelEvent(this.modelName);
}

class SelectedForecastDateEvent extends GraphicEvent {
  final String forecastDate;

  SelectedForecastDateEvent(this.forecastDate);
}

class LocalForecastDataEvent extends GraphicEvent {
  final ForecastInputData localForecastGraphData;

  LocalForecastDataEvent({
    required this.localForecastGraphData,
  });
}
