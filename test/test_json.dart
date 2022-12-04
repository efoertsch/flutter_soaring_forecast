import 'dart:convert';

import 'package:flutter_soaring_forecast/soaring/repository/rasp/view_bounds.dart';
import 'package:flutter_test/flutter_test.dart';

main() {
  var jsonString =
      '{"swLat": "45.1","swLng": "-70.0","neLat": "47.2","neLng": "-65.0"}';

  test('SerializableLatLngBounds', () {
    Map<String, dynamic> jsonObject = json.decode(jsonString);
    var mapBoundsAndZoom = ViewBounds.fromJson(jsonObject);
    print("${mapBoundsAndZoom.latLngBounds.north}");
    expect(mapBoundsAndZoom.latLngBounds.north == 47.23, true);
  });
}
