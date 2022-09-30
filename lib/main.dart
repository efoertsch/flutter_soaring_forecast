import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/about/about_screen.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_material_page_route.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/rasp_screen.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_types/bloc/forecast_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_types/ui/forecast_list.dart';
import 'package:flutter_soaring_forecast/soaring/region/bloc/region_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/region/ui/region_list_screen.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/ui/task_detail.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/ui/task_list.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/custom_see_you_import.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/see_you_import.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_edit_view.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_overhead_view.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoints_list.dart';
import 'package:flutter_soaring_forecast/soaring/values/strings.dart';
import 'package:flutter_soaring_forecast/soaring/windy/bloc/windy_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/windy/ui/windy.dart';

// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) {
//     print('Checking to download airports');
//     var ok = AirportsDownloader(repository: Repository(null))
//         .downloadAirportsIfNeeded();
//     print('AirportsDownloader response : $ok');
//     return Future.value(ok);
//   });
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // In release mode this will override Flutter debugPrint() so nothing printed to logs
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  // Workmanager().initialize(
  //     callbackDispatcher, // The top level function, aka callbackDispatcher
  //     isInDebugMode:
  //         true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
  //     );
  //Workmanager().registerOneOffTask("1", "airportsDownload");
  runApp(RepositorySetup());
}

class RepositorySetup extends StatelessWidget {
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
        debugShowCheckedModeBanner: false,
        // theme: ThemeData(
        //   // force iOS behaviour on Android (for testing)
        //   // (or toggle platform via Flutter Inspector)
        //   // platform: TargetPlatform.iOS,
        //
        //   // specify page transitions for each platform
        //   pageTransitionsTheme: PageTransitionsTheme(
        //     builders: {
        //       // for Android - default page transition
        //       TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        //
        //       // for iOS - one which considers ancestor BackGestureWidthTheme
        //       TargetPlatform.iOS: CupertinoWillPopScopePageTransionsBuilder(),
        //     },
        //   ),
        // ),
        title: Strings.appTitle,
        home: SoaringForecast(),
        initialRoute: SoaringForecast.routeName,
        onGenerateRoute: (settings) {
          if (settings.name == TaskList.routeName) {
            var option = null;
            if (settings.arguments != null) {
              option = settings.arguments as String;
            }
            return CustomMaterialPageRoute(
              builder: (context) {
                return TaskList(viewOption: option);
              },
              settings: settings,
            );
          }
          if (settings.name == TurnpointView.routeName) {
            final turnpointOverheadArgs =
                settings.arguments as TurnpointOverHeadArgs;
            return CustomMaterialPageRoute(
              builder: (context) {
                return TurnpointView(
                    turnpointOverHeadArgs: turnpointOverheadArgs);
              },
              settings: settings,
            );
          }

          if (settings.name == TurnpointEdit.routeName) {
            int? turnpointId =
                (settings.arguments == null ? null : settings.arguments as int);
            return CustomMaterialPageRoute(
              builder: (context) {
                return TurnpointEdit(turnpointId: turnpointId);
              },
              settings: settings,
            );
          }

          if (settings.name == TaskDetail.routeName) {
            final taskId = settings.arguments as int;
            return CustomMaterialPageRoute(
              builder: (context) {
                return TaskDetail(taskId: taskId);
              },
              settings: settings,
            );
          }
          if (settings.name == TurnpointsForTask.routeName) {
            final viewOption = settings.arguments as String;
            return CustomMaterialPageRoute(
              builder: (context) {
                return TurnpointsForTask(viewOption: viewOption);
              },
              settings: settings,
            );
          }

          if (settings.name == TurnpointListRouteBuilder.routeName) {
            return CustomMaterialPageRoute(
              builder: (context) {
                return TurnpointListRouteBuilder();
              },
              settings: settings,
            );
          }

          if (settings.name == TurnpointFileImport.routeName) {
            return CustomMaterialPageRoute(
              builder: (context) {
                return TurnpointFileImport();
              },
              settings: settings,
            );
          }

          if (settings.name == CustomTurnpointFileImport.routeName) {
            return CustomMaterialPageRoute(
              builder: (context) {
                return CustomTurnpointFileImport();
              },
              settings: settings,
            );
          }
          if (settings.name == ForecastList.routeName) {
            final forecastArgs = settings.arguments as ForecastListArgs;
            return CustomMaterialPageRoute(
              builder: (context) {
                return ForecastList(forecastArgs: forecastArgs);
              },
              settings: settings,
            );
          }
          if (settings.name == RegionList.routeName) {
            final selectedForecast = settings.arguments as String;
            return CustomMaterialPageRoute(
              builder: (context) {
                return RegionList(selectedRegion: selectedForecast);
              },
              settings: settings,
            );
          }
          if (settings.name == AboutInfo.routeName) {
            return CustomMaterialPageRoute(
              builder: (context) {
                return AboutInfo();
              },
              settings: settings,
            );
          }

          if (settings.name == WindyScreen.routeName) {
            return CustomMaterialPageRoute(
              builder: (context) {
                return WindyScreen();
              },
              settings: settings,
            );
          }

          assert(false, 'Need to implement ${settings.name}');
          return null;
        });
  }
}

