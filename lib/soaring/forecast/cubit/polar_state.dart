import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/polars.dart';

abstract class PolarDataState {
  const PolarDataState();
}

class GliderPolarInitialState extends PolarDataState {
  const GliderPolarInitialState();
}

class GliderListState extends PolarDataState {
  final List<String> gliderList;

  GliderListState(this.gliderList);
}

class GliderPolarState extends PolarDataState {
  final Polar? polar;

  GliderPolarState(this.polar);
}

class GliderPolarIsWorkingState extends PolarDataState {
  final bool isWorking;

  GliderPolarIsWorkingState(this.isWorking);
}

class GliderPolarErrorState extends PolarDataState {
  final String errorMsg;

  GliderPolarErrorState(this.errorMsg);
}
