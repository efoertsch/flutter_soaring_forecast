import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide BuildContext;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/app/app_drawer.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_state.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/rasp_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/display_ticker.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/forecast_map.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_types/ui/common_forecast_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_types/ui/forecast_list.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/ui/task_list.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_overhead_view.dart';
import 'package:intl/intl.dart';

import '../bloc/rasp_data_bloc.dart';
import '../bloc/rasp_data_event.dart';

class RaspScreen extends StatefulWidget {
  final BuildContext repositoryContext;

  RaspScreen({Key? key, required this.repositoryContext}) : super(key: key);

  @override
  _RaspScreenState createState() => _RaspScreenState();
}

//TODO - keep more data details in Bloc,
class _RaspScreenState extends State<RaspScreen> with TickerProviderStateMixin {
  final abbrevDateformatter = DateFormat('E, MMM dd');
  late final MapController _mapController;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _forecastMapStateKey = GlobalKey<ForecastMapState>();

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

  late List<PreferenceOption> _raspDisplayOptions;
  late String _selectedRegionName;

  // Executed only when class created
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    stopAnimation();
    super.dispose();
  }

  // Make sure first layout occurs prior to map ready otherwise crash occurs
  @override
  void afterFirstLayout(BuildContext context) {
    // print("First layout complete.");
    // print('Calling series of APIs');
    _sendEvent(InitialRaspRegionEvent());
    _mapController.onReady.then((value) => _sendEvent(MapReadyEvent()));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          key: _scaffoldKey,
          drawer: AppDrawer.getDrawer(context),
          appBar: AppBar(
            title: Text('RASP'),
            actions: getRaspMenu(),
          ),
          body: Padding(
            padding: EdgeInsets.all(8.0),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
              _getForecastModelsAndDates(context),
              _getForecastTypes(context),
              _displayForecastTime(context),
              _getForecastWindow(),
              _widgetForSnackBarMessages(),
              _miscStatesHandlerWidget(),
            ]),
          )
          // }),
          ),
    );
  }

  Widget _getForecastModelsAndDates(BuildContext context) {
    //print('creating/updating main ForecastModelsAndDates');
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: forecastModelDropDownList(),
        ),
        Expanded(
            flex: 7,
            child: Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: forecastDatesDropDownList(context),
            )),
      ],
    );
  }

// Display GFS, NAM, ....
  Widget forecastModelDropDownList() {
    return BlocBuilder<RaspDataBloc, RaspDataState>(
        buildWhen: (previous, current) {
      return current is RaspInitialState || current is RaspForecastModels;
    }, builder: (context, state) {
      //print('creating/updating forecastModelDropDown');
      if (state is RaspForecastModels) {
        return DropdownButton<String>(
          style: CustomStyle.bold18(context),
          value: (state.selectedModelName),
          hint: Text('Select Model'),
          isExpanded: true,
          iconSize: 24,
          elevation: 16,
          onChanged: (String? newValue) {
            // print('Selected model onChanged: $newValue');
            _sendEvent(SelectedRaspModelEvent(newValue!));
          },
          items: state.modelNames.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value.toUpperCase()),
            );
          }).toList(),
        );
      } else {
        return Text("Getting Forecast Models");
      }
    });
  }

// Display forecast dates for selected model (eg. GFS)
  Widget forecastDatesDropDownList(BuildContext context) {
    return BlocBuilder<RaspDataBloc, RaspDataState>(
        buildWhen: (previous, current) {
      return current is RaspInitialState || current is RaspModelDates;
    }, builder: (context, state) {
      //print('creating/updating forecastDatesDropDown');
      if (state is RaspModelDates) {
        final _shortDOWs = _reformatDatesToDOW(state.forecastDates);
        final _selectedForecastDOW =
            _shortDOWs[state.forecastDates.indexOf(state.selectedForecastDate)];
        final _forecastDates = state.forecastDates;
        return DropdownButton<String>(
          style: CustomStyle.bold18(context),
          isExpanded: true,
          value: _selectedForecastDOW,
          onChanged: (String? newValue) {
            final selectedForecastDate =
                _forecastDates[_shortDOWs.indexOf(newValue!)];
            _sendEvent(SelectRaspForecastDateEvent(selectedForecastDate));
          },
          items: _shortDOWs.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        );
      } else {
        return Text("Getting Forecast Dates");
      }
    });
  }

