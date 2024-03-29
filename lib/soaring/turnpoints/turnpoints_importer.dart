import 'dart:collection';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoint_utils.dart';
import 'package:http/http.dart' as http;

class TurnpointsImporter {
  late Repository repository;
  static const TURNPOINTS_URL = "http://serkowski.com/soaring/TP/";  //"https://soaringweb.org/TP/";

  TurnpointsImporter({required this.repository});

  static Future<List<Turnpoint>> getTurnpointsFromTurnpointExchange(
      String turnpointUrl) async {
    List<List<dynamic>> parsedTurnpoints = await getTurnpointsCSV(turnpointUrl);
    return await convertTurnpointCsvListToTurnpoints(parsedTurnpoints);
  }

  static Future<List<Turnpoint>> getTurnpointsFromFile(
      File turnpointFile) async {
    String turnpointString = await turnpointFile.readAsString();
    if (turnpointString.indexOf('\r\n') == -1) {
      turnpointString = turnpointString.replaceAll('\n', '\r\n');
    }
    List<List<dynamic>> parsedTurnpoints = const CsvToListConverter(
      eol: '\r\n',
    ).convert(turnpointString);
    return await convertTurnpointCsvListToTurnpoints(parsedTurnpoints);
  }

  static Future<List<List<dynamic>>> getTurnpointsCSV(
      String turnpointUrl) async {
    final response = await http.get(Uri.parse(TURNPOINTS_URL + turnpointUrl));
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the CSV.
      var body = response.body;
      if (body.indexOf('\r\n') == -1) {
        body = body.replaceAll('\n', '\r\n');
      }
      List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter(
        eol: '\r\n',
      ).convert(body);
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
          'TurnpointsDownloader.getTurnpointsCSV(). Failed to download and/or parse turnpoints.csv file');
    }
  }

  static Future<List<Turnpoint>> convertTurnpointCsvListToTurnpoints(
      List<List<dynamic>> turnpointsCSV) async {
    List<Turnpoint> turnpoints = [];
    HashSet<String> turnpointCodes = new HashSet();
    SeeYouFormat seeYouFormat = SeeYouFormat.NOT_DEFINED;
    for (var i = 0; i < turnpointsCSV.length; i++) {
      if (i == 0) {
        seeYouFormat =
            TurnpointUtils.determineTurnpointFileFormat(turnpointsCSV[0]);
        if (seeYouFormat == SeeYouFormat.NOT_DEFINED)
          throw Exception(
              " Check Turnpoint File column order(row 1). It is a new column order not seen before. ");
      } else {
        //end of turnpoints in the file
        if (turnpointsCSV[i][0] == '-----Related Tasks-----') {
          break;
        }
        var turnpoint = TurnpointUtils.createTurnpointFromCSVDetail(
            turnpointsCSV[i], seeYouFormat);
        if (turnpoint != null) {
          // For turnpoints code/title must be unique
          if (!turnpointCodes.contains(turnpoint.code + turnpoint.title)) {
            // not a duplicate code/title
            turnpointCodes.add(turnpoint.code + turnpoint.title);
            turnpoints.add(turnpoint);
          } else {
            print('Duplicate turnpoint code/title' + turnpoint.toString());
          }
        }
      }
    }
    return turnpoints;
  }
}
