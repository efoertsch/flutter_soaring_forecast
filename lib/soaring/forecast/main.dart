import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/rasp.dart';
import 'package:logging/logging.dart';


void main() {
  _setUpLoggin();
  runApp(MyApp());
}

void _setUpLoggin(){
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((rec){
    print ('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

}


class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'RASP',
        theme: ThemeData(
          // brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          primaryColor: Colors.blue,
        ),
        home: RaspPage()
    );
  }
}