// Display description of forecast types (eq. 'Thermal Updraft Velocity (W*)' for wstar)
  Widget _getForecastTypes(BuildContext context) {
    return BlocBuilder<RaspDataBloc, RaspDataState>(
        buildWhen: (previous, current) {
      return current is RaspInitialState || current is RaspForecasts;
    }, builder: (context, state) {
      //print('creating/updating ForecastTypes');
      if (state is RaspForecasts) {
        return _getSelectedForecastDisplay(context, state.selectedForecast);
        //_getForecastDropDown(context, state);
      } else {
        return Text("Getting Forecasts");
      }
    });
  }

  Widget _getSelectedForecastDisplay(BuildContext context, Forecast forecast) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: InkWell(
                    onTap: () {
                      CommonForecastWidgets.showForecastDescriptionBottomSheet(
                          context, forecast);
                    },
                    child: Constants.getForecastIcon(
                        forecast.forecastCategory.toString())),
              ),
              Flexible(
                  fit: FlexFit.tight,
                  child: InkWell(
                    onTap: () {
                      _displayForecastList(forecast: forecast);
                    },
                    child: Text(
                      forecast.forecastNameDisplay,
                      style: CustomStyle.bold18(context),
                    ),
                  )),
              InkWell(
                onTap: () {
                  _displayForecastList(forecast: forecast);
                },
                child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.arrow_drop_down_outlined)),
              )
            ],
          ),
        ),
        const Divider(
            height: 1,
            thickness: 1,
            indent: 0,
            endIndent: 0,
            color: Colors.black12),
      ],
    );
  }

// Display forecast time for model and date
  Widget _displayForecastTime(BuildContext context) {
    //print('creating/updating ForecastTime');
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
                //print('creating/updating ForecastTime value');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(state.error),
          ),
        );
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
    return BlocConsumer<RaspDataBloc, RaspDataState>(
        listener: (context, state) {
      if (state is RaspDisplayOptionsState) {
        // print("Received RaspDisplayOptionsState");
        _raspDisplayOptions = state.displayOptions;
      }
      if (state is SelectedRegionNameState) {
        _selectedRegionName = state.selectedRegionName;
      }
    }, builder: (context, state) {
      return SizedBox.shrink();
    });
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
      //print('Started timer');
    } else {
      //print('Stopping timer');
      if (_tickerSubscription != null) {
        _tickerSubscription!.cancel();
        _displayTimer!.cancelTimer();
        _displayTimer = null;
      }
      // print('Stopped timer');
    }
  }

  void stopAnimation() {
    if (_startImageAnimation) {
      _startImageAnimation = false;
      _startStopImageAnimation();
    }
  }

  List<Widget> getRaspMenu() {
    return <Widget>[
      TextButton(
        child: const Text('SELECT TASK', style: TextStyle(color: Colors.white)),
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
            RaspMenu.displayOptions,
            // RaspMenu.mapBackground,
            RaspMenu.reorderForecasts,
            RaspMenu.opacity,
            RaspMenu.selectRegion
          }.map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
      ),
    ];
  }

  _selectTask() async {
    final result = await Navigator.pushNamed(context, TaskList.routeName,
        arguments: TaskListScreen.SELECT_TASK_OPTION);
    if (result != null && result is int && result > -1) {
      //print('Draw task for ' + result.toString());
      _sendEvent(GetTaskTurnpointsEvent(result));
    }
  }

  void handleClick(String value) async {
    switch (value) {
      case RaspMenu.clearTask:
        _sendEvent(ClearTaskEvent());
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
    }
  }

  Future<void> _displayForecastList({Forecast? forecast = null}) async {
    final result = await Navigator.pushNamed(context, ForecastList.routeName,
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
    final result = await Navigator.pushNamed(
      context,
      TurnpointView.routeName,
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
    final result = await Navigator.pushNamed(context, RegionList.routeName,
        arguments: _selectedRegionName);
    if (result != null && result is String) {
      print("selected region: result");
      // user switched to another region
      if (result != _selectedRegionName) ;
      _sendEvent(InitialRaspRegionEvent());
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

  List<String> _reformatDatesToDOW(List<String> forecastDates) {
    final List<String> shortDOWs = [];
    forecastDates.forEach((date) {
      final realDate = DateTime.tryParse(date);
      if (realDate != null) {
        shortDOWs.add(abbrevDateformatter.format(realDate));
      }
    });
    return shortDOWs;
  }
}
