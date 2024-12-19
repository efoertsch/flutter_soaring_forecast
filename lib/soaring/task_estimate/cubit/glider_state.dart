import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/gliders.dart';

import '../../repository/rasp/estimated_flight_avg_summary.dart';

abstract class GliderCubitState {
  const GliderCubitState();
}

class GliderCubitInitialState extends GliderCubitState {
  const GliderCubitInitialState();
}

class GliderListState extends GliderCubitState {
  final List<String> gliderNameList;
  final String selectedGliderName;

  GliderListState(this.gliderNameList, this.selectedGliderName);
}

class GliderPolarState extends GliderCubitState {
  final Glider defaultPolar;
  final Glider customPolar;
  final DisplayUnits displayUnits;
  final String sinkRateUnits;
  final String velocityUnits;
  final String massUnits;
  final String distanceUnits;
  final bool displayXCSoarValues;

  GliderPolarState(
      {required this.defaultPolar,
      required this.customPolar,
      required this.displayUnits,
      required this.sinkRateUnits,
      required this.velocityUnits,
      required this.massUnits,
      required this.distanceUnits,
      required this.displayXCSoarValues});
}

class GliderCubitWorkingState extends GliderCubitState {
  final bool working;

  GliderCubitWorkingState(this.working);
}


class GliderCubitErrorState extends GliderCubitState {
  final String errorMsg;

  GliderCubitErrorState(this.errorMsg);
}



class CalcEstimatedFlightState extends GliderCubitState {
  final Glider glider;

  CalcEstimatedFlightState(this.glider);
}

class DisplayEstimatedFlightText extends GliderCubitState {}
