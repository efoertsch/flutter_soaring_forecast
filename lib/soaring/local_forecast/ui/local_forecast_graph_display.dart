import 'dart:async';
import 'dart:io';

import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show GraphLiterals, StandardLiterals;
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/local_forecast/bloc/local_forecast_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/local_forecast/shapes/custom_shapes.dart';
import 'package:flutter_soaring_forecast/soaring/region_model/ui/model_date_display.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/grid_widgets.dart';
import 'package:graphic/graphic.dart';

import '../../forecast/ui/common/rasp_progress_indicator.dart';
import '../../region_model/bloc/region_model_bloc.dart';
import '../../region_model/bloc/region_model_event.dart';
import '../../region_model/bloc/region_model_state.dart';
import '../bloc/local_forecast_event.dart';
import '../bloc/local_forecast_graph.dart';
import '../bloc/local_forecast_state.dart';

class LocalForecastGraphDisplay extends StatefulWidget {
  LocalForecastGraphDisplay({Key? key}) : super(key: key);

  @override
  State<LocalForecastGraphDisplay> createState() => _LocalForecastGraphDisplayState();
}

class TabsConfig {
  static List<Tab> forecastTabs = [];
  static int selectedTabIndex = 0;
}

// Used to determine chart point colors, size, shape, and legends
class DataPointsConfig {
  bool cuInForecast = false;
  bool odInForecast = false;
  final sizeOfPoints = <double>[];
  final colorsOfPoints = <Color>[];
  final shapesOfPoints = <PointShape>[];
  final annotationsOfPoints = <Annotation>[];
}

