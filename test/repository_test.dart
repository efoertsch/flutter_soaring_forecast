import 'package:flutter_soaring_forecast/soaring/json/regions.dart';
import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';
import "package:flutter_test/flutter_test.dart";


void main() {

  Repository repository = Repository(null);

  getPrintDatesForFirstRegion(Region region) async {
    await repository.getForecastModels(region) ;
    expect(region.forecastModels.length , region.printDates.length);

  }

  test("Get current.json", () async {
    repository.getRegions().then(expectAsync1(
            (regions) =>
               expect(regions.regions.length,2)
                 //print("Regions: ${regions.regions.length}")
            ))
        ;
  });

  test("Get forecastModels for each printdate in region", () async {
    repository.getRegions().then(expectAsync1(
            (regions) => getPrintDatesForFirstRegion(regions.regions[1])
    ));
  });

}



//
//  test("String.split() splits the string on the delimiter", () {
//    var string = "foo,bar,baz";
//    expect(string.split(","), equals(["foo", "bar", "baz"]));
//  });
//
//  test("String.trim() removes surrounding whitespace", () {
//    var string = "  foo ";
//    expect(string.trim(), equals("foo"));
//  });
