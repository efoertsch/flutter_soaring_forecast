import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_altitude.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_layer.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_model.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_startup_parms.dart';
import 'package:latlong2/latlong.dart';

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

class WindyStartupParmsState extends WindyState {
  final WindyStartupParms windyStartupParms;
  WindyStartupParmsState(this.windyStartupParms);
  @override
  List<Object?> get props => [windyStartupParms];
}

class WindyLatLngState extends WindyState {
  final LatLng latLng;
  WindyLatLngState(LatLng this.latLng);

  @override
  List<Object?> get props => [latLng.toString()];
}

class WindyJavaScriptState extends WindyState {
  final String javaScript;
  WindyJavaScriptState(this.javaScript);
  @override
  List<Object?> get props => [javaScript];
}

class WindyAltitudeVisibleState extends WindyState {
  final bool visible;
  WindyAltitudeVisibleState(this.visible);
  @override
  List<Object?> get props => [visible];
}
