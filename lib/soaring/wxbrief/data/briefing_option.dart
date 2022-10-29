import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show WxBriefTypeOfBrief;
import 'package:flutter_soaring_forecast/soaring/app/extensions/string_apis.dart';

class BriefingOption {
  late final String wxBriefParameterName;
  late final String wxBriefParamDescription;
  late final String displayDescription;

  // if true it means this option should be displayed
  late final bool briefOption;

  // Default value (whether displayed or not) for the selected type of briefing
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
          briefingOption.briefOption = briefingOptionDetails[3].parseBool();
          briefingOption.selectForBrief = briefingOptionDetails[4].parseBool();
          break;
        case WxBriefTypeOfBrief.STANDARD:
          briefingOption.briefOption = briefingOptionDetails[5].parseBool();
          briefingOption.selectForBrief = briefingOptionDetails[6].parseBool();
          break;
        case WxBriefTypeOfBrief.ABBREVIATED:
          briefingOption.briefOption = briefingOptionDetails[7].parseBool();
          briefingOption.selectForBrief = briefingOptionDetails[8].parseBool();
          break;
        case WxBriefTypeOfBrief.NOTAMS:
          briefingOption.briefOption = briefingOptionDetails[9].parseBool();
          briefingOption.selectForBrief = briefingOptionDetails[10].parseBool();
      }
    } catch (exception) {
      briefingOption = null;
    }
    return briefingOption;
  }
}
