// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taf.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Taf _$TafFromJson(Map<String, dynamic> json) => Taf(
      json['returnStatus'] as bool,
      (json['returnCodedMessage'] as List<dynamic>)
          .map((e) => ReturnCodedMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['plainText'] as String,
      json['spokenText'] as String,
      json['rawText'] as String,
    );

Map<String, dynamic> _$TafToJson(Taf instance) => <String, dynamic>{
      'returnStatus': instance.returnStatus,
      'returnCodedMessage': instance.returnCodedMessage,
      'plainText': instance.plainText,
      'spokenText': instance.spokenText,
      'rawText': instance.rawText,
    };
