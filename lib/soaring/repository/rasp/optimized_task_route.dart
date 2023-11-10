
import 'package:json_annotation/json_annotation.dart';

part 'optimized_task_route.g.dart';

///  Generated via https://javiercbk.github.io/json_to_dart/ fron soargbsc.com/rasp/current.json

@JsonSerializable()
class OptimizedTaskRoute {
  String? error;
  String? summary;
  List<RoutePoints>? routePoints;

  OptimizedTaskRoute({this.error, this.summary, this.routePoints});

  OptimizedTaskRoute.fromJson(Map<String, dynamic> json) {
    error = json['error'];
    summary = json['summary'];
    if (json['routePoints'] != null) {
      routePoints = <RoutePoints>[];
      json['routePoints'].forEach((v) {
        routePoints!.add(new RoutePoints.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['error'] = this.error;
    data['summary'] = this.summary;
    if (this.routePoints != null) {
      data['routePoints'] = this.routePoints!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

@JsonSerializable()
class RoutePoints {
  String? lat;
  String? lon;
  String? leg;
  String? segment;
  String? xPos;
  String? yPos;
  String? distance;
  String? time;
  String? length;
  String? climbRate;
  String? thermalStrength;
  String? tailWindMps;
  String? grndSpeed;
  String? thermal;
  String? seconds;

  RoutePoints(
      {this.lat,
        this.lon,
        this.leg,
        this.segment,
        this.xPos,
        this.yPos,
        this.distance,
        this.time,
        this.length,
        this.climbRate,
        this.thermalStrength,
        this.tailWindMps,
        this.grndSpeed,
        this.thermal,
        this.seconds});

  RoutePoints.fromJson(Map<String, dynamic> json) {
    lat = json['Lat'];
    lon = json['Lon'];
    leg = json['Leg'];
    segment = json['Segment'];
    xPos = json['XPos'];
    yPos = json['YPos'];
    distance = json['Distance'];
    time = json['Time'];
    length = json['Length'];
    climbRate = json['ClimbRate'];
    thermalStrength = json['Thermal Strength'];
    tailWindMps = json['TailWind(mps)'];
    grndSpeed = json['Grnd Speed'];
    thermal = json['Thermal%'];
    seconds = json['Seconds'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Lat'] = this.lat;
    data['Lon'] = this.lon;
    data['Leg'] = this.leg;
    data['Segment'] = this.segment;
    data['XPos'] = this.xPos;
    data['YPos'] = this.yPos;
    data['Distance'] = this.distance;
    data['Time'] = this.time;
    data['Length'] = this.length;
    data['ClimbRate'] = this.climbRate;
    data['Thermal Strength'] = this.thermalStrength;
    data['TailWind(mps)'] = this.tailWindMps;
    data['Grnd Speed'] = this.grndSpeed;
    data['Thermal%'] = this.thermal;
    data['Seconds'] = this.seconds;
    return data;
  }
}

