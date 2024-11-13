import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/cubit/glider_state.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/gliders.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:vector_math/vector_math_64.dart';

enum VelocityConversion { kmh2kts, kts2kmh }

enum SinkRateConversion { mpsec2ftpmin, ftpmin2mpsec }

enum MassConversion { kg2lbs, lbs2kg }

enum DistanceConversion { mt2ft, ft2mt }

enum SinkUnits {
  ftPerMin(display: "ft/min"),
  mPerSec(display: "m/sec");

  const SinkUnits({required this.display});

  final String display;
}

enum SpeedUnits {
  kph(display: "kph"),
  kts(display: "kts");

  const SpeedUnits({required this.display});

  final String display;
}

enum WeightUnits {
  lbs(display: "lbs"),
  kg(display: "kg");

  const WeightUnits({required this.display});

  final String display;
}

enum DistanceUnits {
  meters(display: "meters"),
  feet(display: "ft");

  const DistanceUnits({required this.display});

  final String display;
}

class GliderCubit extends Cubit<GliderState> {
  late final Repository _repository;

  DisplayUnits? _displayUnits;
  Glider? _defaultGlider;
  Glider? _customGlider;
  String _velocityUnits = "";
  String _sinkRateUnits = "";
  String _massUnits = "";
  String _distanceUnits = "";

  // double angleInDegrees = 30;
  // double speed = 40; // mph

  // used to calculate thermal turn diameter at given bank angle;
  static const double ktsToFtperSec = 1.68781;
  static const double gravityFtPerSec2 = 32.174; // ft/sec^2
  static const double gravityMetersPerSec2 = 9.8; // gravity meters/sec^2
  static const double kphToMetersPerSec = .27778;// 1000 / (60 * 60); // kph to meters per second
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
    List<Glider>? defaultList = await _repository.getDefaultListOfGliders();
    gliders.addAll(defaultList?.map((polar) => polar.glider) ?? <String>[]);
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

  Future<void> getGliderPolar(String glider) async {
    _indicateWorking(true);
    await _repository.saveLastSelectedGliderName(glider);
    _displayUnits = await _repository.getDisplayUnits();
    _assignDisplayUnitLabels();
    var gliderRecord =
        await _repository.getDefaultAndCustomGliderDetails(glider);
    // repository always have glider details in metric units
    _defaultGlider = gliderRecord.defaultGlider;
    _customGlider = gliderRecord.customGlider;
    // May need to convert to American units -kts, ft, lbs
    var defaultGliderLocalUnits = _convertGliderValues(
        _defaultGlider!.copyWith(), DisplayUnits.Metric, _displayUnits!);
    var customGliderLocalUnits = _convertGliderValues(
        _customGlider!.copyWith(), DisplayUnits.Metric, _displayUnits!);
    calculateThermallingValues(defaultGliderLocalUnits);
    calculateThermallingValues(customGliderLocalUnits);

    emit(GliderPolarState(
        defaultGliderLocalUnits,
        customGliderLocalUnits,
        _displayUnits!,
        _sinkRateUnits,
        _velocityUnits,
        _massUnits,
        _distanceUnits));
    _indicateWorking(false);
  }

  Future<void> saveDisplayUnits(
      DisplayUnits newDisplayUnits, Glider customGlider) async {
    _indicateWorking(true);
    if (_displayUnits == newDisplayUnits) return;
    _displayUnits = newDisplayUnits;
    await _repository.saveDisplayUnits(newDisplayUnits);
    _assignDisplayUnitLabels();
    //TODO very similar to above logic. Consolidate?
    var defaultGliderLocalUnits;
    var customGliderLocalUnits;
    if (newDisplayUnits == DisplayUnits.American) {
      // previously displaying metric, now want display in american units
      defaultGliderLocalUnits = _convertGliderValues(
          _defaultGlider!.copyWith(), DisplayUnits.Metric, _displayUnits!);
      customGliderLocalUnits = _convertGliderValues(
          _customGlider!.copyWith(), DisplayUnits.Metric, _displayUnits!);
    } else {
      // was american, now show in metric
      defaultGliderLocalUnits = _defaultGlider!.copyWith(); //
      customGliderLocalUnits = _convertGliderValues(
          _customGlider!.copyWith(), DisplayUnits.American, DisplayUnits.Metric);
    }
    emit(GliderPolarState(
        defaultGliderLocalUnits,
        customGliderLocalUnits,
        _displayUnits!,
        _sinkRateUnits,
        _velocityUnits,
        _massUnits,
        _distanceUnits));
    _indicateWorking(false);
  }

