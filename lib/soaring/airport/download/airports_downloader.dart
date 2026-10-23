import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:http/http.dart' as http;

import '../../drift/app_database.dart';

enum DownloadState { not_started, downloaded, being_processed, completed }

class AirportsDownloader {
  String AIRPORT_DOWNLOAD_STATE = 'AIRPORT_DOWNLOAD_STATE';
  String NUMBER_AIRPORTS_PROCESSED = 'NUMBER_AIRPORTS_PROCESSED';
  String NUMBER_OF_AIRPORTS_PROCESSED = 'NUMBER_OF_AIRPORTS_PROCESSED';

  int _IDENT = -1;
  int _TYPE = -1;
  int _NAME = -1;
  int _LATITUDE_DEG = -1;
  int _LONGITUDE_DEG = -1;
  int _ELEVATION_FT = -1;
  int _ISO_COUNTRY = -1;
  int _ISO_REGION = -1;
  int _MUNICIPALITY = -1;

  late Repository repository;

  AirportsDownloader({required this.repository});

  Future<bool> downloadAirportsIfNeeded() async {
    final numberAirports = await repository.getCountOfAirports();
    if (numberAirports < 2000) {
      debugPrint('Too few airports in database so trying again');
      return await downloadAirports();
    } else {
      // Assume prior download worked successfully
      debugPrint(
        'Number of airports in database: $numberAirports. '
        'Assuming prior download worked ok',
      );
      return true;
    }
  }

  Future<bool> downloadAirports() async {
    var listOfAirports = await getDownloadedListOfAirports();
    int totalUSAirportsDownloaded = listOfAirports.length;
    debugPrint(
      'Total number of US airports downloaded: $totalUSAirportsDownloaded',
    );
    try {
      if (listOfAirports.length > 0) {
        await repository.deleteAllAirports();
        debugPrint("Deleted all airports from database");
      }
      var totalInserted = await repository.insertAllAirports(listOfAirports);
      debugPrint('Number airports inserted : $totalInserted');
      return (totalUSAirportsDownloaded == totalInserted && totalInserted > 0);
    } catch (e, s) {
      debugPrint('Error inserting airports into database: $e');
      debugPrint('Stacktrace: $s');
      return false;
    }
  }

  Future<List<Airport>> getDownloadedListOfAirports() async {
    var listofAirports = <Airport>[];
    var goodHeaderRow = false;
    var count = 0;
    var maybeBadRow;
    try {
      var parsedAirportList = await getAirportsCSV();
      for (var row in parsedAirportList) {
        if (count == 0) {
          goodHeaderRow = checklabels(row);
        }
        if (count > 0 &&
            goodHeaderRow &&
            row.length > 10 &&
            row[_TYPE] != 'closed' &&
            row[_ISO_COUNTRY].toString().trim() == 'US') {
          var airport = fromList(row);
          maybeBadRow = airport;
          listofAirports.add(airport);
        } else {
          // debugPrint('bypassing airport row:  $row}');
        }
        ++count;
      }
    } catch (e, s) {
      debugPrint('Maybe bad row: ${maybeBadRow.toString()}');
      debugPrint('Exception $e');
      debugPrint('Stacktrace $s');
    }
    return listofAirports;
  }

