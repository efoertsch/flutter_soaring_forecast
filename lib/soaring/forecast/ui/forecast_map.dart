import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:custom_marker/marker_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show
        NewEnglandMapCenter,
        NewEnglandMapLatLngBounds,
        RASP_BASE_URL,
        SUAColor;
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/task_turnpoint_marker_widget.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/data/forecast_graph_data.dart';
import 'package:flutter_soaring_forecast/soaring/repository/options/special_use_airspace.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoint_utils.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_overhead_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ForecastMap extends StatefulWidget {
  final Function stopAnimation;

  ForecastMap({Key? key, required Function this.stopAnimation})
      : super(key: key);

  @override
  ForecastMapState createState() => ForecastMapState();
}

class ForecastMapState extends State<ForecastMap>
    with AfterLayoutMixin<ForecastMap>, TickerProviderStateMixin {
  late final GoogleMapController? _mapController;
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  bool _firstLayoutComplete = false;
  LatLng? _mapCenter;
  SoaringForecastImageSet? soaringForecastImageSet;

  // For google map markers, lines, polygons,...
  Map<MarkerId, Marker> _taskTurnpointMarkers = <MarkerId, Marker>{};
  Map<PolylineId, Polyline> _taskTurnpointCourse = <PolylineId, Polyline>{};
  List<Widget> _taskTurnpointMarkerWidgets = [];
  List<GlobalKey> _taskTurnpointGlobalKeys = [];

  //final List<Polyline> _taskTurnpointCourse = <Polyline>[];
  final List<Marker> _mapMarkers = <Marker>[];
  final List<Marker> _soundingMarkers = <Marker>[];
  final List<Marker> _turnpointMarkers = <Marker>[];
  final List<Polygon> _suaPolygons = <Polygon>[];
  final _taskMarkers = <Marker>[];

  // These bounds define the bounds of the forecast overlays
  LatLngBounds _forecastLatLngBounds = NewEnglandMapLatLngBounds;

  /// Use to center task route in map
  LatLng? _southwest;
  double _swLat = 0;
  double _swLong = 0;
  double _neLat = 0;
  double _neLong = 0;

  bool _soundingsVisibility = false;
  double _forecastOverlayOpacity = 50;
  var _forecastOverlaySliderIsVisible = false;
  Timer? _hideOpacityTimer = null;
  double _mapZoom = 7;
  bool _mapIsReady = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    print("First layout complete");
    _firstLayoutComplete = true;
    _sendEvent(InitialRaspRegionEvent());
  }

  void _printMapBounds(String msg, LatLngBounds latLngBounds) {
    debugPrint(msg +
        " latLngBounds: ${latLngBounds.southwest!.toString()}  ${latLngBounds.northeast!.toString()}");
  }

  // Google maps currently doesnt support overlays!!!
  // var _overlayImages = <OverlayImage>[];

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Stack(children: [
      _miscStatesHandlerWidget(),
      Container(
        alignment: Alignment.center,
        child: _forecastMap(),
      ),
      Container(
        alignment: Alignment.centerRight,
        child: _forecastLegend(),
      ),
      _getOpacitySlider(),
      _getSoundingDisplayWidget(),
    ]));
  }

  Widget _forecastLegend() {
    return BlocConsumer<RaspDataBloc, RaspDataState>(
        listener: (context, state) {},
        buildWhen: (previous, current) {
          return current is RaspInitialState || current is RaspForecastImageSet;
        },
        builder: (context, state) {
          if (state is RaspForecastImageSet) {
            // print('Processing RaspForecastImageSet for forecastLegend');
            return InteractiveViewer(
              panEnabled: true,
              maxScale: 4.0,
              child: Image(
                image: NetworkImage(RASP_BASE_URL +
                    state.soaringForecastImageSet.sideImage!.imageUrl),
                gaplessPlayback: true,
              ),
            );
          }
          return SizedBox.shrink();
        });
  }

  Widget _forecastMap() {
    return BlocConsumer<RaspDataBloc, RaspDataState>(
        listener: (context, state) {
      if (state is CenterOfMapState) {
        _mapCenter = state.latLng;
      }
      if (state is RaspForecastImageSet) {
        // print('Received RaspForecastImageSet in ForecastMap');
        soaringForecastImageSet = state.soaringForecastImageSet;
        updateForecastOverlay();
        return;
      }
      if (state is RaspTaskTurnpoints) {
        _mapTaskTurnpoints(state.taskTurnpoints);
        return;
      }
      if (state is RaspSoundingsState) {
        //  print('Received Soundings in ForecastMap');
        _placeSoundingMarkers(state.soundings);
        return;
      }
      if (state is TurnpointsInBoundsState) {
        //print('Received TurnpointsInBoundsState in ForecastMap');
        _updateTurnpointMarkers(state.turnpoints);
        return;
      }
      if (state is SuaDetailsState) {
        // print('Received SuaDetailsState');
        _updateSuaDetails(state.suaDetails);
        return;
      }
      if (state is ForecastOverlayOpacityState) {
        _forecastOverlayOpacity = state.opacity;
        updateForecastOverlay();
        return;
      }
    }, buildWhen: (previous, current) {
      return current is RaspInitialState ||
          current is CenterOfMapState ||
          current is RaspForecastImageSet ||
          current is RaspTaskTurnpoints ||
          current is RaspSoundingsState ||
          current is TurnpointsInBoundsState ||
          current is RedisplayMarkersState ||
          current is SuaDetailsState ||
          current is ForecastOverlayOpacityState ||
          current is ForecastBoundsState;
    }, builder: (context, state) {
      if (state is RaspInitialState) {
        return SizedBox.shrink();
      }
      List<Widget> widgetStack = [];
      widgetStack.addAll(_taskTurnpointMarkerWidgets.toList());
      var googleMap = GoogleMap(
        initialCameraPosition: CameraPosition(
          target: NewEnglandMapCenter,
          zoom: 7.0,
        ),
        mapType: MapType.hybrid,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          _sendEvent(MapReadyEvent());
          _mapIsReady = true;
        },
        onLongPress: (latLng) => _getLocalForecast(latLng: latLng),
        polylines: Set<Polyline>.of(_taskTurnpointCourse.values),
        markers: Set<Marker>.of(_mapMarkers),
      );
      widgetStack.add(googleMap);
      return Stack(
        children: widgetStack,
      );
    });
  }

  Widget _getSoundingDisplayWidget() {
    return BlocConsumer<RaspDataBloc, RaspDataState>(
        listener: (context, state) {},
        buildWhen: (previous, current) {
          return current is RaspInitialState ||
              current is SoundingForecastImageSet;
        },
        builder: (context, state) {
          if (state is SoundingForecastImageSet) {
            final imageUrl = state.soaringForecastImageSet.bodyImage!.imageUrl;
            return Visibility(
              visible: _soundingsVisibility,
              child: Container(
                color: Colors.white,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: InteractiveViewer(
                        panEnabled: true,
                        maxScale: 4.0,
                        child: Image(
                          image: NetworkImage(RASP_BASE_URL + imageUrl),
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                    Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _soundingsVisibility = false;
                                _sendEvent(DisplayCurrentForecastEvent());
                              });
                            }))
                  ],
                ),
              ),
            );
          }
          ;
          return SizedBox.shrink();
        });
  }

  Widget _miscStatesHandlerWidget() {
    return BlocListener<RaspDataBloc, RaspDataState>(
      listener: (context, state) {
        if (state is DisplayLocalForecastGraphState) {
          _displayLocalForecastGraph(context, state.localForecastGraphData);
        }
        if (state is ForecastBoundsState) {
          _forecastLatLngBounds = state.latLngBounds;
          // _printMapBounds(
          //     "ForecastBoundsState  bounds ", _forecastLatLngBounds!);
          _goToNewBounds(latLngBounds: _forecastLatLngBounds);
          return;
        }
      },
      child: SizedBox.shrink(),
    );
  }

  void _displayLocalForecastGraph(
      BuildContext context, ForecastInputData inputParms) {
    Navigator.pushNamed(
      context,
      LocalForecastGraphRouteBuilder.routeName,
      arguments: inputParms,
    );
  }

  void _mapTaskTurnpoints(List<TaskTurnpoint> taskTurnpoints) async {
    print('number of task turnpoints ${taskTurnpoints.length.toString()} ');
    clearTaskFromMap(taskTurnpoints.length > 0);
    if (taskTurnpoints.length == 0) {
      _taskTurnpointGlobalKeys.clear();
      _taskTurnpointMarkers.clear();
      _taskTurnpointCourse.clear();
      _taskTurnpointMarkerWidgets.clear();
      //  _printMapBounds("TaskTurnpoints.length = 0 ", _forecastLatLngBounds);
      _goToNewBounds(latLngBounds: _forecastLatLngBounds);
    } else {
      List<LatLng> polyLinePoints = <LatLng>[];
      int lineId = 0;
      for (var taskTurnpoint in taskTurnpoints) {
        // print('adding taskturnpoint: ${taskTurnpoint.title}');
        var globalKey = GlobalKey();
        _taskTurnpointGlobalKeys.add(globalKey);
        _taskTurnpointMarkerWidgets.add(TaskTurnpointMarkerWidget(
            globalKey: globalKey,
            taskTurnpoint: taskTurnpoint,
            stopAnimation: widget.stopAnimation));

        var turnpointLatLng =
            LatLng(taskTurnpoint.latitudeDeg, taskTurnpoint.longitudeDeg);
        polyLinePoints.add(turnpointLatLng);

        updateMapLatLngCorner(turnpointLatLng);
      }
      _rebuildMarkerArray();
      final polyLineId = PolylineId(lineId.toString());
      _taskTurnpointCourse[polyLineId] = Polyline(
        polylineId: PolylineId(lineId.toString()),
        points: polyLinePoints,
        width: 2,
        color: Colors.red,
      );
      // Only do this if view
      LatLng southwest = new LatLng(_swLat, _swLong);
      LatLng northeast = new LatLng(_neLat, _neLong);
      final latLngBounds =
          LatLngBounds(southwest: southwest, northeast: northeast);
      // _printMapBounds("_updateTaskTurnpoints ", latLngBounds);
      _goToNewBounds(latLngBounds: latLngBounds, padding: .2);
      _createTaskTurnpointMarkers(_taskTurnpointGlobalKeys, taskTurnpoints);
    }
  }

  // Turnpoint markers require async await to create bitmaps of widgets.
  Future<void> _createTaskTurnpointMarkers(final List<GlobalKey> globalKeys,
      final List<TaskTurnpoint> taskTurnpoints) async {
    WidgetsBinding.instance!.addPostFrameCallback((_) async {
      if (globalKeys.length != taskTurnpoints.length) {
        //TODO return error
        return;
      }
      for (int i = 0; i < taskTurnpoints.length; ++i) {
        var markerTitle = "${taskTurnpoints[i].id}_${taskTurnpoints[i].taskId}";
        final markerId = MarkerId(markerTitle);
        var turnpointLatLng = LatLng(
            taskTurnpoints[i].latitudeDeg, taskTurnpoints[i].longitudeDeg);
        _taskTurnpointMarkers[markerId] = Marker(
          markerId: markerId,
          icon: await MarkerIcon.widgetToIcon(globalKeys[i]),
          position: turnpointLatLng,
        );
      }
      _turnpointMarkers.addAll(_taskTurnpointMarkers.values);
      _rebuildMarkerArray();
      setState(() {});
    });
  }

  Widget _getTaskTurnpointMarker(TaskTurnpoint taskTurnpoint) {
    return InkWell(
      onTap: () {
        _sendEvent(DisplayTaskTurnpointEvent(taskTurnpoint));
      },
      onLongPress: () {
        _getLocalForecast(
            latLng:
                LatLng(taskTurnpoint.latitudeDeg, taskTurnpoint.longitudeDeg),
            turnpointName: ("${taskTurnpoint.title} (${taskTurnpoint.code})"));
      },
      child: Container(
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: Text(taskTurnpoint.title, textAlign: TextAlign.center),
              ),
              Expanded(
                flex: 2,
                child: Text(
                    '${taskTurnpoint.distanceFromPriorTurnpoint.toStringAsFixed(0)} '
                    '/ ${taskTurnpoint.distanceFromStartingPoint.toStringAsFixed(0)} km',
                    textAlign: TextAlign.center),
              ),
              Expanded(
                flex: 1,
                child:
                    Icon(Icons.arrow_drop_down_outlined, color: Colors.white),
              )
            ],
          )),
    );
  }

  void _updateTurnpointMarkers(final List<Turnpoint> turnpoints) {
    print('number of turnpoints ${turnpoints.length.toString()} ');
    _turnpointMarkers.clear();
    for (var turnpoint in turnpoints) {
      // print('adding turnpoint: ${turnpoint.title}');
      var turnpointLatLng =
          LatLng(turnpoint.latitudeDeg, turnpoint.longitudeDeg);

      _turnpointMarkers.add(Marker(
        markerId: MarkerId("${turnpoint.id}"),
        position: turnpointLatLng,
      ));
    }
    _rebuildMarkerArray();
  }

  Widget _getTurnpointMarker(final Turnpoint turnpoint) {
    return InkWell(
      onTap: () {
        _displayTurnpointOverheadView(turnpoint);
      },
      onLongPress: () {
        _getLocalForecast(
            latLng: LatLng(turnpoint.latitudeDeg, turnpoint.longitudeDeg),
            turnpointName: ("${turnpoint.title} (${turnpoint.code})"));
      },
      child: ClipOval(
        child: Container(
            color: Colors.transparent,
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                SizedBox.expand(
                  child: SvgPicture.asset(
                    'assets/svg/ic_turnpoint_white_48dp.svg',
                    color: TurnpointUtils.getColorForTurnpointIcon(
                        turnpoint.style),
                  ),
                ),
                Text(
                    turnpoint.title.length > 4
                        ? turnpoint.title.substring(0, 4)
                        : turnpoint.title,
                    style: _mapZoom < 9
                        ? textStyleBlackFontSize12
                        : textStyleBlackFontSize18,
                    textAlign: TextAlign.center),
              ],
            )),
      ),
    );
  }

  void _placeSoundingMarkers(final List<Soundings> soundings) {
    print('number of soundings ${soundings.length.toString()} ');
    _soundingMarkers.clear();
    for (var sounding in soundings) {
      var soundingLatLng = LatLng(
          double.parse(sounding.latitude!), double.parse(sounding.longitude!));
      _soundingMarkers.add(Marker(
        markerId: MarkerId("Sounding:${sounding.position}"),
        position: soundingLatLng,
      ));
    }
    _rebuildMarkerArray();
  }

  Widget _getSoundingMarker(Soundings sounding) {
    // print('Sounding location: ${sounding.location}');
    return InkWell(
      onTap: () {
        _displaySoundingsView(sounding);
      },
      child: Container(
          color: Colors.transparent,
          //margin: new EdgeInsets.all(4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: 30,
                width: 70,
                child: Container(
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                          flex: 4, child: Image.asset('assets/png/skew_t.png')),
                      Expanded(
                        flex: 6,
                        child: Text(
                          sounding.location!.length > 5
                              ? sounding.location!.substring(0, 5)
                              : sounding.location!,
                          style: textStyleBlackFontSize12,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 10,
                width: 10,
                child: SvgPicture.asset(
                  'assets/svg/ic_downward_triangle.svg',
                  fit: BoxFit.scaleDown,
                  color: Colors.white,
                ),
              ),
            ],
          )),
    );
  }

  void _displaySoundingsView(Soundings sounding) {
    _sendEvent(DisplaySoundingsEvent(sounding));
    setState(() {
      _soundingsVisibility = true;
    });
  }

  void clearTaskFromMap(bool taskDefined) {
    _taskTurnpointCourse.clear();
    _taskMarkers.clear();
    _rebuildMarkerArray();
    if (taskDefined) {
      _southwest = null;
    }
  }

  void updateForecastOverlay() {
    //print('Using RaspForecastImageSet imageset to display map overlay');
    if (_firstLayoutComplete) {
      displayForecastNoAnimation();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
  }

  void displayForecastNoAnimation() {
    // google maps currently does not implement overlays
    // if (soaringForecastImageSet != null) {
    //   // print(
    //   //     "forecast overlay: " + soaringForecastImageSet!.bodyImage!.imageUrl);
    //   var imageUrl = soaringForecastImageSet!.bodyImage!.imageUrl;
    //   var raspUrl = RASP_BASE_URL + imageUrl;
    //   var overlayImage = OverlayImage(
    //       bounds: _forecastLatLngBounds,
    //       opacity: _forecastOverlayOpacity / 100,
    //       imageProvider: NetworkImage(raspUrl),
    //       gaplessPlayback: true);
    //
    //   if (_overlayImages.length == 0) {
    //     _overlayImages.add(overlayImage);
    //   } else {
    //     _overlayImages[0] = overlayImage;
    //   }
    // }
  }

  _getLocalForecast({required LatLng latLng, String? turnpointName = null}) {
    widget.stopAnimation();
    print('Local forecast requested at : ${latLng.latitude.toString()}  :'
        '  ${latLng.longitude.toString()}');
    _sendEvent(DisplayLocalForecastEvent(latLng, turnpointName));
  }

  void _sendEvent(RaspDataEvent event) {
    BlocProvider.of<RaspDataBloc>(context).add(event);
  }

  void updateMapLatLngCorner(LatLng latLng) {
    if (_southwest == null) {
      _southwest = latLng;
      _swLat = latLng.latitude;
      _swLong = latLng.longitude;

      _neLat = latLng.latitude;
      _neLong = latLng.longitude;
    }
    if (latLng.latitude < _swLat) {
      _swLat = latLng.latitude;
    }
    if (latLng.longitude < _swLong) {
      _swLong = latLng.longitude;
    }
    if (latLng.latitude > _neLat) {
      _neLat = latLng.latitude;
    }
    if (latLng.longitude > _neLong) {
      _neLong = latLng.longitude;
    }
  }

  void _rebuildMarkerArray() {
    _mapMarkers.clear();
    _mapMarkers.addAll(_turnpointMarkers);
    _mapMarkers.addAll(_soundingMarkers);
    _mapMarkers.addAll(_taskMarkers);
  }

  void _displayTurnpointOverheadView(Turnpoint turnpoint) async {
    await Navigator.pushNamed(context, TurnpointViewRouteBuilder.routeName,
        arguments: TurnpointOverHeadArgs(turnpoint: turnpoint));
  }

  void _updateSuaDetails(SUA suaDetails) async {
    _suaPolygons.clear();
    final suaColors = SUAColor.values;

    int polygonCount = 0;
    suaDetails.features?.forEach((airspace) {
      Color? polygonColor = null;
      String? label = null;
      bool isDashed = false;
      label = airspace.properties!.type!;
      try {
        final suaColor = suaColors
            .firstWhere((sua) => sua.suaClassType == airspace.properties!.type);
        polygonColor = suaColor.airspaceColor;
        isDashed = suaColor.dashedLine;
        debugPrint(
            "${airspace.properties!.title} has type ${suaColor.suaClassType}  and isDashed: $isDashed");
      } catch (e) {
        debugPrint(
            "Undefined SUA type ${airspace.properties!.type} in SUAColor. ");
      }

      //print("SUA label: $label");
      _suaPolygons.add(Polygon(
          polygonId: PolygonId(polygonCount.toString()),
          strokeWidth: 2,
          points: airspace.geometry!.coordinates,
          strokeColor: polygonColor ?? Color(0x400000F80),
          fillColor: (polygonColor ?? Color(0xFF0000F80)).withOpacity(1)));
      ++polygonCount;
    });
  }

  Widget _getOpacitySlider() {
    return Positioned(
        top: 20,
        left: 0,
        right: 0,
        child: AnimatedOpacity(
          opacity: _forecastOverlaySliderIsVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 2000),
          onEnd: (() {
            if (_forecastOverlaySliderIsVisible) _startHideOpacityTimer();
          }),
          child: Visibility(
            visible: _forecastOverlaySliderIsVisible,
            child: IntrinsicHeight(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      color: Colors.white,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text("0",
                              textAlign: TextAlign.center,
                              style: textStyleBoldBlack87FontSize14),
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.white,
                      child: Slider(
                        value: _forecastOverlayOpacity,
                        max: 100,
                        min: 0,
                        divisions: 100,
                        label: _forecastOverlayOpacity.round().toString(),
                        onChanged: (double value) {
                          if (_hideOpacityTimer != null) {
                            _hideOpacityTimer!.cancel();
                            _hideOpacityTimer = null;
                          }
                          // changing value in setState() doesn't cause overlay opacity change
                          // so save value and receive updated value from bloc state issue
                          _sendEvent(SetForecastOverlayOpacityEvent(value));
                          setState(() {
                            // but need to set value in setState to redraw slider
                            _forecastOverlayOpacity = value;
                          });
                        },
                        onChangeEnd: (double value) {
                          setState(() {
                            _startHideOpacityTimer();
                          });
                        },
                      ),
                    ),
                    Container(
                      color: Colors.white,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text("100",
                              textAlign: TextAlign.center,
                              style: textStyleBoldBlack87FontSize14),
                        ),
                      ),
                    ),
                  ]),
            ),
          ),
        ));
  }

  showOverlayOpacitySlider() {
    setState(() {
      _forecastOverlaySliderIsVisible = true;
    });
  }

  void _startHideOpacityTimer() {
    _hideOpacityTimer = Timer(Duration(seconds: 4), () {
      setState(() {
        _forecastOverlaySliderIsVisible = false;
      });
    });
  }

  Future<void> _goToNewBounds(
      {required LatLngBounds latLngBounds, double? padding}) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
        CameraUpdate.newLatLngBounds(latLngBounds, padding ?? 0.0));
  }
}
