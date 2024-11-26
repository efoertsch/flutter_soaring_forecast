import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/cubit/glider_state.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/gliders.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/cubit/glider_enums.dart';

class GliderCubit extends Cubit<GliderState> {
  late final Repository _repository;

  late DisplayUnits _displayUnits;
  Glider? _defaultGlider; // values always in metric
  Glider? _customGlider; // values always in metric
  Glider?
      _defaultGliderLocalUnits; // values may be metric, or imperial kts, mph, lbs,..
  Glider?
      _customGliderLocalUnits; // values may be metric, or imperial kts, mph, lbs,..

  String _velocityUnits = "";
  String _sinkRateUnits = "";
  String _massUnits = "";
  String _distanceUnits = "";
  bool _displayXCSoarValues = false;

  // double angleInDegrees = 30;
  // double speed = 40; // mph

  // used to calculate thermal turn diameter at given bank angle;
  static const double ktsToFtperSec = 1.68781;
  static const double mphToFtperSec = 1.46667;
  static const double gravityFtPerSec2 = 32.174; // ft/sec^2
  static const double gravityMetersPerSec2 = 9.8; // gravity meters/sec^2
  static const double kphToMetersPerSec =
      .27778; // 1000 / (60 * 60); // kph to meters per second
  static const double twoPi = 2 * pi;

  GliderCubit({required Repository repository})
      : _repository = repository,
        super(GliderPolarInitialState()) {}

  void _indicateWorking(bool isWorking) {
    emit(GliderPolarIsWorkingState(isWorking));
  }

  void checkToDisplayExperimentalText() async {
    var displayText =
        await _repository.getShowEstimatedFlightExperimentalText();
    if (displayText) {
      emit(DisplayEstimatedFlightText());
    }
  }

  Future<void> getListOfGliders() async {
    _indicateWorking(true);
    List<String> gliders = [];
    List<Glider>? fullGliderList = await _repository.getFullListOfGliders();
    gliders.addAll(fullGliderList?.map((polar) => polar.glider) ?? <String>[]);
    emit(GliderListState(
        gliders, await _repository.getLastSelectedGliderName()));
    String selectedGlider = await _repository.getLastSelectedGliderName();
    if (selectedGlider.isNotEmpty) {
      await getGliderPolar(selectedGlider);
    }
    if (await _repository.getDisplayExperimentalOptimalTaskAlertFlag()) {
      emit(DisplayEstimatedFlightText());
    }
    _indicateWorking(false);
  }

  Future<void> getGliderPolar(String gliderName) async {
    _indicateWorking(true);
    await _repository.saveLastSelectedGliderName(gliderName);
    _displayXCSoarValues = await _repository.getDisplayXCSoarValues();
    _displayUnits = await _repository.getDisplayUnits();
    _assignDisplayUnitLabels(_displayUnits);
    var gliderRecord =
        await _repository.getDefaultAndCustomGliderDetails(gliderName);
    // repository always have glider details in metric units
    _defaultGlider = gliderRecord.defaultGlider;
    _customGlider = gliderRecord.customGlider;
    // glider values always stored in metric so
    // may need to convert to Imperial units -kts/mph, ft, lbs
    _convertGliderInfoToPreferredUnits();
    calculateThermalingValues(_defaultGliderLocalUnits!);
    calculateThermalingValues(_customGliderLocalUnits!);
    _emitGlidersInfo();
    _indicateWorking(false);
  }

  Future<void> saveDisplayUnits(DisplayUnits newDisplayUnits) async {
    _indicateWorking(true);
    if (_displayUnits == newDisplayUnits) return;
    _displayUnits = newDisplayUnits;
    await _repository.saveDisplayUnits(newDisplayUnits);
    _assignDisplayUnitLabels(newDisplayUnits);
    _convertGliderInfoToPreferredUnits();
    calculateThermalingValues(_defaultGliderLocalUnits!);
    calculateThermalingValues(_customGliderLocalUnits!);
    _emitGlidersInfo();
    _indicateWorking(false);
  }

