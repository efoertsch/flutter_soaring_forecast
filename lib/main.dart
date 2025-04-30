import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/about/about_screen.dart';
import 'package:flutter_soaring_forecast/soaring/airport/bloc/airport_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/airport/download/airports_downloader.dart';
import 'package:flutter_soaring_forecast/soaring/airport/ui/airport_metar_taf.dart';
import 'package:flutter_soaring_forecast/soaring/airport/ui/airport_search.dart';
import 'package:flutter_soaring_forecast/soaring/airport/ui/selected_airports_list.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show WxBriefBriefingRequest;
import 'package:flutter_soaring_forecast/soaring/app/custom_material_page_route.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/rasp_screen.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_hour/forecast_hour_cubit.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_types/bloc/forecast_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_types/ui/forecast_list.dart';
import 'package:flutter_soaring_forecast/soaring/glider/bloc/glider_cubit.dart';
import 'package:flutter_soaring_forecast/soaring/glider/ui/glider_polar_list.dart';
import 'package:flutter_soaring_forecast/soaring/local_forecast/bloc/local_forecast_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/pdfviewer/pdf_view_screen.dart';
import 'package:flutter_soaring_forecast/soaring/rasp_options/rasp_display_options_cubit.dart';
import 'package:flutter_soaring_forecast/soaring/region/bloc/region_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/region/ui/region_list_screen.dart';
import 'package:flutter_soaring_forecast/soaring/region_model/bloc/region_model_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/region_model/bloc/region_model_event.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/satellite/geos/geos.dart';
import 'package:flutter_soaring_forecast/soaring/settings/bloc/settings_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/settings/ui/settings_screen.dart';
import 'package:flutter_soaring_forecast/soaring/task_estimate/cubit/task_estimate_cubit.dart';
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
import 'package:flutter_soaring_forecast/soaring/windy/ui/windy_forecast.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/bloc/wxbrief_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/ui/wxbrief_auth_screen.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/ui/wxbrief_request_screen.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';
import 'soaring/local_forecast/bloc/local_forecast_event.dart';
import 'soaring/local_forecast/data/local_forecast_graph.dart';
import 'soaring/local_forecast/ui/local_forecast_graph_display.dart';
import 'soaring/task_estimate/ui/task_estimate_display.dart';

