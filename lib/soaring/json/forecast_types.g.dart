// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forecast_types.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForecastTypes _$ForecastTypesFromJson(Map<String, dynamic> json) {
  return ForecastTypes(
    forecasts: (json['forecasts'] as List)
        ?.map((e) =>
            e == null ? null : Forecast.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$ForecastTypesToJson(ForecastTypes instance) =>
    <String, dynamic>{
      'forecasts': instance.forecasts,
    };

Forecast _$ForecastFromJson(Map<String, dynamic> json) {
  return Forecast(
    forecastName: json['forecastName'] as String,
    forecastType:
        _$enumDecodeNullable(_$ForecastTypeEnumMap, json['forecastType']),
    forecastNameDisplay: json['forecastNameDisplay'] as String,
    forecastDescription: json['forecastDescription'] as String,
    forecastCategory: _$enumDecodeNullable(
        _$ForecastCategoryEnumMap, json['forecastCategory']),
  );
}

Map<String, dynamic> _$ForecastToJson(Forecast instance) => <String, dynamic>{
      'forecastName': instance.forecastName,
      'forecastType': _$ForecastTypeEnumMap[instance.forecastType],
      'forecastNameDisplay': instance.forecastNameDisplay,
      'forecastDescription': instance.forecastDescription,
      'forecastCategory': _$ForecastCategoryEnumMap[instance.forecastCategory],
    };

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}

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
