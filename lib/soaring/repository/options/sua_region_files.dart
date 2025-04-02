import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class SUARegionFiles {
  @JsonKey(name: 'sua_regions')
  late List<SuaRegion> suaRegions;

  SUARegionFiles({required this.suaRegions});

  SUARegionFiles.fromJson(Map<String, dynamic> json) {
    if (json['sua_regions'] != null) {
      suaRegions = <SuaRegion>[];
      json['sua_regions'].forEach((v) {
        suaRegions.add(SuaRegion.fromJson(v));
      });
    }
  }
}

@JsonSerializable()
class SuaRegion {
  late String region;

  @JsonKey(name: 'sua_file_name')
  late String suaFileName;

  SuaRegion({required this.region, required this.suaFileName});

  SuaRegion.fromJson(Map<String, dynamic> json) {
    region = json['region'];
    suaFileName = json['sua_file_name'];
  }
}
