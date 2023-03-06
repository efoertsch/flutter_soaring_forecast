import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/data/forecast_graph_data.dart';

//TODO consolidate with RaspDataEvent
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
  final LocalForecastInputData localForecastGraphData;

  LocalForecastDataEvent({
    required this.localForecastGraphData,
  });
}

class ForecastDateSwitchEvent extends GraphicEvent {
  final ForecastDateChange forecastDateSwitch;

  ForecastDateSwitchEvent(this.forecastDateSwitch);
}

class BeginnerModeEvent extends GraphicEvent{
  final bool beginnerMode;

  BeginnerModeEvent(this.beginnerMode);
}

class SetLocationAsFavoriteEvent extends GraphicEvent{

}

