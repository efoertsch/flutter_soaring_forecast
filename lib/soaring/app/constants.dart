library constants;

import 'dart:ui';

import 'package:flutter/material.dart';

/// Hold any system wide constants
const String BASE_URL = 'https://soargbsc.net/';
const String RASP_BASE_URL = BASE_URL + 'rasp/';
const String RASP_OPTIONS_BASE_URL = 'https://soargbsc.com/soaringforecast/';
const String AIRPORT_URL = 'http://ourairports.com/data/airports.csv';
enum ImageTypes { body, head, side, foot }

const String APP_DATABASE = 'app_database.db'; // Floor database name

class RaspMenu {
  static const String selectTask = 'SELECT TASK';
  static const String clearTask = 'Clear Task';
  static const String displayOptions = 'DisplayOptions';
  static const String mapBackground = 'Map Background';
  static const String orderForecasts = 'Order Forecasts';
  static const String opacity = 'Opacity';
  static const String selectRegion = 'Select Region';
}

class RaspDisplayOptionsMenu {
  static const String soundings = 'Soundings';
  static const String sua = 'Special Use Airspace';
  static const String turnpoints = 'Turnpoints';
}

class MapBackgroundMenu {
  static const String terrain = 'Terrain';
  static const String satellite = 'Satellite';
  static const String roadmap = 'Roadmap';
  static const String hybrid = 'Hybrid';
}

class TurnpointMenu {
  static const String searchTurnpoints = "Search";
  static const String importTurnpoints = 'Import Turnpoints';
  static const String addTurnpoint = 'Add Turnpoint';
  static const String exportTurnpoint = 'Export Turnpoint';
  static const String emailTurnpoint = 'Email Turnpoint';
  static const String clearTurnpointDatabase = 'Clear Turnpoint Database';
}

const textStyleBoldBlackFontSize20 =
    TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20);

const textStyleBoldBlack87FontSize15 =
    TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15);
