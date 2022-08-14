// To parse this JSON data, do
//
//     final forecastTypes = forecastTypesFromJson(jsonString);
/// Steps to create class and ...g.dart file
/// 1. Used assets/json/forecast_options as input to https://app.quicktype.io/
/// 2. Modified code for generator:
///    a. Added @JsonSerializable() for each class (except enums) below
///    b. Add getters as needed for convenience
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'forecast_types.g.dart';

/// 1. Gen'ed Dart code from JSON string via using https://app.quicktype.io/
/// 2. Dart code modified for generator
/// 3. Added part'forecast_types.g.dart' above
/// 4. Generated ...g.dart file running following command in terminal
///    flutter packages pub run build_runner build

ForecastTypes forecastTypesFromJson(String str) =>
    ForecastTypes.fromJson(json.decode(str));

String forecastTypesToJson(ForecastTypes data) => json.encode(data.toJson());

@JsonSerializable()
class ForecastTypes {
  List<Forecast> forecasts;

  ForecastTypes({
    required this.forecasts,
  });

  factory ForecastTypes.fromJson(Map<String, dynamic> json) => ForecastTypes(
        forecasts: List<Forecast>.from(
            json["forecasts"].map((x) => Forecast.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "forecasts": List<dynamic>.from(forecasts.map((x) => x.toJson())),
      };
}

@JsonSerializable()
class Forecast extends Equatable {
  String forecastName;
  ForecastType? forecastType;
  String forecastNameDisplay;
  String forecastDescription;
  ForecastCategory? forecastCategory;

  Forecast({
    required this.forecastName,
    this.forecastType,
    required this.forecastNameDisplay,
    required this.forecastDescription,
    required this.forecastCategory,
  });

  factory Forecast.fromJson(Map<String, dynamic> json) => Forecast(
        forecastName: json["forecast_name"],
        forecastType: forecastTypeValues.map[json["forecast_type"]],
        forecastNameDisplay: json["forecast_name_display"],
        forecastDescription: json["forecast_description"],
        forecastCategory: ForecastCategoryValues.map[json["forecast_category"]],
      );

  Map<String, dynamic> toJson() => {
        "forecast_name": forecastName,
        "forecast_type": forecastTypeValues.reverse[forecastType],
        "forecast_name_display": forecastNameDisplay,
        "forecast_description": forecastDescription,
        "forecast_category": ForecastCategoryValues.reverse[forecastCategory],
      };

  @override
  List<Object?> get props => [
        forecastName,
        forecastType,
        forecastNameDisplay,
        forecastDescription,
        forecastCategory
      ];
}

enum ForecastCategory { THERMAL, WIND, CLOUD, WAVE }

final ForecastCategoryValues = EnumValues({
  "cloud": ForecastCategory.CLOUD,
  "thermal": ForecastCategory.THERMAL,
  "wave": ForecastCategory.WAVE,
  "wind": ForecastCategory.WIND
});

enum ForecastType { EMPTY, FULL }

final forecastTypeValues =
    EnumValues({"": ForecastType.EMPTY, "full": ForecastType.FULL});

class EnumValues<T> {
  Map<String, T> map;
  Map<T, String> reverseMap = new Map();

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => new MapEntry(v, k));
    return reverseMap;
  }
}
