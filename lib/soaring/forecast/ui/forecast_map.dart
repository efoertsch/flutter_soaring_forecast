import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
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
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/LatLngForecast.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/sua_layer.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/estimated_flight_avg_summary.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/gliders.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoint_utils.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_overhead_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

import '../../region_model/bloc/region_model_bloc.dart';
import '../../region_model/bloc/region_model_state.dart';

class ForecastMap extends StatefulWidget {
  final Function runAnimation;

  ForecastMap({Key? key, required Function this.runAnimation})
      : super(key: key);

  @override
  ForecastMapState createState() => ForecastMapState();
}

class ForecastMapState extends State<ForecastMap>
    with AfterLayoutMixin<ForecastMap>, TickerProviderStateMixin {
  late final AnimatedMapController _mapController;
  bool _firstLayoutComplete = false;
  LatLng _mapCenter = NewEnglandMapCenter;
  SoaringForecastImageSet? soaringForecastImageSet;
  final List<Turnpoint> _turnpoints = [];
  final List<Polyline> _taskTurnpointCourse = <Polyline>[];
  final List<Polyline> _optimizedTaskRoute = <Polyline>[];
  final List<Polyline> _combinedTaskLines = <Polyline>[];
  final List<Marker> _mapMarkers = <Marker>[];
  final List<Marker> _soundingMarkers = <Marker>[];
  final List<Marker> _turnpointMarkers = <Marker>[];
  final List<Polygon> _suaPolygons = <Polygon>[];
  final _taskMarkers = <Marker>[];
  final List<Marker> _latLngMarkers = <Marker>[];

  // These bounds define the bounds of the forecast overlays
  LatLngBounds _forecastLatLngBounds = NewEnglandMapLatLngBounds;
  late final SuaGeoJsonHandler suaGeoJsonParser;

  /// Use to center task route in map
  LatLng? _southwest;
  double _swLat = 0;
  double _swLong = 0;
  double _neLat = 0;
  double _neLong = 0;

  bool _soundingsAreVisible = false;
  bool _routeIconIsVisible = false;
  bool _routeSummaryIsVisible = false;
  double _forecastOverlayOpacity = 50;
  bool _forecastOverlaySliderIsVisible = false;
  Timer? _hideOpacityTimer = null;
  double _mapZoom = 7;
  double _previousZoom = 7;
  bool _displayOptTaskAvg = false;
  bool _mapReady = false;

  final suaColors = SUAColor.values;

  var infoText = 'No Info';
  var tileSize = 256.0;
  var tilePointCheckZoom = 14;

  String? suaSelected;
  bool _showEstimatedFlightButton = false;



  @override
  void initState() {
    super.initState();
    _mapController = AnimatedMapController(vsync: this);
    suaGeoJsonParser = SuaGeoJsonHandler(context);
  }

  @override
  void afterFirstLayout(BuildContext context) {
    print("First layout complete");
    _firstLayoutComplete = true;
    _sendEvent(InitialRaspRegionEvent());
  }

  void _processMapEvent(MapEvent mapEvent) {
    // _printMapBounds("MapEvent  ${mapEvent} : bounds from _mapController",
    //     _mapController.bounds!);
    _mapZoom = mapEvent.camera.zoom;
    //debugPrint("MapEvent: ${mapEvent.source.name}  Zoom : ${_mapZoom}");
    if ((_mapZoom - _previousZoom).abs() > .25) {
      _previousZoom = _mapZoom;
      setState(() {
        _updateTurnpointMarkers(_turnpoints);
        _rebuildMarkerArray();
      });
    }
  }

  void _printMapBounds(String msg, LatLngBounds latLngBounds) {
    debugPrint(msg +
        " latLngBounds: ${latLngBounds.southWest!.toString()}  ${latLngBounds.northEast!.toString()}");
  }

  var _overlayImages = <OverlayImage>[];

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(children: [
        _getMapAndLegendWidget(),
        _getSoundingDisplayWidget(),
      ]),
    );
  }

  Stack _getMapAndLegendWidget() {
    return Stack(children: [
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
      _getOptimalFlightIcon(),
      _regionModelListener()
    ]);
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
      if (state is RaspForecastImageSet) {
        // print('Received RaspForecastImageSet in ForecastMap');
        soaringForecastImageSet = state.soaringForecastImageSet;
        updateForecastOverlay();
        return;
      }
      if (state is RaspTaskTurnpoints) {
        _updateTaskTurnpoints(state.taskTurnpoints);
        return;
      }
      // if (state is OptimizedTaskRouteState && state.optimizedTaskRoute != null) {
      //   _plotOptimizedRoute(state.optimizedTaskRoute!);
      // }
      if (state is LocalForecastState) {
        _placeLocalForecastMarker(state.latLngForecast);
        return;
      }

      if (state is TurnpointsInBoundsState) {
        //print('Received TurnpointsInBoundsState in ForecastMap');
        _updateTurnpointMarkers(state.turnpoints);
        // save for when zooming map and want to resize icons;
        _turnpoints.clear();
        _turnpoints.addAll(state.turnpoints);
        _updateTurnpointMarkers(state.turnpoints);
        return;
      }

      if (state is ForecastOverlayOpacityState) {
        _forecastOverlayOpacity = state.opacity;
        updateForecastOverlay();
        return;
      }
    }, buildWhen: (previous, current) {
      return current is RaspInitialState ||
          current is RaspForecastImageSet ||
          current is RaspTaskTurnpoints ||
          current is LocalForecastState ||
          current is TurnpointsInBoundsState ||
          current is RedisplayMarkersState ||
          current is ForecastOverlayOpacityState ||
          current is ForecastBoundsState;
    }, builder: (context, state) {
      if (state is RaspInitialState) {
        return SizedBox.shrink();
      }
      return FlutterMap(
          mapController: _mapController.mapController,
          options: MapOptions(
            initialCenter: _mapCenter,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag |
                  InteractiveFlag.pinchMove |
                  InteractiveFlag.pinchZoom,
            ),
            onMapReady: (() {
              _mapReady = true;
              _sendEvent(MapReadyEvent());
              _mapController.animatedFitCamera(
                  cameraFit: CameraFit.bounds(bounds: _forecastLatLngBounds));
            }),

            onMapEvent: ((mapEvent) => _processMapEvent(mapEvent)),
            //bounds: _forecastLatLngBounds,
            // boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(8.0)),
            onLongPress: (longPressPostion, latLng) =>
                _getLocalForecast(latLng: latLng),
            // onTap: (tapPosition, point) => _seeIfSUATapped(point),
          ),
          children: [
            // !!!---- Order of layers very important for receiving click events --- !!!
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: ['a', 'b', 'c'],
            ),
            OverlayImageLayer(
              key: null,
              overlayImages: _overlayImages,
            ),

            PolygonLayer(polygons: _suaPolygons),
            PolylineLayer(
              polylines: _combinedTaskLines,
            ),
            MarkerLayer(
              markers: _mapMarkers,
            ),
          ]);
    });
  }

  //Future<void> _seeIfSUATapped(LatLng point) async {
  //  suaSelected = null;
  //  // figure which tile we're on, then grab that tiles features to loop through
  //  // to find which feature the tap was on. Zoom 14 is kinda arbitrary here
  //  var pt = const Epsg3857()
  //      .latLngToPoint(point, _mapController.zoom.floorToDouble());
  //  var x = (pt.x / tileSize).floor();
  //  var y = (pt.y / tileSize).floor();
  //  var tile = geoJsonIndex.getTile(_mapController.zoom.floor(), x, y);
  //  //print("$x, $y  $point $pt  tile ${tile!.x} ${tile!.y} ${tile!.z}");
