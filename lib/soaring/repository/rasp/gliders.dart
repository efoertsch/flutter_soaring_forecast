import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:vector_math/vector_math_64.dart';

part 'gliders.g.dart';

///  Fields correspond to polar data from XCSoar github  XCSoar/src/Polar/PolarStore.cpp
///  Download to Googlesheet, parsed, then converted to polar JSON string
///  https://docs.google.com/spreadsheets/d/11s6b0BEiOLh2ITzhs9nVlh9HWSmoBeUtlxkrAEwkKUs/edit?usp=sharing
/// 1. Gen'ed Dart code from assets/json/forecast_options via using https://app.quicktype.io/
/// 2. Modified code for generator:
///    a. Added @JsonSerializable() for each class (except enums) below
///    b. Add getters as needed for convenience
/// 3. Added part 'polars.g.dart' above
/// 4. Generated ...g.dart file running following command in terminal
///    dart run build_runner build --delete-conflicting-outputs

@JsonSerializable()
class Gliders {
  List<Glider>? gliders;

  Gliders({
    this.gliders,
  });

  factory Gliders.fromJson(Map<String, dynamic> json) =>
      _$GlidersFromJson(json);

  Map<String, dynamic> toJson() => _$GlidersToJson(this);

  static Gliders glidersFromJsonString(String str) =>
      Gliders.fromJson(json.decode(str));

  static String glidersToJsonString(Gliders data) => json.encode(data.toJson());
}

@JsonSerializable()
class Glider extends Equatable {
  late String glider;
  @JsonKey(name: 'glider_and_max_pilot_wgt')
  late double gliderAndMaxPilotWgt;
  @JsonKey(name: 'max_ballast')
  late double maxBallast;
  @JsonKey(name: 'V1')
  late double v1;
  @JsonKey(name: 'W1')
  late double w1;
  @JsonKey(name: 'V2')
  late double v2;
  @JsonKey(name: 'W2')
  late double w2;
  @JsonKey(name: 'V3')
  late double v3;
  @JsonKey(name: 'W3')
  late double w3;
  @JsonKey(name: 'wing_area')
  late double wingArea;
  @JsonKey(name: 'ballast_dump_time')
  late double ballastDumpTime;
  late double handicap;
  @JsonKey(name: 'glider_empty_mass')
  late double gliderEmptyMass;

  // fields not on XCSoar glider database but calculated in Google XCSoar
  // sheet and added to JSON
  @JsonKey(name: 'pilotMass')
  late double pilotMass;
  @JsonKey(name: 'a')
  late double a;
  @JsonKey(name: 'b')
  late double b;
  @JsonKey(name: 'c')
  late double c;
  @JsonKey(name: 'minSinkSpeed')
  late double minSinkSpeed;
  @JsonKey(name: 'minSinkRate')
  late double minSinkRate;

  // fields not on XCSoar glider database nor calculated on original spreadsheet, user will input or program will set/calculate
  late double loadedBallast;
  late bool updatedVW;

  // values user defined or calculated
  late double minSinkMass; // user defined,metric
  late int
      bankAngle; // Pilot estimate of bank angle they will use when flying the task.
  // Calculated sink rate using min sink and angle of bank
  late double
      thermallingSinkRate; // calculated value based on min SinkRate and bank Angle
  late double polarWeightAdjustment; // assign  using
  // 1. Use value of 1 if using all XCSoar provided values
  // 2. User uses XCSoar Vx/Wx but adjusted where glider/pilot/ballast weight
  //     sq root(glider weight/glider weight when polar Vx/Wx) measured
  // 3. User defined their own Vx/Wx polar figures
  //     Similar calc as 2 but using user specified glider,pilot, ballast values
  //     sq root((glider + pilot + ballast)/(glider + pilot)
  late double
      ballastAdjThermallingSinkRate; // sink rate adjusted for added ballast (value used to send to server)

