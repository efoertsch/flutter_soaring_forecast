import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_state.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/app_drawer.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/display_ticker.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/forecast_map.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_hour/forecast_hour_cubit.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_hour/forecast_hour_state.dart';
import 'package:flutter_soaring_forecast/soaring/rasp_options/rasp_display_options_cubit.dart';
import 'package:flutter_soaring_forecast/soaring/region_model/ui/model_date_display.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/ui/task_list.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_overhead_view.dart';

import '../../forecast_hour/forecast_hour_widget.dart';
import '../../local_forecast/data/local_forecast_graph.dart';
import '../../rasp_options/rasp_display_option_state.dart';
import '../../region_model/bloc/region_model_bloc.dart';
import '../../region_model/bloc/region_model_event.dart';
import '../../region_model/bloc/region_model_state.dart';
import '../bloc/rasp_data_bloc.dart';
import '../bloc/rasp_data_event.dart';
import 'common/forecast_types_display.dart';
import 'common/rasp_progress_indicator.dart';

class RaspScreen extends StatefulWidget {
  RaspScreen({Key? key}) : super(key: key);

  @override
  _RaspScreenState createState() => _RaspScreenState();
}

class _RaspScreenState extends State<RaspScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _forecastMapStateKey = GlobalKey<ForecastMapState>();
  late List<PreferenceOption> _raspDisplayOptions;
  String _selectedRegionName = "";

  int _currentImageIndex = 0;
  int _lastImageIndex = 0;
  DisplayTimer? _displayTimer;

  Stream<int>? _overlayPositionCounter;
  StreamSubscription<int>? _tickerSubscription;

  bool taskSelected = false;
  bool _beginnerMode = true;
  String _currentRegionName = "";

  FixedExtentScrollController forecastScrollController =
      new FixedExtentScrollController();

  RaspDisplayOptionsCubit _getRaspDisplayOptionsCubit() =>
      BlocProvider.of<RaspDisplayOptionsCubit>(context);

  // Executed only when class created
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    stopAnimation();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          key: _scaffoldKey,
          drawer: AppDrawerWidget(
            context: context,
            refreshTaskDisplayFunction: checkForUpdatedTaskOnReturnFromWindy,
          ),
          appBar: _getAppBar(),
          body: _getBody(context)
          // }),
          ),
    );
  }

  AppBar _getAppBar() {
    return AppBar(
      title: Text('RASP'),
      actions: _getRaspMenu(),
    );
  }

  Padding _getBody(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ModelDatesDisplay(),
              SelectedForecastDisplay(),
              _getDividerWidget(),
              ForecastHourDisplay(),
              _getForecastWindow(),
              _raspStatesHandler(),
              _regionModelHandler(),
              _raspDisplayOptionsHandler(),
              _forecastHourHandler()
            ],
          ),
          RaspProgressIndicator(),
        ],
      ),
    );
  }

  Divider _getDividerWidget() {
    return const Divider(
        height: 1,
        thickness: 1,
        indent: 0,
        endIndent: 0,
        color: Colors.black12);
  }

  Widget _raspDisplayOptionsHandler() {
    return BlocListener<RaspDisplayOptionsCubit, RaspPreferenceOptionState>(
      listener: (context, state) {
        if (state is RaspPreferenceOptionsState) {
          _raspDisplayOptions = state.preferenceOptions;
          // see if need to display turnpoints
          _sendEvent(RaspDisplayOptionsEvent(_raspDisplayOptions));
          // see if to display soundings and sua
          _sendEvent(RegionDisplayOptionsEvent(_raspDisplayOptions));
        }
        ;
      },
      child: SizedBox.shrink(),
    );
  }

  Widget _raspStatesHandler() {
    return BlocListener<RaspDataBloc, RaspDataState>(
      listener: (context, state) {
        if (state is DisplayLocalForecastGraphState) {
          stopAnimation();
          _displayLocalForecastGraph(context, state.localForecastGraphData);
        }
        if (state is RaspTimeState) {
          getForecastHourCubit(context).setForecastHour(state.forecastTime);
          _sendEvent(ForecastHourSyncEvent(state.forecastTimeIndex));
        }
        if (state is RaspTaskTurnpoints) {
          taskSelected = state.taskTurnpoints.isNotEmpty;
          return;
        }
        if (state is RaspErrorState) {
          CommonWidgets.showErrorDialog(
              context, StandardLiterals.UH_OH, state.error);
        }
        if (state is TurnpointFoundState) {
          displayTurnpointView(context, state);
        }
      },
      child: SizedBox.shrink(),
    );
  }

  Widget _regionModelHandler() {
    return BlocListener<RegionModelBloc, RegionModelState>(
      listener: (context, state) {
        if (state is ForecastModelsAndDates) {
          _beginnerMode = state.beginnerMode;
          // pass RegionModel info to RASP
          SelectedRegionModelDetailEvent selectedRegionModelDetailEvent =
              SelectedRegionModelDetailEvent(
                  region: state.regionName,
                  modelName: state.modelNameIndex >= 0
                      ? state.modelNames[state.modelNameIndex]
                      : "",
                  modelDate: state.forecastDateIndex >= 0
                      ? state.forecastDates[state.forecastDateIndex]
                      : "",
                  localTimes: state.localTimes,
                  localTime:
                      (state.localTimes.length > 0 && state.localTimeIndex >= 0)
                          ? state.localTimes[state.localTimeIndex]
                          : "");
          _sendEvent(selectedRegionModelDetailEvent);
          // Only need to do this once unless region changes
          if (_currentRegionName != state.regionName) {
            _currentRegionName = state.regionName;
            // have to wait till find out what region you are working with before
            // getting display options that depend on region
            _getRaspDisplayOptionsCubit()..getRaspPreferenceOptions();
          }
        }
      },
      child: SizedBox.shrink(),
    );
  }

  Widget _forecastHourHandler() {
    return BlocListener<ForecastHourCubit, ForecastHourState>(
      listener: (context, state) {
        if (state is RunHourAnimationState) {
          runAnimation(state.runAnimation);
          return;
        }
        if (state is IncrDecrHourIndexState) {
          _sendEvent(IncrDecrRaspForecastHourEvent(state.incrDecrIndex));
        }
      },
      child: SizedBox.shrink(),
    );
  }

