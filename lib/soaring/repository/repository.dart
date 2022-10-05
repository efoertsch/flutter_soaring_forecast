import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:floor/floor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_soaring_forecast/auth/secrets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/floor/airport/airport.dart';
import 'package:flutter_soaring_forecast/soaring/floor/app_database.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image.dart';
import 'package:flutter_soaring_forecast/soaring/repository/ImageCacheManager.dart';
import 'package:flutter_soaring_forecast/soaring/repository/options/rasp_options_api.dart';
import 'package:flutter_soaring_forecast/soaring/repository/options/special_use_airspace.dart';
import 'package:flutter_soaring_forecast/soaring/repository/options/sua_region_files.dart';
import 'package:flutter_soaring_forecast/soaring/repository/options/turnpoint_regions.dart';
import 'package:flutter_soaring_forecast/soaring/repository/usgs/national_map.dart';
import 'package:flutter_soaring_forecast/soaring/satellite/noaa/data/satellite_region.dart';
import 'package:flutter_soaring_forecast/soaring/satellite/noaa/data/satellite_type.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/cup/cup_styles.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoint_utils.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoints_importer.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_altitude.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_layer.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_model.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:retrofit/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'rasp/forecast_models.dart';
import 'rasp/forecast_types.dart';
import 'rasp/rasp_api.dart';
import 'rasp/regions.dart';
import 'usgs/usgs_api.dart';

class Repository {
  static Repository? _repository;
  static Dio _dio = Dio();
  static late BuildContext? _context;
  static late RaspClient _raspClient;
  static late RaspOptionsClient _raspOptionsClient;
  static UsgsClient? _usgsClient;
  static AppDatabase? _appDatabase;
  static var logger = Logger();

  static const String SELECTED_REGION = "SELECTED_REGION";
  static const String DEFAULT_SELECTED_REGION = "NewEngland";
  static const String FORECAST_LIST = "FORECAST_LIST";
  static const String FORECAST_OVERLAY_OPACITY = 'FORECAST_OVERLAY_OPACITY';
  static const String CURRENT_TASK_ID = "CURRENT_TASK_ID";
  static const String SATELLITE_TYPE = "SATELLITE_TYPE";
  static const String SATELLITE_REGION = "SATELLITE_REGION";

  late final String satelliteRegionUS;
  late final String satelliteTypeVis;

  Repository._();

  // BuildContext should only be null if repository created in WorkManager task!!!
  factory Repository(BuildContext? context) {
    if (_repository == null) {
      _repository = Repository._();
      _context = context;
      // _dio.interceptors.add(LogInterceptor(responseBody: true));
      _dio.options.receiveTimeout = 300000;
      _dio.options.followRedirects = true;
      // _dio.interceptors.add(
      //   DioLoggingInterceptor(
      //     level: Level.body,
      //     compact: false,
      //   ),
      // );
      _raspClient = RaspClient(_dio);
      _raspOptionsClient = RaspOptionsClient(_dio);
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

  Future<String> getSelectedRegionName() async {
    return await getGenericString(
        key: SELECTED_REGION, defaultValue: DEFAULT_SELECTED_REGION);
  }

  Future<void> saveSelectedRegionName(String regionName) async {
    await saveGenericString(key: SELECTED_REGION, value: regionName);
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
            await getforecastModelsForRegionAndDate(region.name!, dates[i]);
        region.addForecastModelsForDate(
            forecastModels, dates[i], printdates[i]);
      } catch (error, stackTrace) {
        logger.e(stackTrace);
      }
    }
    return new Future<Region>.value(region);
  }

  // Date in yyyy-mm-dd format
  Future<ForecastModels> getforecastModelsForRegionAndDate(
          String regionName, String date) async =>
      await _raspClient.getForecastModels(regionName, date);

  /// Get the list of forecasts that are generated.
  /// Note we use a customized list held locally.
  Future<List<Forecast>> getForecastList() async {
    /// Retrieves a list of forecast types
    try {
      var forecastList = await _getCustomForecastList();
      if (!forecastList.isEmpty) {
        return forecastList;
      } else {
        return await _getForecastListFromAssets();
      }
    } catch (error, stackTrace) {
      logger.e(stackTrace);
      return <Forecast>[];
    }
  }