  void _convertGliderInfoToPreferredUnits() {
    _defaultGliderLocalUnits =
        _convertAllGliderValues(_defaultGlider!.copyWith(), _displayUnits);
    _customGliderLocalUnits =
        _convertAllGliderValues(_customGlider!.copyWith(), _displayUnits);
  }

  void _emitGlidersInfo() {
    emit(GliderPolarState(
        defaultPolar: _defaultGliderLocalUnits!,
        customPolar: _customGliderLocalUnits!,
        displayUnits: _displayUnits,
        sinkRateUnits: _sinkRateUnits,
        velocityUnits: _velocityUnits,
        massUnits: _massUnits,
        distanceUnits: _distanceUnits,
        displayXCSoarValues: _displayXCSoarValues));
  }

  // This logic is only to convert ALL glider values from
  // Metric to Imperial(kts or mph, lbs, ft, ...
  // Use other methods to update individual fields from 'local units' to metric
  Glider _convertAllGliderValues(Glider glider, DisplayUnits toUnits) {
    if (toUnits == DisplayUnits.Metric) {
      return glider;
    }

    VELOCITY_CONVERSION velocityConversion;
    SINK_RATE_CONVERSION sinkRateConversion;
    MASS_CONVERSION massConversion;
    DISTANCE_CONVERSION distanceConversion;

    if (toUnits == DisplayUnits.Imperial_kts) {
      velocityConversion = VELOCITY_CONVERSION.kph2kts;
    } else if (toUnits == DisplayUnits.Imperial_mph) {
      velocityConversion = VELOCITY_CONVERSION.kph2mph;
    } else {
      emit(GliderPolarErrorState(
          "Invalid displayUnits.  Conversion: ${toUnits.toString()}"));
      return glider;
    }

    glider.minSinkSpeed =
        _convertVelocity(glider.minSinkSpeed, velocityConversion);
    glider.v1 = _convertVelocity(glider.v1, velocityConversion);
    glider.v2 = _convertVelocity(glider.v2, velocityConversion);
    glider.v3 = _convertVelocity(glider.v3, velocityConversion);

    // sink speeds always m/sec to ft/min, weights kg to lbs,
    // distance meters to ft
    sinkRateConversion = SINK_RATE_CONVERSION.mpsec2ftpmin;
    massConversion = MASS_CONVERSION.kg2lbs;
    distanceConversion = DISTANCE_CONVERSION.mt2ft;

    glider.gliderAndMaxPilotWgt =
        _convertMass(glider.gliderAndMaxPilotWgt, massConversion);
    glider.maxBallast = _convertMass(glider.maxBallast, massConversion);
    glider.gliderEmptyMass =
        _convertMass(glider.gliderEmptyMass, massConversion);
    glider.pilotMass = _convertMass(glider.pilotMass, massConversion);

    glider.minSinkRate =
        _convertSinkRate(glider.minSinkRate, sinkRateConversion);
    glider.ballastAdjThermalingSinkRate = _convertSinkRate(
        glider.ballastAdjThermalingSinkRate, sinkRateConversion);
    glider.thermallingSinkRate =
        _convertSinkRate(glider.thermallingSinkRate, sinkRateConversion);
    glider.minSinkSpeedAtBankAngle =
        _convertVelocity(glider.minSinkSpeedAtBankAngle, velocityConversion);
    glider.turnDiameter =
        _convertDistance(glider.turnDiameter, distanceConversion);

    glider.w1 = _convertSinkRate(glider.w1, sinkRateConversion);
    glider.w2 = _convertSinkRate(glider.w2, sinkRateConversion);
    glider.w3 = _convertSinkRate(glider.w3, sinkRateConversion);

    return glider;
  }

