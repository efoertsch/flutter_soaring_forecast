import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/data/local_forecast_graph_data.dart';

@immutable
abstract class GraphicEvent extends Equatable {}

class LocalForecastGraphEvent extends GraphicEvent {
  final LocalForecastGraphData localForecastGraphData;

  LocalForecastGraphEvent({
    required this.localForecastGraphData,
  });

  @override
  // TODO: implement props
  List<Object?> get props => [localForecastGraphData];
}

// All the events related to turnpoints