  Glider _convertGliderValues(
      Glider gliderPolar, DisplayUnits fromUnits, DisplayUnits toUnits) {
    if (fromUnits == toUnits) return gliderPolar;
    VelocityConversion? velocityConversion;
    SinkRateConversion? sinkRateConversion;
    MassConversion? massConversion;
    DistanceConversion? distanceConversion;

    if (toUnits == DisplayUnits.American) {
      velocityConversion = VelocityConversion.kmh2kts;
      sinkRateConversion = SinkRateConversion.mpsec2ftpmin;
      massConversion = MassConversion.kg2lbs;
      distanceConversion = DistanceConversion.mt2ft;
    } else {
      velocityConversion = VelocityConversion.kts2kmh;
      sinkRateConversion = SinkRateConversion.ftpmin2mpsec;
      massConversion = MassConversion.lbs2kg;
      distanceConversion = DistanceConversion.ft2mt;
    }

    gliderPolar.gliderAndMaxPilotWgt =
        _convertMass(gliderPolar.gliderAndMaxPilotWgt, massConversion);
    gliderPolar.maxBallast =
        _convertMass(gliderPolar.maxBallast, massConversion);
    gliderPolar.gliderEmptyMass =
        _convertMass(gliderPolar.gliderEmptyMass, massConversion);
    gliderPolar.pilotMass = _convertMass(gliderPolar.pilotMass, massConversion);
    gliderPolar.minSinkSpeed =
        _convertVelocity(gliderPolar.minSinkSpeed, velocityConversion);
    gliderPolar.minSinkRate =
        _convertSinkRate(gliderPolar.minSinkRate, sinkRateConversion);
    gliderPolar.thermallingSinkRate =
        _convertSinkRate(gliderPolar.thermallingSinkRate, sinkRateConversion);
    gliderPolar.minSinkSpeedAtBankAngle = _convertVelocity(
        gliderPolar.minSinkSpeedAtBankAngle, velocityConversion);
    gliderPolar.turnDiameter =
        _convertDistance(gliderPolar.turnDiameter, distanceConversion);

    gliderPolar.v1 = _convertVelocity(gliderPolar.v1, velocityConversion);
    gliderPolar.v2 = _convertVelocity(gliderPolar.v2, velocityConversion);
    gliderPolar.v3 = _convertVelocity(gliderPolar.v3, velocityConversion);

    gliderPolar.w1 = _convertSinkRate(gliderPolar.w1, sinkRateConversion);
    gliderPolar.w2 = _convertSinkRate(gliderPolar.w2, sinkRateConversion);
    gliderPolar.w3 = _convertSinkRate(gliderPolar.w3, sinkRateConversion);

    return gliderPolar;
  }

  void _assignDisplayUnitLabels() {
    _velocityUnits = (_displayUnits == DisplayUnits.Metric)
        ? SpeedUnits.kph.display
        : SpeedUnits.kts.display;
    _sinkRateUnits = (_displayUnits == DisplayUnits.Metric)
        ? SinkUnits.mPerSec.display
        : SinkUnits.ftPerMin.display;
    _massUnits = (_displayUnits == DisplayUnits.Metric)
        ? WeightUnits.kg.display
        : WeightUnits.lbs.display;
    _distanceUnits = (_displayUnits == DisplayUnits.Metric)
        ? DistanceUnits.meters.display
        : DistanceUnits.feet.display;
  }

