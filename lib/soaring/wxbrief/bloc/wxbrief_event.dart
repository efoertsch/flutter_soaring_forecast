import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show WxBriefFormat, WxBriefTypeOfBriefing;

@immutable
abstract class WxBriefEvent extends Equatable {}

// All the events related to WxBriefs

class WxBriefGetTaskDetailsEvent extends WxBriefEvent {
  WxBriefGetTaskDetailsEvent();

  @override
  List<Object?> get props => [];
}

class WxBriefGetNotamsEvent extends WxBriefEvent {
  final String aircraftRegistration;
  final String accountName;
  final WxBriefFormat wxBriefFormat;

  WxBriefGetNotamsEvent(
      {required this.aircraftRegistration,
      required this.accountName,
      required this.wxBriefFormat});

  @override
  List<Object?> get props => [aircraftRegistration, accountName, wxBriefFormat];
}

class WxBriefSetBriefFormatEvent extends WxBriefEvent {
  final WxBriefFormat wxBriefFormat;

  WxBriefSetBriefFormatEvent({required this.wxBriefFormat});

  @override
  List<Object?> get props => [wxBriefFormat];
}

class WxBriefSetTypeOfBriefEvent extends WxBriefEvent {
  final WxBriefTypeOfBriefing wxBriefTypeOfBriefing;
  WxBriefSetTypeOfBriefEvent({required this.wxBriefTypeOfBriefing});
  @override
  List<Object?> get props => [wxBriefTypeOfBriefing];
}
