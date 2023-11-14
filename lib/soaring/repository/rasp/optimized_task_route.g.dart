// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'optimized_task_route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OptimalTaskSummary _$OptimalTaskSummaryFromJson(Map<String, dynamic> json) =>
    OptimalTaskSummary(
      summary: json['summary'] == null
          ? null
          : Summary.fromJson(json['summary'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OptimalTaskSummaryToJson(OptimalTaskSummary instance) =>
    <String, dynamic>{
      'summary': instance.summary,
    };

Summary _$SummaryFromJson(Map<String, dynamic> json) => Summary(
      error: json['error'] as String?,
      warnings: (json['warnings'] as List<dynamic>?)
          ?.map((e) => Warning.fromJson(e as Map<String, dynamic>))
          .toList(),
      header: json['header'] == null
          ? null
          : Header.fromJson(json['header'] as Map<String, dynamic>),
      footers: (json['footers'] as List<dynamic>?)
          ?.map((e) => Footer.fromJson(e as Map<String, dynamic>))
          .toList(),
      routeTurnpoints: (json['routeTurnpoints'] as List<dynamic>?)
          ?.map((e) => RouteTurnpoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      details: (json['details'] as List<dynamic>?)
          ?.map((e) => Detail.fromJson(e as Map<String, dynamic>))
          .toList(),
      routePoints: (json['routePoints'] as List<dynamic>?)
          ?.map((e) => RoutePoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SummaryToJson(Summary instance) => <String, dynamic>{
      'error': instance.error,
      'warnings': instance.warnings,
      'header': instance.header,
      'footers': instance.footers,
      'routeTurnpoints': instance.routeTurnpoints,
      'details': instance.details,
      'routePoints': instance.routePoints,
    };

Warning _$WarningFromJson(Map<String, dynamic> json) => Warning(
      message: json['message'] as String?,
    );

Map<String, dynamic> _$WarningToJson(Warning instance) => <String, dynamic>{
      'message': instance.message,
    };

Detail _$DetailFromJson(Map<String, dynamic> json) => Detail(
      leg: json['leg'] as String?,
      clockTime: json['clockTime'] as String?,
      sptlAvgDistKm: json['sptlAvgDistKm'] as String?,
      sptlAvgTailWind: json['sptlAvgTailWind'] as String?,
      sptlAvgClimbRate: json['sptlAvgClimbRate'] as String?,
      optAvgTailWind: json['optAvgTailWind'] as String?,
      optAvgClimbRate: json['optAvgClimbRate'] as String?,
      optFlightTimeMin: json['optFlightTimeMin'] as String?,
      optFlightGrndSpeedKt: json['optFlightGrndSpeedKt'] as String?,
      optFlightGrndSpeedKmh: json['optFlightGrndSpeedKmh'] as String?,
      optFlightAirSpeedKt: json['optFlightAirSpeedKt'] as String?,
      optFlightThermalPct: json['optFlightThermalPct'] as String?,
    );

Map<String, dynamic> _$DetailToJson(Detail instance) => <String, dynamic>{
      'leg': instance.leg,
      'clockTime': instance.clockTime,
      'sptlAvgDistKm': instance.sptlAvgDistKm,
      'sptlAvgTailWind': instance.sptlAvgTailWind,
      'sptlAvgClimbRate': instance.sptlAvgClimbRate,
      'optAvgTailWind': instance.optAvgTailWind,
      'optAvgClimbRate': instance.optAvgClimbRate,
      'optFlightTimeMin': instance.optFlightTimeMin,
      'optFlightGrndSpeedKt': instance.optFlightGrndSpeedKt,
      'optFlightGrndSpeedKmh': instance.optFlightGrndSpeedKmh,
      'optFlightAirSpeedKt': instance.optFlightAirSpeedKt,
      'optFlightThermalPct': instance.optFlightThermalPct,
    };

Footer _$FooterFromJson(Map<String, dynamic> json) => Footer(
      message: json['message'] as String?,
    );

Map<String, dynamic> _$FooterToJson(Footer instance) => <String, dynamic>{
      'message': instance.message,
    };

Header _$HeaderFromJson(Map<String, dynamic> json) => Header(
      valid: json['valid'] as String?,
      startTime: json['startTime'] as String?,
      region: json['region'] as String?,
      glider: json['glider'] as String?,
      maxLd: json['maxLd'] as String?,
      polarSpeedAdjustment: json['polarSpeedAdjustment'] as String?,
      thermalStrengthMultiplier: json['thermalStrengthMultiplier'] as String?,
      thermalingSinkRate: json['thermalingSinkRate'] as String?,
      units: json['units'] as String?,
    );

Map<String, dynamic> _$HeaderToJson(Header instance) => <String, dynamic>{
      'valid': instance.valid,
      'startTime': instance.startTime,
      'region': instance.region,
      'glider': instance.glider,
      'maxLd': instance.maxLd,
      'polarSpeedAdjustment': instance.polarSpeedAdjustment,
      'thermalStrengthMultiplier': instance.thermalStrengthMultiplier,
      'thermalingSinkRate': instance.thermalingSinkRate,
      'units': instance.units,
    };

RoutePoint _$RoutePointFromJson(Map<String, dynamic> json) => RoutePoint(
      lat: json['lat'] as String?,
      lon: json['lon'] as String?,
      leg: json['leg'] as String?,
      segment: json['segment'] as String?,
      xPos: json['xPos'] as String?,
      yPos: json['yPos'] as String?,
      distance: json['distance'] as String?,
      time: json['time'] as String?,
      length: json['length'] as String?,
      climbRate: json['climbRate'] as String?,
      thermalStrength: json['thermalStrength'] as String?,
      tailWindMps: json['tailWindMps'] as String?,
      groundSpeed: json['groundSpeed'] as String?,
      thermalPct: json['thermalPct'] as String?,
      seconds: json['seconds'] as String?,
    );

Map<String, dynamic> _$RoutePointToJson(RoutePoint instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lon': instance.lon,
      'leg': instance.leg,
      'segment': instance.segment,
      'xPos': instance.xPos,
      'yPos': instance.yPos,
      'distance': instance.distance,
      'time': instance.time,
      'length': instance.length,
      'climbRate': instance.climbRate,
      'thermalStrength': instance.thermalStrength,
      'tailWindMps': instance.tailWindMps,
      'groundSpeed': instance.groundSpeed,
      'thermalPct': instance.thermalPct,
      'seconds': instance.seconds,
    };

RouteTurnpoint _$RouteTurnpointFromJson(Map<String, dynamic> json) =>
    RouteTurnpoint(
      number: json['number'] as String?,
      name: json['name'] as String?,
      lat: json['lat'] as String?,
      lon: json['lon'] as String?,
    );

Map<String, dynamic> _$RouteTurnpointToJson(RouteTurnpoint instance) =>
    <String, dynamic>{
      'number': instance.number,
      'name': instance.name,
      'lat': instance.lat,
      'lon': instance.lon,
    };
