import 'package:flutter_soaring_forecast/soaring/repository/one800wxbrief/coded_message.dart';
import 'package:json_annotation/json_annotation.dart';

//!!! Remember to run generator with any changes !!!
//!!!  flutter pub run build_runner build  --delete-conflicting-outputs     !!!

@JsonSerializable()
class Metar {
  bool? returnStatus;
  List<ReturnCodedMessage>? returnCodedMessage;
  String? plainText;
  String? spokenText;
  String? rawText;

  Metar(
      {this.returnStatus,
      this.returnCodedMessage,
      this.plainText,
      this.spokenText,
      this.rawText});

  Metar.fromJson(Map<String, dynamic> json) {
    returnStatus = json['returnStatus'];
    if (json['returnCodedMessage'] != null) {
      returnCodedMessage = <ReturnCodedMessage>[];
      json['returnCodedMessage'].forEach((v) {
        returnCodedMessage!.add(new ReturnCodedMessage.fromJson(v));
      });
    }
    plainText = json['plainText'];
    spokenText = json['spokenText'];
    rawText = json['rawText'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['returnStatus'] = this.returnStatus;
    if (this.returnCodedMessage != null) {
      data['returnCodedMessage'] =
          this.returnCodedMessage!.map((v) => v.toJson()).toList();
    }
    data['plainText'] = this.plainText;
    data['spokenText'] = this.spokenText;
    data['rawText'] = this.rawText;
    return data;
  }
}
