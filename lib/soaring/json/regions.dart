
///  Generated via https://javiercbk.github.io/json_to_dart/ fron soargbsc.com/rasp/current.json
/// Note need to remove subsequent regions (e.g. Mifflin) after first (e.g. NewEngland) for generator
///  to successfully gen output\\
///  Somewhat confusingly - changed lower 'Regions' class to Region and updated List<Regions> to List<Region>, etc

class Regions {
  String _initialRegion;
  List<Region> _regions;
  Airspace _airspace;

  Regions({String initialRegion, List<Region> regions, Airspace airspace}) {
    this._initialRegion = initialRegion;
    this._regions = regions;
    this._airspace = airspace;
  }

  String get initialRegion => _initialRegion;
  set initialRegion(String initialRegion) => _initialRegion = initialRegion;

  List<Region> get regions => _regions;
  set regions(List<Region> regions) => _regions = regions;

  // ignore: unnecessary_getters_setters
  Airspace get airspace => _airspace;
  set airspace(Airspace airspace) => _airspace = airspace;

  Regions.fromJson(Map<String, dynamic> json) {
    _initialRegion = json['initialRegion'];
    if (json['regions'] != null) {
      _regions = new List<Region>();
      json['regions'].forEach((v) {
        _regions.add(new Region.fromJson(v));
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
      data['regions'] = this._regions.map((v) => v.toJson()).toList();
    }
    if (this._airspace != null) {
      data['airspace'] = this._airspace.toJson();
    }
    return data;
  }
}

class Region {
  List<String> _dates;
  String _name;
  List<String> _printDates;
  List<Soundings> _soundings;

  Region(
      {List<String> dates,
      String name,
      List<String> printDates,
      List<Soundings> soundings}) {
    this._dates = dates;
    this._name = name;
    this._printDates = printDates;
    this._soundings = soundings;
  }

  List<String> get dates => _dates;
  set dates(List<String> dates) => _dates = dates;
  String get name => _name;
  set name(String name) => _name = name;
  List<String> get printDates => _printDates;
  set printDates(List<String> printDates) => _printDates = printDates;
  List<Soundings> get soundings => _soundings;
  set soundings(List<Soundings> soundings) => _soundings = soundings;

  Region.fromJson(Map<String, dynamic> json) {
    _dates = json['dates'].cast<String>();
    _name = json['name'];
    _printDates = json['printDates'].cast<String>();
    if (json['soundings'] != null) {
      _soundings = new List<Soundings>();
      json['soundings'].forEach((v) {
        _soundings.add(new Soundings.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['dates'] = this._dates;
    data['name'] = this._name;
    data['printDates'] = this._printDates;
    if (this._soundings != null) {
      data['soundings'] = this._soundings.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Soundings {
  String _location;
  String _longitude;
  String _latitude;

  Soundings({String location, String longitude, String latitude}) {
    this._location = location;
    this._longitude = longitude;
    this._latitude = latitude;
  }

  String get location => _location;
  set location(String location) => _location = location;
  String get longitude => _longitude;
  set longitude(String longitude) => _longitude = longitude;
  String get latitude => _latitude;
  set latitude(String latitude) => _latitude = latitude;

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

class Airspace {
  String _baseUrl;
  List<String> _files;

  Airspace({String baseUrl, List<String> files}) {
    this._baseUrl = baseUrl;
    this._files = files;
  }

  String get baseUrl => _baseUrl;
  set baseUrl(String baseUrl) => _baseUrl = baseUrl;
  List<String> get files => _files;
  set files(List<String> files) => _files = files;

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