class SoaringForecast extends StatelessWidget {
  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RaspDataBloc>(
      create: (BuildContext context) =>
          RaspDataBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: RaspScreen(repositoryContext: context),
    );
  }
}

//-----------------------------------------------------------
// Turnpoint related
class TurnpointListRouteBuilder extends StatelessWidget {
  static const routeName = '/turnpointSearchInAppBar';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TurnpointBloc>(
      create: (BuildContext context) =>
          TurnpointBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: TurnpointsList(),
    );
  }
}

class TurnpointsForTask extends StatelessWidget {
  static const routeName = '/turnpointsForTask';
  final String? viewOption;

  TurnpointsForTask({this.viewOption});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TurnpointBloc>(
      create: (BuildContext context) =>
          TurnpointBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: TurnpointsList(viewOption: viewOption),
    );
  }
}

class TurnpointFileImport extends StatelessWidget {
  static const routeName = '/turnpointImport';

  TurnpointFileImport();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TurnpointBloc>(
      create: (BuildContext context) =>
          TurnpointBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: SeeYouImportScreen(),
    );
  }
}

class CustomTurnpointFileImport extends StatelessWidget {
  static const routeName = '/customTurnpointImport';

  CustomTurnpointFileImport();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TurnpointBloc>(
      create: (BuildContext context) =>
          TurnpointBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: CustomSeeYouImportScreen(),
    );
  }
}

class TurnpointView extends StatelessWidget {
  static const routeName = '/ViewTurnpoint';
  final TurnpointOverHeadArgs turnpointOverHeadArgs;

  TurnpointView({required this.turnpointOverHeadArgs});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TurnpointBloc>(
        create: (BuildContext context) => TurnpointBloc(
            repository: RepositoryProvider.of<Repository>(context)),
        child: TurnpointOverheadView(
            turnpointOverHeadArgs: turnpointOverHeadArgs));
  }
}

class TurnpointEdit extends StatelessWidget {
  static const routeName = '/editTurnpoint';
  final int? turnpointId;

  TurnpointEdit({this.turnpointId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TurnpointBloc>(
        create: (BuildContext context) => TurnpointBloc(
            repository: RepositoryProvider.of<Repository>(context)),
        child: TurnpointEditView(turnpointId: turnpointId));
  }
}

//-------------------------------------------------------------
// Task related
class TaskList extends StatelessWidget {
  static const routeName = '/ViewTask';
  final String? viewOption;

  TaskList({this.viewOption = null});

  Widget build(BuildContext context) {
    return BlocProvider<TaskBloc>(
      create: (BuildContext context) =>
          TaskBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: TaskListScreen(viewOption: viewOption),
    );
  }
}

class TaskDetail extends StatelessWidget {
  static const routeName = '/ViewTaskDetail';
  final int taskId;

  TaskDetail({required this.taskId});

  Widget build(BuildContext context) {
    return BlocProvider<TaskBloc>(
      create: (BuildContext context) =>
          TaskBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: TaskDetailScreen(taskId: taskId),
    );
  }
}

//-------------------------------------------------------------
// Forecast related
class ForecastList extends StatelessWidget {
  static const routeName = '/ViewForecastList';
  final ForecastListArgs? forecastArgs;

  ForecastList({this.forecastArgs = null});

  Widget build(BuildContext context) {
    return BlocProvider<ForecastBloc>(
      create: (BuildContext context) =>
          ForecastBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: ForecastListScreen(forecastArgs: forecastArgs),
    );
  }
}

//-------------------------------------------------------------
// Regions
class RegionList extends StatelessWidget {
  static const routeName = '/RegionList';

  var selectedRegion;

  RegionList({required String this.selectedRegion});
  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegionDataBloc>(
      create: (BuildContext context) => RegionDataBloc(
          repository: RepositoryProvider.of<Repository>(context)),
      child: RegionListScreen(selectedRegionName: selectedRegion),
    );
  }
}

class AboutInfo extends StatelessWidget {
  static const routeName = '/aboutScreen';

  AboutInfo();

  @override
  Widget build(BuildContext context) {
    return AboutScreen();
  }
}

class WindyScreen extends StatelessWidget {
  static const routeName = '/Windy';

  Widget build(BuildContext context) {
    return BlocProvider<WindyBloc>(
      create: (BuildContext context) =>
          WindyBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: WindyForecast(),
    );
  }
}
