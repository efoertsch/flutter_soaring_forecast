import 'package:csv/csv.dart';
import 'package:flutter_soaring_forecast/soaring/airport_download/airport_csv.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:http/http.dart' as http;

class AirportsDownloader {
  static Future<List<Airport_CSV>> getDownloadedListOfAirports() async {
    var listofAirports = <Airport_CSV>[];
    var goodHeaderRow = false;
    var count = 0;
    var maybeBadRow;
    try {
      var parsedAirportList = await AirportsDownloader.getAirportsCSV();
      for (var row in parsedAirportList) {
        if (count == 0) {
          goodHeaderRow = checklabels(row);
        }
        if (count > 0 &&
            row.length > 10 &&
            row[2] != 'closed' &&
            row[8].toString().trim() == 'US') {
          var airport = Airport_CSV.fromList(row);
          maybeBadRow = airport;
          listofAirports.add(airport);
        } else {
          print('bypassing airport row:  $row.toString()}');
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

  static Future<List<List<dynamic>>> getAirportsCSV() async {
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
  static bool checklabels(List row) {
    return (row[1].toString().toLowerCase() == 'ident' &&
        row[2].toString().toLowerCase() == 'type' &&
        row[3].toString().toLowerCase() == 'name' &&
        row[4].toString().toLowerCase() == 'latitude_deg' &&
        row[5].toString().toLowerCase() == 'longitude_deg' &&
        row[6].toString().toLowerCase() == 'elevation_ft' &&
        row[9].toString().toLowerCase() == 'iso_region' &&
        row[10].toString().toLowerCase() == 'municipality');
  }
}
