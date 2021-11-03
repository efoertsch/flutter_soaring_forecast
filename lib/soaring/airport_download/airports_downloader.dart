import 'package:csv/csv.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:flutter_soaring_forecast/soaring/floor/airport.dart';
import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';
import 'package:http/http.dart' as http;

enum DownloadState { not_started, downloaded, being_processed, completed }

class AirportsDownloader {
  String AIRPORT_DOWNLOAD_STATE = 'AIRPORT_DOWNLOAD_STATE';
  String NUMBER_AIRPORTS_PROCESSED = 'NUMBER_AIRPORTS_PROCESSED';
  String NUMBER_OF_AIRPORTS_PROCESSED = 'NUMBER_OF_AIRPORTS_PROCESSED';

  late Repository repository;

  AirportsDownloader({required this.repository});

  Future<bool> downloadAirportsIfNeeded() async {
    var totalInserted = 0;
    var totalUSAirportsDownloaded = 0;

    var numberAirports = await repository.getCountOfAirports();
    if (numberAirports < 2000) {
      print('Too few airports in database so trying again');
      var listOfAirports = await getDownloadedListOfAirports();
      totalUSAirportsDownloaded = listOfAirports.length;
      print(
          'Total number of US airports downloaded: $totalUSAirportsDownloaded');
      if (listOfAirports.length > 0) {
        repository.deleteAllAirports();
        print("Deleted all airports from database");
      }
      var insertedResponse = await repository.insertAllAirports(listOfAirports);
      var totalInserted = insertedResponse.fold<int>(0, (previous, current) {
        print('airport insert result: $current');
        return previous + (current ?? 0);
      });

      print('Number airports inserted : $totalInserted');
      return (totalUSAirportsDownloaded == totalInserted && totalInserted > 0);
    } else {
      // Assume prior download worked successfully
      print('Number of airports in database: $numberAirports. '
          'Assuming prior download worked ok');
      return true;
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
            row.length > 10 &&
            row[2] != 'closed' &&
            row[8].toString().trim() == 'US') {
          var airport = Airport.fromList(row);
          maybeBadRow = airport;
          listofAirports.add(airport);
        } else {
          print('bypassing airport row:  $row}');
        }
        ++count;
      }
    } catch (e, s) {
      print('Maybe bad row: ${maybeBadRow.toString()}');
      print('Exception $e');
      print('Stacktrace $s');
    }
    return listofAirports;
  }

  Future<List<List<dynamic>>> getAirportsCSV() async {
    final response = await http.get(Uri.parse(Constants.AIRPORT_URL));
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the CSV.
      List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter(
        eol: '\n',
      ).convert(response.body);
      // for (var row in rowsAsListOfValues) {
      //   for (var value in row) {
      //     print(value);
      //   }
      //   break;
      // }
      return rowsAsListOfValues;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception(
          'AirportsDownloader.getAirportsCSV(). Failed to download and/or parse airports.csv file');
    }
  }

  // make sure first row is labels and order is correct
  bool checklabels(List row) {
    return (row[1].toString().toLowerCase() == 'ident' &&
        row[2].toString().toLowerCase() == 'type' &&
        row[3].toString().toLowerCase() == 'name' &&
        row[4].toString().toLowerCase() == 'latitude_deg' &&
        row[5].toString().toLowerCase() == 'longitude_deg' &&
        row[6].toString().toLowerCase() == 'elevation_ft' &&
        row[9].toString().toLowerCase() == 'iso_region' &&
        row[10].toString().toLowerCase() == 'municipality');
  }

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
//           print('$line: ${line.length} characters');
//         }
//         print('File is now closed.');
//       } catch (e) {
//         print('Error: $e');
//       }
//     }
//
//     Future<bool> downloadAirportFile() async {
//       var csv_file = await _localFile;
//       var dio = Dio();
//       var response = await dio.download(Constants.AIRPORT_URL, csv_file,
//           deleteOnError: true);
//       print("airports.csv download response : ${response.statusCode}");
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
//           print('$line: ${line.length} characters');
//           if (lineNumber > startAt) {
//             processAirport(csvConverter.convert(line));
//           }
//           lineNumber++;
//         }
//         print('File is now closed.');
//       } catch (e) {
//         print('Error: $e');
//       }
//     }

}
