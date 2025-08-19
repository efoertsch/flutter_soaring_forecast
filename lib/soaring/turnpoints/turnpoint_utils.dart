import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/cup/cup_styles.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';

enum SeeYouFormat {
  WITH_WIDTH_AND_DESCRIPTION,
  NO_WIDTH_OR_DESCRIPTION,
  NO_WIDTH_WITH_DESCRIPTION,
  WITH_USERDATA_AND_PICS,
  NOT_DEFINED
}

class TurnpointUtils {
  static const String AIRPORT_DETAILS =
      "%s %s %s\nLat: %s Long: %s\nElev: %s Dir: %s Lngth:%s Width:%s\nFreq: %s\n%s";
  static const String NON_AIRPORT_DETAILS =
      "%s  %s\n%s \nLat: %s Long: %s\nElev: %s \n%s ";
  static NumberFormat latitudeFormat = NumberFormat("0000.000");
  static NumberFormat longitudeFormat = NumberFormat("00000.000");
  static const String QUOTE = "\"";
  static const String COMMA = ",";
  static final List<CupStyle> _cupStyles = [];

  static final latitudeDegreesRegex =
      RegExp(r'^-?([1-8]?[0-9]\.{1}\d{5}$|90\.{1}0{5}$)');
  static final latitudeCupRegex =
      RegExp(r'^(9000\.000|[0-8][0-9][0-5][0-9]\.[0-9]{3})[NS]$');

  static final longitudeDegreesRegex =
      RegExp(r'^-?((([1-9]?[0-9]|1[0-7][0-9])(\.[0-9]{5})?)|180(\.0{5})?)$');
  static final longitudeCupRegex = RegExp(
      r'^(18000\.000|(([0-1][0-7])|([0][0-9]))[0-9][0-5][0-9]\.[0-9]{3})[EW]$');

  static final elevationRegex = RegExp(r'^([0-9]{1,4}(\.[0-9])?)(m|ft)$');
  static final directionRegex =
      RegExp(r'^(360|(3[0-5][0-9])|([12][0-9][0-9])|([0-9][0-9])|([0-9]))$');
  static final lengthRegex = RegExp(r'^([0-9]{1,5}((\.[0-9])?))(m|ft)$');
  static final widthRegex = RegExp(r'^([0-9]{1,3})(m|ft)$');
  static final frequencyRegex =
      RegExp(r'^1[1-3][0-9]\.(([0-9][0-9](0|5))|([0-9][0-9])|[0-9])$');
  static final landableRegex = RegExp(r'^[2-5]$');
  static final airportRegex = RegExp(r'^[25]$');

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

  static const WITH_USERDATA_AND_PICS = [
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
    "desc",
    "userdata",
    "pics"
  ];

  static String getAllColumnHeaders() {
    StringBuffer sb = StringBuffer();
    WITH_WIDTH_AND_DESCRIPTION_LABELS.forEach((element) {
      sb.write(element + COMMA);
    });
    String columnHeaders = sb.toString();
    return columnHeaders.substring(0, columnHeaders.length - 1) +
        Constants.NEW_LINE;
  }

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
          // this case we ignore userdata and pics
        case SeeYouFormat.WITH_USERDATA_AND_PICS:
          turnpoint.runwayWidth = turnpointDetail[9].toString();
          turnpoint.frequency = turnpointDetail[10].toString();
          turnpoint.description = turnpointDetail[11].toString();

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

  static bool validateLatitude(String latitude, bool isDecimalDegreesFormat) {
    return isDecimalDegreesFormat
        ? validateLatitudeInDecimalDegrees(latitude)
        : validateLatitudeInCupFormat(latitude);
  }

  // Validate latitude in decimal degrees format
  static bool validateLatitudeInDecimalDegrees(String latitude) {
    if (!latitudeDegreesRegex.hasMatch(latitude)) {
      return false;
    }
    // double check
    try {
      final decimalLatitude = double.parse(latitude);
      return (decimalLatitude >= -90 && decimalLatitude <= 90);
    } catch (e) {
      return false;
    }
  }

  // Validate latitude in decimal minutes (cup) format
  static bool validateLatitudeInCupFormat(String cupLatitude) {
    return latitudeCupRegex.hasMatch(cupLatitude);
  }

  static bool validateLongitude(String longitude, bool isDecimalDegreesFormat) {
    return isDecimalDegreesFormat
        ? validateLongitudeInDecimalDegrees(longitude)
        : validateLongitudeInCupFormat(longitude);
  }

