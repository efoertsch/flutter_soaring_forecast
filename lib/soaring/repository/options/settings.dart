import 'dart:convert';

// Dart code created using https://app.quicktype.io/ with some modification for null-safety
// To parse this JSON data, do
//
//     final settings = settingsFromJson(jsonString);

List<Settings> settingsFromJson(String str) =>
    List<Settings>.from(json.decode(str).map((x) => Settings.fromJson(x)));

String settingsToJson(List<Settings> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Settings {
  Settings({
    required this.title,
    this.options,
  });

  final String title;
  final List<Option>? options;

  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
        title: json["title"] == null ? null : json["title"],
        options: json["options"] == null
            ? null
            : List<Option>.from(json["options"].map((x) => Option.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "title": title == null ? null : title,
        "options": options == null
            ? null
            : List<dynamic>.from(options!.map((x) => x.toJson())),
      };
}

class Option {
  Option({
    required this.key,
    required this.title,
    this.description,
    required this.optionDefault,
    this.dataType,
    required this.possibleValues,
  });

  final String key;
  final String title;
  final String? description;
  final dynamic optionDefault;
  dynamic savedValue;
  final String? dataType;
  final List<dynamic> possibleValues;

  factory Option.fromJson(Map<String, dynamic> json) => Option(
        key: json["key"] == null ? null : json["key"],
        title: json["title"] == null ? null : json["title"],
        description: json["description"] == null ? null : json["description"],
        optionDefault: json["default"] == null ? null : json["default"],
        dataType: json["data_type"] == null ? "bool" : json["data_type"],
        possibleValues: json["possible_values"] == null ? null: json["possible_values"],
      );

  Map<String, dynamic> toJson() => {
        "key": key,
        "title": title,
        "description": description == null ? null : description,
        "default": optionDefault,
        "dataType": dataType,
        "possible_values": possibleValues,
      };
}
