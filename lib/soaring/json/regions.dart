
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'built_regions.g.dart';

///  1. To easily get fields generated used https://javiercbk.github.io/json_to_dart/ with input from soargbsc.com/rasp/current.json
/// To use the generator you need to remove any repeating group regions (e.g. Mifflin) after first (e.g. NewEngland) for generator
///  to successfully gen output (as of 10/2/19)
///  Somewhat confusingly - changed lower 'Regions' class to Region and updated List<Regions> to List<Region>, etc
///  2. Added  @JsonSerializable() annotation to each class
///  3. Added factory to each class


abstract class Regions implements Built<Regions, BuiltRegionsBuilder> {
  String initialRegion;
  List<Region> regions;
  Airspace airspace;

  Regions._();

  factory Regions([updates(BuiltRegionsBuilder b)]) = _$Regions;

  static Serializer<Regions> get serializer => _$builtRegionsSerializer;

}


class Region {
  List<String> dates;
  String name;
  List<String> printDates;
  List<Soundings> soundings;

  Region({this.dates, this.soundings, this.printDates, this.name});
  factory Region.fromJson(Map<String,dynamic> json)=>_$RegionFromJson(json);
  Map<String, dynamic> toJson() =>_$RegionToJson(this);

}


class Soundings {
  String location;
  String longitude;
  String latitude;

  Soundings({this.longitude, this.latitude, this.location});

  factory Soundings.fromJson(Map<String,dynamic>json)=>_$SoundingsFromJson(json);
  Map<String, dynamic> toJson()=>_$SoundingsToJson(this);

}


class Airspace {
  String baseUrl;
  List<String> files;

  Airspace({this.baseUrl, this.files});

  factory Airspace.fromJson(Map<String, dynamic> json) => _$AirspaceFromJson(json);
  Map<String, dynamic> toJson() => _$AirspaceToJson(this);

}
