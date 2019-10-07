import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:flutter_soaring_forecast/soaring/json/regions.dart';

class Repository {
  static Repository repository;
  static Dio dio = Dio();
  static BuildContext _context;
  static RaspClient raspClient;

  Repository._();

  factory Repository(BuildContext context) {
    if (repository == null) {
      repository = Repository._();
      _context = context;
      dio.interceptors.add(LogInterceptor(responseBody: true));
      raspClient = new RaspClient(dio);
    }
    return repository;
  }

  //  get the list of forecast regions (e.g. NewEngland, Mifflin) and forecast dates, etc for each region
  Future<Regions> getCurrentJson() async {
    return raspClient.getRegions();
  }

  dispose(){
    // what do I need to do here
  }
}
