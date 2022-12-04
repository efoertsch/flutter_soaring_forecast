import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';

class ViewBounds {
  late final LatLngBounds latLngBounds;

  ViewBounds(this.latLngBounds);

  factory ViewBounds.fromJson(Map<String, dynamic> json) {
    var swLat = json['swLat'];
    var swLng = json['swLng'];
    var neLat = json['neLat'];
    var neLng = json['neLng'];
    var viewBounds =
        ViewBounds(LatLngBounds(LatLng(swLat, swLng), LatLng(neLat, neLng)));
    return viewBounds;
  }

  Map<String, dynamic> toJson() => {
        'swLat': latLngBounds.southWest!.latitude,
        'swLng': latLngBounds.southWest!.longitude,
        'neLat': latLngBounds.northEast!.latitude,
        'neLng': latLngBounds.northEast!.longitude,
      };
}
