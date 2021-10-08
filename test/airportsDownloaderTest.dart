import 'package:flutter_soaring_forecast/soaring/airport_download/airport_api.dart';
import 'package:test/test.dart';

void main() {
  test('AirportsDownloader.getAirportsCSV returns List<List<dynamic>>',
      () async {
    expect((await AirportsDownloader.getAirportsCSV()).length > 0, true);
  });

  test(
      'AirportsDownloader.getDownloadedListOfAirports() returns  List<Airport>',
      () async {
    expect((await AirportsDownloader.getDownloadedListOfAirports()).length > 0,
        true);
  });
}