// https://github.com/fluttercommunity/flutter_workmanager#customisation-android-only
@pragma(
    'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // if (task == Workmanager.iOSBackgroundTask) {
    //   debugPrint("The iOS background fetch was triggered");
    // }
    try {
      debugPrint('Checking to download airports');
      var ok = AirportsDownloader(repository: Repository(null))
          .downloadAirportsIfNeeded();
      debugPrint('AirportsDownloader response : $ok');
      return Future.value(ok);
    } catch (err) {
      debugPrint(err.toString());
      throw Exception(err);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // In release mode this will override Flutter debugPrint() so nothing printed to logs
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  //https://firebase.google.com/docs/crashlytics/get-started?platform=flutter
  await Firebase.initializeApp(
    name: "SoaringForecast",
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Since iOS less definitive on when background task will run, just have user kick it off when requested.
  if (Platform.isAndroid) {
    Workmanager().initialize(
        callbackDispatcher, // The top level function, aka callbackDispatcher
        isInDebugMode:
            !kReleaseMode // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
        );
    Workmanager()
        .registerOneOffTask("oneTimeDownload", "workmanager.background.task");
  }

  // needed to fix CERTIFICATE_VERIFY_FAILED error on startup due to
  // Android 7 and earlier versions referencing expired Lets Encrypt cert when accessing
  // website using Lets Encrypt SSL certificate
  // https://stackoverflow.com/questions/54285172/how-to-solve-flutter-certificate-verify-failed-error-while-performing-a-post-req
  // https://flutter-developer.medium.com/flutter-android-7-certificate-verify-failed-with-letsencrypt-ssl-cert-after-sept-30-2021-9cb5f672c090
  ByteData data =
      await PlatformAssetBundle().load('assets/ca/lets-encrypt-r3.pem');
  SecurityContext.defaultContext
      .setTrustedCertificatesBytes(data.buffer.asUint8List());
  // End of Lets Encrypt SSL stuff

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
  late final BuildContext appContext;
  late final RegionModelBloc regionModelBloc;
  late final ForecastHourCubit forecastHourCubit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: [
          BlocProvider<RegionModelBloc>(
            create: (BuildContext context) => RegionModelBloc(
                repository: RepositoryProvider.of<Repository>(context)),
          ),
          BlocProvider<ForecastHourCubit>(
            create: (BuildContext context) => ForecastHourCubit(),
          )
        ],
        child: MaterialApp(
            theme: ThemeData(
              useMaterial3: false,
            ),
            debugShowCheckedModeBanner: false,
            title: Strings.appTitle,
            home: SoaringForecastRouteBuilder(),
            initialRoute: SoaringForecastRouteBuilder.routeName,
            onGenerateRoute: (settings) {
              return _buildRoute(settings);
            }));

    // regionModelBloc =
    //     RegionModelBloc(repository: RepositoryProvider.of<Repository>(context));
    // forecastHourCubit = ForecastHourCubit();
    // return MaterialApp(
    //     theme: ThemeData(
    //       useMaterial3: false,
    //     ),
    //     debugShowCheckedModeBanner: false,
    //     title: Strings.appTitle,
    //     home: SoaringForecastRouteBuilder(
    //       regionModelBloc: regionModelBloc,
    //       forecastHourCubit: forecastHourCubit,
    //     ),
    //     initialRoute: SoaringForecastRouteBuilder.routeName,
    //     onGenerateRoute: (settings) {
    //       return _buildRoute(settings, regionModelBloc);
    //     });
  }

  CustomMaterialPageRoute? _buildRoute(
      RouteSettings settings) {
    if (settings.name == TaskListRouteBuilder.routeName) {
      var option = null;
      if (settings.arguments != null) {
        option = settings.arguments as String;
      }
      return CustomMaterialPageRoute(
        builder: (context) {
          return TaskListRouteBuilder(viewOption: option);
        },
        settings: settings,
      );
    }
    if (settings.name == TurnpointViewRouteBuilder.routeName) {
      final turnpointOverheadArgs = settings.arguments as TurnpointOverHeadArgs;
      return CustomMaterialPageRoute(
        builder: (context) {
          return TurnpointViewRouteBuilder(
              turnpointOverHeadArgs: turnpointOverheadArgs);
        },
        settings: settings,
      );
    }

    if (settings.name == TurnpointEditRouteBuilder.routeName) {
      int? turnpointId =
          (settings.arguments == null ? null : settings.arguments as int);
      return CustomMaterialPageRoute(
        builder: (context) {
          return TurnpointEditRouteBuilder(turnpointId: turnpointId);
        },
        settings: settings,
      );
    }

    if (settings.name == TaskDetailRouteBuilder.routeName) {
      final taskId = settings.arguments as int;
      return CustomMaterialPageRoute(
        builder: (context) {
          return TaskDetailRouteBuilder(taskId: taskId);
        },
        settings: settings,
      );
    }
    if (settings.name == TurnpointsForTaskRouteBuilder.routeName) {
      final viewOption = settings.arguments as String;
      return CustomMaterialPageRoute(
        builder: (context) {
          return TurnpointsForTaskRouteBuilder(viewOption: viewOption);
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

    if (settings.name == TurnpointFileImportRouteBuilder.routeName) {
      return CustomMaterialPageRoute(
        builder: (context) {
          return TurnpointFileImportRouteBuilder();
        },
        settings: settings,
      );
    }

    if (settings.name == CustomTurnpointFileImportRouteBuilder.routeName) {
      return CustomMaterialPageRoute(
        builder: (context) {
          return CustomTurnpointFileImportRouteBuilder();
        },
        settings: settings,
      );
    }
    if (settings.name == ForecastListRouteBuilder.routeName) {
      final forecastArgs = settings.arguments as ForecastListArgs;
      return CustomMaterialPageRoute(
        builder: (context) {
          return ForecastListRouteBuilder(forecastArgs: forecastArgs);
        },
        settings: settings,
      );
    }
    if (settings.name == RegionListRouteBuilder.routeName) {
      final selectedForecast = settings.arguments as String;
      return CustomMaterialPageRoute(
        builder: (context) {
          return RegionListRouteBuilder(selectedRegion: selectedForecast);
        },
        settings: settings,
      );
    }

    if (settings.name == GeosRouteBuilder.routeName) {
      return CustomMaterialPageRoute(
        builder: (context) {
          return GeosScreen();
        },
        settings: settings,
      );
    }

    if (settings.name == AboutInfoRouteBuilder.routeName) {
      return CustomMaterialPageRoute(
        builder: (context) {
          return AboutInfoRouteBuilder();
        },
        settings: settings,
      );
    }

    if (settings.name == WindyRouteBuilder.routeName) {
      return CustomMaterialPageRoute(
        builder: (context) {
          return WindyRouteBuilder();
        },
        settings: settings,
      );
    }

    if (settings.name == AirportMetarTafRouteBuilder.routeName) {
      return CustomMaterialPageRoute(
        builder: (context) {
          return AirportMetarTafRouteBuilder();
        },
        settings: settings,
      );
    }

    if (settings.name == AirportsSearchRouteBuilder.routeName) {
      String? option = null;
      if (settings.arguments != null) {
        option = settings.arguments as String;
      }
      return CustomMaterialPageRoute(
        builder: (context) {
          return AirportsSearchRouteBuilder(option: option);
        },
        settings: settings,
      );
    }

    if (settings.name == SelectedAirportsRouteBuilder.routeName) {
      return CustomMaterialPageRoute(
        builder: (context) {
          return SelectedAirportsRouteBuilder();
        },
        settings: settings,
      );
    }

    if (settings.name == WxBriefAuthBuilder.routeName) {
      return CustomMaterialPageRoute(
        builder: (context) {
          return WxBriefAuthBuilder();
        },
        settings: settings,
      );
    }

    if (settings.name == WxBriefRequestBuilder.routeName) {
      final request = settings.arguments as WxBriefBriefingRequest;
      return CustomMaterialPageRoute(
        builder: (context) {
          return WxBriefRequestBuilder(request: request);
        },
        settings: settings,
      );
    }

    if (settings.name == PdfViewRouteBuilder.routeName) {
      final fileName = settings.arguments as String;
      return CustomMaterialPageRoute(
        builder: (context) {
          return PdfViewRouteBuilder(
            fileName: fileName,
          );
        },
        settings: settings,
      );
    }

    if (settings.name == LocalForecastGraphRouteBuilder.routeName) {
      final graphData = settings.arguments as LocalForecastInputData;
      return CustomMaterialPageRoute(
        builder: (context) {
          return LocalForecastGraphRouteBuilder(graphData: graphData);
        },
        settings: settings,
      );
    }

    if (settings.name == EstimatedTaskRouteBuilder.routeName) {
      return CustomMaterialPageRoute(
        builder: (context) {
          return EstimatedTaskRouteBuilder();
        },
        settings: settings,
      );
    }

    if (settings.name == SettingsRouteBuilder.routeName) {
      return CustomMaterialPageRoute(
        builder: (context) {
          return SettingsRouteBuilder();
        },
        settings: settings,
      );
    }

    if (settings.name == GliderPolarListBuilder.routeName) {
      return CustomMaterialPageRoute(
        builder: (context) {
          return GliderPolarListBuilder();
        },
        settings: settings,
      );
    }

    assert(false, 'Need to implement ${settings.name}');
    return null;
  }
}

class SoaringForecastRouteBuilder extends StatelessWidget {
  static const routeName = '/';

  SoaringForecastRouteBuilder();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
            value: BlocProvider.of<RegionModelBloc>(context)
              ..add(InitialRegionModelEvent())),
        BlocProvider.value(value: BlocProvider.of<ForecastHourCubit>(context)),
        BlocProvider<RaspDataBloc>(
          create: (BuildContext context) => RaspDataBloc(
              repository: RepositoryProvider.of<Repository>(context)),
        ),
        BlocProvider(
            create: (BuildContext context) => RaspDisplayOptionsCubit(
                repository: RepositoryProvider.of<Repository>(context)))
      ],
      child: RaspScreen(),
    );
  }
}

