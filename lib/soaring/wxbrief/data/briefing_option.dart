import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show WxBriefTypeOfBrief;
import 'package:flutter_soaring_forecast/soaring/app/extensions/string_apis.dart';

class BriefingOption {
  ///Name using in request to 1800WxBrief
  late final String wxBriefParameterName;

  /// Description (info only)
  late final String wxBriefParamDescription;

  /// Short description  used for display
  late final String displayDescription;

  /// if true it means this option should be displayed
  late final bool displayThisOption;

  /// Default value (whether displayed or not) for the selected type of briefing
  late bool selectForBrief;

  BriefingOption._() {}

  static Future<BriefingOption?> createBriefingOptionFromCSVDetail(
      List<dynamic> briefingOptions,
      WxBriefTypeOfBrief selectedTypeOfBrief) async {
    List<String> briefingOptionDetails =
        briefingOptions.map((option) => option as String).toList();
    BriefingOption? briefingOption = BriefingOption._();
    try {
      briefingOption.wxBriefParameterName = briefingOptionDetails[0];
      briefingOption.wxBriefParamDescription = briefingOptionDetails[1];
      briefingOption.displayDescription = briefingOptionDetails[2];
      switch (selectedTypeOfBrief) {
        case WxBriefTypeOfBrief.OUTLOOK:
          briefingOption.displayThisOption =
              briefingOptionDetails[3].parseBool();
          briefingOption.selectForBrief = briefingOptionDetails[4].parseBool();
          break;
        case WxBriefTypeOfBrief.STANDARD:
          briefingOption.displayThisOption =
              briefingOptionDetails[5].parseBool();
          briefingOption.selectForBrief = briefingOptionDetails[6].parseBool();
          break;
        case WxBriefTypeOfBrief.ABBREVIATED:
          briefingOption.displayThisOption =
              briefingOptionDetails[7].parseBool();
          briefingOption.selectForBrief = briefingOptionDetails[8].parseBool();
          break;
        case WxBriefTypeOfBrief.NOTAMS:
          briefingOption.displayThisOption =
              briefingOptionDetails[9].parseBool();
          briefingOption.selectForBrief = briefingOptionDetails[10].parseBool();
      }
    } catch (exception) {
      briefingOption = null;
    }
    return briefingOption;
  }
}
