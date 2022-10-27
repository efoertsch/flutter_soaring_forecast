import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class WxBriefEvent extends Equatable {}

// All the events related to WxBriefs

class WxBriefGetTaskDetailsEvent extends WxBriefEvent {
  WxBriefGetTaskDetailsEvent();

  @override
  List<Object?> get props => [];
}
