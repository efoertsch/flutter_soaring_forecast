import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class TurnpointRegions {
  late List<TurnpointRegion>? turnpointRegions;
  TurnpointRegions({required this.turnpointRegions});

  TurnpointRegions.fromJson(Map<String, dynamic> json) {
    if (json['turnpointregions'] != null) {
      turnpointRegions = <TurnpointRegion>[];
      json['turnpointregions'].forEach((v) {
        turnpointRegions!.add(new TurnpointRegion.fromJson(v));
      });
    }
  }
}

@JsonSerializable()
class TurnpointRegion {
  late String region;

  @JsonKey(name: 'turnpointfiles')
  late List<TurnpointFile> turnpointFiles;

  TurnpointRegion({required this.region, required this.turnpointFiles});

  TurnpointRegion.fromJson(Map<String, dynamic> json) {
    region = json['region'];
    if (json['turnpointfiles'] != null) {
      turnpointFiles = <TurnpointFile>[];
      json['turnpointfiles'].forEach((v) {
        turnpointFiles.add(new TurnpointFile.fromJson(v));
      });
    }
  }
}

@JsonSerializable()
class TurnpointFile {
  late String state;
  late String location;
  late String filename;
  late String description;
  late String date;

  TurnpointFile(
      {required this.state,
      required this.location,
      required this.filename,
      required this.description,
      required this.date});

  TurnpointFile.fromJson(Map<String, dynamic> json) {
    state = json['state'];
    location = json['location'];
    filename = json['filename'];
    description = json['description'];
    date = json['date'];
  }
}
