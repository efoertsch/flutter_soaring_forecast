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

  @override
  Widget build(BuildContext context) {
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
    return BlocBuilder<GraphicBloc, GraphState>(buildWhen: (previous, current) {
      return current is GraphDataState;
    }, builder: (context, state) {
      if (state is GraphDataState) {
        return SingleChildScrollView(
          child: Center(
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 5),
                  child: const Text(
                    'Cu Cloudbase (Sfc.LCL) MSL',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 350,
                  height: 300,
                  child: Chart(
                    data: state.forecastData,
                    rebuild: false,
                    padding: (_) => const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    variables: {
                      'Time': Variable(
                        accessor: (Map map) => map['Time'] as String,
                      ),
                      'Cu Cloudbase (Sfc.LCL) MSL': Variable(
                        accessor: (Map map) =>
                            map['Cu Cloudbase (Sfc.LCL) MSL'] as num,
                      ),
                    },
                    elements: [
                      LineElement(
                        shape: ShapeAttr(value: BasicLineShape(smooth: true)),
                        size: SizeAttr(value: 4.0),
                      ),
                    ],
                    coord: RectCoord(color: const Color(0xffdddddd)),
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
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 5),
                  child: const Text(
                    'Thermal Updraft Velocity (ft/min)',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 0),
                  width: 350,
                  height: 80,
                  child: Chart(
                    padding: (_) => const EdgeInsets.fromLTRB(10, 20, 10, 8),
                    rebuild: false,
                    data: state.forecastData,
                    variables: {
                      'Time': Variable(
                        accessor: (Map map) => map['Time'] as String,
                      ),
                      'Thermal Updraft Velocity (W*)': Variable(
                        accessor: (Map map) =>
                            map['Thermal Updraft Velocity (W*)'] as num,
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
                ),
              ],
            ),
          ),
        );
      } else {
        return SizedBox.shrink();
      }
    });
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
