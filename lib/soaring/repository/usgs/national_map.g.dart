// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'national_map.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NationalMap _$NationalMapFromJson(Map<String, dynamic> json) => NationalMap(
      location: json['location'] == null
          ? null
          : Location.fromJson(json['location'] as Map<String, dynamic>),
      locationId: (json['locationId'] as num?)?.toInt(),
      value: json['value'] as String?,
      rasterId: (json['rasterId'] as num?)?.toInt(),
      resolution: (json['resolution'] as num?)?.toInt(),
    );

Map<String, dynamic> _$NationalMapToJson(NationalMap instance) =>
    <String, dynamic>{
      'location': instance.location,
      'locationId': instance.locationId,
      'value': instance.value,
      'rasterId': instance.rasterId,
      'resolution': instance.resolution,
    };

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
      spatialReference: json['spatialReference'] == null
          ? null
          : SpatialReference.fromJson(
              json['spatialReference'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'spatialReference': instance.spatialReference,
    };

SpatialReference _$SpatialReferenceFromJson(Map<String, dynamic> json) =>
    SpatialReference(
      wkid: (json['wkid'] as num?)?.toInt(),
      latestWkid: (json['latestWkid'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SpatialReferenceToJson(SpatialReference instance) =>
    <String, dynamic>{
      'wkid': instance.wkid,
      'latestWkid': instance.latestWkid,
    };
