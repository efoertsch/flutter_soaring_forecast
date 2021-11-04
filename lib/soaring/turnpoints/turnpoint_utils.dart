import 'package:collection/collection.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:intl/intl.dart';

enum SeeYouFormat {
  WITH_WIDTH_AND_DESCRIPTION,
  NO_WIDTH_OR_DESCRIPTION,
  NO_WIDTH_WITH_DESCRIPTION,
  NOT_DEFINED
}

class TurnpointUtils {
  static const String AIRPORT_DETAILS =
      "%s %s %s\nLat: %s Long: %s\nElev: %s Dir: %s Lngth:%s Width:%s\nFreq: %s\n%s";
  static const String NON_AIRPORT_DETAILS =
      "% s  % s\n%3 \nLat: %s Long: %s\nElev: %s \n%s ";
  static const String TURNPOINT_LAT_DECIMAL_FORMAT = "%.5f";
  static const String TURNPOINT_LONG_DECIMAL_FORMAT = "%.5f";
  static NumberFormat latitudeFormat = NumberFormat("0000.000");
  static NumberFormat longitudeFormat = NumberFormat("00000.000");
  static const String QUOTE = "\"";
  static const String COMMA = ",";

// Besides determining the input file format, also used for exporting turnpoints to a file
  static const WITH_WIDTH_AND_DESCRIPTION_LABELS = [
    "name",
    "code",
    "country",
    "lat",
    "lon",
    "elev",
    "style",
    "rwdir",
    "rwlen",
    "rwwidth",
    "freq",
    "desc"
  ];
  static const NO_WIDTH_OR_DESCRIPTION_LABELS = [
    "Title",
    "Code",
    "Country",
    "Latitude",
    "Longitude",
    "Elevation",
    "Style",
    "Direction",
    "Length",
    "Frequency"
  ];
  static const NO_WIDTH_WITH_DESCRIPTION_LABELS = [
    "Title",
    "Code",
    "Country",
    "Latitude",
    "Longitude",
    "Elevation",
    "Style",
    "Direction",
    "Length",
    "Frequency",
    "Description"
  ];

  static Turnpoint? createTurnpointFromCSVDetail(
      List<dynamic> turnpointDetail, SeeYouFormat seeYouFormat) {
    Turnpoint turnpoint = new Turnpoint();
    try {
      turnpoint.title = turnpointDetail[0];
      turnpoint.code = turnpointDetail[1].toString();
      turnpoint.country = turnpointDetail[2].toString();
      turnpoint.latitudeDeg = convertToLat(turnpointDetail[3]);
      turnpoint.longitudeDeg = convertToLong(turnpointDetail[4]);

      turnpoint.elevation = turnpointDetail[5];
      turnpoint.style = turnpointDetail[6].toString();
      turnpoint.direction = turnpointDetail[7].toString();
      turnpoint.length = turnpointDetail[8];

      ///Following depends on file format
      switch (seeYouFormat) {
        case SeeYouFormat.WITH_WIDTH_AND_DESCRIPTION:
          turnpoint.frequency = turnpointDetail[10].toString();
          turnpoint.description = turnpointDetail[11].toString();
          turnpoint.runwayWidth = turnpointDetail[9].toString();
          break;
        case SeeYouFormat.NO_WIDTH_OR_DESCRIPTION:
          turnpoint.frequency = turnpointDetail[9].toString();
          turnpoint.description = "";
          turnpoint.runwayWidth = "";
          break;
        case SeeYouFormat.NO_WIDTH_WITH_DESCRIPTION:
        default:
          turnpoint.frequency = turnpointDetail[9].toString();
          turnpoint.description = turnpointDetail[10].toString();
          turnpoint.runwayWidth = "";
          break;
      }
    } catch (e) {
      return null;
    }
    return turnpoint;
  }

  ///
  ///@param latitudeString is a field of length 9 (1 based), where 1-2 characters are degrees
  ///                       , 3-4 characters are minutes, 5 decimal point
  ///                       , 6-8 characters are decimal minutes
  ///                       and 9th character is either N or S
  ///                       eg 4225.500N
  /// @return latitude converted to decimal degrees
  /// @throws Exception
  static double convertToLat(String latitudeString) {
    if (latitudeString.length != 9 ||
        !(latitudeString.endsWith("N") || latitudeString.endsWith("S"))) {
      throw Exception();
    }
    return (double.parse(latitudeString.substring(0, 2)) +
            (double.parse(latitudeString.substring(2, 4)) / 60) +
            (double.parse(latitudeString.substring(4, 8)) / 60)) *
        (latitudeString.endsWith("N") ? 1 : -1);
  }

