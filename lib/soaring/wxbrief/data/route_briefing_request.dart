import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show WxBriefTypeOfBrief;
import 'package:flutter_soaring_forecast/soaring/app/extensions/string_apis.dart';

/**
 * A much simplified class to hold values needed to make the routeBriefing call to the 1800wxbrief
 * routeBriefing api
 * See https://www.1800wxbrief.com/Website/resources/doc/WebService.xml#op.idp140237337565664 for
 * valid values and definition
 */

enum TimeZoneAbbrev {
  AST,
  ADT,
  EST,
  EDT,
  CST,
  CDT,
  MST,
  MDT,
  PST,
  PDT,
  AKST,
  AKDT,
  HST,
  UTC
}

class RouteBriefingRequest {
  static const String _AMPERSAND = "&";

  List<String> _productCodes = <String>[];

  /**
   * User selected tailoring Options to generate the tailoringOptions list in briefingPreferences
   * <p>
   * eg.
   * ... ,"tailoring":["tailoringOption","tailoringOption",...,"tailoringOption"]
   * ... ,"tailoring":["EXCLUDE_GRAPHICS","EXCLUDE_HISTORICAL_METARS"]
   */
  List<String> _tailoringOptions = <String>[];
  String? _selectedBriefingType = "";
  WxBriefTypeOfBrief? _typeOfBrief = null;

  /**
   * REST calls require type - DOMESTIC (being deprecated) or ICAO -
   */
  String _type = "ICAO";

  // Of course only VFR
  String _flightRules = "VFR";

  String? _departure = null;

  String? _departureInstant = null;

  String? _destination = null;

  /**
   * Default to 12 hr  flight
   */
  String _flightDuration = "PT12H";

  /**
   * Default flight to 6 thousand feet
   */
  String _flightLevel = "060";

  /**
   * Route  (airports along task, comma separated
   * eg. KAFN, KEEN  (Jaffrey and Dillant-Hopkins)
   */
  String? _route;

  /**
   * Glider N number
   */
  String? _aircraftIdentifier;

  /**
   * Nautical miles
   * Integer with restriction minInclusive(25) maxInclusive(100)
   */
  String _routeCorridorWidth = "25";

  String _speedKnots = "50";

  /**
   * Used to provide key/value error msg when errors occur
   * Optional but we want more definitive error info if error does occur
   */
  bool _includeCodedMessages = true;

  /**
   * Optional
   * When briefingType of NGBV2 is requested and the outLookBriefing parameter is included and
   * set to TRUE, it allows the vendor to request NGBV2 briefing with the briefing format is
   * NGBv2 HTML or NGBv2 PDF, as specified by the briefingResultFormat parameter and the briefing
   * contains only Outlook products. When briefingType of NGBV2 is requested and the
   * outLookBriefing parameter is included and set to false or not included at all,
   * Standard briefing is returned.
   */
  bool _outlookBriefing = false;

  /**
   * Optional - but we set to false
   * If the notABriefing parameter is set to true, it allows a vendor to request weather and
   * NOTAM data without an associated pilot or flight plan. A web service call made with
   * notABriefing set to true will not be retained on our system for the purposes of retaining
   * historical briefing data for a pilot or accident reconstruction. If set to false or not
   * provided, the aircraftIdentifier is required and a briefing is recorded in our system.
   * If the notABriefing parameter is set to either true or false, it will result in a minimum
   * versionRequested value of 20160225.
   */

  bool _notABriefing = false;

  /**
   * Optional but must be valid version
   */
  String _versionRequested = "99999999";

  /**
   * The briefingResultFormat is an optional parameter that applies only to briefingType of NGBV2
   * and for this type of briefing it must be specified. If briefingResultFormat is specified as
   * PDF, the returned briefing will be a base64 encoded string of the PDF, containing the NGBv2
   * briefing. The HTML format is for internal Leidos use only, and is disabled for external
   * customers. If briefingResultFormat is specified as HTML, the returned briefing will be HTML
   * with NGBv2 contents and formatting
   */
  String _briefingResultFormat = "PDF";

  /**
   * Required only if record of briefing to be filed with 1800WXBrief
   * Email address
   */
  String? _webUserName;

  /**
   * The emailAddress element is a comma separated list of email addresses.
   * These are the addresses that the email will be sent to.
   * This parameter applies to EMAIL briefings only.
   * For our purposes emailAddress = webUserName
   */
  String? _emailAddress;

  /**
   * Nautical Miles
   * Integer with restriction minInclusive(100) maxInclusive(600)
   */
  String _windsAloftCorridorWidth = "100";

