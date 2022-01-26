import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/airport_download/airports_downloader.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/rasp_screen.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/ui/task_detail.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/ui/task_list.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_detail_view.dart';
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
        home: SoaringForecast(),
        theme: ThemeData(
          // brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          primaryColor: Colors.blue,
        ),
        initialRoute: SoaringForecast.routeName,
        routes: {
          TurnpointSearchInAppBar.routeName: (context) =>
              TurnpointSearchInAppBar(),
          TaskList.routeName: (context) => TaskList(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == TurnpointView.routeName) {
            final turnpoint = settings.arguments as Turnpoint;
            return MaterialPageRoute(
              builder: (context) {
                return TurnpointView(turnpoint: turnpoint);
              },
            );
          }
          if (settings.name == TaskDetail.routeName) {
            final taskId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (context) {
                return TaskDetail(taskId: taskId);
              },
            );
          }
          if (settings.name == TurnpointsForTask.routeName) {
            final viewOption = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) {
                return TurnpointsForTask(viewOption: viewOption);
              },
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

class TurnpointSearchInAppBar extends StatelessWidget {
  static const routeName = '/turnpointSearchInAppBar';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TurnpointBloc>(
      create: (BuildContext context) =>
          TurnpointBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: TurnpointsSearchInAppBarScreen(),
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
      child: TurnpointsSearchInAppBarScreen(viewOption: viewOption),
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

class TaskList extends StatelessWidget {
  static const routeName = '/ViewTask';

  Widget build(BuildContext context) {
    return BlocProvider<TaskBloc>(
      create: (BuildContext context) =>
          TaskBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: TaskListScreen(),
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
