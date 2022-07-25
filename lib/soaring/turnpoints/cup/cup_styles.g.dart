// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cup_styles.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CupStyles _$CupStylesFromJson(Map<String, dynamic> json) => CupStyles(
      styles: (json['styles'] as List<dynamic>)
          .map((e) => Style.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CupStylesToJson(CupStyles instance) => <String, dynamic>{
      'styles': instance.styles,
    };

Style _$StyleFromJson(Map<String, dynamic> json) => Style(
      style: json['style'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$StyleToJson(Style instance) => <String, dynamic>{
      'style': instance.style,
      'description': instance.description,
    };
