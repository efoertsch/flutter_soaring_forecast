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

  factory Polars.fromJson(Map<String, dynamic> json) =>
      Polars(
        polars: List<Polar>.from(
            json["polars"].map((x) => Polar.fromJson(x))),
      );

  Map<String, dynamic> toJson() =>
      {
        "polars": polars != null ? List<dynamic>.from(polars!.map((x) => x.toJson())) : "",
      };

  static Polars polarsFromJson(String str) =>
      Polars.fromJson(json.decode(str));

  static String polarsToJson(Polar data) => json.encode(data.toJson());
}

@JsonSerializable()
class Polar extends Equatable {
  late final String glider;
  late final double gliderAndMaxPilotWgt;
  late final double maxBallast;
  late final double v1;
  late final double w1;
  late final double v2;
  late final double w2;
  late final double v3;
  late final double w3;
  late final double wingArea;
  late final double ballastDumpTime;
  late final double handicap;
  late final double gliderEmptyMass;

  Polar({required this.glider,
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

  Polar.fromJson(Map<String, dynamic> json) {
    glider = json['glider'];
    gliderAndMaxPilotWgt = json['glider_and_max_pilot_wgt'].toDouble();
    maxBallast = json['max_ballast'].toDouble();
    v1 = json['V1'].toDouble();
    w1 = json['W1'].toDouble();
    v2 = json['V2'].toDouble();
    w2 = json['W2'].toDouble();
    v3 = json['V3'].toDouble();
    w3 = json['W3'].toDouble();
    wingArea = json['wing_area'].toDouble();
    ballastDumpTime = json['ballast_dump_time'].toDouble();
    handicap = json['handicap'].toDouble();
    gliderEmptyMass = json['glider_empty_mass'].toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['glider'] = this.glider;
    data['glider_and_max_pilot_wgt'] = this.gliderAndMaxPilotWgt;
    data['max_ballast'] = this.maxBallast;
    data['V1'] = this.v1;
    data['W1'] = this.w1;
    data['V2'] = this.v2;
    data['W2'] = this.w2;
    data['V3'] = this.v3;
    data['W3'] = this.w3;
    data['wing_area'] = this.wingArea;
    data['ballast_dump_time'] = this.ballastDumpTime;
    data['handicap'] = this.handicap;
    data['glider_empty_mass'] = this.gliderEmptyMass;
    return data;
  }

  Polar copyWith({
    required String glider ,
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


  static Polar polarFromJson(String str) =>
      Polar.fromJson(json.decode(str));

  static String polarToJson(Polar data) => json.encode(data.toJson());

  @override
  List<Object?> get props =>
      [
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
}
