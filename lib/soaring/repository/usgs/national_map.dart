import 'package:json_annotation/json_annotation.dart';

part 'national_map.g.dart';

///  Generated via https://javiercbk.github.io/json_to_dart/ using output from call
///  https://nationalmap.gov/epqs/pqs.php?y=42.464&x=-71.454&output=json&units=Feet
///    flutter packages pub run build_runner build

@JsonSerializable()
class NationalMap {
  USGSElevationPointQueryService? uSGSElevationPointQueryService;

  NationalMap({this.uSGSElevationPointQueryService});

  NationalMap.fromJson(Map<String, dynamic> json) {
    uSGSElevationPointQueryService =
        json['USGS_Elevation_Point_Query_Service'] != null
            ? new USGSElevationPointQueryService.fromJson(
                json['USGS_Elevation_Point_Query_Service'])
            : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.uSGSElevationPointQueryService != null) {
      data['USGS_Elevation_Point_Query_Service'] =
          this.uSGSElevationPointQueryService!.toJson();
    }
    return data;
  }
}

@JsonSerializable()
class USGSElevationPointQueryService {
  ElevationQuery? elevationQuery;

  USGSElevationPointQueryService({this.elevationQuery});

  USGSElevationPointQueryService.fromJson(Map<String, dynamic> json) {
    elevationQuery = json['Elevation_Query'] != null
        ? new ElevationQuery.fromJson(json['Elevation_Query'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.elevationQuery != null) {
      data['Elevation_Query'] = this.elevationQuery!.toJson();
    }
    return data;
  }
}

@JsonSerializable()
class ElevationQuery {
  double? x;
  double? y;
  String? dataSource;
  double? elevation;
  String? units;

  ElevationQuery({this.x, this.y, this.dataSource, this.elevation, this.units});

  ElevationQuery.fromJson(Map<String, dynamic> json) {
    x = json['x'];
    y = json['y'];
    dataSource = json['Data_Source'];
    elevation = json['Elevation'];
    units = json['Units'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['x'] = this.x;
    data['y'] = this.y;
    data['Data_Source'] = this.dataSource;
    data['Elevation'] = this.elevation;
    data['Units'] = this.units;
    return data;
  }
}
