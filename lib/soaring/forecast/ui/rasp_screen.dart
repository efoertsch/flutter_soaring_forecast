import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/app_drawer.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_state.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/rasp_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/display_ticker.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/forecast_map.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/util/rasp_utils.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/widgets/model_date_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_types/ui/common_forecast_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_types/ui/forecast_list.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/ui/task_list.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_overhead_view.dart';
import '../../repository/rasp/forecast_types.dart' show Forecast;
import '../bloc/rasp_data_bloc.dart';
import '../bloc/rasp_data_event.dart';

class RaspScreen extends StatefulWidget {
  final BuildContext repositoryContext;

  RaspScreen({Key? key, required this.repositoryContext}) : super(key: key);

  @override
  _RaspScreenState createState() => _RaspScreenState();
}

class _RaspScreenState extends State<RaspScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _forecastMapStateKey = GlobalKey<ForecastMapState>();
  late List<PreferenceOption> _raspDisplayOptions;
  late String _selectedRegionName;
  String _selectedModelName = '';
  List<String> _modelNames = [];
  List<String> _shortDOWs = [];
  String _selectedForecastDOW = '';
  List<String> _forecastDates = [];
  List<Forecast> _forecasts = [];
  Forecast? _selectedForecast;
  int _index = 0;

// TODO internationalize literals
  String _pauseAnimationLabel = "Pause";
  String _loopAnimationLabel = "Loop";

// Start forecast display with animation running
  bool _startImageAnimation = false;
  int _currentImageIndex = 0;
  int _lastImageIndex = 0;
  DisplayTimer? _displayTimer;

  Stream<int>? _overlayPositionCounter;
  StreamSubscription<int>? _tickerSubscription;

  bool taskSelected = false;
  bool _beginnerMode = true;

  FixedExtentScrollController forecastScrollController =
      new FixedExtentScrollController();

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

  // Leaving this in for now to learn about the Flutter app life cycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint("app in resumed");
        _sendEvent(CheckIfForecastRefreshNeededEvent());
        break;
      case AppLifecycleState.inactive:
        debugPrint("app in inactive");
        stopAnimation();
        break;
      case AppLifecycleState.paused:
        debugPrint("app in paused");
        stopAnimation();
        break;
      case AppLifecycleState.detached:
        debugPrint("app in detached");
        break;
    }
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
              _getBeginnerExpertWidget(),
              _getForecastTypes(),
              _getDividerWidget(),
              _displayForecastTime(),
              _getForecastWindow(),
              _widgetForSnackBarMessages(),
              _miscStatesHandlerWidget(),
            ],
          ),
          _getProgressIndicator(),
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

  Widget _getBeginnerExpertWidget() {
    return BlocConsumer<RaspDataBloc, RaspDataState>(
        listener: (context, state) {
      if (state is BeginnerModeState) {
        _beginnerMode = state.beginnerMode;
      }
      if (state is BeginnerForecastDateModelState) {
        _selectedModelName = state.model;
        _selectedForecastDOW = reformatDateToDOW(state.date) ?? '';
      }
      if (state is RaspForecastModels) {
        _selectedModelName = state.selectedModelName;
        _modelNames.clear();
        _modelNames.addAll(state.modelNames);
      }
      if (state is RaspModelDates) {
        _shortDOWs.clear();
        _shortDOWs.addAll(reformatDatesToDOW(state.forecastDates));
        _selectedForecastDOW =
            _shortDOWs[state.forecastDates.indexOf(state.selectedForecastDate)];
        _forecastDates.clear();
        _forecastDates.addAll(state.forecastDates);
      }
    }, buildWhen: (previous, current) {
      return current is BeginnerModeState ||
          current is BeginnerForecastDateModelState ||
          current is RaspForecastModels ||
          current is RaspModelDates;
    }, builder: (context, state) {
      if (_beginnerMode) {
        return _getBeginnerForecast();
      } else {
        return _getForecastModelsAndDates();
      }
    });
  }

  Widget _getBeginnerForecast() {
    return BeginnerForecast(
        context: context,
        leftArrowOnTap: (() {
          stopAnimation();
          _sendEvent(ForecastDateSwitchEvent(ForecastDateChange.previous));
          setState(() {});
        }),
        rightArrowOnTap: (() {
          stopAnimation();
          _sendEvent(ForecastDateSwitchEvent(ForecastDateChange.next));
          setState(() {});
        }),
        displayText:
            "(${_selectedModelName.toUpperCase()}) $_selectedForecastDOW");
  }

  Widget _getForecastModelsAndDates() {
    //debugPrint('creating/updating main ForecastModelsAndDates');
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: ModelDropDownList(
            selectedModelName: _selectedModelName,
            modelNames: _modelNames,
            onModelChange: (String value) {
              _sendEvent(SelectedRaspModelEvent(value));
            },
          ),
        ),
        Expanded(
            flex: 7,
            child: Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: ForecastDatesDropDown(
                selectedForecastDate: _selectedForecastDOW,
                forecastDates: _shortDOWs,
                onForecastDateChange: (String value) {
                  final selectedForecastDate =
                      _forecastDates[_shortDOWs.indexOf(value)];
                  _sendEvent(SelectRaspForecastDateEvent(selectedForecastDate));
                },
              ),
            )),
      ],
    );
  }

