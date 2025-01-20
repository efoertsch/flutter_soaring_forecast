import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';
import 'package:flutter_soaring_forecast/soaring/local_forecast/data/local_forecast_graph.dart';

import '../../repository/rasp/estimated_flight_avg_summary.dart';
import '../../repository/rasp/gliders.dart';

abstract class TaskEstimateState {
  const TaskEstimateState();
}

class TaskEstimateInitialState extends TaskEstimateState {
  const TaskEstimateInitialState();
}

class EstimatedFlightSummaryState extends TaskEstimateState {
  final EstimatedFlightSummary? estimatedFlightSummary;

  EstimatedFlightSummaryState(this.estimatedFlightSummary);
}

class CalcEstimatedFlightState extends TaskEstimateState {
  final Glider glider;

  CalcEstimatedFlightState(this.glider);
}

class TaskEstimateWorkingState extends TaskEstimateState {
  final bool working;

  TaskEstimateWorkingState(this.working);
}

class TaskEstimateErrorState extends TaskEstimateState {
  final String errorMsg;

  TaskEstimateErrorState(this.errorMsg);
}

class DisplayGlidersState extends TaskEstimateState {}

class CurrentHourState extends TaskEstimateState {
  String hour;

  CurrentHourState(this.hour);
}

class DisplayExperimentalHelpText extends TaskEstimateState {
  final bool calcAfterShow;

  DisplayExperimentalHelpText(this.calcAfterShow);
}

class LocalForecastDisplayState extends TaskEstimateState {
  final LocalForecastInputData localForecastGraphData;

  LocalForecastDisplayState(this.localForecastGraphData);
}
