import 'package:google_maps_flutter/google_maps_flutter.dart';

class ViewBounds {
  late final LatLngBounds latLngBounds;

  ViewBounds(this.latLngBounds);

  factory ViewBounds.fromJson(Map<String, dynamic> json) {
    var swLat = json['swLat'];
    var swLng = json['swLng'];
    var neLat = json['neLat'];
    var neLng = json['neLng'];
    var viewBounds = ViewBounds(LatLngBounds(
        southwest: LatLng(swLat, swLng), northeast: LatLng(neLat, neLng)));
    return viewBounds;
  }

  Map<String, dynamic> toJson() => {
        'swLat': latLngBounds.southwest!.latitude,
        'swLng': latLngBounds.southwest!.longitude,
        'neLat': latLngBounds.northeast!.latitude,
        'neLng': latLngBounds.northeast!.longitude,
      };
}
