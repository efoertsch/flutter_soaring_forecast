import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/airport_download/airports_downloader.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_material_page_route.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/rasp_screen.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/ui/task_detail.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/ui/task_list.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/custom_see_you_import.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/see_you_import.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_detail_view.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_edit_view.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_search_in_appbar.dart';
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
            final turnpoint = settings.arguments as Turnpoint;
            return CustomMaterialPageRoute(
              builder: (context) {
                return TurnpointView(turnpoint: turnpoint);
              },
              settings: settings,
            );
          }
          if (settings.name == TurnpointEdit.routeName) {
            final turnpoint = settings.arguments as Turnpoint;
            return CustomMaterialPageRoute(
              builder: (context) {
                return TurnpointEditView(turnpoint: turnpoint);
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

          if (settings.name == TurnpointSearchInAppBar.routeName) {
            return CustomMaterialPageRoute(
              builder: (context) {
                return TurnpointSearchInAppBar();
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
class TurnpointSearchInAppBar extends StatelessWidget {
  static const routeName = '/turnpointSearchInAppBar';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TurnpointBloc>(
      create: (BuildContext context) =>
          TurnpointBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: TurnpointsSearch(),
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
      child: TurnpointsSearch(viewOption: viewOption),
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
  final Turnpoint turnpoint;

  TurnpointView({required this.turnpoint});

  @override
  Widget build(BuildContext context) {
    return TurnpointDetailView(turnpoint: turnpoint);
  }
}

class TurnpointEdit extends StatelessWidget {
  static const routeName = '/editTurnpoint';
  final Turnpoint turnpoint;

  TurnpointEdit({required this.turnpoint});

  @override
  Widget build(BuildContext context) {
    return TurnpointEditView(turnpoint: turnpoint);
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
