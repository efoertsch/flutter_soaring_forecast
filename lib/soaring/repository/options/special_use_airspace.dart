import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

// used https://jsontodart.com to generate JSON
// data from https://soargbsc.com/soaringforecast/sterling7_sua.geojson but deleted all but 1 feather and most of
// lat/longs to that json to dart converter would work
// Not that toJson likely will never be used.
@JsonSerializable()
class SUA {
  String? type;
  String? name;
  Crs? crs;
  List<Features>? features;

  SUA({this.type, this.name, this.crs, this.features});

  SUA.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    name = json['name'];
    crs = json['crs'] != null ? new Crs.fromJson(json['crs']) : null;
    if (json['features'] != null) {
      features = <Features>[];
      json['features'].forEach((v) {
        features!.add(new Features.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['name'] = this.name;
    if (this.crs != null) {
      data['crs'] = this.crs!.toJson();
    }
    if (this.features != null) {
      data['features'] = this.features!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

@JsonSerializable()
class Crs {
  late String? type;
  late Properties? properties;

  Crs({this.type, this.properties});

  Crs.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    properties = json['properties'] != null
        ? new Properties.fromJson(json['properties'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    if (this.properties != null) {
      data['properties'] = this.properties!.toJson();
    }
    return data;
  }
}

@JsonSerializable()
class Features {
  String? type;
  Properties? properties;
  Geometry? geometry;

  Features({this.type, this.properties, this.geometry});

  Features.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    properties = json['properties'] != null
        ? new Properties.fromJson(json['properties'])
        : null;
    geometry = json['geometry'] != null
        ? new Geometry.fromJson(json['geometry'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    if (this.properties != null) {
      data['properties'] = this.properties!.toJson();
    }
    if (this.geometry != null) {
      // data['geometry'] = this.geometry!.toJson();
    }
    return data;
  }
}

// As properties used twice in SUA file but with different parents combined
// attributes into one class
@JsonSerializable()
class Properties {
  String? name;
  String? type;
  String? cLASS; // can't rename to class
  String? title;
  String? tops;
  String? base;

  Properties(
      {this.name, this.type, this.cLASS, this.title, this.tops, this.base});

  Properties.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    type = json['TYPE'];
    cLASS = json['CLASS'];
    title = json['TITLE'];
    tops = json['TOPS'];
    base = json['BASE'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['TYPE'] = type;
    data['CLASS'] = cLASS;
    data['TITLE'] = title;
    data['TOPS'] = tops;
    data['BASE'] = base;
    return data;
  }
}

@JsonSerializable()
class Geometry {
  String? type;
  List<LatLng>? coordinates;

  Geometry({this.type, this.coordinates});

  Geometry.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    if (json['coordinates'] != null) {
      coordinates = <LatLng>[];
      json['coordinates'].forEach((v) {
        coordinates!.add(LatLng(v[0], v[1]));
      });
    }
  }
}

@JsonSerializable()
class Coordinates {
  Coordinates(lat, long);

  Coordinates.fromJson(Map<String, dynamic> json) {}

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    return data;
  }
}
