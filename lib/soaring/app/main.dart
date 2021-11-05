import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/airport_download/airports_downloader.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/rasp_screen.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_search.dart';
import 'package:flutter_soaring_forecast/soaring/values/strings.dart';
import 'package:workmanager/workmanager.dart';

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
  runApp(MainScreen());
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => Repository(context),
      child: SoaringForecastApp(),
    );
  }
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
        initialRoute: '/',
        routes: {
          '/': (context) => SoaringForecast(),
          '/searchturnpoints': (context) => TurnpointSearch(),
        });
  }
}

class SoaringForecast extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<RaspDataBloc>(
      create: (BuildContext context) =>
          RaspDataBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: RaspScreen(repositoryContext: context),
    );
  }
}

class TurnpointSearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<TurnpointBloc>(
      create: (BuildContext context) =>
          TurnpointBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: TurnpointSearchScreen(repositoryContext: context),
    );
  }
}
