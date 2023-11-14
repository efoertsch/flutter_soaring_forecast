import 'dart:math';

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
import 'package:equatable/equatable.dart';

part 'polars.g.dart';

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
class Polars {
  List<Polar>? polars;

  Polars({
    this.polars,
  });

  factory Polars.fromJson(Map<String, dynamic> json) => _$PolarsFromJson(json);

  Map<String, dynamic> toJson() => _$PolarsToJson(this);


  static Polars polarsFromJson(String str) => Polars.fromJson(json.decode(str));

  static String polarsToJson(Polar data) => json.encode(data.toJson());
}

@JsonSerializable()
class Polar extends Equatable {
  late final String glider;
  @JsonKey(name: 'glider_and_max_pilot_wgt')
  late final double gliderAndMaxPilotWgt;
  @JsonKey(name: 'max_ballast')
  late final double maxBallast;
  @JsonKey(name: 'V1')
  late final double v1;
  @JsonKey(name: 'W1')
  late final double w1;
  @JsonKey(name: 'V2')
  late final double v2;
  @JsonKey(name: 'W2')
  late final double w2;
  @JsonKey(name: 'V3')
  late final double v3;
  @JsonKey(name: 'W3')
  late final double w3;
  @JsonKey(name: 'wing_area')
  late final double  wingArea;
  @JsonKey(name: 'ballast_dump_time')
  late final double ballastDumpTime;
  late final double handicap;
  @JsonKey(name: 'glider_empty_mass')
  late final double gliderEmptyMass;

  Polar(
      {required this.glider,
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
      required this.gliderEmptyMass});

  factory Polar.fromJson(Map<String, dynamic> json) => _$PolarFromJson(json);

  Map<String, dynamic> toJson() => _$PolarToJson(this);


  Polar copyWith({
    required String glider,
    required double gliderAndMaxPilotWgt,
    required double maxBallast,
    required double v1,
    required double w1,
    required double v2,
    required double w2,
    required double v3,
    required double w3,
    required double wingArea,
    required double ballastDumpTime,
    required double handicap,
    required double gliderEmptyMass,
  }) =>
      Polar(
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
      );

  static Polar polarFromJson(String str) => Polar.fromJson(json.decode(str));

  static String polarToJson(Polar data) => json.encode(data.toJson());

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
      ];

  // Get polar coefficients as string a,b,c
  String getPolarCoefficients() {
    double a = getA();
    double b = getB(a);
    return a.toStringAsFixed(4) +
        ',' +
        getB(a).toStringAsFixed(4) +
        ',' +
        getC(a, b).toStringAsFixed(4);
  }

  // a,b,c calculated per Reichman  Cross country soaring pg 122.
  double getA() {
    double a = ((v2 - v3) * (w1 - w3) + (v3 - v1) * (w2 - w3)) /
        (pow(v1, 2) * (v2 - v3) +
            pow(v2, 2) * (v3 - v1) +
            pow(v3, 2) * (v1 - v2));
    return a;
  }

  double getB(double a) {
    double b = ((w2 - w3) - a * (pow(v2, 2) - pow(v3, 2))) / (v2 - v3);
    return b;
  }

  double getC(double a, double b) {
    double c = w3 - a * pow(v3, 2) - b * v3;
    return c;
  }
}