  ///
  /// @param longitudeString is a field of length 10 (1 based), where
  ///                        1-3 characters are degrees
  ///                        4-5 characters are minutes,
  ///                        6 decimal point
  ///                        7-9 characters are decimal minutes
  ///                        10th character is either E or W.
  ///                        eg 07147.470W
  /// @return longitude converted to decimal degrees
  /// @throws Exception
  static double convertToLong(String longitudeString) {
    if (longitudeString.length != 10 ||
        !(longitudeString.endsWith("E") || longitudeString.endsWith("W"))) {
      throw new Exception();
    }
    return (double.parse(longitudeString.substring(0, 3)) +
            (double.parse(longitudeString.substring(3, 5)) / 60.0) +
            (double.parse(longitudeString.substring(5, 9)) / 60.0)) *
        (longitudeString.endsWith("E") ? 1 : -1);
  }

  static SeeYouFormat determineTurnpointFileFormat(List firstLineOfTurnpoints) {
    Function eq = const ListEquality().equals;
    if (eq(firstLineOfTurnpoints, WITH_WIDTH_AND_DESCRIPTION_LABELS)) {
      return SeeYouFormat.WITH_WIDTH_AND_DESCRIPTION;
    }
    if (eq(firstLineOfTurnpoints, NO_WIDTH_OR_DESCRIPTION_LABELS)) {
      return SeeYouFormat.NO_WIDTH_OR_DESCRIPTION;
    }
    if (eq(firstLineOfTurnpoints, NO_WIDTH_WITH_DESCRIPTION_LABELS)) {
      return SeeYouFormat.NO_WIDTH_WITH_DESCRIPTION;
    }
    return SeeYouFormat.NOT_DEFINED;
  }

  static String getStyleName(String style) {
    switch (style) {
      case "0":
        return "Unknown";
      case "1":
        return "Waypoint";
      case "2":
        return "Airfield with grass surface runway";
      case "3":
        return "Outlanding";
      case "4":
        return "Gliding airfield";
      case "5":
        return "Airfield with solid surface runway";
      case "6":
        return "Mountain Pass";
      case "7":
        return "Mountain Top";
      case "8":
        return "Transmitter Mast";
      case "9":
        return "VOR";
      case "10":
        return "NDB";
      case "11":
        return "Cooling Tower";
      case "12":
        return "Dam";
      case "13":
        return "Tunnel";
      case "14":
        return "Bridge";
      case "15":
        return "Power Plant";
      case "16":
        return "Castle";
      case "17":
        return "Intersection";
      default:
        return "Unknown";
    }
  }

  static bool isLandable(String style) {
    return style != null && style.indexOf("[2345]") > 0;
  }

  static bool isGrassOrGliderAirport(String style) {
    return (style == "2" || style == "4");
  }

  static bool isHardSurfaceAirport(String style) {
    return style == "5";
  }

  static bool isAirport(String? style) {
    return style != null && style.indexOf("[245]") > 0;
  }

  static String getLatitudeInCupFormat(double lat) {
    double latitude = lat.abs();
    int degrees = latitude.toInt();
    // This convoluted expression is needed for a couple cases where conversion of
    // cup string -> float -> cup string format was off by .001
    double minutes =
        double.parse(longitudeFormat.format((latitude - degrees) * 60));
    return latitudeFormat.format((degrees * 100 + minutes).abs()) +
        (lat >= 0 ? 'N' : 'S');
  }

  static String getLongitudeInCupFormat(double lng) {
    double longitude = lng.abs();
    int degrees = longitude.toInt();
    // This convoluted expression is needed for a couple cases where conversion of
    // cup string -> float -> cup string format was off by .001
    double minutes =
        double.parse(longitudeFormat.format((longitude - degrees) * 60));
    return longitudeFormat.format((degrees * 100) + minutes) +
        (lng >= 0 ? 'E' : 'W');
  }

  static String getCupFormattedRecord(Turnpoint turnpoint) {
    StringBuffer sb = new StringBuffer();
    sb.write({QUOTE, turnpoint.title, QUOTE, COMMA});
    sb.write({QUOTE, turnpoint.code, QUOTE, COMMA});
    sb.write({turnpoint.country, COMMA});
    sb.write({getLatitudeInCupFormat(turnpoint.latitudeDeg), COMMA});
    sb.write({getLongitudeInCupFormat(turnpoint.longitudeDeg), COMMA});
    sb.write({turnpoint.elevation, COMMA});
    sb.write({turnpoint.style, COMMA});
    sb.write({turnpoint.direction, COMMA});
    sb.write({turnpoint.length, COMMA});
    sb.write({turnpoint.runwayWidth, COMMA});
    sb.write({turnpoint.frequency, COMMA});
    if (!turnpoint.description.isEmpty) {
      sb.write({QUOTE, turnpoint.description, QUOTE});
    }
    return sb.toString();
  }
}
