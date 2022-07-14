// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'national_map.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NationalMap _$NationalMapFromJson(Map<String, dynamic> json) => NationalMap(
      uSGSElevationPointQueryService: json['uSGSElevationPointQueryService'] ==
              null
          ? null
          : USGSElevationPointQueryService.fromJson(
              json['uSGSElevationPointQueryService'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$NationalMapToJson(NationalMap instance) =>
    <String, dynamic>{
      'uSGSElevationPointQueryService': instance.uSGSElevationPointQueryService,
    };

USGSElevationPointQueryService _$USGSElevationPointQueryServiceFromJson(
        Map<String, dynamic> json) =>
    USGSElevationPointQueryService(
      elevationQuery: json['elevationQuery'] == null
          ? null
          : ElevationQuery.fromJson(
              json['elevationQuery'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$USGSElevationPointQueryServiceToJson(
        USGSElevationPointQueryService instance) =>
    <String, dynamic>{
      'elevationQuery': instance.elevationQuery,
    };

ElevationQuery _$ElevationQueryFromJson(Map<String, dynamic> json) =>
    ElevationQuery(
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
      dataSource: json['dataSource'] as String?,
      elevation: (json['elevation'] as num?)?.toDouble(),
      units: json['units'] as String?,
    );

Map<String, dynamic> _$ElevationQueryToJson(ElevationQuery instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'dataSource': instance.dataSource,
      'elevation': instance.elevation,
      'units': instance.units,
    };
