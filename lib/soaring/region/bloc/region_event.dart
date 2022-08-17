import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
abstract class RegionDataEvent extends Equatable {}

// All the events that can trigger getting a rasp forecast

class InitialRegionRegionEvent extends RegionDataEvent {
  InitialRegionRegionEvent();
  @override
  List<Object?> get props => [];
}

class ListRegionsEvent extends RegionDataEvent {
  ListRegionsEvent();
  @override
  List<Object?> get props => [];
}

class RegionNameSelectedEvent extends RegionDataEvent {
  final String regionName;

  RegionNameSelectedEvent(String this.regionName);
  @override
  List<Object?> get props => [regionName];
}
