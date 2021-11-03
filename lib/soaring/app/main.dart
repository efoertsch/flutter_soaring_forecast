import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_soaring_forecast/soaring/airport_download/airports_downloader.dart';
import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/values/strings.dart';
import 'package:workmanager/workmanager.dart';

import 'main_screen.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    print('Checking to download airports');
    var ok = AirportsDownloader(repository: Repository(null))
        .downloadAirportsIfNeeded();
    print('AirportsDownloader response : $ok');
    return Future.value(ok);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Workmanager().initialize(
  //     callbackDispatcher, // The top level function, aka callbackDispatcher
  //     isInDebugMode:
  //         true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
  //     );
  //Workmanager().registerOneOffTask("1", "airportsDownload");
  runApp(SoaringForecastApp());
}

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
