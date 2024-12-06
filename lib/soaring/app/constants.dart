library constants;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

//-------- Non translatable values --------------------------------------------
/// Hold any system wide constants
// if you leave off www. below, the POST to get point forecast returns a 301
// If you modify the URLS you need to re-gen the API calls via:
//      dart  run build_runner build  --delete-conflicting-outputs
const String BASE_URL = 'https://www.soargbsc.net/';
const String RASP_BASE_URL = BASE_URL + 'rasp/';
//const String RASP_BASE_URL ='http://192.168.1.7/';
const String RASP_OPTIONS_BASE_URL = 'https://soargbsc.com/soaringforecast/';
const String AIRPORT_URL = 'http://ourairports.com/data/airports.csv';
const String GEOS_GIF =
    "https://cdn.star.nesdis.noaa.gov/GOES16/ABI/GIFS/GOES16-NE-GEOCOLOR-600x600.gif";
const String GEOS_CURRENT =
    "https://cdn.star.nesdis.noaa.gov/GOES16/ABI/SECTOR/ne/GEOCOLOR/2400x2400.jpg";

//const String WXBRIEF_URL = "https://ffspelabs.leidos.com/Website2/rest/";
const String WXBRIEF_URL = "https://lmfsweb.afss.com/Website/rest/";
const String FEEDBACK_EMAIL_ADDRESS = 'ericfoertsch@gmail.com';
const String PRIVACY_POLICY_URL = 'https://soaringforecast.org/privacy-policy/';

const double metersToFeet = 3.28084;
const String ft = "ft";
const String NEW_LINE = '\n';
enum DisplayUnits  {Metric, Imperial_kts, Imperial_mph}
const String nauticalMiles = "nm";
const String statueMiles = "sm";
const String kilometers = "km";

final LatLng NewEnglandMapCenter = LatLng(43.1394043, -72.0759888);
final LatLngBounds NewEnglandMapLatLngBounds = LatLngBounds(
    LatLng(41.2665329, -73.6473083), LatLng(45.0120811, -70.5046997));

enum ImageTypes { body, head, side, foot }

const String APP_DATABASE = 'app_database.db'; // Floor database name

enum TurnpointEditReturn { noChange, tpAddedUpdated, tpDeleted }

enum ForecastCategoryEnum { thermal, wave, wind }


// Order must be most current, (arguably) 'best' model for the day
enum ModelsEnum {hrrr, rap, nam, gfs }
enum ForecastDateChange{previous, next}

final Widget waveIcon = SvgPicture.asset('assets/svg/wave.svg');
final Widget windIcon = SvgPicture.asset('assets/svg/wind.svg');
final Widget thermalIcon = SvgPicture.asset('assets/svg/thermal.svg');
final Widget cloudIcon = SvgPicture.asset('assets/svg/cloud.svg');

Widget getForecastIcon(String forecastCategory) {
  if (forecastCategory == ForecastCategory.THERMAL.toString()) {
    return thermalIcon;
  }
  if (forecastCategory == ForecastCategory.WIND.toString()) {
    return windIcon;
  }
  if (forecastCategory == ForecastCategory.WAVE.toString()) {
    return waveIcon;
  }
  if (forecastCategory == ForecastCategory.CLOUD.toString()) {
    return cloudIcon;
  }
  return Icon(Icons.help);
}

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
final List<PreferenceOption> RaspDisplayOptions = [
  PreferenceOption(
      key: soundingsDisplayOption,
      displayText: RaspDisplayOptionsMenu.soundings ,
      selected: true),
  PreferenceOption(
      key: suaDisplayOption, displayText: RaspDisplayOptionsMenu.sua,
      selected:true),
  PreferenceOption(
      key: turnpointsDisplayOption,
      displayText: RaspDisplayOptionsMenu.turnpoints)
];

enum SUAColor {
  //: Color(0x0000FF).withOpacity(0.5)

