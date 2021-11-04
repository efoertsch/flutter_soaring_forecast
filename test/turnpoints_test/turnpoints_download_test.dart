import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoints_downloader.dart';
import 'package:test/test.dart';

void main() {
  const testUrl = 'Sterling/Sterling, Massachusetts 2021 SeeYou.cup.txt';
  test('TurnpointsDownloader.getTurnpointsCSV returns List<List<dynamic>>',
      () async {
    List<List<dynamic>> turnpoinstCSV =
        await TurnpointsDownloader.getTurnpointsCSV(testUrl);
    expect(turnpoinstCSV.length > 0, true);
  });

  test(
      'TurnpointsDownloader.convertTurnpointCsvListToTurnpoints() returns  List<Turnpoint>',
      () async {
    List<List<dynamic>> turnpoinstCSV =
        await TurnpointsDownloader.getTurnpointsCSV(testUrl);
    expect(turnpoinstCSV.length > 0, true);
    List<Turnpoint> turnpoints =
        await TurnpointsDownloader.convertTurnpointCsvListToTurnpoints(
            turnpoinstCSV);
    expect(turnpoints.length > 0, true);
  });
}
