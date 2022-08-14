// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forecast_types.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForecastTypes _$ForecastTypesFromJson(Map<String, dynamic> json) =>
    ForecastTypes(
      forecasts: (json['forecasts'] as List<dynamic>)
          .map((e) => Forecast.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ForecastTypesToJson(ForecastTypes instance) =>
    <String, dynamic>{
      'forecasts': instance.forecasts,
    };

Forecast _$ForecastFromJson(Map<String, dynamic> json) => Forecast(
      forecastName: json['forecastName'] as String,
      forecastType:
          $enumDecodeNullable(_$ForecastTypeEnumMap, json['forecastType']),
      forecastNameDisplay: json['forecastNameDisplay'] as String,
      forecastDescription: json['forecastDescription'] as String,
      forecastCategory: $enumDecodeNullable(
          _$ForecastCategoryEnumMap, json['forecastCategory']),
    );

Map<String, dynamic> _$ForecastToJson(Forecast instance) => <String, dynamic>{
      'forecastName': instance.forecastName,
      'forecastType': _$ForecastTypeEnumMap[instance.forecastType],
      'forecastNameDisplay': instance.forecastNameDisplay,
      'forecastDescription': instance.forecastDescription,
      'forecastCategory': _$ForecastCategoryEnumMap[instance.forecastCategory],
    };

const _$ForecastTypeEnumMap = {
  ForecastType.EMPTY: 'EMPTY',
  ForecastType.FULL: 'FULL',
};

const _$ForecastCategoryEnumMap = {
  ForecastCategory.THERMAL: 'THERMAL',
  ForecastCategory.WIND: 'WIND',
  ForecastCategory.CLOUD: 'CLOUD',
  ForecastCategory.WAVE: 'WAVE',
};