  double _convertVelocity(
      double? velocity, VelocityConversion velocityConversion) {
    if (velocity == null) return 0;
    if (velocityConversion == VelocityConversion.kmh2kts) {
      // input in metric (km/h) so convert velocity to kts
      return velocity * .539957;
    } else {
      // convert kts to km/h
      return velocity / .539957;
    }
  }

// Jason Input value is always metric
  double _convertSinkRate(
      double? sinkRate, SinkRateConversion sinkRateConversion) {
    if (sinkRate == null) return 0;
    if (sinkRateConversion == SinkRateConversion.mpsec2ftpmin) {
      // input is m/sec so convert to ft/min
      return sinkRate * 3.28084 * 60.0;
    } else {
      // input is ft/min, convert to m/sec
      return sinkRate / (3.28084 * 60.0);
    }
  }

  double _convertMass(double? mass, MassConversion massConversion) {
    if (mass == null) return 0;
    if (massConversion == MassConversion.kg2lbs) {
      // convert from kg to lbs
      return mass * 2.20462;
    } else {
      // convert lbs to kg
      return mass / 2.20462;
    }
  }

  double _convertDistance(
      double? distance, DistanceConversion distanceConversion) {
    if (distance == null) return 0;
    if (distanceConversion == DistanceConversion.mt2ft) {
      // convert meters to feet
      return distance * 3.28084;
    } else {
      // convert feet to meter
      return distance / 3.28084;
    }
  }

  void calcEstimatedTaskTime(Glider customGlider) async {
    _indicateWorking(true);
    await storeCustomGlider(customGlider);
    //  call repository
    _indicateWorking(false);
    emit(CalcEstimatedFlightState(_customGlider!));
  }

  Future<void> storeCustomGlider(Glider customGlider) async {
    if (_displayUnits == DisplayUnits.American) {
      // convert to metric
      _customGlider = _convertGliderValues(
          customGlider.copyWith(), DisplayUnits.American, DisplayUnits.Metric);
    } else {
      _customGlider = customGlider.copyWith();
    };

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


// Calculation from https://groups.io/g/WarnerSpringsSoaring/topic/optimal_bank_angle/87513283?p=,,,20,0,0,0::recentpostdate/sticky,,,20,0,0,87513283,previd=1640661436050123677,nextid=1630163573444280014&previd=1640661436050123677&nextid=1630163573444280014
//  and https://groups.io/g/WarnerSpringsSoaring/attachment/458/0/Bank%20angles%20Wt%20and%20balance.xlsx
// adjusted for adding ballast. Note that just using the 'your glider' mass values not XCSOAR default values
  void calculateThermallingValues(Glider glider) {
    glider.thermallingSinkRate = (1 /
        pow(cos(radians(glider.bankAngle.toDouble())), 1.5).toDouble() *
        glider.minSinkRate);
    glider.ballastAdjThermallingSinkRate = glider.thermallingSinkRate *
        sqrt(
            (glider.pilotMass + glider.gliderEmptyMass + glider.loadedBallast) /
                (glider.pilotMass + glider.gliderEmptyMass));

    glider.minSinkSpeedAtBankAngle =
        glider.minSinkSpeed * pow(1 / cos(glider.bankAngle * pi / 180), .5);

    double speed = 0;
    double funkyNumber = 0;
    double tangent = tan(twoPi / 360.0 * glider.bankAngle);
    //TODO convert to metric if needed
    if (_displayUnits == DisplayUnits.Metric) {
      speed = glider.minSinkSpeedAtBankAngle * kphToMetersPerSec;
      funkyNumber = gravityMetersPerSec2 * tangent;
    } else {
      speed = glider.minSinkSpeedAtBankAngle * ktsToFtperSec;
      funkyNumber = gravityFtPerSec2 * tangent;
    }
    glider.turnDiameter = 2 * pow(speed, 2) / funkyNumber;
    glider.secondsForTurn = (twoPi * speed) / funkyNumber;
    storeCustomGlider(glider);
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