class LocalForecastGraphRouteBuilder extends StatelessWidget {
  static const routeName = '/ForecastGraph';
  final LocalForecastInputData graphData;

  LocalForecastGraphRouteBuilder({required this.graphData});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocalForecastBloc>(
            create: (BuildContext context) => LocalForecastBloc(
                repository: RepositoryProvider.of<Repository>(context))
              ..add(
                  LocalForecastGraphEvent(localForecastGraphData: graphData))),
        BlocProvider.value(
            value: BlocProvider.of<RegionModelBloc>(context)
              ..add(LocalForecastStartupEvent())),
      ],
      child: LocalForecastGraphDisplay(),
    );
  }
}

class EstimatedTaskRouteBuilder extends StatelessWidget {
  static const routeName = '/EstimatedTask';

  EstimatedTaskRouteBuilder();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TaskEstimateCubit>(
            create: (BuildContext context) => TaskEstimateCubit(
                repository: RepositoryProvider.of<Repository>(context))),
        BlocProvider.value(
            value: BlocProvider.of<RegionModelBloc>(context)
              ..add(EstimatedTaskStartupEvent())),
        BlocProvider.value(value: BlocProvider.of<ForecastHourCubit>(context)),
      ],
      child: TaskEstimateDisplay(),
    );
  }
}

