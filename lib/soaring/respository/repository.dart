import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/json/forecast_models.dart';
import 'package:flutter_soaring_forecast/soaring/json/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/json/rasp_api.dart';
import 'package:flutter_soaring_forecast/soaring/json/regions.dart';

class Repository {
  // Hmmm. How to make this only available via static gettter
  static Repository repository;
  static Dio dio = Dio();
  static BuildContext _context;
  static RaspClient raspClient;

  Repository._();

  factory Repository(BuildContext context) {
    if (repository == null) {
      repository = Repository._();
      _context = context;
      dio.interceptors.add(LogInterceptor(responseBody: true));
      dio.options.receiveTimeout = 300000;
      raspClient = new RaspClient(dio);
    }
    return repository;
  }

  // The order of API calls to get a forecast
  // 1. current.json - gets all regions and dates for each region for which some model forecasts have been created
  //
  // 2. status.json - for selected region and date, call status.json to provide list of models (gfs, nam, rap,..), times,
  //    and gps lat/longs for generated forecasts
  //
  // 3. Based on selected region (e.g. 'NewEngland'), model(e.g. 'NAM'),
  //    date and forecast type(eg.' wstar') , retrieve corresponding forecast bitmaps.
  //

  ///  1. Get the list of available forecast regions (e.g. NewEngland, Mifflin) and forecast dates, etc for each region
  Future<Regions> getRegions() async {
    return raspClient.getRegions();
  }

  /// 2. For selected region, iterate through dates for which forecasts have
  /// been provided to find all models (gfs,nam,...) and forecast dates
  Future<Region> loadForecastModelsByDateForRegion(Region region) async {
    region.clearRegionModelDates();
    List<String> printdates = region.printDates;
    List<String> dates = region.dates;
    for (int i = 0; i < region.dates.length - 1; ++i) {
      try {
        ForecastModels forecastModels =
            await raspClient.getForecastModels(region.name, dates[i]);
        region.addForecastModelsForDate(
            forecastModels, dates[i], printdates[i]);
      } catch (error, stackTrace) {
        print(stackTrace);
      }
    }
    return new Future<Region>.value(region);
  }

  /// Get the types of forecasts that are generated.
  /// Note we use a customized list held locally.
  Future<ForecastTypes> getForecastTypes() async {
    /// Retrieves a list of forecast types
    try {
      final json = DefaultAssetBundle.of(_context)
          .loadString('assets/json/forecast_options.json');
      // TODO - why is method hanging here
      ForecastTypes forecastTypes = forecastTypesFromJson(await json);
      return Future<ForecastTypes>.value(forecastTypes);
    } catch (error, stackTrace) {
      print(stackTrace);
      return Future<ForecastTypes>.value(null);
    }
  }

  dispose() {
    // TODO what do I need to do here?
  }
}
