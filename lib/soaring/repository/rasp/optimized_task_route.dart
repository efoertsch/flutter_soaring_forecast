
import 'package:json_annotation/json_annotation.dart';

part 'optimized_task_route.g.dart';

///  Generated via https://javiercbk.github.io/json_to_dart/ fron soargbsc.com/rasp/current.json
// If modified execute from terminal
//  dart run build_runner build --delete-conflicting-outputs
@JsonSerializable()
class OptimalTaskSummary {
  final Summary? summary;

  OptimalTaskSummary({
    this.summary,
  });

  factory OptimalTaskSummary.fromJson(Map<String, dynamic> json) => _$OptimalTaskSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$OptimalTaskSummaryToJson(this);

}

@JsonSerializable()
class Summary {
  final String? error;
  final List<Warning>? warnings;
  final Header? header;
  final List<Footer>? footers;
  final List<RouteTurnpoint>? routeTurnpoints;
  final List<Detail>? details;
  final List<RoutePoint>? routePoints;

  Summary({
    this.error,
    this.warnings,
    this.header,
    this.footers,
    this.routeTurnpoints,
    this.details,
    this.routePoints,
  });

  Summary copyWith({
    String? error,
    List<Warning>? warnings,
    Header? header,
    List<Footer>? footers,
    List<RouteTurnpoint>? routeTurnpoints,
    List<Detail>? details,
    List<RoutePoint>? routePoints,
  }) =>
      Summary(
        error: error ?? this.error,
        warnings: warnings ?? this.warnings,
        header: header ?? this.header,
        footers: footers ?? this.footers,
        routeTurnpoints: routeTurnpoints ?? this.routeTurnpoints,
        details: details ?? this.details,
        routePoints: routePoints ?? this.routePoints,
      );

  factory Summary.fromJson(Map<String, dynamic> json) => _$SummaryFromJson(json);

  Map<String, dynamic> toJson() => _$SummaryToJson(this);
}


@JsonSerializable()
class Warning {
  final String? message;

  Warning({
    this.message,
  });

  Warning copyWith({
    String? message,
  }) =>
      Warning(
        message: message ?? this.message,
      );

  factory Warning.fromJson(Map<String, dynamic> json) => _$WarningFromJson(json);

  Map<String, dynamic> toJson() => _$WarningToJson(this);
}

@JsonSerializable()
class Detail {
  final String? leg;
  final String? clockTime;
  final String? sptlAvgDistKm;
  final String? sptlAvgTailWind;
  final String? sptlAvgClimbRate;
  final String? optAvgTailWind;
  final String? optAvgClimbRate;
  final String? optFlightTimeMin;
  final String? optFlightGrndSpeedKt;
  final String? optFlightGrndSpeedKmh;
  final String? optFlightAirSpeedKt;
  final String? optFlightThermalPct;

  Detail({
    this.leg,
    this.clockTime,
    this.sptlAvgDistKm,
    this.sptlAvgTailWind,
    this.sptlAvgClimbRate,
    this.optAvgTailWind,
    this.optAvgClimbRate,
    this.optFlightTimeMin,
    this.optFlightGrndSpeedKt,
    this.optFlightGrndSpeedKmh,
    this.optFlightAirSpeedKt,
    this.optFlightThermalPct,
  });

  Detail copyWith({
    String? leg,
    String? clockTime,
    String? sptlAvgDistKm,
    String? sptlAvgTailWind,
    String? sptlAvgClimbRate,
    String? optAvgTailWind,
    String? optAvgClimbRate,
    String? optFlightTimeMin,
    String? optFlightGrndSpeedKt,
    String? optFlightGrndSpeedKmh,
    String? optFlightAirSpeedKt,
    String? optFlightThermalPct,
  }) =>
      Detail(
        leg: leg ?? this.leg,
        clockTime: clockTime ?? this.clockTime,
        sptlAvgDistKm: sptlAvgDistKm ?? this.sptlAvgDistKm,
        sptlAvgTailWind: sptlAvgTailWind ?? this.sptlAvgTailWind,
        sptlAvgClimbRate: sptlAvgClimbRate ?? this.sptlAvgClimbRate,
        optAvgTailWind: optAvgTailWind ?? this.optAvgTailWind,
        optAvgClimbRate: optAvgClimbRate ?? this.optAvgClimbRate,
        optFlightTimeMin: optFlightTimeMin ?? this.optFlightTimeMin,
        optFlightGrndSpeedKt: optFlightGrndSpeedKt ?? this.optFlightGrndSpeedKt,
        optFlightGrndSpeedKmh: optFlightGrndSpeedKmh ?? this.optFlightGrndSpeedKmh,
        optFlightAirSpeedKt: optFlightAirSpeedKt ?? this.optFlightAirSpeedKt,
        optFlightThermalPct: optFlightThermalPct ?? this.optFlightThermalPct,
      );

