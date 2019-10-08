import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/json/forecast_models.dart';
import 'package:flutter_soaring_forecast/soaring/json/rasp_api.dart';
import 'package:flutter_soaring_forecast/soaring/json/regions.dart';

class Repository {
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
      raspClient = new RaspClient(dio);
    }
    return repository;
  }

  ///  get the list of available forecast regions (e.g. NewEngland, Mifflin) and forecast dates, etc for each region
  Future<Regions> getRegions() {
    return  raspClient.getRegions();
  }


  getForecastModels(Region region) async {
    region.clearForecastModels();
    for (String printDate in region.printDates) {
      ForecastModels forecastModels = await raspClient.getForecastModels(
          region.name, printDate);
      region.addForecastModel(forecastModels);
    }

  }


  dispose(){
    // what do I need to do here
  }
}