  /**
   * Optional
   * If includeFlowControlMessages is set to true, flow control messages are included in the briefing response. If set to false or not provided, flow control messages are not included in the briefing response. This parameter applies to SIMPLE briefings.
   * This parameter will be deprecated in the future. If items are specified in briefingPreferences, add the product code "ATCSCC" to include flow control messages.
   */
  bool? _includeFlowControlMessages;

  /**
   * Optional
   * If includeNhcBulletins is set to true, NHC Bulletins are included in the briefing response. If set to false or not provided, NHC Bulletins are not included in the briefing response. This parameter applies to SIMPLE briefings.
   * This parameter will be deprecated in the future. If items are specified in briefingPreferences, add the product code "WH" to include NHC Bulletins.
   */
  bool? _includeNhcBulletins;

  /**
   * Optional
   * If includeNonLocationFdcNotams is set to true, FDC NOTAMs that have no location are included in the briefing response. If set to false or not provided, FDC NOTAMs that have no location are not included in the briefing response. This parameter applies to SIMPLE briefings.
   * If items are specified in briefingPreferences, the product code "GENFDC_NTM" must be included.
   */
  bool? _includeNonLocationFdcNotams;

  /**
   * Optional
   * f includeStateDeptNotams is set to true, KZZZ NOTAMs are included in the briefing response. If set to false or not provided, KZZZ NOTAMs are not included in the briefing response. This parameter applies to SIMPLE briefings.
   * If items are specified in briefingPreferences, the product code "GENFDC_NTM" must be included.
   */
  bool? _includeStateDeptNotams;

  /**
   * Optional
   * If includeMilitaryNotams is set to true, Military NOTAMs are included in the briefing response. If set to false or not provided, Military NOTAMs are not included in the briefing response. This parameter applies to SIMPLE briefings.
   * This parameter will be deprecated in the future. If items are specified in briefingPreferences, add the product code "ENROUTE_NTM_MIL" to include Military NOTAMs.
   */
  bool? _includeMilitaryNotams;

  /**
   * Not documented but was part of wsdl. New field to be implemented?
   */
  String? _includeDecisionTool;

  /**
   * Optional
   * If briefingType is SIMPLE, wrapColumn specifies column at which to wrap long lines.
   * Use 0 to indicate no wrap. Default wrap is column 78
   */
  String? _wrapColumn;

  /**
   * Optional
   * If plainText is set to true, the briefing output is returned with plain text translation.
   * If set to false or not provided, the briefing output will remain encoded.
   * This parameter applies to SIMPLE briefings only.
   */
  bool? _plainText;

  /**
   * Optional
   * type string with restriction - enum { 'AST', 'ADT', 'EST', 'EDT', 'CST', 'CDT', 'MST', 'MDT'
   * , 'PST', 'PDT', 'AKST', 'AKDT', 'HST', 'UTC' }
   * <p>
   * For NGB and EMAIL briefings, if plainTextTimeZone is set to a supported timezone
   * , the briefing output is returned with plain text translations containing both the zulu time
   * and the supplied timezone for dates and times. For SIMPLE and HTML briefings,
   * if plainTextTimeZone is set to a supported timezone, and plainText is set to true,
   * the briefing output is returned with plain text translations containing both the zulu time
   * and the supplied timezone for dates and times. If not provided or set to "UTC",
   * all times will be in zulu time.
   */
  String? _plainTextTimeZone;

  void setTurnpointNames(List<String> turnpointNames) {
    turnpointNames = turnpointNames;
    if (turnpointNames.length > 0) {
      _departure = turnpointNames[0];
    }
    if (turnpointNames.length > 1) {
      _destination = turnpointNames[turnpointNames.length - 1];
    }
    setRoute(turnpointNames.join(" "));
  }

  void setNotABriefing(bool notABriefing) {
    this._notABriefing = notABriefing;
  }

  void setTailoringOptions(List<String> tailoringOptions) {
    this._tailoringOptions = tailoringOptions;
  }

  void setProductCodes(List<String> productCodes) {
    this._productCodes = productCodes;
  }

  /**
   * Departure airport
   * eg 3B3
   *
   * @param departure
   */
  void setDeparture(String departure) {
    this._departure = departure;
  }

  /**
   * Destination airport
   * eg. 3B3
   *
   * @param destination
   */
  void setDestination(String destination) {
    this._destination = destination;
  }

  /**
   * Approx departure time (Zulu)
   * eg. 2020-08-08T23:59:00.0
   *
   * @param departureInstant
   */
  void setDepartureInstant(String departureInstant) {
    this._departureInstant = departureInstant;
  }

