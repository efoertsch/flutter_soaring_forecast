import 'package:drift/native.dart';
import 'package:flutter_soaring_forecast/soaring/airport/download/airports_downloader.dart';
import 'package:flutter_soaring_forecast/soaring/drift/app_database.dart' show AppDatabase;
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  late AppDatabase appDatabase;
  setUp(() {
    // Create a fresh in-memory database before each test
    appDatabase = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() async {
    // Close the database after each test
    await appDatabase.close();
  });
  test('AirportsDownloader.getAirportsCSV returns List<List<dynamic>>',
      () async {
    expect(
        (await AirportsDownloader(repository: Repository(null, appDatabase))
                    .getAirportsCSV())
                .length >
            0,
        true);
  });

  test(
      'AirportsDownloader.getDownloadedListOfAirports() returns  List<Airport>',
      () async {
    expect(await Repository(null, appDatabase).getCountOfAirports(), 0);
  });
}
