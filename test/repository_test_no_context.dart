import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import "package:flutter_test/flutter_test.dart";
import 'package:mockito/mockito.dart';

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MockBuildContext _mockContext;

  _mockContext = MockBuildContext();

  Repository repository = Repository(_mockContext);

  test("Get current.json", () async {
    repository.getRegions().then(expectAsync1((regions) =>
        //expect(regions.regions.length,2)
        print("Regions: ${regions.regions!.length}")));
  });

  getPrintDatesForFirstRegion(Region region) async {
    print("getting modelforecasts for ${region.name}");
    repository.loadForecastModelsByDateForRegion(region).then(expectAsync1(
        (region) => expect(
            region.getModelDates().first.getModelDateDetailList().length, 7,
            reason: "Number of forecast dates should be 6")));
  }

  test("Get forecastModels for each printdate in region", () async {
    repository.getRegions().then(expectAsync1(
        (regions) => getPrintDatesForFirstRegion(regions.regions![0])));
  });

  test("Get forecast types", () async {
    repository
        .getDisplayableForecastList()
        .then(expectAsync1((forecasts) => expect(forecasts.length, 43)));
    //print(foreastTypes.toString())))
  });

  test("Get list of glider polars", () async {
    repository.getDefaultListOfGliders().then(expectAsync1((gliderList) => expect(gliderList?.length ,166)));
  });
}
