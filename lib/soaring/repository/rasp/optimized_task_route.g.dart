// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'optimized_task_route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OptimizedTaskRoute _$OptimizedTaskRouteFromJson(Map<String, dynamic> json) =>
    OptimizedTaskRoute(
      error: json['error'] as String?,
      summary: json['summary'] as String?,
      routePoints: (json['routePoints'] as List<dynamic>?)
          ?.map((e) => RoutePoints.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OptimizedTaskRouteToJson(OptimizedTaskRoute instance) =>
    <String, dynamic>{
      'error': instance.error,
      'summary': instance.summary,
      'routePoints': instance.routePoints,
    };

RoutePoints _$RoutePointsFromJson(Map<String, dynamic> json) => RoutePoints(
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
      grndSpeed: json['grndSpeed'] as String?,
      thermal: json['thermal'] as String?,
      seconds: json['seconds'] as String?,
    );

Map<String, dynamic> _$RoutePointsToJson(RoutePoints instance) =>
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
      'grndSpeed': instance.grndSpeed,
      'thermal': instance.thermal,
      'seconds': instance.seconds,
    };
