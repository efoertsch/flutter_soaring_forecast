import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show WxBriefFormat, WxBriefBriefingRequest, WxBriefTypeOfBrief;
import 'package:flutter_soaring_forecast/soaring/wxbrief/data/briefing_option.dart';

@immutable
abstract class WxBriefEvent extends Equatable {}

// All the events related to WxBriefs

class WxBriefInitEvent extends WxBriefEvent {
  final WxBriefBriefingRequest request;

  WxBriefInitEvent(WxBriefBriefingRequest this.request);

  @override
  List<Object?> get props => [request.toString()];
}

class WxAirportIdEvent extends WxBriefEvent {
  final String airportId;

  WxAirportIdEvent(this.airportId);

  @override
  List<Object?> get props => [airportId];
}

class WxBriefUpdateDepartureDateEvent extends WxBriefEvent {
  final String departureDate;

  WxBriefUpdateDepartureDateEvent(String this.departureDate);

  @override
  List<Object?> get props => [departureDate];
}

class WxBriefUpdateAircraftRegistrationEvent extends WxBriefEvent {
  final String registration;

  WxBriefUpdateAircraftRegistrationEvent(String this.registration);

  @override
  List<Object?> get props => [registration];
}

class WxBriefUpdateAccountNameEvent extends WxBriefEvent {
  final String accountName;

  WxBriefUpdateAccountNameEvent(String this.accountName);

  @override
  List<Object?> get props => [accountName];
}

class WxBriefSubmitEvent extends WxBriefEvent {
  WxBriefSubmitEvent();

  @override
  List<Object?> get props => [];
}

class WxBriefSetBriefFormatEvent extends WxBriefEvent {
  final WxBriefFormat wxBriefFormat;

  WxBriefSetBriefFormatEvent({required this.wxBriefFormat});

  @override
  List<Object?> get props => [wxBriefFormat];
}

class WxBriefSetTypeOfBriefEvent extends WxBriefEvent {
  final WxBriefTypeOfBrief wxBriefTypeOfBriefing;

  WxBriefSetTypeOfBriefEvent({required this.wxBriefTypeOfBriefing});

  @override
  List<Object?> get props => [wxBriefTypeOfBriefing];
}

class WxBriefUpdateReportingOptionsEvent extends WxBriefEvent {
  final List<BriefingOption> briefingOptions;

  WxBriefUpdateReportingOptionsEvent({required this.briefingOptions});

  @override
  List<Object?> get props => [briefingOptions.toString()];
}

class WxBriefUpdateProductOptionsEvent extends WxBriefEvent {
  final List<BriefingOption> briefingOptions;

  WxBriefUpdateProductOptionsEvent({required this.briefingOptions});

  @override
  List<Object?> get props => [briefingOptions.toString()];
}

class WxBriefDisplayAuthScreenEvent extends WxBriefEvent {
  @override
  List<Object?> get props => [];
}

class SetWxBriefDisplayAuthScreenEvent extends WxBriefEvent {
  final bool showAuthScreen;
  SetWxBriefDisplayAuthScreenEvent(this.showAuthScreen);

  @override
  List<Object?> get props => [showAuthScreen];
}
