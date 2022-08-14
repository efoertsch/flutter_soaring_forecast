import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
abstract class ForecastEvent extends Equatable {}

// List all Forecasts available
class ListForecastsEvent extends ForecastEvent {
  ListForecastsEvent();

  @override
  List<Object?> get props => [];
}

class ResetForecastListToDefaultEvent extends ForecastEvent {
  ResetForecastListToDefaultEvent();

  @override
  List<Object?> get props => [];
}

// for when a task is moved up or down in the task list
class SwitchOrderOfForecastsEvent extends ForecastEvent {
  final int oldIndex;
  final int newIndex;
  SwitchOrderOfForecastsEvent(this.oldIndex, this.newIndex);
  @override
  List<Object?> get props => [oldIndex, newIndex];
}
