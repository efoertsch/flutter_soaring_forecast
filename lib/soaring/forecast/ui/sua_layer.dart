import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show SUAColor, StandardLiterals;
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:latlong2/latlong.dart';

import '../../app/common_widgets.dart';

class SuaGeoJsonHandler {
  final suaColors = SUAColor.values;
  late GeoJsonParser suaGeoJasonParser;

  BuildContext context;
  SuaGeoJsonHandler(this.context){
    suaGeoJasonParser  = getSuaGeoJasonParser();
    suaGeoJasonParser.setDefaultMarkerTapCallback(onTapSuaMarkerFunction);
  }


  GeoJsonParser getSuaGeoJasonParser() {
    return GeoJsonParser(
      polygonCreationCallback: _createSuaPolygon,
// defaultMarkerColor: Colors.red,
// defaultPolygonBorderColor: Colors.red,
// defaultPolygonFillColor: Colors.red.withOpacity(0.1),
// defaultCircleMarkerColor: Colors.red.withOpacity(0.25),
    );
  }

  void parseGeoJsonAsString(String suaDetail) {
    suaGeoJasonParser.parseGeoJsonAsString(suaDetail);
  }

  List<Polygon<Object>> getGeoJasonPolygons(){
    return suaGeoJasonParser.polygons;

  }

  ///  callback function for creating geoJason [Polygon]
  Polygon _createSuaPolygon(List<LatLng> outerRing,
      List<List<LatLng>>? holesList, Map<String, dynamic> properties) {
    Color suaColor = SUAColor.classUnKnown.airspaceColor;
    String suaInfo= "";
    MapEntry<String, dynamic> suaClass = properties.entries.firstWhere(
        (element) => element.key == "TYPE",
        orElse: () => MapEntry("", ""));
    if (suaClass.value != "") {
      suaColor = suaColors
          .firstWhere((sua) => sua.suaClassType == suaClass.value,
              orElse: (() => SUAColor.classUnKnown))
          .airspaceColor;
      suaInfo = getSuaLabel(properties);
    }

    return Polygon(
      points: outerRing,
      holePointsList: holesList,
      borderColor: suaColor,
      color: Colors.transparent,
      borderStrokeWidth: 3,
      label: suaInfo,
      labelStyle:textStyleBoldBlackFontSize18,
    );
  }

  void onTapSuaMarkerFunction(Map<String, dynamic> properties) {
    String  label = getSuaLabel(properties);
      CommonWidgets.showInfoDialog(
          context: context,
          title: "SUA",
          msg:   label,
          button1Text: StandardLiterals.OK,
          button1Function: (() => Navigator.pop(context)));
  }

  String  getSuaLabel(Map<String, dynamic> properties) {
    StringBuffer sb = StringBuffer();

    for (MapEntry mapEntry in properties.entries) {
      if (mapEntry.key == 'TITLE') {
        sb.write( mapEntry.value +  "\n");
      }
      if (mapEntry.key == 'TYPE') {
        sb.write(mapEntry.value +  "\n");
      }
      if (mapEntry.key == 'BASE') {
        sb.write("Base: " +  mapEntry.value + "\n");
      }
      if (mapEntry.key == 'TOPS') {
        sb.write("Tops: " + mapEntry.value + "\n");
      }
    }
    return sb.isNotEmpty ? sb.toString() : "No Information";
  }


}
