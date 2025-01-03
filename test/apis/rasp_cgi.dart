import 'dart:async';
import 'dart:io';

import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';

Future<void> main() async {
  //final forecastForDay = ForecastsForDay();
  //await forecastForDay.getAllForecastsForDay();
//  final optimizedTaskRoute = OptimizedTaskRoute();
//  final optimizedRoute = await optimizedTaskRoute.getOptimizedTaskRoute();

}

// class OptimizedTaskRoute {
//   static const region = "NewEngland";
//   static const date = "2023-08-11";
//   static const String model = "gfs";
//   static const String grid = "d2";
//   static const String time = "1100x";
//   static const String polar = "LS-4a";
//   static const double wgt = 1;
//   static const double tsink = 1;
//   static const double tmult = 1;
//   static const String latlons =
//       "42.42617,-71.79383,42.805,-72.003,42.90133,-72.26983,42.42617,-71.79383";
//   final repository = Repository(null);
//
//   FutureOr<void> getOptimizedTaskRoute() async {
//     OptimizedTaskRoute? optimizedTaskRoute = await repository.getOptimizedTaskRoute(
//         region,
//         date,
//         model,
//         grid,
//         time,
//         polar,
//         wgt,
//         tsink,
//         tmult,
//         latlons)
//         .then((optimizedTaskRoute) {
//            print(optimizedTaskRoute.toString());
//       }
//     );
//   }
// }



class ForecastsForDay {
  static const forecastParmList = ["hwcrit", "zsfclclmask", "zblclmask"];
  final file = new File('./test/test_resources/forecast_options.json');

//final json = jsonDecode(await file.readAsString());
  ForecastTypes? forecastTypes;

  final options = <Forecast>[]; //json['forecasts'];
  final repository = Repository(null);
  var times = {
  "1000",
  "1100",
  "1200",
  "1300",
  "1400",
  "1500",
  "1600",
  "1700",
    "1800"
  };

  var date = "2022-11-19";
  var region = "NewEngland";
  var model = "gfs";
  var lat = 43.1394043.toString();
  var long = (-72.0759888).toString();
  String forecastParmString = forecastParmList.join(" ");

  FutureOr<void> getAllForecastsForDay() async {
    if (options.isEmpty) {
      forecastTypes = forecastTypesFromJson(await file.readAsString());
      options.addAll(forecastTypes!.forecasts);
    }
    var dailyForecastListMap = <Map<String, Object>>[];
    await Future.forEach(times, (time) async {
      var hourlyListMap = await getForecastInfo(
          region: region,
          date: date,
          model: model,
          time: time.toString(),
          lat: lat,
          long: long,
          forecastParmString: forecastParmString,
          forecastParmList: forecastParmList,
          options: options);
      dailyForecastListMap.addAll(hourlyListMap);
    });
    print(dailyForecastListMap.toString());
  }

  FutureOr<List<Map<String, Object>>> getForecastInfo({
    required String region,
    required String date,
    required String model,
    required String time,
    required String lat,
    required String long,
    required String forecastParmString,
    required List<String> forecastParmList,
    required List<Forecast> options,
  }) async {
    final forecastListMap = <Map<String, Object>>[];
    await repository
        .getLatLngForecast(
            region, date, model, time, lat, long, forecastParmString)
        .then((httpResponse) {
      if (httpResponse.response.statusCode! >= 200 &&
          httpResponse.response.statusCode! < 300) {
        print('LatLngForecast text ${httpResponse.response.data.toString()}');
        var response = httpResponse.response.data.toString().split('\n');
        // for each forecast in list e.g. "wstar", "dwcrit"
        forecastParmList.forEach((element) {
          final forecastMap = Map<String, Object>();
          // find the forecast details (parm nanme, display name etc);
          final forecast = options
              .singleWhere((forecast) => forecast.forecastName == element);
          // and use the display name to get that particular forecast from the string array
          final forecastString = response.firstWhere(
              (line) => line.contains(forecast.forecastNameDisplay));
          print(forecastString);
          final forecastValue = forecastString
              .trim()
              .substring(forecast.forecastNameDisplay.length)
              .trim();
          var value =
              (forecastValue == "-") ? double.nan : double.parse(forecastValue);
          // and then add the display name and forecasted value to the map
          //forecastMap.addAll({forecast.forecastNameDisplay: forecastValue});
          forecastMap
              .addAll({"Time": time, "code": element, "altitude": value});
          forecastListMap.add(forecastMap);
        });
        print(forecastListMap);
      }
    });
    return forecastListMap;
  }
}