  factory Detail.fromJson(Map<String, dynamic> json) => _$DetailFromJson(json);

  Map<String, dynamic> toJson() => _$DetailToJson(this);
}

@JsonSerializable()
class Footer {
  final String? message;

  Footer({
    this.message,
  });

  Footer copyWith({
    String? message,
  }) =>
      Footer(
        message: message ?? this.message,
      );

  factory Footer.fromJson(Map<String, dynamic> json) => _$FooterFromJson(json);

  Map<String, dynamic> toJson() => _$FooterToJson(this);
}

@JsonSerializable()
class Header {
  final String? valid;
  final String? startTime;
  final String? region;
  final String? glider;
  final String? maxLd;
  final String? polarSpeedAdjustment;
  final String? thermalStrengthMultiplier;
  final String? thermalingSinkRate;
  final String? units;

  Header({
    this.valid,
    this.startTime,
    this.region,
    this.glider,
    this.maxLd,
    this.polarSpeedAdjustment,
    this.thermalStrengthMultiplier,
    this.thermalingSinkRate,
    this.units,
  });

  Header copyWith({
    String? valid,
    String? startTime,
    String? region,
    String? glider,
    String? maxLd,
    String? polarSpeedAdjustment,
    String? thermalStrengthMultiplier,
    String? thermalingSinkRate,
    String? units,
  }) =>
      Header(
        valid: valid ?? this.valid,
        startTime: startTime ?? this.startTime,
        region: region ?? this.region,
        glider: glider ?? this.glider,
        maxLd: maxLd ?? this.maxLd,
        polarSpeedAdjustment: polarSpeedAdjustment ?? this.polarSpeedAdjustment,
        thermalStrengthMultiplier: thermalStrengthMultiplier ?? this.thermalStrengthMultiplier,
        thermalingSinkRate: thermalingSinkRate ?? this.thermalingSinkRate,
        units: units ?? this.units,
      );


  factory Header.fromJson(Map<String, dynamic> json) => _$HeaderFromJson(json);

  Map<String, dynamic> toJson() => _$HeaderToJson(this);
}

@JsonSerializable()
class RoutePoint {
  final String? lat;
  final String? lon;
  final String? leg;
  final String? segment;
  final String? xPos;
  final String? yPos;
  final String? distance;
  final String? time;
  final String? length;
  final String? climbRate;
  final String? thermalStrength;
  final String? tailWindMps;
  final String? groundSpeed;
  final String? thermalPct;
  final String? seconds;

  RoutePoint({
    this.lat,
    this.lon,
    this.leg,
    this.segment,
    this.xPos,
    this.yPos,
    this.distance,
    this.time,
    this.length,
    this.climbRate,
    this.thermalStrength,
    this.tailWindMps,
    this.groundSpeed,
    this.thermalPct,
    this.seconds,
  });

  RoutePoint copyWith({
    String? lat,
    String? lon,
    String? leg,
    String? segment,
    String? xPos,
    String? yPos,
    String? distance,
    String? time,
    String? length,
    String? climbRate,
    String? thermalStrength,
    String? tailWindMps,
    String? groundSpeed,
    String? thermalPct,
    String? seconds,
  }) =>
      RoutePoint(
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        leg: leg ?? this.leg,
        segment: segment ?? this.segment,
        xPos: xPos ?? this.xPos,
        yPos: yPos ?? this.yPos,
        distance: distance ?? this.distance,
        time: time ?? this.time,
        length: length ?? this.length,
        climbRate: climbRate ?? this.climbRate,
        thermalStrength: thermalStrength ?? this.thermalStrength,
        tailWindMps: tailWindMps ?? this.tailWindMps,
        groundSpeed: groundSpeed ?? this.groundSpeed,
        thermalPct: thermalPct ?? this.thermalPct,
        seconds: seconds ?? this.seconds,
      );
  factory RoutePoint.fromJson(Map<String, dynamic> json) => _$RoutePointFromJson(json);

  Map<String, dynamic> toJson() => _$RoutePointToJson(this);
}

@JsonSerializable()
class RouteTurnpoint {
  final String? number;
  final String? name;
  final String? lat;
  final String? lon;

  RouteTurnpoint({
    this.number,
    this.name,
    this.lat,
    this.lon,
  });

  RouteTurnpoint copyWith({
    String? number,
    String? name,
    String? lat,
    String? lon,
  }) =>
      RouteTurnpoint(
        number: number ?? this.number,
        name: name ?? this.name,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
      );

  factory RouteTurnpoint.fromJson(Map<String, dynamic> json) => _$RouteTurnpointFromJson(json);

  Map<String, dynamic> toJson() => _$RouteTurnpointToJson(this);
}