  void _assignDisplayUnitLabels(DisplayUnits displayUnits) {
    _velocityUnits = (displayUnits == DisplayUnits.Metric)
        ? SPEED_UNITS.kph.display
        : (displayUnits == DisplayUnits.Imperial_kts)
            ? SPEED_UNITS.kts.display
            : SPEED_UNITS.mph.display;
    _sinkRateUnits = (displayUnits == DisplayUnits.Metric)
        ? SINK_UNITS.mPerSec.display
        : SINK_UNITS.ftPerMin.display;
    _massUnits = (displayUnits == DisplayUnits.Metric)
        ? WEIGHT_UNITS.kg.display
        : WEIGHT_UNITS.lbs.display;
    _distanceUnits = (displayUnits == DisplayUnits.Metric)
        ? DISTANCE_UNITS.meters.display
        : DISTANCE_UNITS.feet.display;
  }

  double _convertVelocity(
      double? velocity, VELOCITY_CONVERSION velocityConversion) {
    if (velocity == null) return 0;
    if (velocityConversion == VELOCITY_CONVERSION.kph2kts) {
      return velocity * .539957; // 1 kph = .539957 kph
    } else if (velocityConversion == VELOCITY_CONVERSION.kts2kph) {
      return velocity * 1.852; // 1 kt = 1.852 kph
    } else if (velocityConversion == VELOCITY_CONVERSION.mph2kph) {
      return velocity * 1.60934; // 1 mph = 1/60934 kph
    } else if (velocityConversion == VELOCITY_CONVERSION.kph2mph) {
      return velocity * 0.621371; // 1 kph = 0.621371 mph
    }
    emit(GliderPolarErrorState(
        "Invalid velocity conversion: ${velocityConversion.toString()}"));
    return 0;
  }

  void updateSinkRate(SINK_RATE_PARM sinkRateParm, double updatedValue) {
    double newValue = 0;
    if (_displayUnits == DisplayUnits.Metric) {
      newValue = updatedValue;
    } else {
      // convert ft/min to m/sec
      newValue =
          _convertSinkRate(updatedValue, SINK_RATE_CONVERSION.ftpmin2mpsec);
    }
    switch (sinkRateParm) {
      case SINK_RATE_PARM.MIN_SINK:
        _customGlider!.minSinkRate = newValue;
        calculateThermalingValues(_customGlider!);
      case SINK_RATE_PARM.W1:
        _customGlider!.updatedVW = true;
        _customGlider!.w1 = newValue;
        break;
      case SINK_RATE_PARM.W2:
        _customGlider!.updatedVW = true;
        _customGlider!.w2 = newValue;
        break;
      case SINK_RATE_PARM.W3:
        _customGlider!.updatedVW = true;
        _customGlider!.v3 = newValue;
        break;
      default:
        emit(GliderPolarErrorState(
            "Missing update logic for sink rate parm ${sinkRateParm}"));
    }
    storeCustomGlider();
    _customGliderLocalUnits =
        _convertAllGliderValues(_customGlider!.copyWith(), _displayUnits);
    _emitGlidersInfo();
  }

  void updateMass(MASS_PARM massParm, double updatedValue) {
    double newValue = 0;
    if (_displayUnits == DisplayUnits.Metric) {
      newValue = updatedValue;
    } else {
      newValue = _convertMass(updatedValue, MASS_CONVERSION.lbs2kg);
    }
    switch (massParm) {
      case MASS_PARM.GLIDER:
        _customGlider!.gliderEmptyMass = newValue;
        break;
      case MASS_PARM.PILOT:
        _customGlider!.pilotMass = newValue;
        break;
      case MASS_PARM.BALLAST:
        _customGlider!.loadedBallast = newValue;
        break;
      case MASS_PARM.MAX_BALLAST:
        _customGlider!.maxBallast = newValue;
        break;
      default:
        emit(GliderPolarErrorState(
            "Missing update logic for glider mass ${massParm}"));
        return;
    }
    storeCustomGlider();
    _customGliderLocalUnits =
        _convertAllGliderValues(_customGlider!.copyWith(), _displayUnits);
    _emitGlidersInfo();
  }

