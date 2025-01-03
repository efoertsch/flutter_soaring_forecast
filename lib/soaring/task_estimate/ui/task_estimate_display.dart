import 'dart:async';
import 'dart:io';

import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show StandardLiterals, TaskEstimateLiterals;
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/region_model/ui/model_date_display.dart';
import 'package:flutter_soaring_forecast/soaring/task_estimate/ui/task_estimate_progress_indicator.dart';

import '../../../main.dart';
import '../../forecast_hour/forecast_hour_cubit.dart';
import '../../forecast_hour/forecast_hour_state.dart';
import '../../forecast_hour/forecast_hour_widget.dart';
import '../../region_model/bloc/region_model_bloc.dart';
import '../../region_model/bloc/region_model_event.dart';
import '../../region_model/bloc/region_model_state.dart';
import '../../repository/rasp/estimated_flight_avg_summary.dart';
import '../cubit/task_estimate_cubit.dart';
import '../cubit/task_estimate_state.dart';

class TaskEstimateDisplay extends StatefulWidget {
  TaskEstimateDisplay({Key? key}) : super(key: key);

  @override
  State<TaskEstimateDisplay> createState() => _TaskEstimateDisplayState();
}

class _TaskEstimateDisplayState extends State<TaskEstimateDisplay> {
  static const String _HELP = "HELP";
  static const String _EXPERIMENTAL_ESTIMATED_FLIGHT_TEXT =
      "This is a feature based on Dr. Jack logic that calculates a task's estimated flight time"
      " and flight information based on the forecast and a glider's min sink rate and polar."
      "\n\nThe specific forecast values used in the estimated flight time calculations are:"
      "\n1. Thermal Updraft Velocity (W*)"
      "\n2. Wind speed (Boundary Layer average)"
      "\n3. Wind direction (Boundary Layer average)"
      "\n\nNote that thermal height is not used so you may be gliding at treetop height!"
      "\n\nTask time, headwind, and related estimates are based on a straight line"
      " course between turnpoints. (Yeah - how often does that happen.) "
      "\n\nFeedback is most welcome. ";

  static const String _SELECT_GLIDER = "Select Glider";

  TaskEstimateCubit _getTaskEstimateCubit() =>
      BlocProvider.of<TaskEstimateCubit>(context);

  ForecastHourCubit _getForecastHourCubit() =>
      BlocProvider.of<ForecastHourCubit>(context);

  void _sendEvent(dynamic event) {
    if (event is RegionModelEvent) {
      BlocProvider.of<RegionModelBloc>(context).add(event);
    }
  }

