library constants;

import 'package:flutter/material.dart';

//-------- Non translatable values --------------------------------------------
/// Hold any system wide constants
// if you leave off www. below, the POST to get point forecast returns a 301
const String BASE_URL = 'https://www.soargbsc.net/';
const String RASP_BASE_URL = BASE_URL + 'rasp/';
const String RASP_OPTIONS_BASE_URL = 'https://soargbsc.com/soaringforecast/';
const String AIRPORT_URL = 'http://ourairports.com/data/airports.csv';

const double metersToFeet = 3.28084;
const String ft = "ft";
const String NEW_LINE = '\n';

enum ImageTypes { body, head, side, foot }

const String APP_DATABASE = 'app_database.db'; // Floor database name

enum TurnpointEditReturn { noChange, tpAddedUpdated, tpDeleted }

class PreferenceOption {
  final String key;
  final String displayText;
  bool selected;
  PreferenceOption(
      {required this.key, required this.displayText, this.selected = false});
}

// Key here is used to store and retrieve preferences so don't change
const String soundingsDisplayOption = "SoundingsDisplayOption";
const String suaDisplayOption = "SuaDisplayOption";
const String turnpointsDisplayOption = "TurnpointsDisplayOption";

// Consider this a const List, but only selected value should be changeable during program execution
final List<PreferenceOption> raspDisplayOptions = [
  PreferenceOption(
      key: soundingsDisplayOption,
      displayText: RaspDisplayOptionsMenu.soundings),
  PreferenceOption(
      key: suaDisplayOption, displayText: RaspDisplayOptionsMenu.sua),
  PreferenceOption(
      key: turnpointsDisplayOption,
      displayText: RaspDisplayOptionsMenu.turnpoints)
];

enum SUAColor {
  //: Color(0x0000FF).withOpacity(0.5)

  classB(suaClassTitle: "CLASS B", airspaceColor: Color(0x0000FF80)),
  classC(suaClassTitle: "CLASS C", airspaceColor: Color(0xFF00FF80)),
  classD(suaClassTitle: "CLASS D", airspaceColor: Color(0x0000FF80)),
  classE(suaClassTitle: "CLASS C", airspaceColor: Color(0xFF00FF80)),
  classMATZ(suaClassTitle: "MATZ", airspaceColor: Color(0xFF0000F80)),
  classDanger(suaClassTitle: "DANGER", airspaceColor: Color(0xFF000080)),
  classProhibited(
      suaClassTitle: "PROHIBITED", airspaceColor: Color(0xFF0000F80));

  const SUAColor({required this.suaClassTitle, required this.airspaceColor});
  final String suaClassTitle;
  final Color airspaceColor;
}

//------------- Translatable values --------------------------------------------
class RaspMenu {
  static const String selectTask = 'SELECT TASK';
  static const String clearTask = 'Clear Task';
  static const String displayOptions = 'DisplayOptions';
  static const String mapBackground = 'Map Background';
  static const String orderForecasts = 'Order Forecasts';
  static const String opacity = 'Opacity';
  static const String selectRegion = 'Select Region';
}

class RaspDisplayOptionsMenu {
  static const String soundings = 'Soundings';
  static const String sua = 'Special Use Airspace';
  static const String turnpoints = 'Turnpoints';
}

class MapBackgroundMenu {
  static const String terrain = 'Terrain';
  static const String satellite = 'Satellite';
  static const String roadmap = 'Roadmap';
  static const String hybrid = 'Hybrid';
}

class TurnpointMenu {
  static const String searchTurnpoints = "Search";
  static const String importTurnpoints = 'Import Turnpoints';
  static const String addTurnpoint = 'Add Turnpoint';
  static const String exportTurnpoints = 'Export Turnpoints';
  static const String emailTurnpoints = 'Email Turnpoints';
  static const String clearTurnpointDatabase = 'Clear Turnpoint Database';
  static const String customImport = 'Custom Import';
}