//
  //  if (tile != null) {
  //    StringBuffer sb = StringBuffer();
  //    // Multiple SUA areas/features may show up in one tile,
  //    // eg overlapping Boston 'wedding cake' SUAs
  //    for (var feature in tile.features) {
  //      var polygonList = feature.geometry;
  //      if (feature.type != 1) {
  //        if (geoJSON.isGeoPointInPoly(pt, polygonList, size: tileSize)) {
  //          if (feature.tags.containsKey('TITLE')) {
  //            sb.write("Title: ${feature.tags['TITLE']}\n");
  //            sb.write("Type : ${feature.tags['TYPE']}\n");
  //            sb.write("Base : ${feature.tags['BASE']}\n");
  //            sb.write("Tops : ${feature.tags['TOPS']}\n\n");
  //          }
  //          // Don't
  //          // highlightedIndex = await GeoJSON().createIndex(null,
  //          //     geoJsonMap: feature.tags['source'], tolerance: 0);
  //        }
  //      }
  //    }
  //    if (sb.isNotEmpty) {
  //      CommonWidgets.showInfoDialog(
  //          context: context,
  //          title: "SUA",
  //          msg: sb.toString(),
  //          button1Text: StandardLiterals.OK,
  //          button1Function: (() => Navigator.pop(context)));
  //    }
  //  }
  //}

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
              visible: _soundingsAreVisible,
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
                                _soundingsAreVisible = false;
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
        if (state is RaspTaskTurnpoints) {
          _routeIconIsVisible = state.taskTurnpoints.length > 0;
          _routeSummaryIsVisible = false;
        }

        if (state is ShowEstimatedFlightButton) {
          _showEstimatedFlightButton = state.showEstimatedFlightButton;
        }
      },
      child: SizedBox.shrink(),
    );
  }



  void _updateTaskTurnpoints(List<TaskTurnpoint> taskTurnpoints) {
    print('number of task turnpoints ${taskTurnpoints.length.toString()} ');
    clearTaskFromMap(taskTurnpoints.length > 0);
    if (taskTurnpoints.length == 0) {
      //  _printMapBounds("TaskTurnpoints.length = 0 ", _forecastLatLngBounds);
      _mapController.animatedFitCamera(
          cameraFit: CameraFit.bounds(bounds: _forecastLatLngBounds));
    } else {
      List<LatLng> points = <LatLng>[];
      for (var taskTurnpoint in taskTurnpoints) {
        // print('adding taskturnpoint: ${taskTurnpoint.title}');
        var turnpointLatLng =
            LatLng(taskTurnpoint.latitudeDeg, taskTurnpoint.longitudeDeg);
        points.add(turnpointLatLng);
        _taskMarkers.add(Marker(
          width: 80.0,
          height: 40.0,
          point: turnpointLatLng,
          child: _getTaskTurnpointMarker(taskTurnpoint),
          //anchorPos: AnchorPos.align(AnchorAlign.top)
        ));
        updateMapLatLngCorner(turnpointLatLng);
      }
      _rebuildMarkerArray();
      _taskTurnpointCourse.add(Polyline(
        points: points,
        strokeWidth: 2.0,
        color: Colors.red,
      ));
      _rebuildTaskLinesArray();
      // Only do this if view
      LatLng southwest = new LatLng(_swLat, _swLong);
      LatLng northeast = new LatLng(_neLat, _neLong);
      final latLngBounds = LatLngBounds(southwest, northeast);
      // latLngBounds.pad(.2);
      // _printMapBounds("_updateTaskTurnpoints ", latLngBounds);
      _mapController.animatedFitCamera(
          cameraFit: CameraFit.bounds(bounds: latLngBounds));
    }
  }

  void _plotOptimizedRoute(EstimatedFlightSummary estimatedFlightRoute) {
    _optimizedTaskRoute.clear();
    var routePoints = <LatLng>[];
    int numberRoutePoints =
        estimatedFlightRoute.routeSummary?.routeTurnpoints?.length ?? 0;
    print('number of route points ${numberRoutePoints} ');
    if (numberRoutePoints == 0) {
      //  _printMapBounds("TaskTurnpoints.length = 0 ", _forecastLatLngBounds);
      _rebuildTaskLinesArray();
      _mapController.animatedFitCamera(
          cameraFit: CameraFit.bounds(bounds: _forecastLatLngBounds));
    } else {
      for (var routePoint
          in estimatedFlightRoute.routeSummary!.routeTurnpoints!) {
        // print('adding taskturnpoint: ${taskTurnpoint.title}');
        var latLngPoint = LatLng(
            double.parse(routePoint.lat!), double.parse(routePoint.lon!));
        routePoints.add(latLngPoint);
        updateMapLatLngCorner(latLngPoint);
      }
      _optimizedTaskRoute.add(Polyline(
        points: routePoints,
        strokeWidth: 2.0,
        color: Colors.black,
      ));
      _rebuildTaskLinesArray();
      // Only do this if view
      LatLng southwest = new LatLng(_swLat, _swLong);
      LatLng northeast = new LatLng(_neLat, _neLong);
      final latLngBounds = LatLngBounds(southwest, northeast);
      //latLngBounds.pad(.2);
      // _printMapBounds("_updateTaskTurnpoints ", latLngBounds);
      _mapController.animatedFitCamera(
          cameraFit: CameraFit.bounds(bounds: latLngBounds));
    }
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
            turnpointName: taskTurnpoint.title,
            turnpointCode: taskTurnpoint.code,
            forTask: true);
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
    debugPrint('number of turnpoints ${turnpoints.length.toString()} ');
    _turnpointMarkers.clear();
    double markerSize = getMarkerSize();
    for (var turnpoint in turnpoints) {
      // print('adding turnpoint: ${turnpoint.title}');
      var turnpointLatLng =
          LatLng(turnpoint.latitudeDeg, turnpoint.longitudeDeg);
      _turnpointMarkers.add(Marker(
          width: markerSize,
          height: markerSize,
          point: turnpointLatLng,
          child: _getTurnpointMarker(turnpoint)));
      // anchorPos: AnchorPos.align(AnchorAlign.top)));
    }
    _rebuildMarkerArray();
  }

  double getMarkerSize() {
    return (_mapZoom < 8.0)
        ? 12
        : (_mapZoom < 9.0)
            ? 24
            : 48;
  }

  Widget _getTurnpointMarker(final Turnpoint turnpoint) {
    return InkWell(
      onTap: () {
        _displayTurnpointOverheadView(turnpoint);
      },
      onLongPress: () {
        _getLocalForecast(
            latLng: LatLng(turnpoint.latitudeDeg, turnpoint.longitudeDeg),
            turnpointName: turnpoint.title,
            turnpointCode: turnpoint.code);
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

  TextStyle getMarkerTextStyle() {
    return (_mapZoom < 9.5)
        ? textStyleBlackFontSize12
        : textStyleBlackFontSize18;
  }

  void _placeSoundingMarkers(final List<Soundings> soundings) {
    print('number of soundings ${soundings.length.toString()} ');
    _soundingMarkers.clear();
    for (var sounding in soundings) {
      var soundingLatLng = LatLng(
          double.parse(sounding.latitude!), double.parse(sounding.longitude!));
      _soundingMarkers.add(Marker(
          height: 40.0,
          width: 70.0,
          point: soundingLatLng,
          child: _getSoundingMarker(sounding)));
      // anchorPos: AnchorPos.align(AnchorAlign.top)));
    }
    setState(() {
      _rebuildMarkerArray();
    });
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
      _soundingsAreVisible = true;
    });
  }

  void _placeLocalForecastMarker(LatLngForecast latLngForecast) {
    _latLngMarkers.clear();
    var latLngMarker = Marker(
      width: 200.0,
      height: 200.0,
      point: latLngForecast.latLng,
      child: _getLatLngForecastMarker(latLngForecast),
      //anchorPos: AnchorPos.align(AnchorAlign.top),
    );
    _latLngMarkers.add(latLngMarker);
    _rebuildMarkerArray();
  }

  Widget _getLatLngForecastMarker(LatLngForecast latLngForecast) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: Colors.white,
          constraints: BoxConstraints(maxHeight: 200),
          child: TextFormField(
              readOnly: true,
              initialValue: latLngForecast.getForecastText(),
              textAlign: TextAlign.center,
              style: TextStyle(backgroundColor: Colors.white),
              maxLines: 5,
              minLines: 5,
              onTap: () {
                _removeLocalForecastMarker();
              }),
        ),
        Icon(Icons.arrow_drop_down, color: Colors.white),
      ],
    );
  }

  void clearTaskFromMap(bool taskDefined) {
    _taskTurnpointCourse.clear();
    _optimizedTaskRoute.clear();
    _taskMarkers.clear();
    _rebuildMarkerArray();
    _rebuildTaskLinesArray();
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
    if (soaringForecastImageSet != null) {
      // print(
      //     "forecast overlay: " + soaringForecastImageSet!.bodyImage!.imageUrl);
      var imageUrl = soaringForecastImageSet!.bodyImage!.imageUrl;
      var raspUrl = RASP_BASE_URL + imageUrl;
      var overlayImage = OverlayImage(
          bounds: _forecastLatLngBounds,
          opacity: _forecastOverlayOpacity / 100,
          imageProvider: NetworkImage(raspUrl),
          gaplessPlayback: true);

      if (_overlayImages.length == 0) {
        _overlayImages.add(overlayImage);
      } else {
        _overlayImages[0] = overlayImage;
      }
    }
  }

  _getLocalForecast(
      {required LatLng latLng,
      String? turnpointName = null,
      String? turnpointCode,
      bool forTask = false}) {
    widget.runAnimation(false);
    // debugPrint('Local forecast requested at : ${latLng.latitude.toString()}  :'
    //     '  ${latLng.longitude.toString()}');
    _sendEvent(DisplayLocalForecastEvent(
        latLng: latLng,
        turnpointName: turnpointName,
        turnpointCode: turnpointCode,
        forTask: forTask));
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
    _mapMarkers.addAll(_latLngMarkers);
    setState(() {
    });
  }

  void _rebuildTaskLinesArray() {
    _combinedTaskLines.clear();
    _combinedTaskLines.addAll(_taskTurnpointCourse);
    _combinedTaskLines.addAll(_optimizedTaskRoute);
  }