class _LocalForecastGraphDisplayState extends State<LocalForecastGraphDisplay>
    with TickerProviderStateMixin {
  final forecastChannel = StreamController<GestureEvent>.broadcast();
  late TabController _tabController;

  double _screenWidth = 0;
  double _chartWidthMargin = 30;
  double graphLegendOffset = 40; // used to place legends on graph

  final altitudeGraphBackground = Colors.blue[200];

  final crossHairGuide = [
    PaintStyle(strokeColor: Colors.black38, strokeWidth: 2),
    PaintStyle(strokeColor: Colors.black38, strokeWidth: 2)
  ];
  ForecastGraphData? forecastGraphData;

  bool _beginnerMode = true;
  String _selectedModelName = '';
  String _selectedForecastDate = '';

  late Object _graphKey;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: TabsConfig.forecastTabs.length,
      vsync: this,
      initialIndex: TabsConfig.selectedTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      leading: BackButton(onPressed: () => _onWillPop()),
      actions: _getGraphMenu(),
      //  actions: _getAppBarMenu(),
    );
  }

  List<Widget> _getGraphMenu() {
    return <Widget>[
      PopupMenuButton<String>(
        onSelected: handleClick,
        icon: Icon(Icons.more_vert),
        itemBuilder: (BuildContext context) {
          return {
            _beginnerMode
                ? StandardLiterals.EXPERT_MODE
                : StandardLiterals.BEGINNER_MODE,
            GraphLiterals.SET_AS_FAVORITE
          }.map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
      )
    ];
  }

  void handleClick(String value) async {
    switch (value) {
      case StandardLiterals.EXPERT_MODE:
      case StandardLiterals.BEGINNER_MODE:
        // toggle flag
        setState(() {
          _beginnerMode = !_beginnerMode;
          context.read<RegionModelBloc>().add(BeginnerModeEvent(_beginnerMode));
        });
        break;
      case GraphLiterals.SET_AS_FAVORITE:
        context.read<LocalForecastBloc>().add(SetLocationAsFavoriteEvent());
    }
  }

  Widget _miscStatesHandlerWidget() {
    return BlocListener<RegionModelBloc, RegionModelState>(
      listener: (context, state) {
        if (state is ForecastModelsAndDates) {
          // the model or date changed, send the info on so new graphs created
          LocalModelDateChange localForecastModelDateChange =
          LocalModelDateChange(state.regionName, state.modelNames[state.modelNameIndex]
              , state.forecastDates[state.forecastDateIndex], state.localTimes);
          context.read<LocalForecastBloc>().add(LocalModelDateChangeEvent(localForecastModelDateChange));
        }
      },
      child: SizedBox.shrink(),
    );
  }

  Widget _getBody() {
    return Stack(
      children: [
        Column(children: [
          _widgetForMessages(),
          Padding(
            child: ModelDatesDisplay(),
            padding: EdgeInsets.all(8.0),
          ),
          _getLocalForecastWidget(),
          _miscStatesHandlerWidget(),
        ]),
        //RaspProgressIndicator<LocalForecastBloc>(),
      ],
    );
  }

  Widget _getLocalForecastWidget() {
    return BlocConsumer<LocalForecastBloc, LocalForecastState>(
        listener: (context, state) {
      if (state is GraphDataState) {
        //
      }
    }, buildWhen: (previous, current) {
      return current is GraphDataState;
    }, builder: (context, state) {
      if (state is GraphDataState) {
        List<Tab> forecastTabs =
            _getLocalForecastTabs(state.forecastData.pointForecastsGraphData);
        List<Widget> tabBarWidgets = _getLocalForecastTabView(
            state.forecastData.pointForecastsGraphData,
            state.forecastData.maxAltitude,
            state.forecastData.maxThermalStrength);
        _tabController = TabController(
            length: tabBarWidgets.length,
            vsync: this,
            initialIndex: state.forecastData.startIndex);
        _tabController.addListener(() {
          context.read<LocalForecastBloc>().add(LocationTabIndexEvent(_tabController.index));
        });

        return Expanded(
          child: (Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: Colors.grey[300],
                  padding: const EdgeInsets.only(left: 8.0, right: 8),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: Colors.white,
                    ),
                    controller: _tabController,
                    isScrollable: true,
                    tabs: forecastTabs,
                    labelStyle: textStyleBoldBlackFontSize16,
                    unselectedLabelStyle: textStyleBoldBlackFontSize16,
                  ),
                ),
                Expanded(
                    child: TabBarView(
                        controller: _tabController, children: tabBarWidgets))
              ])),
        );
      }
      return SizedBox.shrink();
    });
  }

  List<Tab> _getLocalForecastTabs(
      List<PointForecastGraphData> pointForecastsGraphData) {
    List<Tab> forecastTabs = [];
    pointForecastsGraphData.forEach((pointForecastGraphData) {
      forecastTabs.add(Tab(text: _getLocationTitle(pointForecastGraphData)));
    });
    return forecastTabs;
  }

  String _getLocationTitle(PointForecastGraphData pointForecastGraphData) {
    var text;
    if (pointForecastGraphData.turnpointTitle != null) {
      text =
          ("${pointForecastGraphData.turnpointTitle} (${pointForecastGraphData.turnpointCode}) ");
    } else if (pointForecastGraphData.lat != null &&
        pointForecastGraphData.lng != null) {
      text = pointForecastGraphData.lat!.toStringAsFixed(5) +
          "/" +
          pointForecastGraphData.lng!.toStringAsFixed(5);
    }
    if (text != null) {
      return text;
    } else {
      return "Undefined";
    }
  }

  List<Widget> _getLocalForecastTabView(
      List<PointForecastGraphData> pointForecastsGraphData,
      double maxAltitude,
      double maxThermalStrength) {
    List<Widget> forecastGraphWidgets = [];
    pointForecastsGraphData.forEach((pointForecastGraphData) {
      forecastGraphWidgets.add(_forecastGraphWidget(
          pointForecastGraphData, maxAltitude, maxThermalStrength));
    });
    return forecastGraphWidgets;
  }

  ///TODO - Expanded should be under Column, Row, or Flex.
  Widget _forecastGraphWidget(PointForecastGraphData pointForecastGraphData,
      double maxAltitude, double maxThermalStrength) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _getCloudbaseWidget(pointForecastGraphData, maxAltitude),
          _getThermalUpdraftWidget(pointForecastGraphData, maxThermalStrength),
          _getGridDataWidget(pointForecastGraphData)
        ],
      ),
    );
  }