class TurnpointEditMenu {
  static const String save = "SAVE";
  static const String reset = "Reset";
  static const String toggleLatLongFormat = "Toggle lat/lng format";
  static const String airNav = "AIRNAV";
  static const String dragMarker = "Drag Marker";
  static const String deleteTurnpoint = "Delete Turnpoint";
  static const String exportTurnpoint = "Export Turnpoint";
}

class TurnpointEditText {
  static const String viewTurnpoint = "View Turnpoint";
  static const String editTurnpoint = "Edit Turnppint";
  static const String waypointName = 'Waypoint Name';
  static const String waypointCode = 'Waypoint Code';
  static const String countryCode = 'Country Code';
  static const String countryCodeDefault = 'US';
  static const String latitudeDecimalDegrees = 'Latitude (-)dd.ddddd';
  static const String latitudeDecimalMinutes = 'Latitude DDMM.mmm(N|S)';
  static const String longitudeDecimalDegrees = 'Longitude (-)ddd.ddddd';
  static const String longitudeDecimalMinutes = 'Longitude DDDMM.mmm(W|E)';
  static const String elevation = 'Elevation ending in ft or m';
  static const String runwayDirection = 'Runway direction - 3 digit number';
  static const String runwayLength = 'Runway length - ending in ft or m';
  static const String runwayWidth = 'Runway width - ending in ft or m';
  static const String runwayWidthHint = 'e.g. 70ft';
  static const String airportFrequency = 'Airport Frequency nnn.nn(0|5)';
  static const String description = 'Description';
  static const String turnpointType = "Turnpoint Type";
  static const String screenTitle = "Turnpoint";
  static const String enterWaypointTitle = "Please enter waypoint title";
  static const String turnpointCodeRequired = 'A turnpoint code is required';
  static const String countryCodeRequired =
      'Country(probably \'US\') is required';
  static const String latitudeRequired = "Latitude is required";
  static const String latitudeInvalid = "Invalid latitude format";
  static const String longitudeRequired = "Longitude is required";
  static const String longitudeInvalid = "Invalid longitude format";
  static const String elevationRequired = "Elevation is required";
  static const String elevationInvalid = "Invalid elevation";
  static const String selectTurnpointType = 'Select turnpoint type';
  static const String runwayDirectionRequired = "Runway direction required";
  static const String invalidRunwayDirection = "Invalid runway direction value";
  static const String runwayLengthRequired =
      "Enter runway/landable area length";
  static const String invalidRunwayLength =
      "Invalid runway/landable area value";
  static const String invalidRunwayWidth = "Invalid runway/landable area width";
  static const String invalidAirportFrequency = "Invalid airport frequency";
  static const String correctDataErrors = "Correct data errors in turnpoint.";
  static const String turnpointInEditMode = "Turnpoint in edit mode.";
  static const String turnpointInReadOnlyMode = "Turnpoint in read only mode.";
  static const String reset = "Reset";
  static const String saveLocation = "Save Location";
  static String close = "Close";
}

// Turnpoint icon colors for type of runway
const Color grassRunway = Color(0xFF3CB043);
const Color asphaltRunway = Colors.black;
const Color noRunway = Color(0xFFEE4926);
//---------------------------------------------------------------------------
const textStyleBoldBlackFontSize20 =
    TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20);

const textStyleBlackFontSize20 = TextStyle(color: Colors.black, fontSize: 20);

const textStyleBoldBlackFontSize18 =
    TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18);

const textStyleBoldBlackFontSize16 =
    TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16);

const textStyleBlackFontSize16 = TextStyle(color: Colors.black, fontSize: 16);

const textStyleBoldBlackFontSize14 =
    TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14);

const textStyleBlackFontSize14 = TextStyle(color: Colors.black, fontSize: 14);

const textStyleBoldBlack87FontSize15 =
    TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15);

const textStyleBlack87FontSize15 =
    TextStyle(color: Colors.black87, fontSize: 15);

const textStyleBoldBlack87FontSize14 =
    TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14);

const textStyleBlack87FontSize14 =
    TextStyle(color: Colors.black87, fontSize: 14);

const textStyleWhiteFontSize12 = TextStyle(color: Colors.white, fontSize: 12);
const textStyleBlackFontSize12 = TextStyle(color: Colors.black, fontSize: 12);