  /**
   * Format eg. PT04H
   *
   * @param flightDuration
   */
  void setFlightDuration(String flightDuration) {
    this._flightDuration = flightDuration;
  }

  /**
   * Comma separated flight route (not including departure and destination
   * eg. KAFN,KEEN
   *
   * @param route
   */
  void setRoute(String route) {
    this._route = route;
  }

  /**
   * Aircraft N number
   * eg 'N68RM'
   *
   * @param aircraftIdentifier
   */
  void setAircraftIdentifier(String aircraftIdentifier) {
    this._aircraftIdentifier = aircraftIdentifier;
  }

  /**
   * In positive decimal number in nautical miles
   *
   * @param routeCorridorWidth
   */
  void setRouteCorridorWidth(String routeCorridorWidth) {
    this._routeCorridorWidth = routeCorridorWidth;
  }

  void setTypeOfBrief(WxBriefTypeOfBrief selectedTypeOfBrief) {
    this._typeOfBrief = selectedTypeOfBrief;
    setOutlookBriefing(selectedTypeOfBrief == WxBriefTypeOfBrief.OUTLOOK);
  }

  void setOutlookBriefing(bool outlookBriefing) {
    this._outlookBriefing = outlookBriefing;
  }

  void setSelectedBriefFormat(String selectedBriefingType) {
    this._selectedBriefingType = selectedBriefingType;
  }

  void setBriefingResultFormat(String briefingResultFormat) {
    this._briefingResultFormat = briefingResultFormat;
  }

  void setWebUserName(String webUserName) {
    this._webUserName = webUserName;
  }

  void setEmailAddress(String emailAddress) {
    this._emailAddress = emailAddress;
  }

  void setWindsAloftCorridorWidth(String windsAloftCorridorWidth) {
    this._windsAloftCorridorWidth = windsAloftCorridorWidth;
  }

  void setPlainTextTimeZone(String plainTextTimeZone) {
    this._plainTextTimeZone = plainTextTimeZone;
  }

  /**
   * Create the parm string for a REST routeBriefing API call. Create string like
   * includeCodedMessages=true&routeCorridorWidth=25&briefingPreferences={"tailoring":["ENCODED_ONLY"]}
   * &type=DOMESTIC&outlookBriefing=false&flightRules=VFR&departure=3B3
   * &departureInstant=2020-08-08T23:59:00.0&destination=3B3&flightDuration=PT04H
   * &route=KAFN, KEEN&aircraftIdentifier=N68RM&webUserName=flightservice@soaringforecast.org
   * &speedKnots=50&versionRequested=99999999&notABriefing=false&briefingType=NGBV2
   * &briefingResultFormat=PDF&emailAddress=flightservice%40soaringforecast.org
   */
  String getRestParmString() {
    StringBuffer sb = new StringBuffer();
    // sb.append("notABriefing=",notABriefing);
    sb.writeAll([_AMPERSAND, "includeCodedMessages=", _includeCodedMessages]);
    sb.writeAll([_AMPERSAND, "type=", _type]); //ICAO

    sb.writeAll([_AMPERSAND, "aircraftIdentifier=", _aircraftIdentifier]);
    sb.writeAll([_AMPERSAND, "routeCorridorWidth=", _routeCorridorWidth]);
    sb.writeAll([
      _AMPERSAND,
      "outlookBriefing=",
      ((_outlookBriefing != null) ? _outlookBriefing : false)
    ]);
    sb.writeAll([_AMPERSAND, "flightRules=", _flightRules]);
    sb.writeAll([_AMPERSAND, "departure=", _departure]);
    sb.writeAll([_AMPERSAND, "departureInstant=", _departureInstant]);
    sb.writeAll([_AMPERSAND, "destination=", _destination]);
    sb.writeAll([_AMPERSAND, "route=", _route]);
    sb.writeAll([_AMPERSAND, "flightDuration=", _flightDuration]);
//        if (!notABriefing) {
//            sb.writeAll([AMPERSAND,"webUserName=",webUserName);
//        }
    sb.writeAll([_AMPERSAND, "webUserName=", _webUserName]);
    sb.writeAll([_AMPERSAND, "speedKnots=", _speedKnots]);
    sb.writeAll([_AMPERSAND, "versionRequested=", "99999999"]);
    sb.writeAll([_AMPERSAND, "briefingType=", _selectedBriefingType]);
    if (_selectedBriefingType != null) {
      switch (_selectedBriefingType) {
        case "NGBV2":
          sb.writeAll(
              [_AMPERSAND, "briefingResultFormat=", _briefingResultFormat]);
          // LEIDOS wants altitudeVFRFL when requesting PDF
          sb.writeAll([_AMPERSAND, "altitudeVFRFL=", _flightLevel]);
          break;
        case "EMAIL":
          sb.writeAll([_AMPERSAND, "emailAddress=", _emailAddress]);
          sb.writeAll([_AMPERSAND, "altitudeVFR"]);
          break;
        default:
          sb.writeAll([_AMPERSAND, "altitudeVFR"]);
      }
    }
    if (_selectedBriefingType != null &&
        _selectedBriefingType!.equals("SIMPLE")) {
      sb.writeAll([_AMPERSAND, "plainText=true"]);
    }
    // make sure current timezone valid possible IllegalArgumentException
    String plainTextTimeZone = DateTime.now().timeZoneName;
    sb.writeAll([_AMPERSAND, "plainTextTimeZone=", plainTextTimeZone]);
    if (_selectedBriefingType != null) {
      sb.writeAll(
          [_AMPERSAND, "briefingPreferences=", getBriefingPreferences()]);
    }
    String unencodedParms = sb.toString();
    debugPrint("Briefing Request Options (unencoded): ${unencodedParms}");
    return unencodedParms;
  }

