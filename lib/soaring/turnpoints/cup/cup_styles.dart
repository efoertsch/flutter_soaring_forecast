import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'cup_styles.g.dart';

/// 1. Gen'ed Dart code from JSON string via using https://app.quicktype.io/
/// 2. Dart code modified for generator :
///    Added @JsonSerializable()
/// 3. Added part 'cup_styles.g.dart'; above
/// 4. Generated ...g.dart file running following command in terminal
///    flutter packages pub run build_runner build

CupStyles cupStylesFromJson(String str) => CupStyles.fromJson(json.decode(str));

String cupStylesToJson(CupStyles data) => json.encode(data.toJson());

@JsonSerializable()
class CupStyles {
  final List<Style> styles;
  CupStyles({
    required this.styles,
  });

  factory CupStyles.fromJson(Map<String, dynamic> json) => CupStyles(
        styles: List<Style>.from(json["styles"].map((x) => Style.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "styles": List<dynamic>.from(styles.map((x) => x.toJson())),
      };
}

@JsonSerializable()
class Style {
  final String style;
  final String description;

  Style({
    required this.style,
    required this.description,
  });

  factory Style.fromJson(Map<String, dynamic> json) => Style(
        style: json["style"],
        description: json["description"],
      );

  Map<String, dynamic> toJson() => {
        "style": style,
        "description": description,
      };
}
