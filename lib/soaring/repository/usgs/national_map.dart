import 'package:json_annotation/json_annotation.dart';

part 'national_map.g.dart';

///  Generated via https://javiercbk.github.io/json_to_dart/ using output from call
///  https://nationalmap.gov/epqs/pqs.php?y=42.464&x=-71.454&output=json&units=Feet
///    flutter packages pub run build_runner build

@JsonSerializable()
class NationalMap {
  Location? location;
  int? locationId;
  double? value;
  int? rasterId;
  int? resolution;

  NationalMap(
      {this.location,
        this.locationId,
        this.value,
        this.rasterId,
        this.resolution});

  NationalMap.fromJson(Map<String, dynamic> json) {
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    locationId = json['locationId'];
    value = json['value'];
    rasterId = json['rasterId'];
    resolution = json['resolution'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['locationId'] = this.locationId;
    data['value'] = this.value;
    data['rasterId'] = this.rasterId;
    data['resolution'] = this.resolution;
    return data;
  }
}

@JsonSerializable()
class Location {
  double? x;
  double? y;
  SpatialReference? spatialReference;

  Location({this.x, this.y, this.spatialReference});

  Location.fromJson(Map<String, dynamic> json) {
    x = json['x'];
    y = json['y'];
    spatialReference = json['spatialReference'] != null
        ? new SpatialReference.fromJson(json['spatialReference'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['x'] = this.x;
    data['y'] = this.y;
    if (this.spatialReference != null) {
      data['spatialReference'] = this.spatialReference!.toJson();
    }
    return data;
  }
}

@JsonSerializable()
class SpatialReference {
  int? wkid;
  int? latestWkid;

  SpatialReference({this.wkid, this.latestWkid});

  SpatialReference.fromJson(Map<String, dynamic> json) {
    wkid = json['wkid'];
    latestWkid = json['latestWkid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['wkid'] = this.wkid;
    data['latestWkid'] = this.latestWkid;
    return data;
  }
}
