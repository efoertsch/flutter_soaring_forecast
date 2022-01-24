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

  Regions.fromJson(Map<String, dynamic> json) {
    _initialRegion = json['initialRegion'];
    if (json['regions'] != null) {
      _regions = <Region>[];
      json['regions'].forEach((v) {
        _regions!.add(new Region.fromJson(v));
      });
    }
    _airspace = json['airspace'] != null
        ? new Airspace.fromJson(json['airspace'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['initialRegion'] = this._initialRegion;
    if (this._regions != null) {
      data['regions'] = this._regions!.map((v) => v.toJson()).toList();
    }
    if (this._airspace != null) {
      data['airspace'] = this._airspace!.toJson();
    }
    return data;
  }
}

@JsonSerializable()
class Region {
  List<String>? _printDates;
  List<Soundings>? _soundings;
  List<String>? _dates;
  String? _name;

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

  List<Soundings>? get soundings => _soundings;

  set soundings(List<Soundings>? soundings) => _soundings = soundings;

  List<String>? get dates => _dates;

  set dates(List<String>? dates) => _dates = dates;

  String? get name => _name;

  set name(String? name) => _name = name;

  Region.fromJson(Map<String, dynamic> json) {
    _printDates = json['printDates'].cast<String>();
    if (json['soundings'] != null) {
      _soundings = <Soundings>[];
      json['soundings'].forEach((v) {
        _soundings!.add(new Soundings.fromJson(v));
      });
    }
    _dates = json['dates'].cast<String>();
    _name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['printDates'] = this._printDates;
    if (this._soundings != null) {
      data['soundings'] = this._soundings!.map((v) => v.toJson()).toList();
    }
    data['dates'] = this._dates;
    data['name'] = this._name;
    return data;
  }

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
    ModelDateDetails modelDateDetails =
        ModelDateDetails(printDate, date, model);
    // See if you have already seen that model
    ModelDates? modelDates = _modelDates
        .firstWhereOrNull((modelDates) => (modelDates.modelName == model.name));
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
}

//---------- End Custom Code -----------------------

@JsonSerializable()
class Soundings {
  String? _location;
  String? _longitude;
  String? _latitude;

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

  Soundings.fromJson(Map<String, dynamic> json) {
    _location = json['location'];
    _longitude = json['longitude'];
    _latitude = json['latitude'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['location'] = this._location;
    data['longitude'] = this._longitude;
    data['latitude'] = this._latitude;
    return data;
  }
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

  Airspace.fromJson(Map<String, dynamic> json) {
    _baseUrl = json['baseUrl'];
    _files = json['files'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['baseUrl'] = this._baseUrl;
    data['files'] = this._files;
    return data;
  }
}

//------------- Custom code --------------------------
/// Custom coded convenience classes
/// For each model (e.g. gfs, nam, ...) forecasts have been produced for
///, hold the list of dates and forecast times and lat/long details
/// Note that this class 'inverts' the web order. Here it is model, dates
/// whereas web is dates, model
class ModelDates {
  String? modelName;
  List<ModelDateDetails> modelDateDetailList = [];

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
  String? printDate;
  String? date;
  Model? model;

  ModelDateDetails(String printDate, String date, Model model) {
    this.printDate = printDate;
    this.date = date;
    this.model = model;
  }

//---------- End Custom Code -----------------------
}
