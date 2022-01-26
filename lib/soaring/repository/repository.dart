import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:floor/floor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:flutter_soaring_forecast/soaring/floor/airport/airport.dart';
import 'package:flutter_soaring_forecast/soaring/floor/app_database.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image.dart';
import 'package:flutter_soaring_forecast/soaring/repository/ImageCacheManager.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoints_downloader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'rasp/forecast_models.dart';
import 'rasp/forecast_types.dart';
import 'rasp/rasp_api.dart';
import 'rasp/regions.dart';

class Repository {
  static Repository? _repository;
  static Dio _dio = Dio();
  static late BuildContext? _context;
  static late RaspClient _raspClient;
  static AppDatabase? _appDatabase;

  Repository._();

  // BuildContext should only be null if repository created in WorkManager task!!!
  factory Repository(BuildContext? context) {
    if (_repository == null) {
      _repository = Repository._();
      _context = context;
      // _dio.interceptors.add(LogInterceptor(responseBody: true));
      _dio.options.receiveTimeout = 300000;
      _raspClient = new RaspClient(_dio);
    }
    return _repository!;
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
    return _raspClient.getRegions();
  }

  /// 2. For selected region, iterate through dates for which forecasts have
  /// been provided to find all models (gfs,nam,...) and forecast dates
  Future<Region> loadForecastModelsByDateForRegion(Region region) async {
    region.clearRegionModelDates();
    List<String> printdates = region.printDates!;
    List<String> dates = region.dates!;
    for (int i = 0; i < region.dates!.length; ++i) {
      try {
        ForecastModels forecastModels =
            await _raspClient.getForecastModels(region.name!, dates[i]);
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
      final json = DefaultAssetBundle.of(_context!)
          .loadString('assets/json/forecast_options.json');
      // TODO - why is method hanging here in test
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

  // ----------- Get RASP forecast images -----------------------
  Future<SoaringForecastImage> getRaspForecastImageByUrl(
      SoaringForecastImage soaringForecastImage) async {
    String fullUrl = Constants.RASP_BASE_URL + soaringForecastImage.imageUrl;
    File file = await ImageCacheManager().getSingleFile(fullUrl);
    //print("Downloading forecast image: $fullUrl");
    Image image = Image.file(file);
    soaringForecastImage.setImage(image);
    return Future<SoaringForecastImage>.value(soaringForecastImage);
  }

  Future<Image> getRaspForecastImageByParms(
      String regionName,
      String forecastDate,
      String model,
      String forecastType,
      String forecastTime,
      String imageType) async {
    return getRaspForecastImage(Constants.RASP_BASE_URL +
        "/$regionName/$forecastDate/$model/$forecastType.$forecastTime}local.d2.$imageType.png");
  }

  getRaspForecastImage(String url) async {
    File file = await ImageCacheManager().getSingleFile(url);
    Image image = Image.file(file);
    return Future<Image>.value(image);
  }

  // Set up Floor database
  Future<AppDatabase> makeDatabaseAvailable() async {
    if (_appDatabase == null) {
      print('App database being created');
      _appDatabase =
          await $FloorAppDatabase.databaseBuilder('app_database.db').build();
    }
    return _appDatabase!;
  }

  Future<int> getCountOfAirports() async {
    await makeDatabaseAvailable();
    return await _appDatabase!.airportDao.getCountOfAirports() ?? 0;
  }

  @transaction
  Future<int?> deleteAllAirports() async {
    await makeDatabaseAvailable();
    return _appDatabase!.airportDao.deleteAll();
  }

  @transaction
  Future<List<int?>> insertAllAirports(List<Airport> airports) async {
    await makeDatabaseAvailable();
    return _appDatabase!.airportDao.insertAll(airports);
  }

  // ------ Tasks -------------------------------------
  Future<List<Task>> getAllTasks() async {
    await makeDatabaseAvailable();
    return _appDatabase!.taskDao.listAllTasks();
  }

  // ----- Turnpoints ----------------------------------
  @transaction
  Future<int?> deleteAllTurnpoints() async {
    await makeDatabaseAvailable();
    return _appDatabase!.turnpointDao.deleteAllTurnpoints();
  }

  Future<int> getCountOfTurnpoints() async {
    await makeDatabaseAvailable();
    //int? count = await _appDatabase!.turnpointDao.getTurnpointCount();
    int? count = Sqflite.firstIntValue(await _appDatabase!.database
        .rawQuery('select count(*) count from turnpoint'));
    return count ?? 0;
  }

  @transaction
  Future<int?> insertTurnpoint(Turnpoint turnpoint) async {
    await makeDatabaseAvailable();
    return _appDatabase!.turnpointDao.insert(turnpoint);
  }

  @transaction
  Future<List<int?>> insertAllTurnpoints(List<Turnpoint> turnpoints) async {
    await makeDatabaseAvailable();
    return _appDatabase!.turnpointDao.insertAll(turnpoints);
  }

  Future<List<Turnpoint>> getAllTurnpoints() async {
    await makeDatabaseAvailable();
    return _appDatabase!.turnpointDao.listAllTurnpoints();
  }

  Future<List<Turnpoint>> findTurnpoints(String query) async {
    await makeDatabaseAvailable();
    return _appDatabase!.turnpointDao.findTurnpoints('%' + query + '%');
  }

  Future<List<Turnpoint>> downloadTurnpointsFromTurnpointExchange(
      String endUrl) async {
    List<Turnpoint> turnpoints = [];
    turnpoints.addAll(await TurnpointsDownloader.downloadTurnpointFile(endUrl));
    var ids = await insertAllTurnpoints(turnpoints);
    print("Number turnpoints downloaded: ${ids.length}");
    return turnpoints;
  }

  //------  Selected turnpoint files available from turnpoint exchange ------

  // ----- Task ----------------------------------------

  Future<List<Task>> getAlltasks() async {
    await makeDatabaseAvailable();
    return _appDatabase!.taskDao.listAllTasks();
  }

  Future<Task> getTask(int taskId) async {
    await makeDatabaseAvailable();
    Task? task = await _appDatabase!.taskDao.getTask(taskId);
    return task ?? Task();
  }

  Future<List<TaskTurnpoint>> getTaskTurnpoints(int taskId) async {
    await makeDatabaseAvailable();
    return _appDatabase!.taskTurnpointDao.getTaskTurnpoints(taskId);
  }
  // ----- Shared preferences --------------------------
  // Make sure keys are unique among calling routines!

  Future<bool> saveGenericString(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  Future<String> getGenericString(String key, String defaultValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? defaultValue;
  }

  Future<bool> saveGenericInt(String key, int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(key, value);
  }

  Future<int> getGenericInt(String key, int defaultValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? defaultValue;
  }
}
