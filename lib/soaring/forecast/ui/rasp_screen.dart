import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide BuildContext;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/app/app_drawer.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/app/main.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_state.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/rasp_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/display_ticker.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/forecast_map.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/ui/task_list.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_overhead_view.dart';

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
  late final MapController _mapController;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _displayOptionsController =
      StreamController<PreferenceOption>.broadcast();

// TODO internationalize literals
  String _pauseAnimationLabel = "Pause";
  String _loopAnimationLabel = "Loop";

// Start forecast display with animation running
  bool _startImageAnimation = false;
  int _currentImageIndex = 0;
  int _lastImageIndex = 0;

  SoaringForecastImageSet? soaringForecastImageSet;
  DisplayTimer? _displayTimer;

  Stream<int>? _overlayPositionCounter;
  StreamSubscription<int>? _tickerSubscription;

  late List<PreferenceOption> _raspDisplayOptions;

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
    _fireEvent(context, InitialRaspRegionEvent());
    _mapController.onReady
        .then((value) => _fireEvent(context, MapReadyEvent()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawer.getDrawer(context),
        appBar: AppBar(
          title: Text('RASP'),
          actions: getRaspMenu(),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
              _getForecastModelsAndDates(context),
              _getForecastTypes(context),
              _displayForecastTime(context),
              _getForecastWindow(),
              _widgetForSnackBarMessages(),
              _widgetToGetRaspDisplayOptions(),
            ]),
          ),
        )
        // }),
        );
  }

  Widget _getForecastModelsAndDates(BuildContext context) {
    print('creating/updating main ForecastModelsAndDates');
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
      print('creating/updating forecastModelDropDown');
      if (state is RaspForecastModels) {
        return DropdownButton<String>(
          style: CustomStyle.bold18(context),
          value: (state.selectedModelName),
          hint: Text('Select Model'),
          isExpanded: true,
          iconSize: 24,
          elevation: 16,
          onChanged: (String? newValue) {
            print('Selected model onChanged: $newValue');
            _fireEvent(context, SelectedRaspModelEvent(newValue!));
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
      print('creating/updating forecastDatesDropDown');
      if (state is RaspModelDates) {
        return DropdownButton<String>(
          style: CustomStyle.bold18(context),
          isExpanded: true,
          value: state.selectedForecastDate,
          onChanged: (String? newValue) {
            _fireEvent(context, SelectRaspForecastDateEvent(newValue!));
          },
          items:
              state.forecastDates.map<DropdownMenuItem<String>>((String value) {
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
      print('creating/updating ForecastTypes');
      if (state is RaspForecasts) {
        return DropdownButton<String>(
          style: CustomStyle.bold18(context),
          isExpanded: true,
          value: state.selectedForecast.forecastNameDisplay,
          onChanged: (String? newValue) {
            var selectedForecast = state.forecasts.firstWhere(
                (forecast) => forecast.forecastNameDisplay == newValue);
            _fireEvent(context, SelectedRaspForecastEvent(selectedForecast));
          },
          items: state.forecasts
              .map((forecast) => forecast.forecastNameDisplay)
              .toList()
              .map<DropdownMenuItem<String>>((String? value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value!),
            );
          }).toList(),
        );
      } else {
        return Text("Getting Forecasts");
      }
    });
  }

// Display forecast time for model and date
  Widget _displayForecastTime(BuildContext context) {
    print('creating/updating ForecastTime');
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
                    _fireEvent(context, PreviousTimeEvent());
                    setState(() {});
                  },
                  child: IncrDecrIconWidget.getIncIconWidget('<'),
                )),
            Expanded(
              flex: 6,
              child: BlocBuilder<RaspDataBloc, RaspDataState>(
                  buildWhen: (previous, current) {
                return current is RaspInitialState ||
                    current is RaspForecastImageSet;
              }, builder: (context, state) {
                print('creating/updating ForecastTime value');
                if (state is RaspForecastImageSet) {
                  var localTime = state.soaringForecastImageSet.localTime;
                  _currentImageIndex = state.displayIndex;
                  _lastImageIndex = state.numberImages - 1;
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
                    _fireEvent(context, NextTimeEvent());
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

  void _fireEvent(BuildContext context, RaspDataEvent event) {
    BlocProvider.of<RaspDataBloc>(context).add(event);
  }

  Widget _widgetForSnackBarMessages() {
    return BlocConsumer<RaspDataBloc, RaspDataState>(
        listener: (context, state) {
      if (state is RaspDataLoadErrorState) {
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
      if (state is RaspDataLoadErrorState) {
        return SizedBox.shrink();
      } else {
        return SizedBox.shrink();
      }
    });
  }

  Widget _widgetToGetRaspDisplayOptions() {
    return BlocBuilder<RaspDataBloc, RaspDataState>(builder: (context, state) {
      if (state is RaspDisplayOptionsState) {
        _raspDisplayOptions = state.displayOptions;
      }
      return SizedBox.shrink();
    });
  }

  void _startStopImageAnimation() {
    //TODO timer and subscription to convoluted. Make simpler
    if (_startImageAnimation) {
      _displayTimer = DisplayTimer(Duration(seconds: 3));
      _overlayPositionCounter = _displayTimer!.stream;
      _tickerSubscription = _overlayPositionCounter!.listen((int counter) {
        _fireEvent(context, NextTimeEvent());
      });
      _displayTimer!.setStartAndLimit(_currentImageIndex, _lastImageIndex);
      _displayTimer!.startTimer();
      print('Started timer');
    } else {
      print('Stopping timer');
      if (_tickerSubscription != null) {
        _tickerSubscription!.cancel();
        _displayTimer!.cancelTimer();
        _displayTimer = null;
      }
      print('Stopped timer');
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
            RaspMenu.mapBackground,
            RaspMenu.orderForecasts,
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
      print('Draw task for ' + result.toString());
      _fireEvent(context, GetTaskTurnpointsEvent(result));
    }
  }

  void handleClick(String value) {
    switch (value) {
      case RaspMenu.clearTask:
        _fireEvent(context, ClearTaskEvent());
        break;
      case RaspMenu.displayOptions:
        _showMapDisplayOptionsDialog();
        break;
      case RaspMenu.mapBackground:
        break;
      case RaspMenu.orderForecasts:
        break;
      case RaspMenu.opacity:
        break;
      case RaspMenu.selectRegion:
        break;
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
        stopAnimation: _stopAnimation,
        displayOptionsController: _displayOptionsController);
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

  // Process the change in the preference/display option
  // Since you are here you know the preference/display option has been toogled
  void _processSelectedOptionChange(
      PreferenceOption preferenceOption, bool newValue) {
    // save change
    _sendEvent(SaveRaspDisplayOptionsEvent(preferenceOption));
  }
}
