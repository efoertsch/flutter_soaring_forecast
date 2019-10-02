import 'package:flutter_soaring_forecast/repository.dart';
import "package:flutter_test/flutter_test.dart";

void main()   {
  test("Get current.json", () {
    Repository repository = Repository();
    repository.getCurrentJson().then(expectAsync1((regions) {
     //print(regions.toJson().toString());
      expect(regions.regions.length, 2);
    }));
  });

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
}