  Future<List<List<dynamic>>> getAirportsCSV() async {
    try {
      debugPrint('Getting airports from ${Constants.AIRPORT_URL}');
      final response = await http.get(Uri.parse(Constants.AIRPORT_URL));
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the CSV.
        List<List<dynamic>> rowsAsListOfValues = csv.decode(response.body);
        // for (var row in rowsAsListOfValues) {
        //   for (var value in row) {
        //     debugPrint(value);
        //   }
        //   break;
        // }
        return rowsAsListOfValues;
      } else {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        throw Exception(
          'AirportsDownloader.getAirportsCSV(). Failed to download and/or parse airports.csv file',
        );
      }
    } catch (e, s) {
      debugPrint('Error getting airports from ${Constants.AIRPORT_URL}');
      debugPrint('Exception $e');
      debugPrint('Stacktrace $s');
      throw Exception(
        'AirportsDownloader.getAirportsCSV(). Failed to download and/or parse airports.csv file',
      );
    }
  }

  // make sure first row is labels and order is correct
  bool checklabels(List row) {
    _IDENT = getColumnNumber(row, 'ident');
    _TYPE = getColumnNumber(row, 'type');
    _NAME = getColumnNumber(row, 'name');
    _LATITUDE_DEG = getColumnNumber(row, 'latitude_deg');
    _LONGITUDE_DEG = getColumnNumber(row, 'longitude_deg');
    _ELEVATION_FT = getColumnNumber(row, 'elevation_ft');
    _ISO_COUNTRY = getColumnNumber(row, 'iso_country');
    _ISO_REGION = getColumnNumber(row, 'iso_region');
    _MUNICIPALITY = getColumnNumber(row, 'municipality');
    return (_IDENT >= 0 &&
        _TYPE >= 0 &&
        _NAME >= 0 &&
        _LATITUDE_DEG >= 0 &&
        _LONGITUDE_DEG >= 0 &&
        _ELEVATION_FT >= 0 &&
        _ISO_COUNTRY >= 0 &&
        _ISO_REGION >= 0 &&
        _MUNICIPALITY >= 0);
  }

  int getColumnNumber(List row, String columnName) {
    int columNumber = row.indexOf(columnName);
    return columNumber;
  }

  Airport fromList(List<dynamic> list) => Airport(
    id: -1,
    ident: list[_IDENT],
    type: list[_TYPE],
    name: list[_NAME],
    latitudeDeg: (num.tryParse(list[_LATITUDE_DEG]) != null)
        ? num.parse(list[_LATITUDE_DEG]).toDouble()
        : 0.0,
    longitudeDeg: (num.tryParse(list[_LONGITUDE_DEG]) != null)
        ? num.parse(list[_LONGITUDE_DEG]).toDouble()
        : 0.0,
    elevationFt: (num.tryParse(list[_ELEVATION_FT]) != null)
        ? num.parse(list[_ELEVATION_FT]).toInt()
        : 0,
    state: list[_ISO_REGION].toString().length > 3
        ? list[_ISO_REGION].toString().substring(3)
        : list[_ISO_REGION].toString(),
    municipality: list[_MUNICIPALITY],
  );

  //---- started but then discarded. Maybe use for the future if can't
  // download and process airports in one gulp

  //     Future<void> getAirportDownloadState() async {
  //       var state = await repository.getGenericString(
  //           AIRPORT_DOWNLOAD_STATE, DownloadState.not_started.toString());
  //       DownloadState enum_state = convertDownloadStringToState(state);
  //       switch (enum_state) {
  //         case DownloadState.not_started:
  //           downloadAirportFile();
  //           //TODO download file
  //           break;
  //         case DownloadState.downloaded:
  //         // TODO process file
  //           break;
  //         case DownloadState.being_processed:
  //         // TODO process file
  //           break;
  //
  //         case DownloadState.completed:
  //         // TODO don't need to do anything! Woohoo!
  //           break;
  //       }
  //     }
  //
  //     DownloadState convertDownloadStringToState(String state) {
  //       return DownloadState.values
  //           .firstWhere((e) => e.toString() == 'DownloadState.' + state);
  //     }
  //
  //     Future<bool> saveAirportDownloadStatus(DownloadState state) async {
  //       SharedPreferences prefs = await SharedPreferences.getInstance();
  //       return prefs.setString(AIRPORT_DOWNLOAD_STATE, state.toString());
  //     }
  //
  // // get/save number of airports processed in download file
  //     Future<int> getNumberOfAirportsProcessed() async {
  //       return repository.getGenericInt(NUMBER_AIRPORTS_PROCESSED, 0);
  //     }
  //
  //     Future<bool> saveNumberOfAirportsProcessed(int count) async {
  //       return repository.saveGenericInt(NUMBER_AIRPORTS_PROCESSED, count);
  //     }
  //
  //     Future<String> get _localPath async {
  //       final directory = await getApplicationDocumentsDirectory();
  //       return directory.path;
  //     }
  //
  //     Future<File> get _localFile async {
  //       final path = await _localPath;
  //       return File('$path/airports.csv');
  //     }
  //     void processDownloadedFile(File filename, startProcessingAt) async {
  //       var csvConverter = CsvToListConverter(
  //         eol: '\n',
  //       );
  //       Stream<String> lines = filename
  //           .openRead()
  //           .transform(utf8.decoder) // Decode bytes to UTF-8.
  //           .transform(LineSplitter()); // Convert stream to individual lines.
  //       try {
  //         await for (var line in lines) {
  //           debugPrint('$line: ${line.length} characters');
  //         }
  //         debugPrint('File is now closed.');
  //       } catch (e) {
  //         debugPrint('Error: $e');
  //       }
  //     }
  //
  //     Future<bool> downloadAirportFile() async {
  //       var csv_file = await _localFile;
  //       var dio = Dio();
  //       var response = await dio.download(Constants.AIRPORT_URL, csv_file,
  //           deleteOnError: true);
  //       debugPrint("airports.csv download response : ${response.statusCode}");
  //       return (response.statusCode == 200);
  //     }
  //
  //     Future<void> processAirportsFile(File airportFile, int startAt) async {
  //       var csvConverter = CsvToListConverter(
  //         eol: '\n',
  //       );
  //       int lineNumber = 1;
  //       Stream<String> lines = airportFile
  //           .openRead()
  //           .transform(utf8.decoder) // Decode bytes to UTF-8.
  //           .transform(LineSplitter()); // Convert stream to individual lines.
  //       try {
  //         await for (var line in lines) {
  //           debugPrint('$line: ${line.length} characters');
  //           if (lineNumber > startAt) {
  //             processAirport(csvConverter.convert(line));
  //           }
  //           lineNumber++;
  //         }
  //         debugPrint('File is now closed.');
  //       } catch (e) {
  //         debugPrint('Error: $e');
  //       }
  //     }
}