  classB(
      suaClassType: "CLASS B",
      airspaceColor: Color(0x400000FF),
      dashedLine: false),
  classC(
      suaClassType: "CLASS C",
      airspaceColor: Color(0x40FF00FF),
      dashedLine: false),
  classD(
      suaClassType: "CLASS D",
      airspaceColor: Color(0x400000FF),
      dashedLine: true),
  classE(
      suaClassType: "CLASS C",
      airspaceColor: Color(0x40FF00FF),
      dashedLine: true),
  classMATZ(
      suaClassType: "MATZ",
      airspaceColor: Color(0x40FF0000),
      dashedLine: false),
  classDanger(
      suaClassType: "DANGER",
      airspaceColor: Color(0x40FF0000),
      dashedLine: false),
  classProhibited(
      suaClassType: "PROHIBITED",
      airspaceColor: Color(0x800000FF),
      dashedLine: false),
  classUnKnown(
      suaClassType: "UNKNOWN",
      airspaceColor: Color(0x40FF0000),
      dashedLine: false);

  const SUAColor(
      {required this.suaClassType,
      required this.airspaceColor,
      required this.dashedLine});

  final String suaClassType;
  final Color airspaceColor;
  final bool dashedLine;
}

enum WxBriefBriefingRequest {
  AREA_REQUEST,
  NOTAMS_REQUEST, //Basically route request but focus on NOTAMS
  ROUTE_REQUEST;
}

enum WxBriefTypeOfBrief {
  STANDARD(option: "Standard"),
  ABBREVIATED(option: "Abbreviated"),
  NOTAMS(option: "NOTAMS"), // for NOTAMS of interest to glider pilots
  OUTLOOK(option: "Outlook");

  const WxBriefTypeOfBrief({required this.option});

  final String option;
}

enum WxBriefFormat {
  NGBV2(option: "Online(PDF)"),
  EMAIL(option: "EMail");

  const WxBriefFormat({required this.option});

  final String option;

  String getOption() {
    return option;
  }
}

// TODO Consolidate all classes into one. It got a bit out of control...
//------------- Translatable values --------------------------------------------
class StandardLiterals {
  static const YES = "Yes";
  static const NO = "No";
  static const CANCEL = "Cancel";
  static const SUBMIT = "Submit";
  static const OK = "OK";
  static const HURRAH = "Hurrah!";
  static const UH_OH = "Uh-Oh!";
  static const UNDEFINED_STATE = 'Hmmm. Undefined state.';
  static const CONTINUE = "Continue";
  static const CLOSE = "Close";
  static const REFRESH = "Refresh";
  static const UNDO = "Undo";
  static const REMOVED = "Removed";
  static const UNSAVED_CHANGES = "Unsaved Changes!";
  static const CHANGES_WILL_BE_LOST = "Changes will be lost. Continue?";
  static const String BEGINNER_MODE = "Beginner Mode";
  static const String EXPERT_MODE = "Expert Mode";
  static const String PAUSE_LABEL = "Pause";
  static const String LOOP_LABEL = "Loop";

}

