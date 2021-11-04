import 'package:flutter/material.dart';

@immutable
abstract class TurnpointEvent {}

// All the events related to turnpoints

class TurnpointSearchInitialEvent extends TurnpointEvent {
  TurnpointSearchInitialEvent();
}

class SearchTurnpointsEvent extends TurnpointEvent {
  final String searchString;
  SearchTurnpointsEvent(this.searchString);
}