class GliderPolarListBuilder extends StatelessWidget {
  static const routeName = '/GliderPolarList';

  Widget build(BuildContext context) {
    return BlocProvider<GliderCubit>(
      create: (BuildContext context) =>
          GliderCubit(repository: RepositoryProvider.of<Repository>(context))
            ..getListOfGliders(),
      child: GliderPolarListScreen(),
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

class TurnpointsForTaskRouteBuilder extends StatelessWidget {
  static const routeName = '/turnpointsForTask';
  final String? viewOption;

  TurnpointsForTaskRouteBuilder({this.viewOption});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TurnpointBloc>(
      create: (BuildContext context) =>
          TurnpointBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: TurnpointsList(viewOption: viewOption),
    );
  }
}

class TurnpointFileImportRouteBuilder extends StatelessWidget {
  static const routeName = '/turnpointImport';

  TurnpointFileImportRouteBuilder();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TurnpointBloc>(
      create: (BuildContext context) =>
          TurnpointBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: SeeYouImportScreen(),
    );
  }
}

class CustomTurnpointFileImportRouteBuilder extends StatelessWidget {
  static const routeName = '/customTurnpointImport';

  CustomTurnpointFileImportRouteBuilder();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TurnpointBloc>(
      create: (BuildContext context) =>
          TurnpointBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: CustomSeeYouImportScreen(),
    );
  }
}

class TurnpointViewRouteBuilder extends StatelessWidget {
  static const routeName = '/ViewTurnpoint';
  final TurnpointOverHeadArgs turnpointOverHeadArgs;

  TurnpointViewRouteBuilder({required this.turnpointOverHeadArgs});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TurnpointBloc>(
        create: (BuildContext context) => TurnpointBloc(
            repository: RepositoryProvider.of<Repository>(context)),
        child: TurnpointOverheadView(
            turnpointOverHeadArgs: turnpointOverHeadArgs));
  }
}

class TurnpointEditRouteBuilder extends StatelessWidget {
  static const routeName = '/editTurnpoint';
  final int? turnpointId;

  TurnpointEditRouteBuilder({this.turnpointId});

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
class TaskListRouteBuilder extends StatelessWidget {
  static const routeName = '/ViewTask';
  final String? viewOption;

  TaskListRouteBuilder({this.viewOption = null});

