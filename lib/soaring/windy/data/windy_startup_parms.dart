import 'package:google_maps_flutter/google_maps_flutter.dart';

class WindyStartupParms {
  late final String key;
  late final double lat;
  late final double long;
  late final int zoom;
  late final LatLngBounds mapLatLngBounds;

  WindyStartupParms(
      {required this.key,
      required this.lat,
      required this.long,
      required this.mapLatLngBounds,
      required this.zoom});

  // note  that bounds.southWest.toJson reverse lat/lng to lng/lat giving something like
  //  [{"coordinates":[-73.6473083,41.2665329]}] which screws up leaflet
  // so create json as [lat,lng]
  Map toJson() => {
        'key': key,
        "lat": lat,
        "long": long,
        "mapLatLngBounds": [
          [
            toLatLongJson(mapLatLngBounds.southwest),
          ],
          [
            toLatLongJson(mapLatLngBounds.northeast),
          ]
        ],
        "zoom": zoom
      };

  Map<String, dynamic> toLatLongJson(LatLng latLng) => {
        'coordinates': [latLng.latitude, latLng.longitude]
      };
}
