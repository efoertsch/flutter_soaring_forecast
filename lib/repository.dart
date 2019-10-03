import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter_soaring_forecast/soaring/json/regions.dart';

class Repository {

  //  get the list of forecast regions (e.g. NewEngland, Mifflin) and forecast dates, etc for each region
  Future<Regions> getCurrentJson() async {
    final response = await get('http://soargbsc.com/rasp/current.json');

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON.
      return Regions.fromJson(jsonDecode(response.body));
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to load post');
    }
  }


}
