import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show GraphLiterals, StandardLiterals;
import 'package:flutter_soaring_forecast/soaring/graphics/bloc/graphic_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/bloc/graphic_event.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/bloc/graphic_state.dart';
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

      //  actions: _getAppBarMenu(),
    );
  }

  Widget _getBody() {
    return Stack(
      children: [
        _getForecastCharts(),
        _getProgressIndicator(),
        _widgetForMessages(),
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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _getLocationName(state.forecastData.turnpointTitle),
                    _getChartHeader('Cu Cloudbase (Sfc.LCL) MSL'),
                    _getCloudbase(state.forecastData.altitudeData!),
                    _getThermalUpdraft(state.forecastData.thermalData!),
                  ],
                ),
              ),
            );
          }
          return SizedBox.shrink();
        });
  }

  Widget _getLocationName(String? turnpointTitle) {
    if (turnpointTitle != null) {
      return Container(
        child: Center(
          child: Text(
            turnpointTitle,
            style: TextStyle(fontSize: 20),
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Container _getChartHeader(String title) {
    return Container(
      child: Center(
        child: Text(
          title,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Container _getCloudbase(List<Map<String, Object>> forecastData) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      width: _screenWidth - 75,
      height: 400,
      child: Chart(
        data: forecastData,
        rebuild: false,
        padding: (_) => const EdgeInsets.fromLTRB(10, 0, 10, 4),
        variables: {
          'Time': Variable(
            accessor: (Map map) => map['Time'] as String,
          ),
          'value': Variable(
            accessor: (Map map) => map['value'] as num,
          ),
          'code': Variable(
            accessor: (Map map) => map['code'] as String,
          ),
        },
        coord: RectCoord(horizontalRange: [0.01, 0.99]),
        elements: [
          LineElement(
            position: Varset('Time') * Varset('value') / Varset('code'),
            shape: ShapeAttr(value: BasicLineShape(smooth: true)),
            size: SizeAttr(value: 4.0),
            color: ColorAttr(
              variable: 'code',
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
              variable: 'code',
              values: Defaults.colors10,
              updaters: {
                'groupMouse': {false: (color) => color.withAlpha(100)},
                'groupTouch': {false: (color) => color.withAlpha(100)},
              },
            ),
          ),
        ],
        axes: [
          Defaults.horizontalAxis,
          Defaults.verticalAxis,
        ],
        selections: {'tap': PointSelection(dim: Dim.x)},
        tooltip: TooltipGuide(),
        crosshair: CrosshairGuide(),
        gestureChannel: forecastChannel,
      ),
    );
  }

  Container _getThermalUpdraft(List<Map<String, Object>> forecastData) {
    return Container(
      margin: const EdgeInsets.only(top: 0),
      width: _screenWidth - 75,
      height: 80,
      child: Chart(
        padding: (_) => const EdgeInsets.fromLTRB(10, 0, 10, 8),
        rebuild: false,
        data: forecastData,
        variables: {
          'Time': Variable(
            accessor: (Map map) => map['Time'] as String,
          ),
          'value': Variable(
            accessor: (Map map) => map['value'] as num,
          ),
        },
        coord: RectCoord(color: const Color(0xffdddddd)),
        elements: [
          LineElement(
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
        tooltip: TooltipGuide(),
        crosshair: CrosshairGuide(),
        gestureChannel: forecastChannel,
      ),
    );
  }

  _sendEvent(GraphicEvent event) {
    BlocProvider.of<GraphicBloc>(context).add(event);
  }

  Widget _getProgressIndicator() {
    return BlocListener<GraphicBloc, GraphState>(
      listener: (context, state) {
        if (state is GraphWorkingState) {
          _isWorking = state.working;
        }
      },
      child: _isWorking
          ? Container(
              child: AbsorbPointer(
                  absorbing: true,
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  )),
              alignment: Alignment.center,
              color: Colors.transparent,
            )
          : SizedBox.shrink(),
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
}
