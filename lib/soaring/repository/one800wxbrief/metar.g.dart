// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metar.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Metar _$MetarFromJson(Map<String, dynamic> json) => Metar(
      json['returnStatus'] as bool,
      (json['returnCodedMessage'] as List<dynamic>)
          .map((e) => ReturnCodedMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['plainText'] as String,
      json['spokenText'] as String,
      json['rawText'] as String,
    );

Map<String, dynamic> _$MetarToJson(Metar instance) => <String, dynamic>{
      'returnStatus': instance.returnStatus,
      'returnCodedMessage': instance.returnCodedMessage,
      'plainText': instance.plainText,
      'spokenText': instance.spokenText,
      'rawText': instance.rawText,
    };
