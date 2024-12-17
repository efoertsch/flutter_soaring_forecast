// For glider polars
enum VELOCITY_PARM {MIN_SINK_SPEED,MIN_SINK_SPEED_AT_BANK_ANGLE, V1, V2, V3 }
enum SINK_RATE_PARM { MIN_SINK,W1, W2, W3 }
enum MASS_PARM{GLIDER, PILOT, BALLAST, MAX_BALLAST}
enum VELOCITY_CONVERSION { kph2kts, kph2mph, kts2kph, mph2kph }
enum SINK_RATE_CONVERSION { mpsec2ftpmin, ftpmin2mpsec }
enum MASS_CONVERSION { kg2lbs, lbs2kg }
enum DISTANCE_CONVERSION { mt2ft, ft2mt }

enum SINK_UNITS {
  ftPerMin(display: "ft/min"),
  mPerSec(display: "m/sec");

  const SINK_UNITS({required this.display});

  final String display;
}

enum SPEED_UNITS {
  kph(display: "kph"),
  kts(display: "kts"),
  mph(display: "mph");

  const SPEED_UNITS({required this.display});

  final String display;
}

enum WEIGHT_UNITS {
  lbs(display: "lbs"),
  kg(display: "kg");

  const WEIGHT_UNITS({required this.display});

  final String display;
}

enum DISTANCE_UNITS {
  meters(display: "meters"),
  feet(display: "ft");

  const DISTANCE_UNITS({required this.display});

  final String display;
}

