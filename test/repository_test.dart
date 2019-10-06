import 'package:logging/logging.dart';

import 'package:chopper/chopper.dart';
import 'package:flutter_soaring_forecast/soaring/json/rasp_api_service.dart';
import "package:flutter_test/flutter_test.dart";
import 'dart:convert';


void main() {

  test("Get current.json", () async
  {

    // Logger setup
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });


    RaspApiService raspApiService = RaspApiService.create();
    Future<Response< dynamic>> response = raspApiService.getCurrentJson();
     Response<dynamic> data = await response;
    final Map<String, dynamic> stuff = json.decode(data.bodyString);
     print(stuff.toString());
//    var dio = Dio();
//    dio.options.connectTimeout = 5000; //5s
//    dio.options.receiveTimeout = 3000000;
//
////    dio.interceptors.add(
////        LogInterceptor(request: true, requestBody: true, responseBody: true,));
//    final client = RestClient(dio);
    //var regions =  await client.getCurrentJson();
     //  print(regions.toString());

  });

}