class RaspMenu {
  static const String selectTask = 'SELECT TASK';
  static const String clearTask = 'Clear Task';
  static const String displayOptions = 'DisplayOptions';
  static const String mapBackground = 'Map Background';
  static const String reorderForecasts = 'Reorder Forecasts';
  static const String opacity = 'Opacity';
  static const String selectRegion = 'Select Region';
  static const String one800WxBrief = '1800WxBrief';
  static const String notamsBrief = "NOTAMS";
  static const String routeBrief = "Route Brief";
  static const String refreshForecast = "Refresh Forecast";
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

class TaskLiterals {
  static const String TASK = "Task";
  static const String TASK_NAME = "Task Name:";
  static const String TASK_LIST = "Task List";
  static const String TASK_DETAIL = "Task Detail";
  static const String TASK_ERROR = "Task Error";
  static const String DISTANCE = "Distance:";
  static const String KM = "km";
  static const String TURNPOINTS = "Turnpoints:";
  static const String START = "Start";
  static const String FINISH = "Finish";
  static const String FROM_PRIOR_POINT = "From prior point:";
  static const String FROM_START = "From start:";
  static const String ADD_TURNPOINTS = "Add Turnpoints";
  static const String ADD_TASK = "ADD";
  static const String SAVE_TASK = "SAVE";
  static var LEAVE_BLANK_FOR_DEFAULT_NAME =
      "Leave blank for default name when saved";
}

class TurnpointMenu {
  static const String searchTurnpoints = "Search";
  static const String importTurnpoints = 'Import Turnpoints';
  static const String addTurnpoint = 'Add Turnpoint';
  static const String exportTurnpoints = 'Export Turnpoints';
  static const String emailTurnpoints = 'Email Turnpoints';
  static const String clearTurnpointDatabase = 'Clear Turnpoint Database';
  static const String customImport = 'Custom Import';
  static const String turnpoints = "Turnpoints";
  static const String turnpoint = "Turnpoint";
  static const String turnpointImport = "Turnpoint Import";
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
  static const String editTurnpoint = "Edit Turnpoint";
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

class WindyMenu {
  static const String selectTask = 'Select Task';
  static const String clearTask = "Clear Task";
  static const String TopoMap = 'Topo Map';
}

class GeosMenu {
  static const String loop = "LOOP";
  static const String noaa = "NOAA";
  static const String current = "CURRENT";
}

class MetarTafMenu {
  static const String list = "List";
  static const String add = "Add";
  static const String refresh = "Refresh";
}

class AirportMenu {
  static const String refresh = "Refresh";
}

class AirportLiterals {
  static const String METAR_TAF_AIRPORTS = "METAR/TAF Airports";
  static const String DOWNLOAD_AIRPORTS = "Download Airports?";
  static const String NO_AIRPORTS_FOUND_MSG =
      "Hmmm. Looks like we need to download the airport database. Is it Ok to download now? It might take 30 secs or so.";
  static const String DOWNLOAD_SUCCESSFUL =
      "Airports downloaded successfully. You can now search on airports.";
  static const String DOWNLOAD_UNSUCCESSFUL =
      "Hmmm. Airport download unsuccessful. Please try again later.";
  static const String REFRESH_AIRPORTS = "Refresh Airports?";
  static const String CONFIRM_DELETE_RELOAD =
      "Are you sure you want to delete/reload the Airport database?";
  static const String NO_AIRPORTS_FOUND = "No airports found";
  static const String AIRPORTS_ERROR = 'Airports Error';
  static const String NO_AIRPORTS_SELECTED_YET =
      "No airports have been selected yet. Would you like to add some?";
}

class MetarOrTAF {
  static const String METAR_TAF = "METAR/TAF";
  static const String METAR = "METAR";
  static const String TAF = "TAF";
  static const String FETCHING_INFORMATION = "Fetching information";
  static const String UNDEFINED_ERROR = "Undefined error";
  static const String NO_AIRPORTS_SELECTED_YET = 'No airports selected yet.';
  static const String AIRPORTS_ERROR = 'Airports Error';
  static const String ELEV = "Elev";
  static const String FT = "ft";
}

class Feedback {
  static const String SOARING_FORECAST = "SoaringForecast";
  static const String FEEDBACK_TITLE = "SoaringForecast Feedback";
  static const String FEEDBACK_HINT = "Please enter your feedback";
  static const String FEEDBACK_CANCEL = "Cancel";
  static const String FEEDBACK_SUBMIT = "Submit";
}

class WxBriefMenu {
  static const String HELP = "Help";
}

class PolarLiterals {
  static const String POLAR = "Polar";
}
class WxBriefLiterals {
  static const String DO_NOT_SHOW_THIS_AGAIN = "Do not show this again";
  static const String WXBRIEF_AUTHORIZATION = "1800Brief Authorization";
  static const String ONE800WXBRIEF = "1800WxBrief";
  static const String ONE800WX_AREA_BRIEF = "Area Brief";
  static const String ONE800WX_ROUTE_BRIEF = "Route Brief";
  static const String NOTAMS_BRIEFING = "NOTAMS Only";
  static const String NOTAMS_ABBREV_BRIEF = "NOTAMS Abbreviated Brief";
  static const String REPORT_OPTIONS = "Report Options";
  static const String PRODUCT_OPTIONS = "Product Options";
  static const String CANCEL = "Cancel";
  static const String CLOSE = "Close";
  static const String SUBMIT = "Submit";
  static const String AIRPORT_ID = "Airport Id";
  static const String INVALID_AIRPORT_ID = "Invalid Airport Id";
  static const String AIRCRAFT_REGISTRATION_LABEL = 'Aircraft Registration';
  static const String INVALID_AIRCRAFT_REGISTRATION_ID =
      "Invalid aircraft registration id";
  static const String WXBRIEF_ACCOUNT_NAME =
      '1800WxBrief Account Name(Email address)';
  static const String INVALID_WXBRIEF_USER_NAME =
      "Invalid 1800WXBrief user name. Must be email address.";
  static const String BRIEFING_FORMAT = "Briefing Format";
  static const String DEPARTURE_DATE = "Departure Date";
  static const String TYPE_OF_BRIEF = "Type of Brief";
  static const String SELECT = "Select";
  static const String WXBRIEF_ACCOUNT_NAME_INFO =
      "Your email address associated with your 1800WXBrief account.";
  static const String DEPARTURE_DATE_INFO =
      "For current date the brief assumes 1hr in the future. For future days, a 9AM departure is assumed.";