  /**
   * The briefing preferences element is a JSON string containing the desired briefing products, tailoring options, and a plain text parameter.
   * Usage:
   * {"items":["productCode","productCode",...,"productCode"],"plainText":true,"tailoring":["tailoringOption","tailoringOption",...,"tailoringOption"]}
   * <p>
   * Note: The items parameter is not supported by SIMPLE briefingType. If it is not specified, all briefing products will be included.
   * The plainText parameter is not supported by NGBv2 briefingType.
   * If it is not specified, it will default to false. If it is true, then plain text will be included regardless of the tailoring options.
   * <p>
   * Example for NGBv2 briefingType:
   * {"items":["DD_NTM","SEV_WX","METAR","PIREP"],"tailoring":["EXCLUDE_GRAPHICS","EXCLUDE_HISTORICAL_METARS"]}
   * The returned briefing will include only the following products: Closed/Unsafe NOTAMs, Severe Weather, METARs, and Pilot Reports. Also, it will not include graphics nor historical METARs.
   * <p>
   * Note: If there is a conflict between a tailoring option and a product item, the tailoring option takes precedence.
   * For example, a briefing with the following briefingPreferences will include only Synopsis:
   * {"items":["SYNS","WH"],"tailoring":["EXCLUDE_NHC_BULLETIN"]}
   * <p>
   * Formatted briefingPreferences string
   * {"items":["productCode","productCode",...,"productCode"],"plainText":true,"tailoring":["tailoringOption","tailoringOption",...,"tailoringOption"]}
   * Note "plainText" parm not included
   *
   * @return
   */
  String getBriefingPreferences() {
    StringBuffer sb = new StringBuffer();
    sb.write('{');
    sb.write(getProductCodesJson());
    sb.write(getTailorOptionsJson());
    sb.write(getPlainTextOption());
    sb.write('}');
    return sb.toString();
  }

  String getPlainTextOption() {
    if (_selectedBriefingType!.equals("NGBV2")) {
      return "";
    }
    // EMAIL/SIMPLE
    return ",\"plainText\":true";
  }

  /**
   * Items are the list of product codes to be requested
   *
   * @return
   */
  String getProductCodesJson() {
    if (_typeOfBrief == WxBriefTypeOfBrief.STANDARD ||
        _typeOfBrief == WxBriefTypeOfBrief.OUTLOOK) {
      return "";
    }
    StringBuffer sb = new StringBuffer();
    sb.write("\"items\":[");
    if (_productCodes.length > 0) {
      for (int i = 0; i < _productCodes.length; ++i) {
        sb.write(i > 0 ? ",\"" : "\"");
        sb.write(_productCodes[i]);
        sb.write("\"");
      }
    }
    sb.write("],");
    return sb.toString();
  }

  String getTailorOptionsJson() {
    StringBuffer sb = new StringBuffer();
    sb.write("\"tailoring\":[");
    if (_tailoringOptions.length > 0) {
      for (int i = 0; i < _tailoringOptions.length; ++i) {
        sb.write(i > 0 ? ",\"" : "\"");
        sb.write(_tailoringOptions[i]);
        sb.write("\"");
      }
    }
    sb.write(']');

    return sb.toString();
  }
}
