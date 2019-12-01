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
  // list of models for each printDate in printDates
  // must be added in same order as printDates
  // Yeah, just a bit convoluted/confusing
  @JsonKey(ignore: true)
  List<ForecastModels> _forecastModels = List();

  addForecastModel(ForecastModels forecastModels) {
    this._forecastModels.add(forecastModels);
  }

  clearForecastModels() {
    _forecastModels.clear();
  }

  List<ForecastModels> getForecastModels() {
    return _forecastModels;
  }

  // For the specified index (date) get the list of models
  List<String> getForecastModelNames(int i) {
    return (_forecastModels.length > 0
        ? _forecastModels[i].getModelNames()
        : List<String>());
  }

  ForecastModels getForecastModel(int i) {
    return _forecastModels[i];
  }

  Region({this.dates, this.name, this.printDates, this.soundings});

  factory Region.fromJson(Map<String, dynamic> json) => _$RegionFromJson(json);
  Map<String, dynamic> toJson() => _$RegionToJson(this);
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