// Currently only display max of 1, so if changes in future need to revisit logic
  void _removeLocalForecastMarker() {
    _latLngMarkers.clear();
    _rebuildMarkerArray();
    _sendEvent(RedisplayMarkersEvent());
  }

  void _displayTurnpointOverheadView(Turnpoint turnpoint) async {
    await Navigator.pushNamed(context, TurnpointViewRouteBuilder.routeName,
        arguments: TurnpointOverHeadArgs(turnpoint: turnpoint));
  }

  void _updateGeoJsonSuaDetails(String suaDetail) async {
    setState(() {
      _suaPolygons.clear();
      suaGeoJsonParser.parseGeoJsonAsString(suaDetail);
      _suaPolygons.addAll(suaGeoJsonParser.getGeoJasonPolygons());
    });
  }

//Widget _getGeoJsonWidget() {
// return GeoJSONWidget(
//   drawClusters: false,
//   drawFeatures: true,
//   index: geoJsonIndex,
//   options: GeoJSONOptions(
//     featuresHaveSameStyle: false,
//     overallStyleFunc: (TileFeature feature) {
//       var paint = Paint()
//         ..style = PaintingStyle.stroke
//         ..color = Colors.blue.shade200
//         ..strokeWidth = 5
//         ..isAntiAlias = false;
//       if (feature.type == 3) {
//         // lineString
//         ///paint.style = PaintingStyle.fill;
//       }
//       return paint;
//     },
//     // f
//     ///clusterFunc: () { return Text("Cluster"); },
//     ///lineStringFunc: () { if(CustomImages.imageLoaded) return CustomImages.plane;}
//     lineStringStyle: (feature) {
//       return Paint()
//         ..style = PaintingStyle.stroke
//         ..color = Colors.red
//         ..strokeWidth = 2
//         ..isAntiAlias = true;
//     },
//     polygonFunc: null,
//     polygonStyle: (feature) {
//       var suaColor = suaColors.firstWhere(
//           (sua) => sua.suaClassType == feature.tags['TYPE'],
//           orElse: (() => SUAColor.classUnKnown));
//       suaColor.airspaceColor;
//       var paint = Paint()
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 2
//         ..isAntiAlias = true
//         ..color = suaColor.airspaceColor;
//       paint.isAntiAlias = false;
//       return paint;
//     },
//     polygonLabel: (feature, canvas, offsets) {
//       Label.paintText(
//         canvas,
//         offsets,
//         feature.tags['TYPE'],
//         // If I don't include as TextStyle I get class conflict. Don't know why AS is showing that
//         textStyleBlack87FontSize14,
//         _mapController.rotation, // rotationRad,
//         rotate: true, //polygonOpt.rotateLabel,
//         labelPlacement:
//             PolygonLabelPlacement.centroid, //polygonOpt.labelPlacement
//       );
//     },
//   ),
// );
//

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

  Widget _getOptimalFlightIcon() {
    return (_routeIconIsVisible && _showEstimatedFlightButton)
        ? Positioned(
            bottom: 0,
            left: 0,
            child: ElevatedButton(
              style: const ButtonStyle(
                backgroundColor: MaterialStatePropertyAll<Color>(Colors.white),
              ),
              onPressed: () async {
                widget.runAnimation(false);
                await Navigator.pushNamed(
                    context, EstimatedTaskRouteBuilder.routeName);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/svg/task_route.svg',
                    height: 40,
                    width: 40,
                  ),
                  Text(
                    "Estimated\nFlight",
                    style: textStyleBoldBlackFontSize14,
                  ),
                ],
              ),
            ),
          )
        : SizedBox.shrink();
  }




  _regionModelListener() {
    return BlocListener<RegionModelBloc, RegionModelState>(
        listener: (context, state) {
          if (state is CenterOfMapState) {
            setState(() {
              _mapCenter = state.latLng;
            });
          }
          if (state is SuaDetailsState) {
            _updateGeoJsonSuaDetails(state.suaDetails);
            return;
          }
          if (state is RegionSoundingsState) {
            _placeSoundingMarkers(state.soundings);
          }
          if (state is RegionLatLngBoundsState) {
            _forecastLatLngBounds = state.latLngBounds;
            _sendEvent(ViewBoundsEvent(_forecastLatLngBounds));
            if (_mapReady) {
              _mapController.animatedFitCamera(
                  cameraFit: CameraFit.bounds(bounds: _forecastLatLngBounds));
            }
            return;
          }
        },
        child: SizedBox.shrink());
  }
}