// Hmmm, graph doesn't redraw on first previous or next click
  Widget _getCloudbaseWidget(
      PointForecastGraphData pointForecastGraphData, double maxAltitude) {
    _graphKey = Object();
    DataPointsConfig dataPointsConfig =
        _checkForCuAndOdInForecast(pointForecastGraphData.altitudeData);
    // print(" ----------   altitude data -------------");
    // (pointForecastGraphData.altitudeData.forEach((map) {
    //   map.forEach((key, value) {
    //     print("${key} : ${value.toString()}");
    //   });
    // }));
    // print(" ------- end altitude data -------------");
    // WidgetsBinding.instance!.addPostFrameCallback((_) {
    //   _getModelSheetForGridDataWidget(context, state.forecastData);
    // });

    //  debugPrint("Plotting GraphDataState: ${state.forecastData.model} / ${state.forecastData.date}");
    return Container(
      key: ValueKey<Object>(_graphKey),
      margin: const EdgeInsets.only(top: 8),
      width: _screenWidth - _chartWidthMargin,
      height: 300,
      child: Chart(
        data: pointForecastGraphData.altitudeData,
        rebuild: false,
        padding: (_) => const EdgeInsets.fromLTRB(30, 0, 10, 4),
        variables: {
          'time': Variable(
            accessor: (Map map) => map['time'] as String,
          ),
          'value': Variable(
            accessor: (Map map) => map['value'] as num,
            scale: LinearScale(
                formatter: (value) => '${value.toInt()}',
                min: 0,
                max: maxAltitude),
          ),
          'name': Variable(
            accessor: (Map map) => map['name'] as String,
          ),
        },

        coord: RectCoord(
            horizontalRange: [0.01, 0.99], color: altitudeGraphBackground),
        //coord: RectCoord(color: const Color(0xffdddddd)),
        marks: [
          PointMark(
            size: SizeEncode(
                variable: "name", values: dataPointsConfig.sizeOfPoints),
            color: ColorEncode(
              variable: 'name',
              values: dataPointsConfig.colorsOfPoints,
              updaters: {
                'groupMouse': {false: (color) => color.withAlpha(100)},
                'groupTouch': {false: (color) => color.withAlpha(100)},
              },
            ),
            shape: ShapeEncode(
                variable: 'name', values: dataPointsConfig.shapesOfPoints),
          ),
        ],
        axes: [
          Defaults.horizontalAxis
            ..label = (LabelStyle(
                textStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold))),
          Defaults.verticalAxis
            ..label = (LabelStyle(
                textStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold))),
        ],
        selections: {'tap': PointSelection(dim: Dim.x)},
        //tooltip: TooltipGuide(),
        crosshair: CrosshairGuide(styles: crossHairGuide),
        gestureStream: forecastChannel,
        annotations: dataPointsConfig.annotationsOfPoints,
      ),
    );
  }

  Widget _getThermalUpdraftWidget(PointForecastGraphData pointForecastGraphData,
      double maxThermalStrength) {
    _graphKey = Object();
    return Container(
      key: ValueKey<Object>(_graphKey),
      margin: const EdgeInsets.only(top: 20),
      width: _screenWidth - _chartWidthMargin,
      height: 140,
      child: Chart(
        padding: (_) => const EdgeInsets.fromLTRB(30, 0, 10, 8),
        rebuild: false,
        data: pointForecastGraphData.thermalData,
        variables: {
          'time': Variable(
            accessor: (Map map) => map['time'] as String,
          ),
          'value': Variable(
            accessor: (Map map) => map['value'] as num,
            scale: LinearScale(
                formatter: (value) => '${value.toInt()}',
                min: 0,
                max: maxThermalStrength),
          ),
        },
        coord: RectCoord(color: const Color(0xffdddddd)),
        marks: [
          LineMark(
            color: ColorEncode(
                variable: 'value', values: [Colors.red, Colors.red]),
            shape: ShapeEncode(value: BasicLineShape(smooth: true)),
            size: SizeEncode(value: 4.0),
          ),
        ],
        axes: [
          Defaults.horizontalAxis
            ..label = (LabelStyle(
                textStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold))),
          Defaults.verticalAxis
            ..label = (LabelStyle(
                textStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold))),
        ],
        selections: {'tap': PointSelection(dim: Dim.x)},
        //tooltip: TooltipGuide(),
        crosshair: CrosshairGuide(styles: crossHairGuide),
        gestureStream: forecastChannel,
        annotations: _getGraphLegend(
            label: "Thermal Updraft ft/min",
            initialOffset: graphLegendOffset,
            color: Colors.red,
            // same as thermal in top graph
            xPosIndex: 0,
            yPosIndex: 0,
            yOffset: 125),
      ),
    );
  }

  /// conditions might be that the forecast doesn't include Cu or OD so we need
  ///
  DataPointsConfig _checkForCuAndOdInForecast(
      List<Map<String, Object>> altitudeData) {
    DataPointsConfig dataPointsConfig = DataPointsConfig();

    // always add thermal color,size, shape,etc
    dataPointsConfig.colorsOfPoints.add(Colors.red);
    dataPointsConfig.sizeOfPoints.add(30.0);
    dataPointsConfig.shapesOfPoints.add(ThermalShape(hollow: false));
    dataPointsConfig.annotationsOfPoints.addAll(_getGraphLegend(
        label: "MSL Thermal Updraft Strength @ 175fpm (Dry)",
        initialOffset: graphLegendOffset,
        color: Colors.red,
        xPosIndex: 0,
        yPosIndex: -1,
        yOffset: 290));

    // See if any OD Cloudbase forcast present
    dataPointsConfig.odInForecast = false;
    dataPointsConfig.cuInForecast = false;
    for (var map in altitudeData) {
      if (map.containsValue("zblcl")) {
        dataPointsConfig.odInForecast = true;
        dataPointsConfig.colorsOfPoints.add(Colors.black);
        dataPointsConfig.sizeOfPoints.add(30.0);
        dataPointsConfig.shapesOfPoints.add(CumulusShape(hollow: false));
        dataPointsConfig.annotationsOfPoints.addAll(_getGraphLegend(
            label: "OD Cloudbase(MSL)",
            initialOffset: graphLegendOffset,
            color: Colors.black,
            xPosIndex: 0,
            yPosIndex: 0,
            yOffset: 290));
        break;
      }
    }
    // See if Cu Cloudbase present. But adjust positions if OD also present
    for (var map in altitudeData) {
      if (map.containsValue("zsfclcl")) {
        dataPointsConfig.cuInForecast = true;
        dataPointsConfig.colorsOfPoints.add(Colors.white);
        dataPointsConfig.sizeOfPoints.add(30.0);
        dataPointsConfig.shapesOfPoints.add(CumulusShape(hollow: false));
        dataPointsConfig.annotationsOfPoints.addAll(_getGraphLegend(
            label: "Cu Cloudbase(MSL)",
            initialOffset: graphLegendOffset,
            color: dataPointsConfig.odInForecast
                ? dataPointsConfig.colorsOfPoints[2]
                : dataPointsConfig.colorsOfPoints[1],
            xPosIndex: dataPointsConfig.odInForecast ? 1 : 0,
            yPosIndex: 0,
            yOffset: 290));
        break;
      }
    }
    // Hack alert.  Don't know why but SizeAttr/ColorAttr values requires at
    // least 2 sizes in array so if no OD or Cu add values to get array lengths to 2
    if (!dataPointsConfig.odInForecast && !dataPointsConfig.cuInForecast) {
      dataPointsConfig.colorsOfPoints.add(Colors.transparent);
      dataPointsConfig.sizeOfPoints.add(0);
      dataPointsConfig.shapesOfPoints.add(
        CircleShape(hollow: true),
      );
    }
    return dataPointsConfig;
  }

  List<Annotation> _getGraphLegend(
      {required String label,
      required double initialOffset,
      required Color color,
      required int xPosIndex,
      required double yPosIndex,
      required double yOffset}) {
    var annotations = <Annotation>[
      _getCustomAnnotation(
        initialOffset: initialOffset,
        color: color,
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

  CustomAnnotation _getCustomAnnotation(
      {required double initialOffset,
      required Color color,
      required int xPosIndex,
      required double yOffset,
      required double yPosIndex}) {
    return CustomAnnotation(
      renderer: (offset, size) => [
        RectElement(
          rect: Rect.fromLTWH(offset.dx - 3, offset.dy - 5, 10, 10),
          style: PaintStyle(fillColor: color),
        )
      ],
      anchor: (size) => Offset(
          initialOffset + (xPosIndex == 0 ? 0 : (size.width / 2) * xPosIndex),
          yOffset + 12 * yPosIndex),
    );
  }

// return MarkAnnotation(
//   relativePath: Path()
//     ..addRect(Rect.fromCircle(center: const Offset(0, 0), radius: 5)),
//   style: Paint()..color = colorsOfPoints[colorIndex],
//   anchor: (size) => Offset(
//       initialOffset + (xPosIndex == 0 ? 0 : (size.width / 2) * xPosIndex),
//       yOffset + 12 * yPosIndex),
// );

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
            textStyle: textStyleBlackFontSize13, align: Alignment.centerRight),
      ),
      anchor: (size) => Offset(
          initialOffset + (xPosIndex == 0 ? 0 : (size.width / 2) * xPosIndex),
          yOffset + 12 * yPosIndex),
    );
  }

  _sendLocalForecastEvent(LocalForecastEvent event) {
    BlocProvider.of<LocalForecastBloc>(context).add(event);
  }

  Widget _widgetForMessages() {
    return BlocListener<LocalForecastBloc, LocalForecastState>(
      listener: (context, state) async {
        if (state is LocalForecastErrorState) {
          CommonWidgets.showErrorDialog(context, "Error", state.error);
        }
      },
      child: SizedBox.shrink(),
    );
  }

  Widget _getGridDataWidget(PointForecastGraphData pointForecastGraphData) {
    // get list of hours for which forecasts have been made
    final hours = pointForecastGraphData.hours;
    List<RowDescription> descriptions = [];
    pointForecastGraphData.descriptions.forEach((forecast) {
      descriptions.add(RowDescription(
          description: forecast.forecastNameDisplay,
          helpDescription: forecast.forecastDescription));
    });
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 20),
      child: ScrollableTable(
          columnHeadings: hours,
          dataCellWidth: 60,
          dataCellHeight: 50,
          headingBackgroundColor: Colors.yellow.withOpacity(0.3),
          descriptionColumnWidth: 125,
          descriptionBackgroundColor: Colors.yellow.withOpacity(0.3),
          dataRowsBackgroundColors: [Colors.white, Colors.green.shade50],
          gridData: pointForecastGraphData.gridData,
          descriptions: descriptions),
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(
        context,
        LocalForecastOutputData(
            modelName: _selectedModelName,
            date: _selectedForecastDate,
            ));
    return true;
  }
}
