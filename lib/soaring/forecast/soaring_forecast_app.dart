import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/values/strings.dart';

import 'main_screen.dart';

void main() => runApp(SoaringForecastApp());

class SoaringForecastApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: Strings.appTitle,
        theme: ThemeData(
          // brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          primaryColor: Colors.blue,
        ),
        home: MainScreen());
  }
}