  void updateVelocity(VELOCITY_PARM velocityParm, double updatedValue) {
    double newValue = 0;
    if (_displayUnits == DisplayUnits.Metric) {
      newValue = updatedValue;
    } else {
      if (_displayUnits == DisplayUnits.Imperial_kts) {
        newValue = _convertVelocity(updatedValue, VELOCITY_CONVERSION.kts2kph);
      } else {
        newValue = _convertVelocity(updatedValue, VELOCITY_CONVERSION.mph2kph);
      }
    }
    switch (velocityParm) {
      case VELOCITY_PARM.MIN_SINK_SPEED:
        _customGlider!.minSinkSpeed = newValue;
        calculateThermalingValues(_customGlider!);
        break;
      case VELOCITY_PARM.V1:
        _customGlider!.v1 = newValue;
        _customGlider!.updatedVW = true;
        break;
      case VELOCITY_PARM.V2:
        _customGlider!.v2 = newValue;
        _customGlider!.updatedVW = true;
        break;
      case VELOCITY_PARM.V3:
        _customGlider!.v3 = newValue;
        _customGlider!.updatedVW = true;
        break;
      default:
        emit(GliderPolarErrorState(
            "Missing update logic for polar sink rate parm ${velocityParm}"));
        return;
    }
    storeCustomGlider();
    _customGliderLocalUnits =
        _convertAllGliderValues(_customGlider!.copyWith(), _displayUnits);
    _emitGlidersInfo();
  }

// Jason Input value is always metric
  double _convertSinkRate(
      double? sinkRate, SINK_RATE_CONVERSION sinkRateConversion) {
    if (sinkRate == null) return 0;
    if (sinkRateConversion == SINK_RATE_CONVERSION.mpsec2ftpmin) {
      // input is m/sec so convert to ft/min
      return sinkRate * 3.28084 * 60.0;
    } else {
      // input is ft/min, convert to m/sec
      return sinkRate / (3.28084 * 60.0);
    }
  }

  double _convertMass(double? mass, MASS_CONVERSION massConversion) {
    if (mass == null) return 0;
    if (massConversion == MASS_CONVERSION.kg2lbs) {
      // convert from kg to lbs
      return mass * 2.20462;
    } else {
      // convert lbs to kg
      return mass / 2.20462;
    }
  }

  double _convertDistance(
      double? distance, DISTANCE_CONVERSION distanceConversion) {
    if (distance == null) return 0;
    if (distanceConversion == DISTANCE_CONVERSION.mt2ft) {
      // convert meters to feet
      return distance * 3.28084;
    } else {
      // convert feet to meter
      return distance / 3.28084;
    }
  }

  void calcEstimatedTaskTime() async {
    // need to send values in metric
    emit(CalcEstimatedFlightState(_customGlider!));
  }

  // Store the customized glider mass/min sink/polar values
  // Note any updates to glider must be done prior to this point and all
  // values must be metric
  Future<void> storeCustomGlider() async {
    calculatePolarAdjustmentFactor(_customGlider!, _defaultGlider!);
    await _repository.saveCustomPolar(_customGlider!);
  }

  Future<void> displayExperimentalText(bool value) async {
    _repository.saveDisplayExperimentalOptimalTaskAlertFlag(value);
  }

  Future<void> resetExperimentalTextDisplay() async {
    displayExperimentalText(true);
    emit(DisplayEstimatedFlightText());
  }

