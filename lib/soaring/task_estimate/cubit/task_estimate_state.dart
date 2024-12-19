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

class DisplayEstimatedFlightText extends TaskEstimateState {}

class TaskEstimateWorkingState extends TaskEstimateState {
  final bool working;

  TaskEstimateWorkingState(this.working);
}

class TaskEstimateErrorState extends TaskEstimateState {
  final String errorMsg;

  TaskEstimateErrorState(this.errorMsg);
}

class DisplayGlidersState extends TaskEstimateState{
}