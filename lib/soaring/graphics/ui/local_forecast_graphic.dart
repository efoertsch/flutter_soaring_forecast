import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show GraphLiterals, StandardLiterals;
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/bloc/graphic_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/bloc/graphic_event.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/bloc/graphic_state.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/data/forecast_graph_data.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/ui/grid_widgets.dart';
import 'package:graphic/graphic.dart';

class LocalForecastGraphic extends StatefulWidget {
  LocalForecastGraphic({Key? key}) : super(key: key);

  @override
  State<LocalForecastGraphic> createState() => _LocalForecastGraphicState();
}

class _LocalForecastGraphicState extends State<LocalForecastGraphic> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final forecastChannel = StreamController<GestureSignal>.broadcast();

  bool _isWorking = false;

  double _screenWidth = 0;

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        appBar: getAppBar(context),
        body: _getBody(),
      ),
    );
  }

  AppBar getAppBar(BuildContext context) {
    return AppBar(
      title: Text(GraphLiterals.LOCAL_FORECAST),
      leading: BackButton(onPressed: () => Navigator.pop(context)),
      actions: _getGraphMenu(),
      //  actions: _getAppBarMenu(),
    );
  }

  List<Widget> _getGraphMenu() {
    return <Widget>[
      TextButton(
        child: const Text(StandardLiterals.REFRESH,
            style: TextStyle(color: Colors.white)),
        onPressed: () {
          setState(() {});
        },
      ),
    ];
  }

  Widget _getBody() {
    return Stack(
      children: [
        _widgetForMessages(),
        _getForecastCharts(),
        _getProgressIndicator(),
      ],
    );
  }

  Widget _getForecastCharts() {
    return BlocConsumer<GraphicBloc, GraphState>(
        listener: (context, state) {},
        buildWhen: (previous, current) {
          return current is GraphDataState;
        },
        builder: (context, state) {
          if (state is GraphDataState) {
            return Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8),
              child: Column(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _getLocationTitleWidget(
                            state.forecastData.turnpointTitle,
                            state.forecastData.lat,
                            state.forecastData.lng),
                        //_getChartHeaderWidget('Cu Cloudbase (Sfc.LCL) MSL'),
                        _getCloudbaseWidget(state.forecastData.altitudeData!),
                        _getThermalUpdraftWidget(
                            state.forecastData.thermalData!),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _getGridDataWidget(
                      state.forecastData,
                    ),
                  ),
                ],
              ),
            );
          }
          return SizedBox.shrink();
        });
  }

  Widget _getLocationTitleWidget(
      String? turnpointTitle, double? lat, double? lng) {
    var text;
    if (turnpointTitle != null) {
      text = turnpointTitle;
    } else if (lat != null && lng != null) {
      text = lat.toStringAsFixed(5) + "/" + lng.toStringAsFixed(5);
    }
    if (text != null) {
      return Container(
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Center(
            child: Text(
              text,
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Container _getChartHeaderWidget(String title) {
    return Container(
      child: Center(
        child: Text(
          title,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Container _getCloudbaseWidget(List<Map<String, Object>> forecastData) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      width: _screenWidth - 75,
      height: 300,
      child: Chart(
        data: forecastData,
        rebuild: false,
        padding: (_) => const EdgeInsets.fromLTRB(10, 0, 10, 4),
        variables: {
          'time': Variable(
            accessor: (Map map) => map['time'] as String,
          ),
          'value': Variable(
            accessor: (Map map) => map['value'] as num,
            scale:
                LinearScale(formatter: (value) => '${value.toInt()}', min: 0),
          ),
          'name': Variable(
            accessor: (Map map) => map['name'] as String,
          ),
        },

        coord: RectCoord(
            horizontalRange: [0.01, 0.99], color: const Color(0xffdddddd)),
        //coord: RectCoord(color: const Color(0xffdddddd)),
        elements: [
          LineElement(
            position: Varset('time') * Varset('value') / Varset('name'),
            shape: ShapeAttr(value: BasicLineShape(smooth: true)),
            size: SizeAttr(value: 4.0),
            color: ColorAttr(
              variable: 'name',
              values: Defaults.colors10,
              updaters: {
                'groupMouse': {false: (color) => color.withAlpha(100)},
                'groupTouch': {false: (color) => color.withAlpha(100)},
              },
            ),
          ),
          PointElement(
            size: SizeAttr(value: 4.0),
            color: ColorAttr(
              variable: 'name',
              values: Defaults.colors10,
              updaters: {
                'groupMouse': {false: (color) => color.withAlpha(100)},
                'groupTouch': {false: (color) => color.withAlpha(100)},
              },
            ),
          ),
        ],
        axes: [
          Defaults.horizontalAxis..label = null,
          Defaults.verticalAxis
            ..label = (LabelStyle(
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold))),
        ],
        selections: {'tap': PointSelection(dim: Dim.x)},
        //tooltip: TooltipGuide(),
        crosshair: CrosshairGuide(),
        gestureChannel: forecastChannel,
        annotations: [
          _getMarkAnnotation(
              colorIndex: 0,
              xPosIndex: 0,
              yOffset: 290,
              yPosIndex: -1,
              color: Defaults.colors10[0]),
          _getTagAnnotation(
              label: "Altitude Thermal Strength >= 225fpm (MSL/Dry)",
              xPosIndex: 0,
              yOffset: 290,
              yPosIndex: -1),
          _getMarkAnnotation(
              colorIndex: 1,
              xPosIndex: 0,
              yOffset: 290,
              yPosIndex: 0,
              color: Defaults.colors10[1]),
          _getTagAnnotation(
              label: "Cu Cloudbase(MSL)",
              xPosIndex: 0,
              yOffset: 290,
              yPosIndex: 0),
          _getMarkAnnotation(
              colorIndex: 2,
              xPosIndex: 1,
              yOffset: 290,
              yPosIndex: 0,
              color: Defaults.colors10[2]),
          _getTagAnnotation(
              label: "OD Cloudbase(MSL)",
              xPosIndex: 1,
              yOffset: 290,
              yPosIndex: 0),
        ],
      ),
    );
  }

  Container _getThermalUpdraftWidget(List<Map<String, Object>> forecastData) {
    return Container(
      margin: const EdgeInsets.only(top: 0),
      width: _screenWidth - 75,
      height: 140,
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Chart(
          padding: (_) => const EdgeInsets.fromLTRB(10, 0, 10, 8),
          rebuild: false,
          data: forecastData,
          variables: {
            'time': Variable(
              accessor: (Map map) => map['time'] as String,
            ),
            'value': Variable(
              accessor: (Map map) => map['value'] as num,
              scale:
                  LinearScale(formatter: (value) => '${value.toInt()}', min: 0),
            ),
          },
          coord: RectCoord(color: const Color(0xffdddddd)),
          elements: [
            LineElement(
              color: ColorAttr(
                  variable: 'value', values: [Colors.red, Colors.red]),
              shape: ShapeAttr(value: BasicLineShape(smooth: true)),
              size: SizeAttr(value: 4.0),
            ),
          ],
          axes: [
            Defaults.horizontalAxis
              ..label = (LabelStyle(
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold))),
            Defaults.verticalAxis
              ..label = (LabelStyle(
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold))),
          ],
          selections: {'tap': PointSelection(dim: Dim.x)},
          //tooltip: TooltipGuide(),
          crosshair: CrosshairGuide(),
          gestureChannel: forecastChannel,
          annotations: [
            _getMarkAnnotation(
                colorIndex: 3,
                xPosIndex: 0,
                yOffset: 100,
                yPosIndex: 0,
                color: Colors.red),
            _getTagAnnotation(
                label: "Thermal Updraft ft/min",
                xPosIndex: 0,
                yOffset: 100,
                yPosIndex: 0)
          ],
        ),
      ),
    );
  }

  MarkAnnotation _getMarkAnnotation(
      {required int colorIndex,
      required int xPosIndex,
      required double yOffset,
      required double yPosIndex,
      required color}) {
    return MarkAnnotation(
      relativePath: Path()
        ..addRect(Rect.fromCircle(center: const Offset(0, 0), radius: 5)),
      style: Paint()..color = color,
      anchor: (size) => Offset(
          25 + (xPosIndex == 0 ? 0 : (size.width / 2) * xPosIndex),
          yOffset + 12 * yPosIndex),
    );
  }

  TagAnnotation _getTagAnnotation(
      {required String label,
      required int xPosIndex,
      required double yOffset,
      required double yPosIndex}) {
    return TagAnnotation(
      label: Label(
        label,
        LabelStyle(
            style: textStyleBlackFontSize13, align: Alignment.centerRight),
      ),
      anchor: (size) => Offset(
          34 + (xPosIndex == 0 ? 0 : (size.width / 2) * xPosIndex),
          yOffset + 12 * yPosIndex),
    );
  }

  _sendEvent(GraphicEvent event) {
    BlocProvider.of<GraphicBloc>(context).add(event);
  }

  Widget _getProgressIndicator() {
    return BlocConsumer<GraphicBloc, GraphState>(
      listener: (context, state) {},
      buildWhen: (previous, current) {
        return current is GraphWorkingState;
      },
      builder: (context, state) {
        if (state is GraphWorkingState) {
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

  Widget _widgetForMessages() {
    return BlocListener<GraphicBloc, GraphState>(
      listener: (context, state) async {
        if (state is GraphErrorMsgState) {
          CommonWidgets.showErrorDialog(context, "Error", state.error);
        }
      },
      child: SizedBox.shrink(),
    );
  }

  Widget _getGridDataWidget(ForecastGraphData forecastGraphData) {
    // get list of hours for which forecasts have been made
    final hours = forecastGraphData.hours;
    final descriptions = forecastGraphData.descriptions;
    return ScrollableTable(
        columnHeadings: hours,
        dataCellWidth: 60,
        dataCellHeight: 40,
        headingBackgroundColor: Colors.yellow.withOpacity(0.3),
        descriptionColumnWidth: 125,
        descriptionBackgroundColor: Colors.yellow.withOpacity(0.3),
        dataRowsBackgroundColors: [Colors.white, Colors.green.shade50],
        gridData: forecastGraphData.gridData,
        descriptions: descriptions);
  }
}
