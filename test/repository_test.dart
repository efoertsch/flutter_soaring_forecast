import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';
import "package:flutter_test/flutter_test.dart";


void main() {
  test("Get current.json", () async {

    Repository repository = Repository(null);

    repository.getCurrentJson().then(expectAsync1(
            (regions) =>
               expect(regions.regions.length,2)
                 //print("Regions: ${regions.regions.length}")
            ))
        ;
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