// Display description of forecast types (eq. 'Thermal Updraft Velocity (W*)' for wstar)
  Widget _getForecastTypes() {
    return BlocConsumer<RaspDataBloc, RaspDataState>(
        listener: (context, state) {
      if (state is RaspForecasts) {
        _selectedForecast = state.selectedForecast;
        _forecasts = state.forecasts;
        _index = _forecasts.indexOf(_selectedForecast!);
      }
    }, buildWhen: (previous, current) {
      return current is RaspInitialState || current is RaspForecasts;
    }, builder: (context, state) {
      //debugPrint('creating/updating ForecastTypes');
      if (state is RaspForecasts) {
        return _getSelectedForecastDisplay(context);
        //_getForecastDropDown(context, state);
      } else {
        return Text("Getting Forecasts");
      }
    });
  }

  Widget _getSelectedForecastDisplay(BuildContext context) {
    return SizedBox(
      height: 50,
      child: PageView.builder(
        key:ObjectKey(Object()),
        scrollDirection: Axis.horizontal,
        controller: PageController(viewportFraction: 1.0, initialPage: _index, keepPage: false),
        itemCount: _forecasts.length,
        onPageChanged: ((int index) {
          setState(() {
            _index = index;
            _sendEvent(SelectedRaspForecastEvent(_forecasts[index]));
          });
        }),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _getSelectedForecastIcon(context, _forecasts[index]),
                _getForecastTextWidget(context, _forecasts[index]),
                _getForecastDropDownIconWidget(_forecasts[index])
              ],
            ),
          );
        },
      ),
    );
  }

  Padding _getSelectedForecastIcon(BuildContext context, Forecast forecast) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
      child: InkWell(
          onTap: () {
            CommonForecastWidgets.showForecastDescriptionBottomSheet(
                context, forecast);
          },
          child:
              Constants.getForecastIcon(forecast.forecastCategory.toString())),
    );
  }

  Widget _getForecastTextWidget(BuildContext context, Forecast forecast) {
    return Expanded(
        child: InkWell(
          onTap: () {
            _displayForecastList(forecast: forecast);
          },
          child: Text(
            forecast.forecastNameDisplay,
            style: CustomStyle.bold18(context),
            maxLines: 2,
            overflow: TextOverflow.fade,
          ),
        ));
  }

  InkWell _getForecastDropDownIconWidget(Forecast forecast) {
    return InkWell(
      onTap: () {
        _displayForecastList(forecast: forecast);
      },
      child: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Icon(Icons.arrow_drop_down_outlined)),
    );
  }

