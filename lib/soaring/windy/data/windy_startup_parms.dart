import 'package:flutter_map/flutter_map.dart';

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

  Map toJson() => {
        'key': key,
        "lat": lat,
        "long": long,
        "mapLatLngBounds": [
          [
            mapLatLngBounds.southWest!.toJson(),
          ],
          [
            mapLatLngBounds.northEast!.toJson(),
          ]
        ],
        "zoom": zoom
      };
}
