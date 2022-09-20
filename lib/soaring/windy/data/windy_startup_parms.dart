class WindyStartupParms {
  late final String key;
  late final double lat;
  late final double long;
  late final int zoom;

  WindyStartupParms(
      {required this.key,
      required this.lat,
      required this.long,
      required this.zoom});

  Map toJson() => {'key': key, "lat": lat, "long": long, "zoom": zoom};
}
