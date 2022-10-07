import 'package:flutter_soaring_forecast/soaring/airport/download/airports_downloader.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:test/test.dart';

void main() {
  test('AirportsDownloader.getAirportsCSV returns List<List<dynamic>>',
      () async {
    expect(
        (await AirportsDownloader(repository: Repository(null))
                    .getAirportsCSV())
                .length >
            0,
        true);
  });

  test(
      'AirportsDownloader.getDownloadedListOfAirports() returns  List<Airport>',
      () async {
    expect(await Repository(null).getCountOfAirports(), 0);
  });
}
