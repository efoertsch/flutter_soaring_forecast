import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

import 'forecast_models.dart';

part 'regions.g.dart';

///  Generated via https://javiercbk.github.io/json_to_dart/ fron soargbsc.com/rasp/current.json
/// As of 10/2/19 if you need to regen you will need to remove subsequent regions (e.g. Mifflin) after first (e.g. NewEngland) for generator
///  to successfully gen output
///  Somewhat confusingly - changed lower 'Regions' class to Region and updated List<Regions> to List<Region>, etc

@JsonSerializable()
class Regions {
  String? _initialRegion;
  List<Region>? _regions;
  Airspace? _airspace;

  Regions({String? initialRegion, List<Region>? regions, Airspace? airspace}) {
    this._initialRegion = initialRegion;
    this._regions = regions;
    this._airspace = airspace;
  }

  String? get initialRegion => _initialRegion;

  set initialRegion(String? initialRegion) => _initialRegion = initialRegion;

  List<Region>? get regions => _regions;

  set regions(List<Region>? regions) => _regions = regions;

  Airspace? get airspace => _airspace;

  set airspace(Airspace? airspace) => _airspace = airspace;

  factory Regions.fromJson(Map<String, dynamic> json) => _$RegionsFromJson(json);

  Map<String, dynamic> toJson() => _$RegionsToJson(this);

}

@JsonSerializable()
class Region {
  List<String>? _printDates;
  List<Soundings>? _soundings;
  List<String>? _dates;
  String? _name;
  bool _soundingPositionSet = false;

  Region(
      {List<String>? printDates,
      List<Soundings>? soundings,
      List<String>? dates,
      String? name}) {
    this._printDates = printDates;
    this._soundings = soundings;
    this._dates = dates;
    this._name = name;
  }

  List<String>? get printDates => _printDates;

  set printDates(List<String>? printDates) => _printDates = printDates;

  List<Soundings>? get soundings {
    if (!_soundingPositionSet) {
      if (_soundings != null && _soundings!.length > 0) {
        for (int i = 0; i < _soundings!.length; ++i) {
          _soundings![i].position = i + 1;
        }
      }
      _soundingPositionSet = true;
    }
    return _soundings;
  }

  set soundings(List<Soundings>? soundings) => _soundings = soundings;

  List<String>? get dates => _dates;

  set dates(List<String>? dates) => _dates = dates;

  String? get name => _name;

  set name(String? name) => _name = name;

  factory Region.fromJson(Map<String, dynamic> json) => _$RegionFromJson(json);

  Map<String, dynamic> toJson() => _$RegionToJson(this);

//---------- Custom Code -----------------------
  @JsonKey(ignore: true)
  List<ModelDates> _modelDates = [];

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
    ModelDateDetail modelDateDetail =
        ModelDateDetail(printDate, date, model);
    // See if you have already seen that model
    ModelDates? modelDates = _modelDates
        .firstWhereOrNull((modelDates) => (modelDates.modelName == model.name));
    if (modelDates == null) {
      // First time for that model so add it to the list with the date details
      _modelDates.add(ModelDates(model.name, modelDateDetail));
    } else {
      // model already in list so just add new date/details to the list
      modelDates.addNewModelDates(modelDateDetail);
    }
  }

  ModelDates getModelDatesForModel(String modelName) {
    return _modelDates
        .firstWhere(((modelDates) => modelDates.modelName == modelName));
  }

  // Model in form of 'hrrr','rap,...   Date in form of YYYY-MM-DD
  ModelDateDetail? doModelDateDetailsExist(String modelName, String date ){
    ModelDates? modelDates = _modelDates
        .firstWhereOrNull((modelDates) => (modelDates.modelName == modelName));
    if (modelDates == null) {
      // model doesn't exist
      return null;
    }
    // model exists but see if that model has a forecast for the requested date
    return  modelDates.getModelDateDetailList().firstWhereOrNull((modelDateDetail) => modelDateDetail.date == date);

  }
}

//---------- End Custom Code -----------------------

@JsonSerializable()
class Soundings {
  String? _location;
  String? _longitude;
  String? _latitude;
  int? position;

  Soundings({String? location, String? longitude, String? latitude}) {
    this._location = location;
    this._longitude = longitude;
    this._latitude = latitude;
  }

  String? get location => _location;
  set location(String? location) => _location = location;
  String? get longitude => _longitude;
  set longitude(String? longitude) => _longitude = longitude;
  String? get latitude => _latitude;
  set latitude(String? latitude) => _latitude = latitude;

  factory Soundings.fromJson(Map<String, dynamic> json) => _$SoundingsFromJson(json);

  Map<String, dynamic> toJson() => _$SoundingsToJson(this);

}

@JsonSerializable()
class Airspace {
  String? _baseUrl;
  List<String>? _files;

  Airspace({String? baseUrl, List<String>? files}) {
    this._baseUrl = baseUrl;
    this._files = files;
  }

  String? get baseUrl => _baseUrl;
  set baseUrl(String? baseUrl) => _baseUrl = baseUrl;
  List<String>? get files => _files;
  set files(List<String>? files) => _files = files;

  factory Airspace.fromJson(Map<String, dynamic> json) => _$AirspaceFromJson(json);

  Map<String, dynamic> toJson() => _$AirspaceToJson(this);
}

//------------- Custom code --------------------------
/// Custom coded convenience classes
/// For each model (e.g. gfs, nam, ...) forecasts have been produced for
///, hold the list of dates and forecast times and lat/long details
/// Note that this class 'inverts' the web order. Here it is model, dates
/// whereas web is dates, model
class ModelDates {
  String? modelName;
  List<ModelDateDetail> modelDateDetailList = [];

  ModelDates(String modelName, ModelDateDetail modelDateDetails) {
    this.modelName = modelName;
    modelDateDetailList.add(modelDateDetails);
  }

  List<ModelDateDetail> getModelDateDetailList() {
    return modelDateDetailList;
  }

  void addNewModelDates(ModelDateDetail newModelDateDetails) {
    modelDateDetailList.add(newModelDateDetails);
  }
}

/// For a specific model and date , hold the date data
class ModelDateDetail {
  String? printDate;
  String? date;
  Model? model;

  ModelDateDetail(String printDate, String date, Model model) {
    this.printDate = printDate;
    this.date = date;
    this.model = model;
  }

//---------- End Custom Code -----------------------
}
