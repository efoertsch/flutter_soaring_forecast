
import 'package:flutter_bloc/flutter_bloc.dart';

import 'forecast_hour_state.dart';

class ForecastHourCubit extends Cubit<ForecastHourState> {
  ForecastHourCubit() :super(ForecastHourInitialState()) {}


  // call to display either pause or loop text
  Future<void> setForecastHour(String forecastHour) async {
    emit(CurrentForecastHourState(forecastHour));
  }


  // call to display either pause or loop text
  Future<void> runAnimation( bool runAnimation) async {
    emit(RunHourAnimationState(runAnimation));
  }

  // call to tell other blocs to increment(+1) or decrement(-1) the forecast hour
  Future<void> incrDecrHourIndex( int  incrDecrIndex) async {
    emit(RunHourAnimationState(false));
    emit(IncrDecrHourIndexState(incrDecrIndex));
  }


}