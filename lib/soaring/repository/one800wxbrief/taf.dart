import 'package:flutter_soaring_forecast/soaring/repository/one800wxbrief/coded_message.dart';
import 'package:flutter_soaring_forecast/soaring/repository/one800wxbrief/metar_taf_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'taf.g.dart';

//!!! Remember to run generator with any changes !!!
//!!!  flutter pub run build_runner build  --delete-conflicting-outputs     !!!

@JsonSerializable()
class Taf extends MetarTafResponse {
  Taf(bool returnStatus, List<ReturnCodedMessage> returnCodedMessage,
      String plainText, String spokenText, String rawText)
      : super(
            returnStatus: returnStatus,
            returnCodedMessage: returnCodedMessage,
            plainText: plainText,
            spokenText: spokenText,
            rawText: rawText);

  Taf.fromJson(Map<String, dynamic> json) {
    MetarTafResponse.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return super.toJson();
  }
}
