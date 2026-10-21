// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one800wxbrief.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

One800WxBrief _$One800WxBriefFromJson(Map<String, dynamic> json) =>
    One800WxBrief(
      returnStatus: json['returnStatus'] as bool?,
      returnMessage: (json['returnMessage'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      returnCodedMessage: (json['returnCodedMessage'] as List<dynamic>?)
          ?.map((e) => ReturnCodedMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      textualWeatherBriefing: json['textualWeatherBriefing'] as String?,
      simpleWeatherBriefing: json['simpleWeatherBriefing'] as String?,
      htmlweatherBriefing: json['htmlweatherBriefing'] as String?,
      ngbsummary: json['ngbsummary'] as String?,
      ngbweatherBriefing: json['ngbweatherBriefing'] as String?,
      ngbv2HtmlBriefing: json['ngbv2HtmlBriefing'] as String?,
      ngbv2PdfBriefing: json['ngbv2PdfBriefing'] as String?,
    );

Map<String, dynamic> _$One800WxBriefToJson(One800WxBrief instance) =>
    <String, dynamic>{
      'returnStatus': instance.returnStatus,
      'returnMessage': instance.returnMessage,
      'returnCodedMessage': instance.returnCodedMessage,
      'textualWeatherBriefing': instance.textualWeatherBriefing,
      'simpleWeatherBriefing': instance.simpleWeatherBriefing,
      'htmlweatherBriefing': instance.htmlweatherBriefing,
      'ngbsummary': instance.ngbsummary,
      'ngbweatherBriefing': instance.ngbweatherBriefing,
      'ngbv2HtmlBriefing': instance.ngbv2HtmlBriefing,
      'ngbv2PdfBriefing': instance.ngbv2PdfBriefing,
    };
