// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forecast_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForecastModels _$ForecastModelsFromJson(Map<String, dynamic> json) =>
    ForecastModels(
      models: (json['models'] as List<dynamic>)
          .map((e) => Model.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ForecastModelsToJson(ForecastModels instance) =>
    <String, dynamic>{
      'models': instance.models,
    };

Model _$ModelFromJson(Map<String, dynamic> json) => Model(
      center: (json['center'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      times: (json['times'] as List<dynamic>).map((e) => e as String).toList(),
      name: json['name'] as String,
      corners: (json['corners'] as List<dynamic>)
          .map((e) =>
              (e as List<dynamic>).map((e) => (e as num).toDouble()).toList())
          .toList(),
    );

Map<String, dynamic> _$ModelToJson(Model instance) => <String, dynamic>{
      'center': instance.center,
      'times': instance.times,
      'name': instance.name,
      'corners': instance.corners,
    };
