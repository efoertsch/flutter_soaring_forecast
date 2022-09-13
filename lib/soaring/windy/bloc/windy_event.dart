import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_altitude.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_layer.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_model.dart';

@immutable
abstract class WindyEvent extends Equatable {}

// All the events related to Tasks

class WindyInitEvent extends WindyEvent {
  WindyInitEvent();
  @override
  List<Object?> get props => [];
}

class WindyModelEvent extends WindyEvent {
  final WindyModel windyModel;
  WindyModelEvent(this.windyModel);
  @override
  List<Object?> get props => [windyModel];
}

class WindyAltitudeEvent extends WindyEvent {
  final WindyAltitude windyAltitude;
  WindyAltitudeEvent(this.windyAltitude);
  @override
  List<Object?> get props => [windyAltitude];
}

class WindyLayerEvent extends WindyEvent {
  final WindyLayer windyLayer;
  WindyLayerEvent(this.windyLayer);
  @override
  List<Object?> get props => [windyLayer];
}
