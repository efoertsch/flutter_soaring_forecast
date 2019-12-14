import 'dart:convert';

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
    this.models,
  });

  List<String> getModelNames() {
    var modelNames = List<String>();
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
    this.center,
    this.times,
    this.name,
    this.corners,
  });

  factory Model.fromJson(Map<String, dynamic> json) => _$ModelFromJson(json);
  Map<String, dynamic> toJson() => _$ModelToJson(this);
}
