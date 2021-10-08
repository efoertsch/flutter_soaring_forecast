import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'forecast_models.g.dart';

/// JSON string obtained from http://soargbsc.com/rasp/NewEngland/2019-10-08/status.json
/// (region 'NewEngland' and date '2019-10-08' are variables supplied to Rest api)
/// Gen'ed Dart code from JSON string via using https://app.quicktype.io/
/// Then dart code modified for generator
/// Then generated ...g.dart file running following command in terminal
///    flutter packages pub run build_runner build

ForecastModels forecastModelsFromJson(String str) =>
    ForecastModels.fromJson(json.decode(str));

String forecastModelsToJson(ForecastModels data) => json.encode(data.toJson());

@JsonSerializable()
class ForecastModels {
  List<Model> models;

  ForecastModels({
    required this.models,
  });

  List<String> getModelNames() {
    var modelNames = <String>[];
    for (Model model in models) {
      modelNames.add(model.name);
    }
    return modelNames;
  }

  List<Model> getModels() {
    return models;
  }

  Model getModel(int i) {
    return models[i];
  }

  factory ForecastModels.fromJson(Map<String, dynamic> json) =>
      _$ForecastModelsFromJson(json);
  Map<String, dynamic> toJson() => _$ForecastModelsToJson(this);
}

@JsonSerializable()
class Model {
  List<double> center;
  List<String> times;
  String name;
  List<List<double>> corners;

  Model({
    required this.center,
    required this.times,
    required this.name,
    required this.corners,
  });

  factory Model.fromJson(Map<String, dynamic> json) => _$ModelFromJson(json);
  Map<String, dynamic> toJson() => _$ModelToJson(this);

  // -----------  Custom code -----------------
  LatLngBounds get latLngBounds {
    return LatLngBounds(southwest: southWestLatLng, northeast: northEastLatLng);
  }

  LatLng get southWestLatLng {
    if (corners != null && corners.length > 0 && corners[0].length > 1) {
      return new LatLng(corners[0][0], corners[0][1]);
    }
    return LatLng(0.0, 0.0);
  }

  LatLng get northEastLatLng {
    if (corners != null && corners.length > 1 && corners[1].length > 1) {
      return new LatLng(corners[1][0], corners[1][1]);
    }
    return LatLng(0.0, 0.0);
  }

  //------------ End custom code ---------------
}
