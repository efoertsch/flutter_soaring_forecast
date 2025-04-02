import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoints_importer.dart';
import 'package:test/test.dart';

void main() {
  const testUrl = 'Sterling/Sterling, Massachusetts 2021 SeeYou.cup.txt';
  var repository = Repository(null);
  test('TurnpointsDownloader.getTurnpointsCSV returns List<List<dynamic>>',
      () async {
    List<List<dynamic>> turnpoinstCSV = await getTurnpoinstCSV(testUrl);
    expect(turnpoinstCSV.length > 0, true);
  });

  test(
      'TurnpointsDownloader.convertTurnpointCsvListToTurnpoints() returns  List<Turnpoint>',
      () async {
    List<List<dynamic>> turnpoinstCSV = await getTurnpoinstCSV(testUrl);
    expect(turnpoinstCSV.length > 0, true);
    List<Turnpoint> turnpoints =
        await convertDynamicListToTurnpoints(turnpoinstCSV);
    expect(turnpoints.length > 0, true);
  });

  test('TurnpointsDownloader.insertAllTurnpoints)', () async {
    await repository.deleteAllTurnpoints();
    expect(await repository.getCountOfTurnpoints(), 0);
    List<List<dynamic>> turnpoinstCSV = await getTurnpoinstCSV(testUrl);
    expect(turnpoinstCSV.length > 0, true);
    List<Turnpoint> turnpoints =
        await convertDynamicListToTurnpoints(turnpoinstCSV);
    // turnpoints.forEach((turnpoint) async {
    //   var id = await repository.insertTurnpoint(turnpoint);
    //   debugPrint('turnpoint id $id');
    // });
    await Future.delayed(Duration(seconds: 1));
    //print('Number of turnpoints ${numberOfTurnpoints}');
    expect(await repository.getCountOfTurnpoints() > 0, true);
  });
}

Future<List<List<dynamic>>> getTurnpoinstCSV(String testUrl) async {
  return await TurnpointsImporter.getTurnpointsCSV(testUrl);
}

Future<List<Turnpoint>> convertDynamicListToTurnpoints(
    List<List<dynamic>> turnpoinstCSV) async {
  return await TurnpointsImporter.convertTurnpointCsvListToTurnpoints(
      turnpoinstCSV);
}