  void updateThermalingBankAngle(int newBankAngle) {
    _customGlider!.bankAngle = newBankAngle;
    storeCustomGlider();
    _customGliderLocalUnits =
        _convertAllGliderValues(_customGlider!.copyWith(), _displayUnits);
    calculateThermalingValues(_customGliderLocalUnits!);

    _emitGlidersInfo();
  }

// Calculation from https://groups.io/g/WarnerSpringsSoaring/topic/optimal_bank_angle/87513283?p=,,,20,0,0,0::recentpostdate/sticky,,,20,0,0,87513283,previd=1640661436050123677,nextid=1630163573444280014&previd=1640661436050123677&nextid=1630163573444280014
//  and https://groups.io/g/WarnerSpringsSoaring/attachment/458/0/Bank%20angles%20Wt%20and%20balance.xlsx
// adjusted for adding ballast. Note that just using the 'your glider' mass values not XCSOAR default values
  void calculateThermalingValues(Glider glider) {
    _calcThermallingSinkRate(glider);
    _calcBallastAdjSinkRate(glider);
    _calcMinSinkSpeedAtBankAngle(glider);

    double speed = 0;
    double funkyNumber = 0;
    double tangent = tan(twoPi / 360.0 * glider.bankAngle);
    if (tangent == 0){  // if  bank angle is 0
      glider.turnDiameter = 0;
      glider.secondsForTurn = 0;
      return;
    }
    //TODO convert to metric if needed
    switch (_displayUnits) {
      case DisplayUnits.Metric:
        speed = glider.minSinkSpeedAtBankAngle * kphToMetersPerSec;
        funkyNumber = gravityMetersPerSec2 * tangent;
        break;
      case DisplayUnits.Imperial_kts:
        speed = glider.minSinkSpeedAtBankAngle * ktsToFtperSec;
        funkyNumber = gravityFtPerSec2 * tangent;
      case DisplayUnits.Imperial_mph:
        speed = glider.minSinkSpeedAtBankAngle * mphToFtperSec;
        funkyNumber = gravityFtPerSec2 * tangent;
      default:
        emit(GliderPolarErrorState(
            "Missing thermaling logic for ${_displayUnits}"));
        speed = 0;
        funkyNumber = 1;
    }

    glider.turnDiameter = 2 * pow(speed, 2) / funkyNumber;
    glider.secondsForTurn = (twoPi * speed) / funkyNumber;
  }

  void _calcMinSinkSpeedAtBankAngle(Glider glider) {
    glider.minSinkSpeedAtBankAngle =
        glider.minSinkSpeed * pow(1 / cos(glider.bankAngle * pi / 180), .5);
  }

  void _calcThermallingSinkRate(Glider glider) {
    glider.thermallingSinkRate = (1 /
        pow(cos(radians(glider.bankAngle.toDouble())), 1.5).toDouble() *
        glider.minSinkRate);
  }

  void _calcBallastAdjSinkRate(Glider glider) {
    glider.ballastAdjThermalingSinkRate = glider.thermallingSinkRate *
        sqrt(
            (glider.pilotMass + glider.gliderEmptyMass + glider.loadedBallast) /
                (glider.pilotMass + glider.gliderEmptyMass));
  }

  void calculatePolarAdjustmentFactor(
      Glider customGlider, Glider xcSoarGlider) {
    if (customGlider.updatedVW = true) {
      // user changed the Vx/Wx values so just use myGlider weights
      customGlider.polarWeightAdjustment = sqrt((customGlider.pilotMass +
              customGlider.gliderEmptyMass +
              customGlider.loadedBallast) /
          (customGlider.pilotMass + customGlider.gliderEmptyMass));
    } else {
      customGlider.polarWeightAdjustment = (sqrt(customGlider.pilotMass +
              customGlider.gliderEmptyMass +
              customGlider.loadedBallast) /
          xcSoarGlider.gliderAndMaxPilotWgt);
    }
  }

  void displayXCSoarValues(bool dislayXCSoarValues) {
    _repository.saveDisplayXCSoarValues(dislayXCSoarValues);
  }

// updated XCSoar json input to have a,b,c calculated in spreadsheet and placed in JSON
// keeping for future reference
// a,b,c calculated per Reichman  Cross country soaring pg 122.
// void recalcPolarValues() {
//   a = ((v2 - v3) * (w1 - w3) + (v3 - v1) * (w2 - w3)) /
//       (pow(v1, 2) * (v2 - v3) +
//           pow(v2, 2) * (v3 - v1) +
//           pow(v3, 2) * (v1 - v2));
//
//   b = ((w2 - w3) - a * (pow(v2, 2) - pow(v3, 2))) / (v2 - v3);
//
//   c = w3 - a * pow(v3, 2) - b * v3;
// Good reference for finding min sink speed/ min sink based on quadratic
// https://www.youtube.com/watch?v=jn_4oUlKGjc&t=152s
// minSinkSpeed = b / (2 * a);
// minSinkRate = (minSinkSpeed * a * a) + (b * minSinkSpeed) + c;
//
}