  Widget build(BuildContext context) {
    return BlocProvider<TaskBloc>(
      create: (BuildContext context) =>
          TaskBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: TaskListScreen(viewOption: viewOption),
    );
  }
}

class TaskDetailRouteBuilder extends StatelessWidget {
  static const routeName = '/ViewTaskDetail';
  final int taskId;

  TaskDetailRouteBuilder({required this.taskId});

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
class ForecastListRouteBuilder extends StatelessWidget {
  static const routeName = '/ViewForecastList';
  final ForecastListArgs? forecastArgs;

  ForecastListRouteBuilder({this.forecastArgs = null});

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
class RegionListRouteBuilder extends StatelessWidget {
  static const routeName = '/RegionList';

  final selectedRegion;

  RegionListRouteBuilder({required String this.selectedRegion});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegionDataBloc>(
      create: (BuildContext context) => RegionDataBloc(
          repository: RepositoryProvider.of<Repository>(context)),
      child: RegionListScreen(selectedRegionName: selectedRegion),
    );
  }
}

class GeosRouteBuilder extends StatelessWidget {
  static const routeName = '/geos';

  GeosRouteBuilder();

  @override
  Widget build(BuildContext context) {
    return GeosScreen();
  }
}

class AboutInfoRouteBuilder extends StatelessWidget {
  static const routeName = '/aboutScreen';

  AboutInfoRouteBuilder();

  @override
  Widget build(BuildContext context) {
    return AboutScreen();
  }
}

class WindyRouteBuilder extends StatelessWidget {
  static const routeName = '/Windy';

  Widget build(BuildContext context) {
    return BlocProvider<WindyBloc>(
      create: (BuildContext context) =>
          WindyBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: WindyForecast(),
    );
  }
}

class AirportMetarTafRouteBuilder extends StatelessWidget {
  static const routeName = '/AirportMetarTaf';

  Widget build(BuildContext context) {
    return BlocProvider<AirportBloc>(
      create: (BuildContext context) =>
          AirportBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: AirportMetarTaf(
          repository: RepositoryProvider.of<Repository>(context)),
    );
  }
}

class SelectedAirportsRouteBuilder extends StatelessWidget {
  static const routeName = '/SelectedAirports';

  Widget build(BuildContext context) {
    return BlocProvider<AirportBloc>(
      create: (BuildContext context) =>
          AirportBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: SelectedAirportsList(),
    );
  }
}

class AirportsSearchRouteBuilder extends StatelessWidget {
  static const routeName = '/AirportsSearch';
  final String? option;

  AirportsSearchRouteBuilder({this.option = null});

  Widget build(BuildContext context) {
    return BlocProvider<AirportBloc>(
      create: (BuildContext context) =>
          AirportBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: AirportsSearch(option: option),
    );
  }
}

class WxBriefAuthBuilder extends StatelessWidget {
  static const routeName = '/WxBriefAuth';

  WxBriefAuthBuilder();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WxBriefBloc>(
      create: (BuildContext context) =>
          WxBriefBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: WxBriefAuthScreen(),
    );
  }
}

class WxBriefRequestBuilder extends StatelessWidget {
  static const routeName = '/WxBriefRequest';
  final WxBriefBriefingRequest request;

  WxBriefRequestBuilder({required this.request});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WxBriefBloc>(
      create: (BuildContext context) =>
          WxBriefBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: WxBriefRequestScreen(request: request),
    );
  }
}

class PdfViewRouteBuilder extends StatelessWidget {
  static const routeName = '/PDFViewer';
  final String fileName;

  PdfViewRouteBuilder({required this.fileName});

  Widget build(BuildContext context) {
    return PdfViewScreen(fileName: fileName);
  }
}

class SettingsRouteBuilder extends StatelessWidget {
  static const routeName = '/Settings';

  Widget build(BuildContext context) {
    return BlocProvider<SettingsBloc>(
      create: (BuildContext context) =>
          SettingsBloc(repository: RepositoryProvider.of<Repository>(context)),
      child: SettingsScreen(),
    );
  }
}