  bool _showExperimentalDialog = false;
  bool _beginnerMode = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return ConditionalWillPopScope(
        onWillPop: _onWillPop,
        shouldAddCallback: true,
        child: _buildSafeArea(context),
      );
    } else {
      //iOS
      return GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.direction >= 0) {
            _onWillPop();
          }
        },
        child: _buildSafeArea(context),
      );
    }
  }

  SafeArea _buildSafeArea(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: getAppBar(context),
        body: _getBody(),
      ),
    );
  }

  AppBar getAppBar(BuildContext context) {
    return AppBar(
      title: Text(TaskEstimateLiterals.TASK_ESTIMATE),
      leading: BackButton(onPressed: () => _onWillPop()),
      actions: _getMenu(),
      //  actions: _getAppBarMenu(),
    );
  }

  List<Widget> _getMenu() {
    return <Widget>[
      TextButton(
          child: const Text(_HELP, style: TextStyle(color: Colors.white)),
          onPressed: () {
            _getTaskEstimateCubit().showExperimentalTextHelp();
          }),
      PopupMenuButton<String>(
          onSelected: _handleClick,
          icon: Icon(Icons.more_vert),
          itemBuilder: (BuildContext context) {
            return {
              _SELECT_GLIDER,
              _beginnerMode
                  ? StandardLiterals.EXPERT_MODE
                  : StandardLiterals.BEGINNER_MODE,
              // _DISPLAY_EXPERIMENTAL_TEXT,
            }.map((String choice) {
              // only one choice
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          }),
    ];
  }

  void _handleClick(String value) async {
    switch (value) {
      case _SELECT_GLIDER:
        await _getGlider();
        break;
      case StandardLiterals.EXPERT_MODE:
      case StandardLiterals.BEGINNER_MODE:
        // toggle flag
        //setState(() {
        _sendEvent(BeginnerModeEvent(!_beginnerMode));
      //});
      // case _DISPLAY_EXPERIMENTAL_TEXT:
      //   resetDisplayExperimentalText();
      //   break;
    }
  }

  Future<void> _getGlider() async {
    Object? glider =
        await Navigator.pushNamed(context, GliderPolarListBuilder.routeName);
    if (glider is String && glider.isNotEmpty) {
      _getTaskEstimateCubit().calcEstimatedTaskWithNewGlider();
    }
  }

  void resetDisplayExperimentalText() async {
    _getTaskEstimateCubit().resetExperimentalTextDisplay();
  }

  Widget _getBody() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: ModelDatesDisplay(),
        ),
        ForecastHourDisplay(displayPauseLoop: false),
    Expanded(
      child: SingleChildScrollView(
          child:Stack(
            children: [
              Container(
                  child: _showEstimatedTaskAvgTable(),
                ),
              TaskEstimateProgressIndicator()
            ],
          )),
    ),
       // _getOptimalFlightCloseButton(),
        _regionModelStatesHandler(),
        _taskEstimateStatesHandler(),
        _forecastHourHandler(),
      ],
    );
  }

  Widget _regionModelStatesHandler() {
    return BlocListener<RegionModelBloc, RegionModelState>(
      listener: (context, state) {
        // This listener fires AFTER the return to the
        // RASP screen and a refresh fires off a
        // ForecastModelsAndDates state. Don't know why this
        // still fires but checking the current route check is
        // a way to ignore this state. Yes - seems like a hack
        final route = ModalRoute.of(context);
        final isCurrentRoute = route?.isCurrent ?? false;
        if (isCurrentRoute) {
          if (state is EstimatedTaskRegionModelState) {
            _getTaskEstimateCubit()
                .setRegionModelDateParms(state.estimatedTaskRegionModel);
          }
          if (state is ForecastModelsAndDates) {
            _beginnerMode = state.beginnerMode;
            // the model or date changed, send the info on so get new estimate
            _getTaskEstimateCubit().processModelDateChange(
                regionName: state.regionName,
                selectedModelName: state.modelNames[state.modelNameIndex],
                selectedDate: state.forecastDates[state.forecastDateIndex],
                forecastHours: state.localTimes,
                selectedHourIndex: state.localTimeIndex);
            _getForecastHourCubit()
                .setForecastHour(state.localTimes[state.localTimeIndex]);
          }
        }
      },
      child: SizedBox.shrink(),
    );
  }

  Widget _taskEstimateStatesHandler() {
    return BlocListener<TaskEstimateCubit, TaskEstimateState>(
      listener: (context, state) async {
        if (state is DisplayGlidersState) {
          _getGlider();
        }
        if (state is CurrentHourState) {
          _getForecastHourCubit().setForecastHour(state.hour);
        }
        if (state is DisplayExperimentalHelpText) {
          _displayEstimatedFlightHelp(
              state.showExperimentalText, state.calcAfterShow);
        }
      },
      child: SizedBox.shrink(),
    );
  }

  Widget _forecastHourHandler() {
    return BlocListener<ForecastHourCubit, ForecastHourState>(
      listener: (context, state) async {
        if (state is IncrDecrHourIndexState) {
          _getTaskEstimateCubit().updateTimeIndex(state.incrDecrIndex);
        }
      },
      child: SizedBox.shrink(),
    );
  }

  Widget _showEstimatedTaskAvgTable() {
    return BlocConsumer<TaskEstimateCubit, TaskEstimateState>(
      listener: (context, state) {
        if (state is EstimatedFlightSummaryState) {}
      },
      buildWhen: (previous, current) {
        return current is EstimatedFlightSummaryState;
      },
      builder: (context, state) {
        if (state is EstimatedFlightSummaryState) {
          return _getOptimalFlightSummary(state.estimatedFlightSummary!);
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  Widget _getOptimalFlightSummary(EstimatedFlightSummary optimalTaskSummary) {
    return SingleChildScrollView(
      child: Column(children: [
        _getOptimalFlightParms(optimalTaskSummary),
        //_getTurnpointsTableHeader(),
        //_getTaskTurnpointsTable(optimalTaskSummary),
        _getLegTableHeader(),
        _getLegDetailsTable(optimalTaskSummary),
        _getWarningMsgDisplay(optimalTaskSummary),
      ]),
    );
  }

  RenderObjectWidget _getOptimalFlightParms(
      EstimatedFlightSummary optimalTaskSummary) {
    if (optimalTaskSummary.routeSummary?.header != null) {
      var header = optimalTaskSummary.routeSummary?.header;
      var headerTable = Table(
        columnWidths: {0: IntrinsicColumnWidth(), 1: IntrinsicColumnWidth()},
        border: TableBorder.all(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: <TableRow>[
          TableRow(
            children: [
              _formattedTextCell("Glider " + (header!.glider ?? "")),
              _formattedTextCell("L/D= " +
                  double.parse(header.maxLd ?? "0").toStringAsFixed(1)),
            ],
          ),
          TableRow(
            children: [
              _formattedTextCell("Polar Speed Adjustment"),
              _formattedTextCell(
                  double.parse(header.polarSpeedAdjustment ?? "0")
                      .toStringAsFixed(1)),
            ],
          ),
          TableRow(
            children: [
              _formattedTextCell("Thermaling Sink \nRate (ft/min)"),
              _formattedTextCell(double.parse(header.thermalingSinkRate ?? "0")
                  .toStringAsFixed(1)),
            ],
          ),
        ],
      );
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: headerTable,
      );
    }
    return SizedBox.shrink();
  }

  Widget _formattedTextCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text,
          style: textStyleBoldBlackFontSize18, textAlign: TextAlign.center),
    );
  }

  // Keeping code in case want to display it again
  Widget _getTaskTurnpointsTable(EstimatedFlightSummary optimalTaskSummary) {
    if (optimalTaskSummary.routeSummary?.routeTurnpoints != null) {
      var routeTurnPoints = optimalTaskSummary.routeSummary!.routeTurnpoints;
      var turnpointRows = _getTaskTurnpointTableRows(routeTurnPoints!);
      var headerTable = Table(
        columnWidths: {
          0: IntrinsicColumnWidth(),
          1: IntrinsicColumnWidth(),
          2: IntrinsicColumnWidth(),
          3: IntrinsicColumnWidth(),
        },
        border: TableBorder.all(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: turnpointRows,
      );
      return headerTable;
    }
    return SizedBox.shrink();
  }

  List<TableRow> _getTaskTurnpointTableRows(List<RouteTurnpoint> turnpoints) {
    var routePointTableRows = <TableRow>[];
    for (var routePoint in turnpoints) {
      var tableRow = TableRow(
        children: [
          _formattedTextCell(routePoint.number ?? " "),
          _formattedTextCell(routePoint.name ?? " "),
          _formattedTextCell(
              double.parse(routePoint.lat ?? "0").toStringAsFixed(5)),
          _formattedTextCell(
              double.parse(routePoint.lon ?? "0").toStringAsFixed(5)),
        ],
      );
      routePointTableRows.add(tableRow);
    }
    return routePointTableRows;
  }

  Widget _getLegDetailsTable(EstimatedFlightSummary optimalTaskSummary) {
    var legDetailRows = _getLegTableRows(
        optimalTaskSummary.routeSummary!.legDetails!,
        optimalTaskSummary.routeSummary!.routeTurnpoints!);
    var legDetailTable = Table(
      columnWidths: {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: IntrinsicColumnWidth(),
        3: IntrinsicColumnWidth(),
        4: IntrinsicColumnWidth(),
        5: IntrinsicColumnWidth(),
        6: IntrinsicColumnWidth(),
        7: IntrinsicColumnWidth(),
        8: IntrinsicColumnWidth(),
        9: IntrinsicColumnWidth(),
        10: IntrinsicColumnWidth(),
        11: IntrinsicColumnWidth(),
      },
      border: TableBorder.all(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: legDetailRows,
    );
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          margin: EdgeInsets.only(right: 8),
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, child: legDetailTable)),
    );
  }