  Future<List<Forecast>> _getForecastListFromAssets() async {
    final json = await DefaultAssetBundle.of(_context!)
        .loadString('assets/json/forecast_options.json');
    ForecastTypes forecastTypes = forecastTypesFromJson(json);
    return forecastTypes.forecasts;
  }

  Future<List<Forecast>> _getCustomForecastList() async {
    final forecasts = <Forecast>[];
    final jsonString =
        await getGenericString(key: FORECAST_LIST, defaultValue: "");
    if (jsonString.isNotEmpty) {
      final forecastTypes = forecastTypesFromJson(jsonString);
      forecasts.addAll(forecastTypes.forecasts);
    }
    return forecasts;
  }

  Future<bool> deleteCustomForecastList() async {
    return await _deleteGenericString(key: FORECAST_LIST);
  }

  Future<bool> saveForecasts(List<Forecast> forecasts) async {
    final jsonForecasts =
        forecastTypesToJson(ForecastTypes(forecasts: forecasts));
    return await saveGenericString(key: FORECAST_LIST, value: jsonForecasts);
  }

  /**
   * Get point forecast for specific lat/long
   *
   * @param region       - e.g. NewEngland
   * @param date    - eg 2022-04-17
   * @param model        - e.g. GFS
   * @param time   - eg 1200
   * @param lat
   * @param lon
   * @param forecastType - a space separated list of forecast types
   * @return
   */
  Future<HttpResponse> getLatLngForecast(String region, String date,
      String model, String time, String lat, String lon, String forecastType) {
    final String contentType = "application/x-www-form-urlencoded";
    return _raspClient.getLatLongPointForecast(
        contentType, region, date, model, time, lat, lon, forecastType);
  }

  Future<double> getForecastOverlayOpacity() async {
    return await getGenericDouble(
        key: FORECAST_OVERLAY_OPACITY, defaultValue: 50);
  }

  Future<void> setForecastOverlayOpacity(double forecastOverlayOpacity) async {
    await saveGenericDouble(
        key: FORECAST_OVERLAY_OPACITY, value: forecastOverlayOpacity);
  }

  dispose() {
    // TODO what do I need to do here?
  }

