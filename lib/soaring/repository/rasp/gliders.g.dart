// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gliders.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Gliders _$GlidersFromJson(Map<String, dynamic> json) => Gliders(
      gliders: (json['gliders'] as List<dynamic>?)
          ?.map((e) => Glider.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GlidersToJson(Gliders instance) => <String, dynamic>{
      'gliders': instance.gliders,
    };

Glider _$GliderFromJson(Map<String, dynamic> json) => Glider(
      glider: json['glider'] as String,
      gliderAndMaxPilotWgt:
          (json['glider_and_max_pilot_wgt'] as num).toDouble(),
      maxBallast: (json['max_ballast'] as num).toDouble(),
      v1: (json['V1'] as num).toDouble(),
      w1: (json['W1'] as num).toDouble(),
      v2: (json['V2'] as num).toDouble(),
      w2: (json['W2'] as num).toDouble(),
      v3: (json['V3'] as num).toDouble(),
      w3: (json['W3'] as num).toDouble(),
      wingArea: (json['wing_area'] as num).toDouble(),
      ballastDumpTime: (json['ballast_dump_time'] as num).toDouble(),
      handicap: (json['handicap'] as num).toDouble(),
      gliderEmptyMass: (json['glider_empty_mass'] as num).toDouble(),
      pilotMass: (json['pilotMass'] as num).toDouble(),
      a: (json['a'] as num).toDouble(),
      b: (json['b'] as num).toDouble(),
      c: (json['c'] as num).toDouble(),
      minSinkSpeed: (json['minSinkSpeed'] as num).toDouble(),
      minSinkRate: (json['minSinkRate'] as num).toDouble(),
    );

Map<String, dynamic> _$GliderToJson(Glider instance) => <String, dynamic>{
      'glider': instance.glider,
      'glider_and_max_pilot_wgt': instance.gliderAndMaxPilotWgt,
      'max_ballast': instance.maxBallast,
      'V1': instance.v1,
      'W1': instance.w1,
      'V2': instance.v2,
      'W2': instance.w2,
      'V3': instance.v3,
      'W3': instance.w3,
      'wing_area': instance.wingArea,
      'ballast_dump_time': instance.ballastDumpTime,
      'handicap': instance.handicap,
      'glider_empty_mass': instance.gliderEmptyMass,
      'pilotMass': instance.pilotMass,
      'a': instance.a,
      'b': instance.b,
      'c': instance.c,
      'minSinkSpeed': instance.minSinkSpeed,
      'minSinkRate': instance.minSinkRate,
    };
