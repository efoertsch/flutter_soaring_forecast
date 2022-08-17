import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
abstract class RegionDataState extends Equatable {}

class RegionInitialState extends RegionDataState {
  final state = "RegionInitialState";
  @override
  String toString() => state;

  @override
  List<Object?> get props => [state];
}

class RegionErrorState extends RegionDataState {
  final String error;
  RegionErrorState(this.error);

  @override
  List<Object?> get props => [error];
}

class RegionsLoadedState extends RegionDataState {
  final List<String> regions;
  RegionsLoadedState(this.regions);
  @override
  List<Object?> get props => [regions];
}