// runAnimation = true - run the animation of course!
//                = false - stop it
  void runAnimation(bool runAnimation) {
    //TODO timer and subscription too convoluted. Make simpler
    if (runAnimation) {
      _displayTimer = DisplayTimer(Duration(seconds: 3));
      _overlayPositionCounter = _displayTimer!.stream;
      _tickerSubscription = _overlayPositionCounter!.listen((int counter) {
        _sendEvent(IncrDecrRaspForecastHourEvent(1));
      });
      _displayTimer!.setStartAndLimit(_currentImageIndex, _lastImageIndex);
      _displayTimer!.startTimer();
      //debugPrint('Started timer');
    } else {
      //debugPrint('Stopping timer');
      if (_tickerSubscription != null) {
        _tickerSubscription!.cancel();
      }
      if (_displayTimer != null) {
        _displayTimer!.cancelTimer();
        _displayTimer = null;
      }
      // debugPrint('Stopped timer');
    }
  }

  void stopAnimation() {
    runAnimation(false);
  }

  List<Widget> _getRaspMenu() {
    return <Widget>[
      TextButton(
        child: const Text(RaspMenu.selectTask,
            style: TextStyle(color: Colors.white)),
        onPressed: () {
          _selectTask();
        },
      ),
      PopupMenuButton<String>(
        onSelected: _handleClick,
        icon: Icon(Icons.more_vert),
        itemBuilder: (BuildContext context) {
          return {
            RaspMenu.clearTask,
            RaspMenu.one800WxBrief,
            RaspMenu.displayOptions,
            // RaspMenu.mapBackground,
            RaspMenu.reorderForecasts,
            RaspMenu.opacity,
            RaspMenu.selectRegion,
            _beginnerMode
                ? StandardLiterals.EXPERT_MODE
                : StandardLiterals.BEGINNER_MODE,
            RaspMenu.refreshForecast
          }.map((String choice) {
            if (choice == RaspMenu.clearTask) {
              return PopupMenuItem<String>(
                value: choice,
                enabled: taskSelected,
                child: Text(choice),
              );
            }
            if (choice == RaspMenu.one800WxBrief) {
              return PopupMenuItem<String>(
                value: choice,
                enabled: taskSelected,
                child: _getBriefSubMenu(),
              );
            }
            ;
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
      )
    ];
  }

  Widget _getBriefSubMenu() {
    return PopupMenuButton<String>(
      offset: Offset(-30, 25),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(RaspMenu.one800WxBrief),
          Spacer(),
          Icon(Icons.arrow_right, size: 20.0, color: Colors.black),
        ],
      ),
      onSelected: _handleClick,
      itemBuilder: (BuildContext context) {
        return {
          RaspMenu.notamsBrief,
          RaspMenu.routeBrief,
        }.map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Text(choice),
          );
        }).toList();
      },
    );
  }

  _selectTask() async {
    final result = await Navigator.pushNamed(
        context, TaskListRouteBuilder.routeName,
        arguments: TaskListScreen.SELECT_TASK_OPTION);
    if (result != null && result is int && result > -1) {
      //debugPrint('Draw task for ' + result.toString());
      _sendEvent(GetTaskTurnpointsEvent(result));
    }
  }

  void _handleClick(String value) async {
    switch (value) {
      case RaspMenu.clearTask:
        _sendEvent(ClearTaskEvent());
        break;
      case RaspMenu.notamsBrief:
        Navigator.pop(context);
        _displayWxBriefRequest(WxBriefBriefingRequest.NOTAMS_REQUEST);
        break;
      case RaspMenu.routeBrief:
        Navigator.pop(context);
        _displayWxBriefRequest(WxBriefBriefingRequest.ROUTE_REQUEST);
        break;
      case RaspMenu.displayOptions:
        _showMapDisplayOptionsDialog();
        break;
      case RaspMenu.mapBackground:
        break;
      case RaspMenu.reorderForecasts:
        displayForecastList(
          context: context,
          sendEvent: _sendEvent,
        );
        break;
      case RaspMenu.opacity:
        _forecastMapStateKey.currentState!.showOverlayOpacitySlider();
        break;
      case RaspMenu.selectRegion:
        _showRegionListScreen();
        break;
      case StandardLiterals.EXPERT_MODE:
      case StandardLiterals.BEGINNER_MODE:
        // toggle flag
        //setState(() {
        _sendEvent(BeginnerModeEvent(!_beginnerMode));
        //});
        break;
      case RaspMenu.refreshForecast:
        _sendEvent(ListTypesOfForecastsEvent());
        _sendEvent(InitialRegionModelEvent());
        break;
    }
  }

  void displayTurnpointView(
      BuildContext context, TurnpointFoundState state) async {
    await Navigator.pushNamed(
      context,
      TurnpointViewRouteBuilder.routeName,
      arguments: TurnpointOverHeadArgs(turnpoint: state.turnpoint),
    );
  }

  void _sendEvent(dynamic event) {
    if (event is RegionModelEvent) {
      BlocProvider.of<RegionModelBloc>(context).add(event);
    } else if (event is RaspDataEvent) {
      BlocProvider.of<RaspDataBloc>(context).add(event);
    }
  }

  Widget _getForecastWindow() {
    return ForecastMap(key: _forecastMapStateKey, runAnimation: runAnimation);
  }

  void _showMapDisplayOptionsDialog() async {
    List<CheckboxItem> currentDisplayOptions = [];
    _raspDisplayOptions.forEach((option) {
      currentDisplayOptions
          .add(CheckboxItem(option.displayText, option.selected));
    });

    CommonWidgets.showCheckBoxsInfoDialog(
      context: context,
      msg: "",
      title: "Display",
      button1Text: "Cancel",
      button1Function: _cancel,
      button2Text: "OK",
      button2Function: (() => Navigator.pop(context, currentDisplayOptions)),
      checkboxItems: currentDisplayOptions,
    ).then((newDisplayOptions) => _processDisplayOptions(newDisplayOptions));
  }

  void _showRegionListScreen() async {
    final result = await Navigator.pushNamed(
        context, RegionListRouteBuilder.routeName,
        arguments: _selectedRegionName);
    if (result != null && result is String) {
      debugPrint("selected region: result");
      // user switched to another region
      if (result != _selectedRegionName) ;
      _sendEvent(SwitchedRegionEvent());
      _sendEvent(RegionChangedEvent());
    }
  }

  _processDisplayOptions(List<CheckboxItem>? newDisplayOptions) {
    if (newDisplayOptions == null) return;

    newDisplayOptions.forEach((newOption) {
      final oldOption = _raspDisplayOptions.firstWhere(
          (oldOption) => oldOption.displayText == newOption.checkboxText);
      if (newOption.isChecked != oldOption.selected) {
        // some change in checked status
        oldOption.selected = newOption.isChecked;
        // Don't know who is interested in it so sending it to both blocs.
        _getRaspDisplayOptionsCubit().saveRaspPreferenceOption(oldOption);
        // update if turnpoints to be displayed
        _sendEvent(RaspDisplayOptionEvent(oldOption));
        // see if to update display of soundings or sua
        _sendEvent(RegionDisplayOptionEvent(oldOption));
      }
      ;
    });
  }

  _cancel() {
    Navigator.pop(context);
  }

  void checkForUpdatedTaskOnReturnFromWindy(bool possibleTaskChange) {
    if (possibleTaskChange) {
      _sendEvent(MapReadyEvent());
    }
  }

  void _displayWxBriefRequest(WxBriefBriefingRequest request) async {
    await Navigator.pushNamed(context, WxBriefRequestBuilder.routeName,
        arguments: request);
  }

  void _displayLocalForecastGraph(
      BuildContext context, LocalForecastInputData inputParms) async {
    await Navigator.pushNamed(
      context,
      LocalForecastGraphRouteBuilder.routeName,
      arguments: inputParms,
    );
    _sendEvent(RefreshModelDateEvent());
  }
}