  Glider({
    required this.glider,
    required this.gliderAndMaxPilotWgt,
    required this.maxBallast,
    required this.v1,
    required this.w1,
    required this.v2,
    required this.w2,
    required this.v3,
    required this.w3,
    required this.wingArea,
    required this.ballastDumpTime,
    required this.handicap,
    required this.gliderEmptyMass,
    required this.pilotMass,
    required this.a,
    required this.b,
    required this.c,
    required this.minSinkSpeed,
    required this.minSinkRate,
    // custom code
    this.loadedBallast = 0,
    this.updatedVW = false,
    this.minSinkMass = 0,
    this.bankAngle = 45,
    this.thermallingSinkRate = 0,
    this.polarWeightAdjustment = 1,
    this.ballastAdjThermallingSinkRate = 0,
  }) {
    calcThermallingSinkRate();
  }

  factory Glider.fromJson(Map<String, dynamic> json) => _$GliderFromJson(json);

  Map<String, dynamic> toJson() => _$GliderToJson(this);

  Glider copyWith({
    String? glider,
    double? gliderAndMaxPilotWgt,
    double? maxBallast,
    double? v1,
    double? w1,
    double? v2,
    double? w2,
    double? v3,
    double? w3,
    double? wingArea,
    double? ballastDumpTime,
    double? handicap,
    double? gliderEmptyMass,
    double? pilotMass,
    double? a,
    double? b,
    double? c,
    double? minSinkSpeed,
    double? minSinkRate,
    double? loadedBallast,
    bool? updatedVW,
    double? minSinkMass,
    int? bankAngle,
    double? thermallingSinkRate,
    double? polarWeightAdjustment,
    double? ballastAdjThermallingSinkRate,
  }) =>
      Glider(
        glider: glider ?? this.glider,
        gliderAndMaxPilotWgt: gliderAndMaxPilotWgt ?? this.gliderAndMaxPilotWgt,
        maxBallast: maxBallast ?? this.maxBallast,
        v1: v1 ?? this.v1,
        w1: w1 ?? this.w1,
        v2: v2 ?? this.v2,
        w2: w2 ?? this.w2,
        v3: v3 ?? this.v3,
        w3: w3 ?? this.w3,
        wingArea: wingArea ?? this.wingArea,
        ballastDumpTime: ballastDumpTime ?? this.ballastDumpTime,
        handicap: handicap ?? this.handicap,
        gliderEmptyMass: gliderEmptyMass ?? this.gliderEmptyMass,
        pilotMass: pilotMass ?? this.pilotMass,
        a: a ?? this.a,
        b: b ?? this.b,
        c: c ?? this.c,
        minSinkSpeed: minSinkSpeed ?? this.minSinkSpeed,
        minSinkRate: minSinkRate ?? this.minSinkRate,
        loadedBallast: loadedBallast ?? this.loadedBallast,
        updatedVW: updatedVW ?? this.updatedVW,
        minSinkMass: minSinkMass ?? this.minSinkMass,
        bankAngle: bankAngle ?? this.bankAngle,
        thermallingSinkRate: thermallingSinkRate ?? this.thermallingSinkRate,
        polarWeightAdjustment:
            polarWeightAdjustment ?? this.polarWeightAdjustment,
        ballastAdjThermallingSinkRate: ballastAdjThermallingSinkRate ?? this.ballastAdjThermallingSinkRate,
      );

  static Glider gliderFromJson(String str) => Glider.fromJson(json.decode(str));

  static String gliderToJson(Glider data) => json.encode(data.toJson());

  @override
  List<Object?> get props => [
        glider,
        gliderAndMaxPilotWgt,
        maxBallast,
        v1,
        w1,
        v2,
        w2,
        v3,
        w3,
        wingArea,
        ballastDumpTime,
        handicap,
        gliderEmptyMass,
        pilotMass,
        a,
        b,
        c,
        minSinkSpeed,
        minSinkRate,
        loadedBallast,
        updatedVW,
        minSinkMass,
        bankAngle,
        thermallingSinkRate,
        polarWeightAdjustment,
        ballastAdjThermallingSinkRate,
      ];

  //----------- Custom Code ----------------------------------
  // Get polar coefficients as string a,b,c
  String getPolarCoefficients() {
    return a.toStringAsFixed(5) +
        ',' +
        b.toStringAsFixed(5) +
        ',' +
        c.toStringAsFixed(5);
  }

