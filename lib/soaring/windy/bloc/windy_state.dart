import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_altitude.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_layer.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_model.dart';

@immutable
abstract class WindyState extends Equatable {}

class WindyLoadingState extends WindyState {
  @override
  List<Object?> get props => [];
}

class WindyModelListState extends WindyState {
  final List<WindyModel> models;
  WindyModelListState(List<WindyModel> this.models);

  @override
  List<Object?> get props => [models];
}

class WindyAltitudeListState extends WindyState {
  final List<WindyAltitude> altitudes;
  WindyAltitudeListState(List<WindyAltitude> this.altitudes);

  @override
  List<Object?> get props => [altitudes];
}

class WindyLayerListState extends WindyState {
  final List<WindyLayer> layers;
  WindyLayerListState(List<WindyLayer> this.layers);

  @override
  List<Object?> get props => [layers];
}

class WindyHtmlState extends WindyState {
  final String html;
  WindyHtmlState(String this.html);

  @override
  List<Object?> get props => [html];
}
