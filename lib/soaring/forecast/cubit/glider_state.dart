import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/gliders.dart';

abstract class GliderState {
  const GliderState();
}

class GliderPolarInitialState extends GliderState {
  const GliderPolarInitialState();
}

class GliderListState extends GliderState {
  final List<String> gliderNameList;
  final String selectedGliderName;

  GliderListState(this.gliderNameList, this.selectedGliderName);
}

class GliderPolarState extends GliderState {
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

class GliderPolarIsWorkingState extends GliderState {
  final bool isWorking;

  GliderPolarIsWorkingState(this.isWorking);
}

class GliderPolarErrorState extends GliderState {
  final String errorMsg;

  GliderPolarErrorState(this.errorMsg);
}

class CalcEstimatedFlightState extends GliderState {
  final Glider glider;

  CalcEstimatedFlightState(this.glider);
}

class DisplayEstimatedFlightText extends GliderState {}