// Display forecast time for model and date
  Widget _displayForecastTime() {
    //debugPrint('creating/updating ForecastTime');
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(' '),
        ),
        Expanded(
          flex: 5,
          child: Row(children: [
            Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    stopAnimation();
                    _sendEvent(PreviousTimeEvent());
                    setState(() {});
                  },
                  child: IncrDecrIconWidget.getIncIconWidget('<'),
                )),
            Expanded(
              flex: 6,
              child: BlocBuilder<RaspDataBloc, RaspDataState>(
                  buildWhen: (previous, current) {
                return current is RaspInitialState ||
                    current is RaspForecastImageSet ||
                    current is SoundingForecastImageSet;
              }, builder: (context, state) {
                var localTime;
                //debugPrint('creating/updating ForecastTime value');
                if (state is RaspForecastImageSet ||
                    state is SoundingForecastImageSet) {
                  if (state is RaspForecastImageSet) {
                    localTime = state.soaringForecastImageSet.localTime;
                    _currentImageIndex = state.displayIndex;
                    _lastImageIndex = state.numberImages - 1;
                  }
                  if (state is SoundingForecastImageSet) {
                    localTime = state.soaringForecastImageSet.localTime;
                    _currentImageIndex = state.displayIndex;
                    _lastImageIndex = state.numberImages - 1;
                  }
                  localTime = localTime.startsWith("old ")
                      ? localTime.substring(4)
                      : localTime;
                  return Text(
                    localTime + " (Local)",
                    style: CustomStyle.bold18(context),
                  );
                } else {
                  return Text("Getting forecastTime");
                }
              }),
            ),
            Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    stopAnimation();
                    _sendEvent(NextTimeEvent());
                    setState(() {});
                  },
                  child: IncrDecrIconWidget.getIncIconWidget('>'),
                )),
          ]),
        ),
        Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _startImageAnimation = !_startImageAnimation;
                  _startStopImageAnimation();
                });
              },
              child: Text(
                (_startImageAnimation
                    ? _pauseAnimationLabel
                    : _loopAnimationLabel),
                textAlign: TextAlign.end,
                style: CustomStyle.bold18(context),
              ),
            )),
      ],
    );
  }

  Widget _widgetForSnackBarMessages() {
    return BlocConsumer<RaspDataBloc, RaspDataState>(
        listener: (context, state) {
      if (state is RaspErrorState) {
        CommonWidgets.showErrorDialog(
            context, StandardLiterals.UH_OH, state.error);
      }
      if (state is TurnpointFoundState) {
        displayTurnpointView(context, state);
      }
    }, builder: (context, state) {
      if (state is RaspErrorState) {
        return SizedBox.shrink();
      } else {
        return SizedBox.shrink();
      }
    });
  }

  Widget _miscStatesHandlerWidget() {
    return BlocListener<RaspDataBloc, RaspDataState>(
      listener: (context, state) {
        if (state is RaspTaskTurnpoints) {
          taskSelected = state.taskTurnpoints.isNotEmpty;
          return;
        }
        if (state is RaspDisplayOptionsState) {
          // debugPrint("Received RaspDisplayOptionsState");
          _raspDisplayOptions = state.displayOptions;
          return;
        }
        if (state is SelectedRegionNameState) {
          _selectedRegionName = state.selectedRegionName;
          return;
        }
        if (state is DisplayLocalForecastGraphState) {
          stopAnimation();
          return;
        }
      },
      child: SizedBox.shrink(),
    );
  }

  void _startStopImageAnimation() {
    //TODO timer and subscription too convoluted. Make simpler
    if (_startImageAnimation) {
      _displayTimer = DisplayTimer(Duration(seconds: 3));
      _overlayPositionCounter = _displayTimer!.stream;
      _tickerSubscription = _overlayPositionCounter!.listen((int counter) {
        _sendEvent(NextTimeEvent());
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
    if (_startImageAnimation) {
      _startImageAnimation = false;
      _startStopImageAnimation();
    }
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
        onSelected: handleClick,
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
                ? StandardLiterals.expertMode
                : StandardLiterals.beginnerMode,
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
      onSelected: handleClick,
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

  void handleClick(String value) async {
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
        _displayForecastList();
        break;
      case RaspMenu.opacity:
        _forecastMapStateKey.currentState!.showOverlayOpacitySlider();
        break;
      case RaspMenu.selectRegion:
        _showRegionListScreen();
        break;
      case StandardLiterals.expertMode:
      case StandardLiterals.beginnerMode:
        // toggle flag
        setState(() {
          _beginnerMode = !_beginnerMode;
          _sendEvent(BeginnerModeEvent(_beginnerMode));
        });
        break;
      case RaspMenu.refreshForecast:
        _refreshForecast();
        break;
    }
  }

  Future<void> _displayForecastList({Forecast? forecast = null}) async {
    final result = await Navigator.pushNamed(
        context, ForecastListRouteBuilder.routeName,
        arguments: ForecastListArgs(forecast: forecast));
    if (result != null) {
      if (result is ReturnedForecastArgs) {
        if (result.reorderedForecasts) {
          _sendEvent(LoadForecastTypesEvents());
        }
        if (result.forecast != null) {
          _sendEvent(SelectedRaspForecastEvent(result.forecast!));
        }
      }
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

  void _sendEvent(RaspDataEvent event) {
    BlocProvider.of<RaspDataBloc>(context).add(event);
  }

  void _stopAnimation() {
    _startImageAnimation = false;
    _startStopImageAnimation();
  }

  Widget _getForecastWindow() {
    return ForecastMap(
        key: _forecastMapStateKey, stopAnimation: _stopAnimation);
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
        _sendEvent(SaveRaspDisplayOptionsEvent(oldOption));
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

  void _refreshForecast(){
    _sendEvent(RefreshForecastEvent());
  }

  // TODO create common ProgressIndicator<Bloc,State>  widget and
  // TODO WorkingState (along with error, info, ... states)
  // TODO OK - This will be a bunch of refactoring
  Widget _getProgressIndicator() {
    return BlocConsumer<RaspDataBloc, RaspDataState>(
      listener: (context, state) {},
      buildWhen: (previous, current) {
        return current is RaspWorkingState;
      },
      builder: (context, state) {
        if (state is RaspWorkingState) {
          if (state.working) {
            return Container(
              child: AbsorbPointer(
                  absorbing: true,
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  )),
              alignment: Alignment.center,
              color: Colors.transparent,
            );
          }
        }
        return SizedBox.shrink();
      },
    );
  }
}