  static double convertLatitudeToDouble(
      String longitude, bool isDecimalDegreesFormat) {
    try {
      return isDecimalDegreesFormat
          ? double.parse(longitude)
          : convertToLong(longitude);
    } catch (e) {
      return 0;
    }
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

  // Validate latitude in decimal degrees format
  static bool validateLongitudeInDecimalDegrees(String longitude) {
    if (!longitudeDegreesRegex.hasMatch(longitude)) {
      return false;
    }
    // double check
    try {
      final decimalLongitude = double.parse(longitude);
      return (decimalLongitude >= -180 && decimalLongitude <= 180);
    } catch (e) {
      return false;
    }
  }

  // Validate latitude in decimal minutes (cup) format
  static bool validateLongitudeInCupFormat(String cupLongitude) {
    return longitudeCupRegex.hasMatch(cupLongitude);
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
    if (eq(firstLineOfTurnpoints, WITH_USERDATA_AND_PICS)) {
      return SeeYouFormat.WITH_USERDATA_AND_PICS;
    }
    return SeeYouFormat.NOT_DEFINED;
  }

  /// Bit of a hack.
  /// _cupStyles must be set earlier (by bloc call loading them)
  /// before use in these util functions.
  static String getStyleFromStyleDescription(
      List<CupStyle> cupStyles, String styleDescription) {
    return cupStyles
        .firstWhere((cupStyle) => cupStyle.description == styleDescription,
            orElse: () => CupStyle(style: '0', description: "Unknown"))
        .style;
  }

  /// Bit of a hack.
  /// _cupStyles must be set earlier (by bloc call loading them)
  /// before use in these util functions.
  static String getStyleDescriptionFromStyle(
      List<CupStyle> cupStyles, String style) {
    return cupStyles
        .firstWhere((cupStyle) => cupStyle.style == style,
            orElse: () => CupStyle(style: '0', description: "Unknown"))
        .description;
  }

  static void setCupStyles(List<CupStyle> listOfCupStyles) {
    _cupStyles.clear();
    _cupStyles.addAll(listOfCupStyles);
  }

  /// Bit of a hack.
  /// _cupStyles must be set earlier (by bloc call loading them)
  /// before use in these util functions.
  static List<CupStyle> getCupStyles() {
    return _cupStyles;
  }

  // Note that whatever calls this must first call setCupStyles
  static String getStyleName(String styleNumber) {
    return getStyleDescriptionFromStyle(_cupStyles, styleNumber);
  }

  static bool isLandable(String style) {
    return landableRegex.hasMatch(style);
  }

  static bool isGrassOrGliderAirport(String style) {
    return (style == "2" || style == "4");
  }

  static bool isHardSurfaceAirport(String style) {
    return style == "5";
  }

  static bool isAirport(String? style) {
    return style != null && airportRegex.hasMatch(style);
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
    sb.write(QUOTE + turnpoint.title + QUOTE + COMMA);
    sb.write(QUOTE + turnpoint.code + QUOTE + COMMA);
    sb.write(turnpoint.country + COMMA);
    sb.write(getLatitudeInCupFormat(turnpoint.latitudeDeg) + COMMA);
    sb.write(getLongitudeInCupFormat(turnpoint.longitudeDeg) + COMMA);
    sb.write(turnpoint.elevation + COMMA);
    sb.write(turnpoint.style + COMMA);
    sb.write(turnpoint.direction + COMMA);
    sb.write(turnpoint.length + COMMA);
    sb.write(turnpoint.runwayWidth + COMMA);
    sb.write(turnpoint.frequency + COMMA);
    if (!turnpoint.description.isEmpty) {
      sb.write(QUOTE + turnpoint.description + QUOTE);
    }
    return sb.toString();
  }

  static Color getColorForTurnpointIcon(String style) {
    if (isGrassOrGliderAirport(style)) {
      return grassRunway;
    }
    if (isHardSurfaceAirport(style)) {
      return asphaltRunway;
    } else {
      return noRunway;
    }
  }

  static String getFormattedTurnpointDetails(
      Turnpoint turnpoint, bool isDecimalDegreesFormat) {
    String turnpointDetails;
    switch (turnpoint.style) {
      case "2":
      case "4":
      case "5":
        turnpointDetails = sprintf(AIRPORT_DETAILS, [
          turnpoint.title,
          turnpoint.code,
          getStyleName(turnpoint.style),
          getLatitudeInDisplayFormat(
              isDecimalDegreesFormat, turnpoint.latitudeDeg),
          getLongitudeInDisplayFormat(
              isDecimalDegreesFormat, turnpoint.longitudeDeg),
          turnpoint.elevation,
          turnpoint.direction,
          turnpoint.length,
          turnpoint.runwayWidth,
          turnpoint.frequency,
          turnpoint.description
        ]);
        break;
      default:
        turnpointDetails = sprintf(NON_AIRPORT_DETAILS, [
          turnpoint.title,
          turnpoint.code,
          getStyleName(turnpoint.style),
          getLatitudeInDisplayFormat(
              isDecimalDegreesFormat, turnpoint.latitudeDeg),
          getLongitudeInDisplayFormat(
              isDecimalDegreesFormat, turnpoint.longitudeDeg),
          turnpoint.elevation,
          turnpoint.description
        ]);
    }
    return turnpointDetails;
  }

  static String getLongitudeInDisplayFormat(
      bool isDecimalDegreesFormat, double longitudeInDegrees) {
    return isDecimalDegreesFormat
        ? longitudeInDegrees.toStringAsFixed(5)
        : getLongitudeInCupFormat(longitudeInDegrees);
  }

  static String getLatitudeInDisplayFormat(
      bool isDecimalDegreesFormat, double latitudeInDegrees) {
    return isDecimalDegreesFormat
        ? latitudeInDegrees.toStringAsFixed(5)
        : getLatitudeInCupFormat(latitudeInDegrees);
  }

  //TODO - convert string for doublE
  static double parseLatitudeValue(String value, bool isDecimalDegreesFormat) {
    return isDecimalDegreesFormat ? double.parse(value) : convertToLat(value);
  }

  static double parseLongitudeValue(String value, bool isDecimalDegreesFormat) {
    return isDecimalDegreesFormat ? double.parse(value) : convertToLong(value);
  }

  static bool elevationValid(String elevation) {
    return elevationRegex.hasMatch(elevation);
  }

  static bool runwayDirectionValid(String direction) {
    return directionRegex.hasMatch(direction);
  }

  static bool runwayLengthValid(String length) {
    return lengthRegex.hasMatch(length);
  }

  static bool runwayWidthValid(String width) {
    return widthRegex.hasMatch(width);
  }

  static bool airportFrequencyValid(String frequency) {
    return frequencyRegex.hasMatch(frequency);
  }

  static double convertMetersToFeet(double meters) {
    return meters * Constants.metersToFeet;
  }
}
