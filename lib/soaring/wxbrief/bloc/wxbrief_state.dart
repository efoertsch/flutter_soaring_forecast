import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show WxBriefFormat, WxBriefTypeOfBrief;
import 'package:flutter_soaring_forecast/soaring/wxbrief/data/briefing_option.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/data/wxbrief_defaults.dart';

@immutable
abstract class WxBriefState extends Equatable {}

class WxBriefInitialState extends WxBriefState {
  @override
  List<Object?> get props => [];
}

class WxBriefMessageState extends WxBriefState {
  final String msg;
  WxBriefMessageState(this.msg);

  @override
  List<Object?> get props => [msg];
}

class WxBriefPdfDocState extends WxBriefState {
  final String fileName;
  WxBriefPdfDocState(this.fileName);
  @override
  List<Object?> get props => [fileName];
}

class WxBriefErrorState extends WxBriefState {
  final String error;

  WxBriefErrorState(this.error);

  @override
  List<Object?> get props => [error];
}

class WxBriefBriefFormatsState extends WxBriefState {
  final List<WxBriefFormat> wxBriefFormats;

  WxBriefBriefFormatsState(this.wxBriefFormats);
  @override
  List<Object?> get props => [wxBriefFormats.toString()];
}

class WxBriefDepartureDatesState extends WxBriefState {
  final List<String> departureDates;

  WxBriefDepartureDatesState(this.departureDates);
  @override
  List<Object?> get props => [departureDates.join(" ")];
}

class WxBriefBriefingTypesState extends WxBriefState {
  final List<WxBriefTypeOfBrief> briefingTypes;

  WxBriefBriefingTypesState(this.briefingTypes);
  @override
  List<Object?> get props => [briefingTypes.join(" ")];
}

// Not used for NOTAMS briefing
class WxBriefReportingOptionsState extends WxBriefState {
  final List<BriefingOption> reportingOptions;

  WxBriefReportingOptionsState(this.reportingOptions);
  @override
  List<Object?> get props => [reportingOptions.join(" ")];
}

// Only used for abbreviation briefing
class WxBriefProductOptionsState extends WxBriefState {
  final List<BriefingOption> productOptions;

  WxBriefProductOptionsState(this.productOptions);
  @override
  List<Object?> get props => [productOptions.join(" ")];
}

class WxBriefTaskTitleState extends WxBriefState {
  final String taskName;
  final List<String> turnpointIds;

  WxBriefTaskTitleState({required this.taskName, required this.turnpointIds});

  @override
  List<Object?> get props => [taskName, turnpointIds];
}

class WxBriefDefaultsState extends WxBriefState {
  final WxBriefDefaults wxBriefDefaults;

  WxBriefDefaultsState({required this.wxBriefDefaults});

  @override
  List<Object?> get props => [wxBriefDefaults];
}

class WxBriefWorkingState extends WxBriefState {
  final bool working;
  WxBriefWorkingState({required this.working});

  @override
  List<Object?> get props => [working];
}
