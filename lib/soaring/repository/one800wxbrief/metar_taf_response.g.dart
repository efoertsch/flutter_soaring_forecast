// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metar_taf_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetarTafResponse _$MetarTafResponseFromJson(Map<String, dynamic> json) =>
    MetarTafResponse(
      returnStatus: json['returnStatus'] as bool?,
      returnCodedMessage: (json['returnCodedMessage'] as List<dynamic>?)
          ?.map((e) => ReturnCodedMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      plainText: json['plainText'] as String?,
      spokenText: json['spokenText'] as String?,
      rawText: json['rawText'] as String?,
    );

Map<String, dynamic> _$MetarTafResponseToJson(MetarTafResponse instance) =>
    <String, dynamic>{
      'returnStatus': instance.returnStatus,
      'returnCodedMessage': instance.returnCodedMessage,
      'plainText': instance.plainText,
      'spokenText': instance.spokenText,
      'rawText': instance.rawText,
    };
