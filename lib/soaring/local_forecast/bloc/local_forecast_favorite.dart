
class LocalForecastFavorite {
  final String? turnpointName;
  final String? turnpointCode;
  final double lat;
  final double lng;

  LocalForecastFavorite(
      {this.turnpointName = null,
        this.turnpointCode = null,
        required this.lat,
        required this.lng,
       }
      );

  factory LocalForecastFavorite.fromJson(Map<String, dynamic> json) {
     return LocalForecastFavorite(
    turnpointName: json['turnpointName'],
    turnpointCode: json['turnpointCode'],
      lat : json['lat'],
      lng : json['lng'],
     );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['turnpointName'] = this.turnpointName;
    data['turnpointCode'] = this.turnpointCode;
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    return data;
  }
}

