import 'package:flutter_soaring_forecast/soaring/repository/one800wxbrief/coded_message.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class RouteBriefing {
  bool? returnStatus;
  List<String>? returnMessage;
  List<ReturnCodedMessage>? returnCodedMessage;
  String? textualWeatherBriefing;
  String? simpleWeatherBriefing;
  String? htmlweatherBriefing;
  String? ngbsummary;
  String? ngbweatherBriefing;
  String? ngbv2HtmlBriefing;
  String? ngbv2PdfBriefing;

  RouteBriefing(
      {this.returnStatus,
      this.returnMessage,
      this.returnCodedMessage,
      this.textualWeatherBriefing,
      this.simpleWeatherBriefing,
      this.htmlweatherBriefing,
      this.ngbsummary,
      this.ngbweatherBriefing,
      this.ngbv2HtmlBriefing,
      this.ngbv2PdfBriefing});

  RouteBriefing.fromJson(Map<String, dynamic> json) {
    returnStatus = json['returnStatus'];
    if (json['returnMessage'] != null) {
      returnMessage = <String>[];
      json['returnMessage'].forEach((v) {
        returnMessage!.add(v);
      });
    }
    if (json['returnCodedMessage'] != null) {
      returnCodedMessage = <ReturnCodedMessage>[];
      json['returnCodedMessage'].forEach((v) {
        returnCodedMessage!.add(ReturnCodedMessage.fromJson(v));
      });
    }
    textualWeatherBriefing = json['textualWeatherBriefing'];
    simpleWeatherBriefing = json['simpleWeatherBriefing'];
    htmlweatherBriefing = json['htmlweatherBriefing'];
    ngbsummary = json['ngbsummary'];
    ngbweatherBriefing = json['ngbweatherBriefing'];
    ngbv2HtmlBriefing = json['ngbv2HtmlBriefing'];
    ngbv2PdfBriefing = json['ngbv2PdfBriefing'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['returnStatus'] = this.returnStatus;
    if (this.returnMessage != null) {
      data['returnMessage'] = this.returnMessage!.map((v) => v).toList();
    }
    if (this.returnCodedMessage != null) {
      data['returnCodedMessage'] =
          this.returnCodedMessage!.map((v) => v.toJson()).toList();
    }
    data['textualWeatherBriefing'] = this.textualWeatherBriefing;
    data['simpleWeatherBriefing'] = this.simpleWeatherBriefing;
    data['htmlweatherBriefing'] = this.htmlweatherBriefing;
    data['ngbsummary'] = this.ngbsummary;
    data['ngbweatherBriefing'] = this.ngbweatherBriefing;
    data['ngbv2HtmlBriefing'] = this.ngbv2HtmlBriefing;
    data['ngbv2PdfBriefing'] = this.ngbv2PdfBriefing;
    return data;
  }
}