  static const String WXBRIEF_NOTAMS_ABBREV_BRIEF_INFO =
      '''This option retrieves aeronautical and meteorological data from 1800wxbrief.com, and provides NOTAMs and TFRs as of the time the request is made.
  \n\nOnly the following are requested for this briefing:
  \n\u2022 Temporary Flight Restrictions
  \n\u2022 Closed/Unsafe NOTAMS
  \n\u2022 Departure and Destination NOTAMS
  \n\u2022 UAS Operating Area
  \n\u2022 Communication NOTAM
  \n\u2022 Special Use Airspace NOTAM
  \n\u2022 Runway/Taxiway/Apron/Aerodome/FDC NOTAM
  \n\nThe route corridor is set to 50nm width, the minimum allowed by 1800WXBrief.''';
  static const String WXBRIEF_SENT_TO_MAILBOX =
      "Your briefing should arrive in our mailbox shortly";
}

class GraphLiterals {
  static const String LOCAL_FORECAST = "Local Forecast";
  static const String SET_AS_FAVORITE = "Set As Favorite";
  static const String GRAPH_ERROR = "Graph Error";
  static const String GRAPH_DATA = "Graph Data";
  static const String GRAPH_DATA_MISSING = "Data used for graph is missing!";
}

class DrawerLiterals {
  static const String SOARING_FORECAST = "SoaringForecast";
  static const String OTHER_FORECASTS = "Other Forecasts";
  static const String WINDY = "Windy";
  static const String SKYSIGHT = "SkySight";
  static const String DR_JACKS = "Dr Jacks";
  static const String ONE_800_WX_BRIEF = "1800WxBrief";
  static const String AREA_BRIEF = "Area Brief";
  static const String AIRPORT_METAR_TAF = "Airport METAR/TAF";
  static const String GEOS_NE = " GEOS NE";
  static const String CUSTOMIZATION = "Customization";
  static const String TASK_LIST = "Task List";
  static const String TURNPOINTS = "Turnpoints";
  static const String TAF_METAR_LIST = "METAR/TAF List";
  static const String SETTINGS = "Settings";
  static const String FEEDBACK = "Feedback";
  static const String ABOUT = "About";
}

class PolarMenu {
  static const String UNITS = "Units";
  static const String METRIC = "Metric";
  static const String AMERICAN = "American";

}

// Turnpoint icon colors for type of runway
const Color grassRunway = Color(0xFF3CB043);
const Color asphaltRunway = Colors.black;
const Color noRunway = Color(0xFFEE4926);
//---------------------------------------------------------------------------
