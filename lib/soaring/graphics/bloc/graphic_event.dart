import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/data/forecast_graph_data.dart';

@immutable
abstract class GraphicEvent extends Equatable {}

class LocalForecastDataEvent extends GraphicEvent {
  final ForecastInputData localForecastGraphData;

  LocalForecastDataEvent({
    required this.localForecastGraphData,
  });

  @override
  // TODO: implement props
  List<Object?> get props => [localForecastGraphData];
}

// All the events related to turnpoints
