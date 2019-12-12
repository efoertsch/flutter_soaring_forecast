import 'package:flutter_soaring_forecast/soaring/json/regions.dart';
import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';
import "package:flutter_test/flutter_test.dart";

void main() {
  Repository repository = Repository(null);

  test("Get current.json", () async {
    repository.getRegions().then(expectAsync1((regions) =>
        //expect(regions.regions.length,2)
        print("Regions: ${regions.regions.length}")));
  });

  getPrintDatesForFirstRegion(Region region) async {
    print("getting modelforecasts for ${region.name}");
    repository.loadForecastModelsByDateForRegion(region).then(expectAsync1(
        (region) => expect(
            region.getForecastModels().length, region.printDates.length)));
  }

  test("Get forecastModels for each printdate in region", () async {
    repository.getRegions().then(expectAsync1(
        (regions) => getPrintDatesForFirstRegion(regions.regions[0])));
  });

  test("Get forecast types", () async {
    repository.getForecastTypes().then(expectAsync1(
        (forecastTypes) => expect(forecastTypes.forecasts.length, 43)));
    //print(foreastTypes.toString())))
  });
}