  // updated XCSoar json input to have a,b,c calculated in spreadsheet and placed in JSON
  // keeping for future reference
  // a,b,c calculated per Reichman  Cross country soaring pg 122.
  void recalcPolarValues() {
    a = ((v2 - v3) * (w1 - w3) + (v3 - v1) * (w2 - w3)) /
        (pow(v1, 2) * (v2 - v3) +
            pow(v2, 2) * (v3 - v1) +
            pow(v3, 2) * (v1 - v2));

    b = ((w2 - w3) - a * (pow(v2, 2) - pow(v3, 2))) / (v2 - v3);

    c = w3 - a * pow(v3, 2) - b * v3;

    // Good reference for finding min sink speed/ min sink based on quadratic
    // https://www.youtube.com/watch?v=jn_4oUlKGjc&t=152s
    minSinkSpeed = b / (2 * a);
    minSinkRate = (minSinkSpeed * a * a) + (b * minSinkSpeed) + c;
  }

  void updatePolar(Glider updatedPolar) {
    this.gliderAndMaxPilotWgt = updatedPolar.gliderAndMaxPilotWgt;
    this.maxBallast = updatedPolar.maxBallast;
    this.v1 = updatedPolar.v1;
    this.w1 = updatedPolar.w1;
    this.v2 = updatedPolar.v2;
    this.w2 = updatedPolar.w2;
    this.v3 = updatedPolar.v3;
    this.w3 = updatedPolar.w3;
    this.wingArea = updatedPolar.wingArea;
    this.ballastDumpTime = updatedPolar.ballastDumpTime;
    this.handicap = updatedPolar.handicap;
    this.gliderEmptyMass = updatedPolar.gliderEmptyMass;
    this.pilotMass = updatedPolar.pilotMass;
    this.a = updatedPolar.a;
    this.b = updatedPolar.b;
    this.c = updatedPolar.c;
    this.loadedBallast = updatedPolar.loadedBallast;
    this.updatedVW = updatedPolar.updatedVW;
    this.minSinkSpeed = updatedPolar.minSinkSpeed;
    this.minSinkRate = updatedPolar.minSinkRate;
    this.minSinkMass = updatedPolar.minSinkMass;
    this.bankAngle = updatedPolar.bankAngle;
    this.thermallingSinkRate = updatedPolar.thermallingSinkRate;
    this.polarWeightAdjustment = updatedPolar.polarWeightAdjustment;
    this.ballastAdjThermallingSinkRate = updatedPolar.ballastAdjThermallingSinkRate;
  }

  // Calculation from https://groups.io/g/WarnerSpringsSoaring/topic/optimal_bank_angle/87513283?p=,,,20,0,0,0::recentpostdate/sticky,,,20,0,0,87513283,previd=1640661436050123677,nextid=1630163573444280014&previd=1640661436050123677&nextid=1630163573444280014
  //  and https://groups.io/g/WarnerSpringsSoaring/attachment/458/0/Bank%20angles%20Wt%20and%20balance.xlsx
  // adjusted for adding ballast. Note that just using the 'your glider' mass values not XCSOAR default values
  void calcThermallingSinkRate() {
    thermallingSinkRate =
        (1 / cos(radians(bankAngle.toDouble())) * 1.5).toDouble() *
            minSinkRate;
    ballastAdjThermallingSinkRate = thermallingSinkRate * sqrt(
        (pilotMass + gliderEmptyMass + loadedBallast) /
            (pilotMass + gliderEmptyMass));
  }

  void calculatePolarAdjustmentFactor(Glider xcSoarGlider) {
    if (updatedVW = true) {
      // user changed the Vx/Wx values so just use myGlider weights
      polarWeightAdjustment = sqrt(
          (pilotMass + gliderEmptyMass + loadedBallast) /
              (pilotMass + gliderEmptyMass));
    } else {
      polarWeightAdjustment =
          (sqrt(pilotMass + gliderEmptyMass + loadedBallast) /
              xcSoarGlider.gliderAndMaxPilotWgt);
    }
  }
}
