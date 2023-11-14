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
      forecastName: json['forecast_name'] as String,
      forecastType:
          $enumDecodeNullable(_$ForecastTypeEnumMap, json['forecast_type']),
      forecastNameDisplay: json['forecast_name_display'] as String,
      forecastDescription: json['forecast_description'] as String,
      forecastCategory: $enumDecodeNullable(
          _$ForecastCategoryEnumMap, json['forecast_category']),
      selectable: json['selectable'] as bool?,
    );

Map<String, dynamic> _$ForecastToJson(Forecast instance) => <String, dynamic>{
      'forecast_name': instance.forecastName,
      'forecast_type': _$ForecastTypeEnumMap[instance.forecastType],
      'forecast_name_display': instance.forecastNameDisplay,
      'forecast_description': instance.forecastDescription,
      'forecast_category': _$ForecastCategoryEnumMap[instance.forecastCategory],
      'selectable': instance.selectable,
    };

const _$ForecastTypeEnumMap = {
  ForecastType.EMPTY: '',
  ForecastType.FULL: 'full',
};

const _$ForecastCategoryEnumMap = {
  ForecastCategory.CLOUD: 'cloud',
  ForecastCategory.THERMAL: 'thermal',
  ForecastCategory.WAVE: 'wave',
  ForecastCategory.WIND: 'wind',
};
