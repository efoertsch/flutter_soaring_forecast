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
import 'package:flutter_soaring_forecast/soaring/graphics/shapes/custom_shapes.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/ui/grid_widgets.dart';
import 'package:graphic/graphic.dart';
import 'package:intl/intl.dart';

class LocalForecastGraphic extends StatefulWidget {
  LocalForecastGraphic({Key? key}) : super(key: key);

  @override
  State<LocalForecastGraphic> createState() => _LocalForecastGraphicState();
}

class _LocalForecastGraphicState extends State<LocalForecastGraphic> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final forecastChannel = StreamController<GestureSignal>.broadcast();

  double _screenWidth = 0;
  double _chartWidthMargin = 30;
  double graphLegendOffset = 40; // used to place legends on graph
  final abbrevDateformatter = DateFormat('E, MMM dd');

  final altitudeGraphBackground = Colors.blue[200];

  // Used to determine chart point colors, size, shape, and legends
  bool cuInForecast = false;
  bool odInForecast = false;
  final sizeOfPoints = <double>[];
  final colorsOfPoints = <Color>[];
  final shapesOfPoints = <PointShape>[];
  final annotationsOfPoints = <Annotation>[];
  final crossHairGuide = [
    StrokeStyle(color: Colors.black38),
    StrokeStyle(color: Colors.black38)
  ];

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
        _getForecastGraphWidgets(),
        _getProgressIndicator(),
      ],
    );
  }

  Widget _getForecastGraphWidgets() {
    return BlocConsumer<GraphicBloc, GraphState>(listener: (context, state) {
      if (state is GraphDataState) {
        // Very Important! Determine what forecasts are present in data
        // Used to determine shapes, colors, legends, etc.
        _checkForCuAndOdInForecast(state.forecastData.altitudeData);
        print(" ----------   altitude data -------------");
        state.forecastData.altitudeData.forEach((map) {
          map.forEach((key, value) {
            print("${key} : ${value.toString()}");
          });
        });
        print(" ------- end altitude data -------------");
        // WidgetsBinding.instance!.addPostFrameCallback((_) {
        //   _getModelSheetForGridDataWidget(context, state.forecastData);
        // });
      }
    }, buildWhen: (previous, current) {
      return current is GraphDataState;
    }, builder: (context, state) {
      if (state is GraphDataState) {
        return Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8),
          child: Column(children: [
            _getLocationTitleWidget(state.forecastData.turnpointTitle,
                state.forecastData.lat, state.forecastData.lng),
            _getModelAndDateWidgets(
                state.forecastData.model, state.forecastData.date),
            _getCloudbaseWidget(state.forecastData.altitudeData!),
            _getThermalUpdraftWidget(state.forecastData.thermalData!),
            _getShowGraphDataButtonWidget(state.forecastData),
          ]),
        );
      } else
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
              style: textStyleBlackFontSize20,
            ),
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _getModelAndDateWidgets(String model, String date) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            model.toUpperCase(),
            style: textStyleBlackFontSize14,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              abbrevDateformatter.format(DateTime.tryParse(date)!),
              style: textStyleBlackFontSize14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCloudbaseWidget(List<Map<String, Object>> forecastData) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: _screenWidth - _chartWidthMargin,
      height: 300,
      child: Chart(
        data: forecastData,
        rebuild: false,
        padding: (_) => const EdgeInsets.fromLTRB(30, 0, 10, 4),
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
            horizontalRange: [0.01, 0.99], color: altitudeGraphBackground),
        //coord: RectCoord(color: const Color(0xffdddddd)),
        elements: [
          PointElement(
            size: SizeAttr(variable: "name", values: sizeOfPoints),
            color: ColorAttr(
              variable: 'name',
              values: colorsOfPoints,
              updaters: {
                'groupMouse': {false: (color) => color.withAlpha(100)},
                'groupTouch': {false: (color) => color.withAlpha(100)},
              },
            ),
            shape: ShapeAttr(variable: 'name', values: shapesOfPoints),
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
        crosshair: CrosshairGuide(styles: crossHairGuide),
        gestureChannel: forecastChannel,
        annotations: annotationsOfPoints,
      ),
    );
  }

  Widget _getThermalUpdraftWidget(List<Map<String, Object>> forecastData) {
    return Container(
      margin: const EdgeInsets.only(top: 0),
      width: _screenWidth - _chartWidthMargin,
      height: 140,
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Chart(
          padding: (_) => const EdgeInsets.fromLTRB(30, 0, 10, 8),
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
          crosshair: CrosshairGuide(styles: crossHairGuide),
          gestureChannel: forecastChannel,
          annotations: _getGraphLegend(
              label: "Thermal Updraft ft/min",
              initialOffset: graphLegendOffset,
              colorIndex: 0,
              // same as thermal in top graph
              xPosIndex: 0,
              yPosIndex: 0,
              yOffset: 100),
        ),
      ),
    );
  }

  /// conditions might be that the forecast doesn't include Cu or OD so we need
  ///
  void _checkForCuAndOdInForecast(List<Map<String, Object>> altitudeData) {
    colorsOfPoints.clear();
    sizeOfPoints.clear();
    shapesOfPoints.clear();
    annotationsOfPoints.clear();

    // always add thermal color,size, shape,etc
    colorsOfPoints.add(Colors.red);
    sizeOfPoints.add(30.0);
    shapesOfPoints.add(ThermalShape(hollow: false));
    annotationsOfPoints.addAll(_getGraphLegend(
        label: "MSL Thermal Updraft Strength @ 175fpm (Dry)",
        initialOffset: graphLegendOffset,
        colorIndex: 0,
        xPosIndex: 0,
        yPosIndex: -1,
        yOffset: 290));

    // See if any OD Cloudbase forcast present
    odInForecast = false;
    cuInForecast = false;
    for (var map in altitudeData) {
      if (map.containsValue("zblcl")) {
        odInForecast = true;
        colorsOfPoints.add(Colors.black);
        sizeOfPoints.add(30.0);
        shapesOfPoints.add(CumulusShape(hollow: false));
        annotationsOfPoints.addAll(_getGraphLegend(
            label: "OD Cloudbase(MSL)",
            initialOffset: graphLegendOffset,
            colorIndex: 1,
            xPosIndex: 0,
            yPosIndex: 0,
            yOffset: 290));
        break;
      }
    }
    // See if Cu Cloudbase present. But adjust positions if OD also present
    for (var map in altitudeData) {
      if (map.containsValue("zsfclcl")) {
        cuInForecast = true;
        colorsOfPoints.add(Colors.white);
        sizeOfPoints.add(30.0);
        shapesOfPoints.add(CumulusShape(hollow: false));
        annotationsOfPoints.addAll(_getGraphLegend(
            label: "Cu Cloudbase(MSL)",
            initialOffset: graphLegendOffset,
            colorIndex: odInForecast ? 2 : 1,
            xPosIndex: odInForecast ? 1 : 0,
            yPosIndex: 0,
            yOffset: 290));
        break;
      }
    }
    // Hack alert.  Don't know why but SizaAttr/ColorAttr values requires at
    // least 2 sizes in array so if no OD or Cu add values to get array lengths to 2
    if (!odInForecast && !cuInForecast) {
      colorsOfPoints.add(Colors.transparent);
      sizeOfPoints.add(0);
      shapesOfPoints.add(
        CircleShape(hollow: true),
      );
    }
  }

  List<Annotation> _getGraphLegend(
      {required String label,
      required double initialOffset,
      required int colorIndex,
      required int xPosIndex,
      required double yPosIndex,
      required double yOffset}) {
    var annotations = <Annotation>[
      _getMarkAnnotation(
        initialOffset: initialOffset,
        colorIndex: colorIndex,
        xPosIndex: xPosIndex,
        yOffset: yOffset,
        yPosIndex: yPosIndex,
      ),
      _getTagAnnotation(
          initialOffset: initialOffset + 9,
          label: label,
          xPosIndex: xPosIndex,
          yOffset: yOffset,
          yPosIndex: yPosIndex)
    ];
    return annotations;
  }

  MarkAnnotation _getMarkAnnotation(
      {required double initialOffset,
      required int colorIndex,
      required int xPosIndex,
      required double yOffset,
      required double yPosIndex}) {
    return MarkAnnotation(
      relativePath: Path()
        ..addRect(Rect.fromCircle(center: const Offset(0, 0), radius: 5)),
      style: Paint()..color = colorsOfPoints[colorIndex],
      anchor: (size) => Offset(
          initialOffset + (xPosIndex == 0 ? 0 : (size.width / 2) * xPosIndex),
          yOffset + 12 * yPosIndex),
    );
  }

  TagAnnotation _getTagAnnotation(
      {required double initialOffset,
      required String label,
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
          initialOffset + (xPosIndex == 0 ? 0 : (size.width / 2) * xPosIndex),
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

  _getShowGraphDataButtonWidget(final ForecastGraphData forecastGraphData) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Center(
        child: ElevatedButton(
            child: Text("Show Graph Data"),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(50, 40),
              foregroundColor: Colors.white,
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              showModalBottomSheet<void>(
                  context: context,
                  enableDrag: true,
                  isScrollControlled: true,
                  barrierColor: Colors.transparent,
                  builder: (BuildContext context) {
                    return Container(
                      height: MediaQuery.of(context).size.height * .80,
                      color: Colors.white,
                      child: _getGridDataWidget(forecastGraphData),
                    );
                  });
            }),
      ),
    );
  }

  Widget _getGridDataWidget(ForecastGraphData forecastGraphData) {
    // get list of hours for which forecasts have been made
    final hours = forecastGraphData.hours;
    List<RowDescription> descriptions = [];
    forecastGraphData.descriptions.forEach((forecast) {
      descriptions.add(RowDescription(
          description: forecast.forecastNameDisplay,
          helpDescription: forecast.forecastDescription));
    });
    return Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: ScrollableTable(
            columnHeadings: hours,
            dataCellWidth: 60,
            dataCellHeight: 50,
            headingBackgroundColor: Colors.yellow.withOpacity(0.3),
            descriptionColumnWidth: 125,
            descriptionBackgroundColor: Colors.yellow.withOpacity(0.3),
            dataRowsBackgroundColors: [Colors.white, Colors.green.shade50],
            gridData: forecastGraphData.gridData,
            descriptions: descriptions));
  }
}