//  routeTurnpoints.length must be legDetails.length -1
  List<TableRow> _getLegTableRows(
      List<LegDetail> legDetails, List<RouteTurnpoint> routeTurnPoints) {
    var legDetailTableRows = <TableRow>[];
    legDetailTableRows.add(_getLegDetailLabels());
    for (int i = 0; i < legDetails.length; ++i) {
      var tableRow = TableRow(
        children: [
          (i < legDetails.length - 1)
              ? (_formattedTextCell((routeTurnPoints[i].name ?? "") +
                  " - " +
                  (routeTurnPoints[i + 1].name ?? " ")))
              : _formattedTextCell(legDetails[i].leg ?? " "),
          _formattedTextCell(legDetails[i].clockTime ??
              (legDetails[i].message != null ? legDetails[i].message! : "")),
          _formattedTextCell(double.parse(legDetails[i].optFlightTimeMin ?? "0")
              .toStringAsFixed(0)),
          _formattedTextCell(double.parse(legDetails[i].sptlAvgDistKm ?? "0")
              .toStringAsFixed(1)),
          //  convert tailwind to headwind
          // _formattedTextCell(
          //    (double.parse(legDetail.sptlAvgTailWind ?? "0") * -1)
          //        .toStringAsFixed(0)),
          //  _formattedTextCell(double.parse(legDetail.sptlAvgClimbRate ?? "0")
          //      .toStringAsFixed(0)),
          //  convert tailwind to headwind
          _formattedTextCell(
              (double.parse(legDetails[i].optAvgTailWind ?? "0") *
                      ((legDetails[i].optAvgTailWind ?? "0") != "0" ? -1 : 1))
                  .toStringAsFixed(0)),
          _formattedTextCell(double.parse(legDetails[i].optAvgClimbRate ?? "0")
              .toStringAsFixed(0)),
          _formattedTextCell(
              double.parse(legDetails[i].optFlightGrndSpeedKt ?? "0")
                  .toStringAsFixed(0)),
          _formattedTextCell(
              double.parse(legDetails[i].optFlightGrndSpeedKmh ?? "0")
                  .toStringAsFixed(0)),
          _formattedTextCell(
              double.parse(legDetails[i].optFlightAirSpeedKt ?? "0")
                  .toStringAsFixed(0)),
          _formattedTextCell(
              double.parse(legDetails[i].optFlightThermalPct ?? "0")
                  .toStringAsFixed(0)),
        ],
      );
      legDetailTableRows.add(tableRow);
    }
    return legDetailTableRows;
  }

  TableRow _getLegDetailLabels() {
    return TableRow(
      children: [
        _formattedTextCell("LEG"),
        _formattedTextCell("ClockTime"),
        _formattedTextCell("Time\nMin"),
        _formattedTextCell("Dist\nkm"),
        _formattedTextCell("Head\nWind\nkt"),
        _formattedTextCell("Clmb\nRate\nkt"),
        _formattedTextCell("Gnd\nSpd\nkt"),
        _formattedTextCell("Gnd\nSpd\nkm/h"),
        _formattedTextCell("Air\nSpd\nkt"),
        _formattedTextCell("Thermaling\nPct\n%"),
      ],
    );
  }

  // Keeping in case want to display this info again
  Widget _getTurnpointsTableHeader() {
    return Center(
      child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text("Task Turnpoints", style: textStyleBoldBlackFontSize18)),
    );
  }

  Widget _getLegTableHeader() {
    return Center(
      child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            "Leg Details\nUsing wind-adjusted speed-to-fly",
            style: textStyleBoldBlackFontSize18,
            textAlign: TextAlign.center,
          )),
    );
  }

  Widget _getWarningMsgDisplay(EstimatedFlightSummary optimalTaskSummary) {
    List<Footer> footers =
        optimalTaskSummary.routeSummary?.footers ?? <Footer>[];
    List<Widget> warnings = [];

    footers.forEach((footer) {
      warnings.add(_formattedTextCell(footer.message ?? ""));
    });
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: warnings,
    );
  }

  Widget _getOptimalFlightCloseButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity,
                40), // double.infinity is the width and 30 is the height
            foregroundColor: Colors.white,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Text("Close"),
          onPressed: () {
            _onWillPop();
          },
        ),
      ),
    );
  }

  void _displayEstimatedFlightHelp(
      bool showExperimentalText, bool calcAfterShow) async {
    CommonWidgets.showTextAndCheckboxDialogBuilder(
        context: context,
        title: "TASK FLIGHT ESTIMATES\n(EXPERIMENTAL)",
        child: _getExperimentalFlightTextWidget(showExperimentalText),
        button1Text: StandardLiterals.OK,
        button1Function: (() {
          Navigator.pop(context);
          if (calcAfterShow) {
            _getTaskEstimateCubit().doCalc();
          }
        }));
  }

  Widget _getExperimentalFlightTextWidget(bool showExperimentalText) {
    _showExperimentalDialog = showExperimentalText;
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
            child: Text(_EXPERIMENTAL_ESTIMATED_FLIGHT_TEXT),
          ),
          StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return CheckboxListTile(
              title: Text(
                  "Do not display on start. (Will always display via HELP)"),
              controlAffinity: ListTileControlAffinity.leading,
              value: !_showExperimentalDialog,
              onChanged: (newValue) async {
                _showExperimentalDialog = newValue != null ? !newValue : true;
                await _getTaskEstimateCubit()
                    .displayExperimentalText(_showExperimentalDialog);
                setState(() {
                  // Seems like flutter wants async task out of setstate
                  // if checked then DO NOT display experimental text, hence save as false
                });
              },
            );
          })
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context);
    return true;
  }
}
