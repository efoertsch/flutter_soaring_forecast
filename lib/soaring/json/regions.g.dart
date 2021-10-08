// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'regions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Regions _$RegionsFromJson(Map<String, dynamic> json) => Regions(
      initialRegion: json['initialRegion'] as String?,
      regions: (json['regions'] as List<dynamic>?)
          ?.map((e) => Region.fromJson(e as Map<String, dynamic>))
          .toList(),
      airspace: json['airspace'] == null
          ? null
          : Airspace.fromJson(json['airspace'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RegionsToJson(Regions instance) => <String, dynamic>{
      'initialRegion': instance.initialRegion,
      'regions': instance.regions,
      'airspace': instance.airspace,
    };

Region _$RegionFromJson(Map<String, dynamic> json) => Region(
      printDates: (json['printDates'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      soundings: (json['soundings'] as List<dynamic>?)
          ?.map((e) => Soundings.fromJson(e as Map<String, dynamic>))
          .toList(),
      dates:
          (json['dates'] as List<dynamic>?)?.map((e) => e as String).toList(),
      name: json['name'] as String?,
    );

Map<String, dynamic> _$RegionToJson(Region instance) => <String, dynamic>{
      'printDates': instance.printDates,
      'soundings': instance.soundings,
      'dates': instance.dates,
      'name': instance.name,
    };

Soundings _$SoundingsFromJson(Map<String, dynamic> json) => Soundings(
      location: json['location'] as String?,
      longitude: json['longitude'] as String?,
      latitude: json['latitude'] as String?,
    );

Map<String, dynamic> _$SoundingsToJson(Soundings instance) => <String, dynamic>{
      'location': instance.location,
      'longitude': instance.longitude,
      'latitude': instance.latitude,
    };

Airspace _$AirspaceFromJson(Map<String, dynamic> json) => Airspace(
      baseUrl: json['baseUrl'] as String?,
      files:
          (json['files'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$AirspaceToJson(Airspace instance) => <String, dynamic>{
      'baseUrl': instance.baseUrl,
      'files': instance.files,
    };