  // ----------- Get RASP forecast images -----------------------
  Future<SoaringForecastImage> getRaspForecastImageByUrl(
      SoaringForecastImage soaringForecastImage) async {
    String fullUrl = Constants.RASP_BASE_URL + soaringForecastImage.imageUrl;
    File file = await ImageCacheManager().getSingleFile(fullUrl);
    //logger.d("Downloading forecast image: $fullUrl");
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

  //--------  Floor -----------------------------------------------------------------------
  // Set up Floor database
  Future<AppDatabase> makeDatabaseAvailable() async {
    if (_appDatabase == null) {
      logger.d('App database being created');
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

  Future<List<Turnpoint>> getTurnpointsWithinBounds(
      LatLngBounds latLngBounds) async {
    await makeDatabaseAvailable();
    return _appDatabase!.turnpointDao.getTurnpointsWithinBounds(
        latLngBounds.southWest!.latitude,
        latLngBounds.southWest!.longitude,
        latLngBounds.northEast!.latitude,
        latLngBounds.northEast!.longitude);
  }

  Future<List<Turnpoint>> findTurnpoints(String query) async {
    await makeDatabaseAvailable();
    return _appDatabase!.turnpointDao.findTurnpoints('%' + query + '%');
  }

  // Download a file to the downloads directory
  // from https://fluttercorner.com/how-to-download-file-from-url-and-save-in-local-storage-in-flutter/
  Future<String> downloadFile(String url, String fileName, String dir) async {
    HttpClient httpClient = new HttpClient();
    File file;
    String filePath = '';
    String myUrl = '';

    try {
      myUrl = url + '/' + fileName;
      var request = await httpClient.getUrl(Uri.parse(myUrl));
      var response = await request.close();
      if (response.statusCode == 200) {
        var bytes = await consolidateHttpClientResponseBytes(response);
        filePath = '$dir/$fileName';
        file = File(filePath);
        await file.writeAsBytes(bytes);
      } else
        filePath = 'Error code: ' + response.statusCode.toString();
    } catch (ex) {
      filePath = 'Can not fetch url';
    }

    return filePath;
  }

  Future<Turnpoint?> getTurnpointByCode(String code) async {
    await makeDatabaseAvailable();
    return _appDatabase!.turnpointDao.getTurnpointByCode(code);
  }

  Future<Color> getColorForTurnpoint(String turnpointCode) async {
    Turnpoint? turnpoint = await getTurnpointByCode(turnpointCode);
    return (turnpoint != null)
        ? TurnpointUtils.getColorForTurnpointIcon(turnpoint.style)
        : Colors.red;
  }

  //------  Selected turnpoint files available from turnpoint exchange ------
  Future<List<TurnpointFile>> getListOfTurnpointExchangeRegionFiles() async {
    List<TurnpointRegion> turnpointRegionList = [];
    var stringJson = await _raspOptionsClient.getTurnpointRegions();
    TurnpointRegions turnpointRegions =
        TurnpointRegions.fromJson(jsonDecode(stringJson));
    if (turnpointRegions != null) {
      turnpointRegionList.addAll(turnpointRegions.turnpointRegions!);
    }
    String selectedRegion = await getGenericString(
        key: SELECTED_REGION, defaultValue: DEFAULT_SELECTED_REGION);
    return turnpointRegionList
        .firstWhere((region) => region.region == selectedRegion)
        .turnpointFiles;
  }

  // eg from https://soaringweb.org/TP/Sterling/Sterling,%20Massachusetts%202021%20SeeYou.cup
  Future<List<Turnpoint>> importTurnpointsFromTurnpointExchange(
      String endUrl) async {
    List<Turnpoint> turnpoints = [];
    turnpoints.addAll(
        await TurnpointsImporter.getTurnpointsFromTurnpointExchange(endUrl));
    var ids = await insertAllTurnpoints(turnpoints);
    logger.d("Number turnpoints downloaded: ${ids.length}");
    return turnpoints;
  }

  Future<List<Turnpoint>> importTurnpointsFromFile(File turnpointFile) async {
    List<Turnpoint> turnpoints = [];
    turnpoints
        .addAll(await TurnpointsImporter.getTurnpointsFromFile(turnpointFile));
    var ids = await insertAllTurnpoints(turnpoints);
    logger.d("Number turnpoints downloaded: ${ids.length}");
    return turnpoints;
  }

  Future<Turnpoint?> getTurnpoint(String title, String code) async {
    await makeDatabaseAvailable();
    return _appDatabase!.turnpointDao.getTurnpoint(title, code);
  }

  Future<Turnpoint?> getTurnpointById(int turnpointId) async {
    await makeDatabaseAvailable();
    return _appDatabase!.turnpointDao.getTurnpointById(turnpointId);
  }

  Future<int?> saveTurnpoint(Turnpoint turnpoint) async {
    await makeDatabaseAvailable();
    return _appDatabase!.turnpointDao.insert(turnpoint);
  }

  Future<int?> updateTurnpoint(Turnpoint turnpoint) async {
    await makeDatabaseAvailable();
    return _appDatabase!.turnpointDao.update(turnpoint);
  }

  Future<int?> deleteTurnpoint(int id) async {
    await makeDatabaseAvailable();
    return _appDatabase!.turnpointDao.deleteTurnpoint(id);
  }

  /// Get the types of valid cup styles
  /// Note we use a customized list held locally.
  Future<List<CupStyle>> getCupStyles() async {
    final List<CupStyle> cupListStyles = [];
    try {
      final json = DefaultAssetBundle.of(_context!)
          .loadString('assets/json/turnpoint_styles.json');
      CupStyles cupStyles = cupStylesFromJson(await json);
      cupListStyles.addAll(cupStyles.styles);
    } catch (error, stackTrace) {
      logger.e(stackTrace);
    }
    return Future<List<CupStyle>>.value(cupListStyles);
  }

  // ----- Task ----------------------------------------

  Future<int?> getCountOfTasks() async {
    await makeDatabaseAvailable();
    int? count = Sqflite.firstIntValue(await _appDatabase!.database
        .rawQuery('select count(*) count from task'));
    return count ?? 0;
  }

  Future<List<Task>> getAlltasks() async {
    await makeDatabaseAvailable();
    return _appDatabase!.taskDao.listAllTasks();
  }

  Future<Task> getTask(int taskId) async {
    await makeDatabaseAvailable();
    Task? task = await _appDatabase!.taskDao.getTask(taskId);
    return task ?? Task();
  }

  Future<int?> saveTask(Task task) async {
    await makeDatabaseAvailable();
    return _appDatabase!.taskDao.insert(task);
  }

  Future<int> updateTask(Task task) async {
    await makeDatabaseAvailable();
    return _appDatabase!.taskDao.update(task);
  }

  Future<int?> deleteTask(int taskId) async {
    await makeDatabaseAvailable();
    return _appDatabase!.taskDao.deleteTask(taskId);
  }

  // -1 is no task defined
  Future<int> getCurrentTaskId() async {
    return getGenericInt(key: CURRENT_TASK_ID, defaultValue: -1);
  }

  // Set to -1 to clear task
  void setCurrentTaskId(int taskId) async {
    saveGenericInt(key: CURRENT_TASK_ID, value: taskId);
  }

  // ----- Task Turnpoints----------------------------------------

  Future<List<TaskTurnpoint>> getTaskTurnpoints(final int taskId) async {
    await makeDatabaseAvailable();
    return _appDatabase!.taskTurnpointDao.getTaskTurnpoints(taskId);
  }

  Future<int?> insertTaskTurnpoint(final TaskTurnpoint taskTurnpoint) async {
    await makeDatabaseAvailable();
    return _appDatabase!.taskTurnpointDao.insert(taskTurnpoint);
  }

  Future<int?> updateTaskTurnpoint(final TaskTurnpoint taskTurnpoint) async {
    await makeDatabaseAvailable();
    return _appDatabase!.taskTurnpointDao.update(taskTurnpoint);
  }

  Future<int?> deleteTaskTurnpoint(final int taskTurnpointId) async {
    await makeDatabaseAvailable();
    return _appDatabase!.taskTurnpointDao.deleteTaskTurnpoint(taskTurnpointId);
  }

  //-------- Map Display Options ----------------------------------------
  Future<List<PreferenceOption>> getRaspDisplayOptions() async {
    List<PreferenceOption> displayOptions = [];
    for (var option in raspDisplayOptions) {
      final isSelected =
          await getGenericBool(key: option.key, defaultValue: false);
      displayOptions.add(PreferenceOption(
          key: option.key,
          displayText: option.displayText,
          selected: isSelected));
    }
    ;
    return displayOptions;
  }

  FutureOr<void> saveRaspDisplayOptions(
      List<PreferenceOption> displayOptions) async {
    raspDisplayOptions.forEach((option) async {
      saveRaspDisplayOption(option);
    });
  }

  FutureOr<void> saveRaspDisplayOption(PreferenceOption option) async {
    await saveGenericBool(key: option.key, value: option.selected);
  }

  // ---- USGS calls --------------------------------------------------
  Future<NationalMap> getElevationAtLatLongPoint(
      double latitude, double longitude) {
    if (_usgsClient == null) {
      _usgsClient = UsgsClient(_dio);
    }
    return _usgsClient!.getElevation(
        latitude.toStringAsFixed(6), longitude.toStringAsFixed(6), "Feet");
  }

  // ------- Special Use Airspace ----------------------

  /**
   * The process to retrieve/display an SUA for the region is
   * 1. See if SUA file already downloaded for region
   * 2. If so, pass on the GeoJson object
   * 3. In any case, get the lastest SUA info from the server
   * 4. If SUA file was available and the file name matches that of the
   * server, it means the file is still most current so stop here
   * 5. If SUA file not available OR the SUA file is no longer current (an updated file is on server)
   * a. download the new file
   * b. if successful download delete the old (if it existed)
   * c. Emit updated GeoJson object
   *
   * @param region
   */

  Future<SUA?> getSuaForRegion(String region) async {
    String? suaString = null;
    SUA? sua = null;
    // See if SUA on device and send it if found
    String? oldSuaFilename = await _seeIfRegionSuaFileExists(region);
    if (oldSuaFilename != null) {
      suaString = await _readAppDocFile(oldSuaFilename);
      logger.d("Found existing sua file $oldSuaFilename in app directory");
      sua = SUA.fromJson(json.decode(suaString));
    } else {
      logger.d("No sua file related to region $region found in app directory");
    }
    // Now see if newer SUA available
    var suaRegionsString = await _raspOptionsClient.getSUARegions();
    if (suaRegionsString != null) {
      SUARegionFiles? suaRegionFiles =
          SUARegionFiles.fromJson(jsonDecode(suaRegionsString));
      try {
        String? suaFileName = suaRegionFiles.suaRegions
            .singleWhere(
              (suaRegion) => suaRegion.region == region,
            )
            .suaFileName;
        if (oldSuaFilename == null ||
            (oldSuaFilename != null &&
                !(oldSuaFilename).endsWith(region + '_' + suaFileName))) {
          logger.d(
              "Need to get SUA file from server (no sua on device or new file available");
          // so get details from server
          suaString = await _raspOptionsClient.downloadSuaFile(suaFileName);
          // and if OK save them to file
          if (suaString != null) {
            sua = SUA.fromJson(json.decode(suaString));
            File file = await _writeStringToAppDocsFile(
                region + '_' + suaFileName, suaString);
            // and delete the old file
            if (oldSuaFilename != null) {
              await _deleteFileFromAppDocsDirectory(oldSuaFilename);
            }
          }
        }
      } catch (e) {
        // some error maybe no SUA files, or region not in list of sua files
        // ignoring
        logger.d("Exception when getting sua file: ${e.toString()}");
      }
      if (sua != null) {
        logger.d("returning sua: ${sua.type!.toString()}");
      } else {
        logger.d("No SUA found");
      }
      return sua;
    }
  }

  bool equalsIgnoreCase(String string1, String string2) {
    return string1.toLowerCase() == string2.toLowerCase();
  }

  Future<String> _getAppDocsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getAppDocsFile(String fileName) async {
    final path = await _getAppDocsPath();
    return File(path + '/' + fileName);
  }

  Future<String> _readAppDocFile(String fileName) async {
    try {
      final file = await _getAppDocsFile(fileName);
      // Read the file
      final contents = await file.readAsStringSync();
      return contents;
    } catch (e) {
      logger.d("Error reading $fileName");
      return "";
    }
  }

  Future<File> _writeStringToAppDocsFile(String filename, String data) async {
    final file = await _getAppDocsFile(filename);
    return file.writeAsString(data);
  }

  Future<String?> _seeIfRegionSuaFileExists(String region) async {
    String? fileName = null;
    RegExp fileEndsWith = RegExp(region + "_.+\.geojson");
    String path = await _getAppDocsPath();
    final dir = Directory(path);
    final List<FileSystemEntity?> files = await dir.list().toList();
    try {
      fileName = basename(files
          .singleWhere(
              (file) => file is File && fileEndsWith.hasMatch(file.path),
              orElse: () => null)!
          .path);
      // logger.d("SUA file found: $fileName");
    } catch (e) {
      // may get Bad State: No element execption if no file found. We ignore exception
    }
    return fileName;
  }

  Future<void> _deleteFileFromAppDocsDirectory(String filename) async {
    final file = await _getAppDocsFile(filename);
    await file.delete();
  }

  //-------------- Methods for Windy options  -----------------------------------

  Future<String> getWindyKey() async {
    return windyKey;
  }

  Future<List<WindyModel>> getWindyModels() async {
    final list = <WindyModel>[];
    final string = await rootBundle.loadString('assets/txt/windy_model.txt');
    string.split("\n").forEach((element) {
      list.add(WindyModel(element));
    });
    return list;
  }

  Future<List<WindyLayer>> getWindyLayers() async {
    final list = <WindyLayer>[];
    final string = await rootBundle.loadString('assets/txt/windy_layer.txt');
    string.split("\n").forEach((element) {
      list.add(WindyLayer(element));
    });
    return list;
  }

  Future<List<WindyAltitude>> getWindyAltitudes() async {
    final list = <WindyAltitude>[];
    final string = await rootBundle.loadString('assets/txt/windy_altitude.txt');
    string.split("\n").forEach((element) {
      list.add(WindyAltitude(element));
    });
    return list;
  }

  Future<String> getCustomWindyHtml() async {
    return await rootBundle.loadString('assets/html/windy.html');
  }

  // -----  NOAA Satellite settings --------------------
  Future<List<SatelliteType>> getNoaaSatelliteTypes() async {
    final list = <SatelliteType>[];
    final string =
        await rootBundle.loadString('assets/txt/noaa_satellite_type.txt');
    string.split("\n").forEach((element) {
      list.add(SatelliteType(element));
    });
    return list;
  }

  // Hack - Need to call getNoaaSatelliteRegions before calling this
  Future<SatelliteType> getSelectedNoaaSatelliteType() async {
    return SatelliteType(await getGenericString(
        key: SATELLITE_TYPE, defaultValue: satelliteTypeVis));
  }

  // Hack - Need to call getNoaaSatelliteRegions before calling this
  void saveSelectedNoaaSatelliteType(SatelliteType satelliteType) async {
    await saveGenericString(
        key: SATELLITE_TYPE, value: satelliteType.toStore());
  }

  Future<List<SatelliteRegion>> getNoaaSatelliteRegions() async {
    final list = <SatelliteRegion>[];
    final string =
        await rootBundle.loadString('assets/txt/noaa_satellite_region.txt');
    string.split("\n").forEach((element) {
      list.add(SatelliteRegion(element));
    });
    satelliteRegionUS =
        list.singleWhere((element) => element.code == "us").toStore();
    return list;
  }

  // Hack - Need to call getNoaaSatelliteRegions before calling this
  Future<SatelliteRegion> getSelectedNoaaSatelliteRegion() async {
    return SatelliteRegion(await getGenericString(
        key: SATELLITE_REGION, defaultValue: satelliteRegionUS));
  }

  // Hack - Need to call getNoaaSatelliteRegions before calling this
  void saveSelectedNoaaSatelliteRegion(SatelliteRegion satelliteRegion) async {
    await saveGenericString(
        key: SATELLITE_REGION, value: satelliteRegion.toStore());
  }

  // ----- Shared preferences --------------------------
  // Make sure keys are unique among calling routines!

  Future<bool> saveGenericString(
      {required String key, required String value}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString(key, value);
  }

  Future<String> getGenericString(
      {required String key, required String defaultValue}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.getString(key) ?? defaultValue;
  }

  Future<bool> _deleteGenericString({required String key}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.remove(key);
  }

  Future<bool> saveGenericInt({required String key, required int value}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setInt(key, value);
  }

  Future<int> getGenericInt(
      {required String key, required int defaultValue}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? defaultValue;
  }

  Future<bool> saveGenericDouble(
      {required String key, required double value}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setDouble(key, value);
  }

  Future<double> getGenericDouble(
      {required String key, required double defaultValue}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.getDouble(key) ?? defaultValue;
  }

  Future<bool> saveGenericBool(
      {required String key, required bool value}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(key, value);
  }

  Future<bool> getGenericBool(
      {required String key, required bool defaultValue}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.getBool(key) ?? defaultValue;
  }
}
