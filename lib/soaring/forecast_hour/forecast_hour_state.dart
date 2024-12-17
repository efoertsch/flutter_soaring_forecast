
import 'package:flutter/foundation.dart';

@immutable
abstract class ForecastHourState {}

class ForecastHourInitialState extends ForecastHourState {
}

class RunHourAnimationState extends ForecastHourState{
final bool runAnimation;

RunHourAnimationState(this.runAnimation);
}

class IncrDecrHourIndexState extends ForecastHourState{
  final int incrDecrIndex;

  IncrDecrHourIndexState(this.incrDecrIndex);
}

class CurrentForecastHourState extends ForecastHourState{
  final String forecastHour;

  CurrentForecastHourState(this.forecastHour);
}