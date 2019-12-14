import 'package:flutter_soaring_forecast/soaring/json/forecast_models.dart';
import 'package:json_annotation/json_annotation.dart';

part 'regions.g.dart';

///  Generated via https://javiercbk.github.io/jsontodart/ fron soargbsc.com/rasp/current.json
/// As of 10/2/19 if you need to regen you will need to remove subsequent regions (e.g. Mifflin) after first (e.g. NewEngland) for generator
///  to successfully gen output
///  Somewhat confusingly - changed lower 'Regions' class to Region and updated List<Regions> to List<Region>, etc

@JsonSerializable()
class Regions {
  String initialRegion;
  List<Region> regions;
  Airspace airspace;

  Regions({this.initialRegion, this.regions, this.airspace});

  factory Regions.fromJson(Map<String, dynamic> json) =>
      _$RegionsFromJson(json);
  Map<String, dynamic> toJson() => _$RegionsToJson(this);
}

@JsonSerializable()
class Region {
  List<String> dates;
  String name;
  List<String> printDates;
  List<Soundings> soundings;

  Region({this.dates, this.name, this.printDates, this.soundings});

  factory Region.fromJson(Map<String, dynamic> json) => _$RegionFromJson(json);

  Map<String, dynamic> toJson() => _$RegionToJson(this);

  //---------- Custom Code -----------------------
  @JsonKey(ignore: true)
  List<ModelDates> _modelDates = List();

  void clearRegionModelDates() {
    _modelDates.clear();
  }

  List<ModelDates> getModelDates() {
    return _modelDates;
  }

  void addForecastModelsForDate(
      ForecastModels forecastModels, String date, String printdate) {
    List<Model> forecastModelList = forecastModels.getModels();
    // For this date, for each model (gfs, name) create model/date/date details
    forecastModelList
        .forEach((model) => addToModelDates(model, date, printdate));
  }

  /// For a particular model (e.g. nam) add the date and model details
  void addToModelDates(Model model, String date, String printDate) {
    ModelDateDetails modelDateDetails =
        ModelDateDetails(printDate, date, model);
    // See if you have already seen that model
    ModelDates modelDates = _modelDates.firstWhere(
        (modelDates) => (modelDates.modelName == model.name),
        orElse: () => null);
    if (modelDates == null) {
      // First time for that model so add it to the list with the date details
      _modelDates.add(ModelDates(model.name, modelDateDetails));
    } else {
      // model already in list so just add new date/details to the list
      modelDates.addNewModelDates(modelDateDetails);
    }
  }

  ModelDates getModelDatesForModel(String modelName) {
    return _modelDates
        .firstWhere(((modelDates) => modelDates.modelName == modelName));
  }

//---------- End Custom Code -----------------------
}

@JsonSerializable()
class Soundings {
  String location;
  String longitude;
  String latitude;

  Soundings({this.location, this.longitude, this.latitude});

  factory Soundings.fromJson(Map<String, dynamic> json) =>
      _$SoundingsFromJson(json);
  Map<String, dynamic> toJson() => _$SoundingsToJson(this);
}

@JsonSerializable()
class Airspace {
  String baseUrl;
  List<String> files;

  Airspace({this.baseUrl, this.files});

  factory Airspace.fromJson(Map<String, dynamic> json) =>
      _$AirspaceFromJson(json);
  Map<String, dynamic> toJson() => _$AirspaceToJson(this);
}

//------------- Custom code --------------------------
/// Cutom coded convenience classes
/// For each model (e.g. gfs, nam, ...) forecasts have been produced for
///, hold the list of dates and forecast times and lat/long details
/// Note that this class 'inverts' the web order. Here it is model, dates
/// whereas web is dates, model
class ModelDates {
  String modelName;
  List<ModelDateDetails> modelDateDetailList = List();

  ModelDates(String modelName, ModelDateDetails modelDateDetails) {
    this.modelName = modelName;
    modelDateDetailList.add(modelDateDetails);
  }

  List<ModelDateDetails> getModelDateDetailList() {
    return modelDateDetailList;
  }

  void addNewModelDates(ModelDateDetails newModelDateDetails) {
    modelDateDetailList.add(newModelDateDetails);
  }
}

/// For a specific model and date , hold the date deta
class ModelDateDetails {
  String printDate;
  String date;
  Model model;

  ModelDateDetails(String printDate, String date, Model model) {
    this.printDate = printDate;
    this.date = date;
    this.model = model;
  }

  //---------- End Custom Code -----------------------
}
