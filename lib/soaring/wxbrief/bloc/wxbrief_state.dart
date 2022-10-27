import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/data/wxbrief_defaults.dart';

@immutable
abstract class WxBriefState extends Equatable {}

class WxBriefInitialState extends WxBriefState {
  @override
  List<Object?> get props => [];
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
