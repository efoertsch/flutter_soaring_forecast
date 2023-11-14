import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'forecast_types.g.dart';

/// Steps to create class and ...g.dart file
/// 1. Gen'ed Dart code from assets/json/forecast_options via using https://app.quicktype.io/
/// 2. Modified code for generator:
///    a. Added @JsonSerializable() for each class (except enums) below
///    b. Add getters as needed for convenience
/// 3. Added part 'forecast_types.g.dart' above
/// 4. Generated ...g.dart file running following command in terminal
///    flutter packages pub run build_runner build

// To parse this JSON data, do
//
//     final forecastTypes = forecastTypesFromJson(jsonString);

ForecastTypes forecastTypesFromJson(String str) =>
    ForecastTypes.fromJson(json.decode(str));

String forecastTypesToJson(ForecastTypes data) => json.encode(data.toJson());

@JsonSerializable()
class ForecastTypes {
  List<Forecast> forecasts;

  ForecastTypes({
    required this.forecasts,
  });

  factory ForecastTypes.fromJson(Map<String, dynamic> json) =>
      _$ForecastTypesFromJson(json);

  Map<String, dynamic> toJson() => _$ForecastTypesToJson(this);
}

@JsonSerializable()
//ignore: must_be_immutable
class Forecast extends Equatable {
  @JsonKey(name: 'forecast_name')
  String forecastName;
  @JsonKey(name: 'forecast_type')
  ForecastType? forecastType;
  @JsonKey(name: 'forecast_name_display')
  String forecastNameDisplay;
  @JsonKey(name: 'forecast_description')
  String forecastDescription;
  @JsonKey(name: 'forecast_category')
  ForecastCategory? forecastCategory;
  bool? selectable;

  Forecast({
    required this.forecastName,
    this.forecastType,
    required this.forecastNameDisplay,
    required this.forecastDescription,
    required this.forecastCategory,
    this.selectable,
  });

  factory Forecast.fromJson(Map<String, dynamic> json) =>
      _$ForecastFromJson(json);

  Map<String, dynamic> toJson() => _$ForecastToJson(this);

  @override
  List<Object?> get props => [
        forecastName,
        forecastType,
        forecastNameDisplay,
        forecastDescription,
        forecastCategory,
        selectable
      ];
}

enum ForecastCategory {
  @JsonValue("cloud")
  CLOUD,
  @JsonValue("thermal")
  THERMAL,
  @JsonValue("wave")
  WAVE,
  @JsonValue("wind")
  WIND
}

enum ForecastType {
  @JsonValue("")
  EMPTY,
  @JsonValue("full")
  FULL,
}
