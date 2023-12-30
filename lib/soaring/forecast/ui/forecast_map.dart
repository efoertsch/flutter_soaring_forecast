import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show NewEnglandMapLatLngBounds, RASP_BASE_URL, SUAColor, StandardLiterals;
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/LatLngForecast.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/util/animated_map_controller.dart';
import 'package:flutter_soaring_forecast/soaring/graphics/data/forecast_graph_data.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/estimated_flight_avg_summary.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/gliders.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoint_utils.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_overhead_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geojson_vector_slicer/geojson/classes.dart';
import 'package:geojson_vector_slicer/geojson/geojson.dart';
import 'package:geojson_vector_slicer/geojson/geojson_options.dart';
import 'package:geojson_vector_slicer/geojson/geojson_widget.dart';
import 'package:geojson_vector_slicer/geojson/index.dart';
import 'package:geojson_vector_slicer/vector_tile/vector_tile.dart';
import 'package:latlong2/latlong.dart';

import '../../app/label.dart';
import '../../forecast_types/ui/common_forecast_widgets.dart';

class ForecastMap extends StatefulWidget {
  final Function stopAnimation;

  ForecastMap({Key? key, required Function this.stopAnimation})
      : super(key: key);

  @override
  ForecastMapState createState() => ForecastMapState();
}

class ForecastMapState extends State<ForecastMap>
    with AfterLayoutMixin<ForecastMap>, TickerProviderStateMixin {
  late final AnimatedMapController _mapController;
  bool _firstLayoutComplete = false;
  LatLng? _mapCenter;
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
  EstimatedFlightSummary? _estimatedFlightSummary;

  final suaColors = SUAColor.values;

  late GeoJSONVT geoJsonIndex = GeoJSONVT({}, GeoJSONVTOptions(buffer: 32));
  late GeoJSONVT? highlightedIndex =
      GeoJSONVT({}, GeoJSONVTOptions(buffer: 32, debug: 0));
  var infoText = 'No Info';
  var tileSize = 256.0;
  var tilePointCheckZoom = 14;
  GeoJSON geoJSON = GeoJSON();
  VectorTileIndex vectorTileIndex = VectorTileIndex();
  String? suaSelected;
  bool _showEstimatedFlightButton = false;

  @override
  void initState() {
    super.initState();
    _mapController = AnimatedMapController(this);
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
    _mapZoom = mapEvent.zoom;
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
      _showOptimalFlightAvgTable()
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
      if (state is RaspSoundingsState) {
        //  print('Received Soundings in ForecastMap');
        _placeSoundingMarkers(state.soundings);
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
      if (state is SuaDetailsState) {
        _updateGeoJsonSuaDetails(state.suaDetails);
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
          current is LocalForecastState ||
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
      return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            onMapReady: (() {
              _sendEvent(MapReadyEvent());
            }),
            center: _mapCenter,
            interactiveFlags: InteractiveFlag.drag |
                InteractiveFlag.pinchMove |
                InteractiveFlag.pinchZoom,
            onMapEvent: ((mapEvent) => _processMapEvent(mapEvent)),
            //bounds: _forecastLatLngBounds,
            // boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(8.0)),
            onLongPress: (longPressPostion, latLng) =>
                _getLocalForecast(latLng: latLng),
            onTap: (tapPosition, point) => _seeIfSUATapped(point),
          ),
          children: [
            // !!!---- Order of layers very important for receiving click events --- !!!
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: ['a', 'b', 'c'],
            ),
            OverlayImageLayer(
              key: null,
              overlayImages: _overlayImages,
            ),

            //PolygonLayer(polygons: _suaPolygons),
            _getGeoJsonWidget(),
            PolylineLayer(
              polylines: _combinedTaskLines,
            ),
            MarkerLayer(
              markers: _mapMarkers,
            ),
          ]);
    });
  }

  Future<void> _seeIfSUATapped(LatLng point) async {
    suaSelected = null;
    // figure which tile we're on, then grab that tiles features to loop through
    // to find which feature the tap was on. Zoom 14 is kinda arbitrary here
    var pt = const Epsg3857()
        .latLngToPoint(point, _mapController.zoom.floorToDouble());
    var x = (pt.x / tileSize).floor();
    var y = (pt.y / tileSize).floor();
    var tile = geoJsonIndex.getTile(_mapController.zoom.floor(), x, y);
    //print("$x, $y  $point $pt  tile ${tile!.x} ${tile!.y} ${tile!.z}");

    if (tile != null) {
      StringBuffer sb = StringBuffer();
      // Multiple SUA areas/features may show up in one tile,
      // eg overlapping Boston 'wedding cake' SUAs
      for (var feature in tile.features) {
        var polygonList = feature.geometry;
        if (feature.type != 1) {
          if (geoJSON.isGeoPointInPoly(pt, polygonList, size: tileSize)) {
            if (feature.tags.containsKey('TITLE')) {
              sb.write("Title: ${feature.tags['TITLE']}\n");
              sb.write("Type : ${feature.tags['TYPE']}\n");
              sb.write("Base : ${feature.tags['BASE']}\n");
              sb.write("Tops : ${feature.tags['TOPS']}\n\n");
            }
            // Don't
            // highlightedIndex = await GeoJSON().createIndex(null,
            //     geoJsonMap: feature.tags['source'], tolerance: 0);
          }
        }
      }
      if (sb.isNotEmpty) {
        CommonWidgets.showInfoDialog(
            context: context,
            title: "SUA",
            msg: sb.toString(),
            button1Text: StandardLiterals.OK,
            button1Function: (() => Navigator.pop(context)));
      }
    }
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
        if (state is DisplayLocalForecastGraphState) {
          _displayLocalForecastGraph(context, state.localForecastGraphData);
        }
        if (state is RaspTaskTurnpoints) {
          _routeIconIsVisible = state.taskTurnpoints.length > 0;
          _routeSummaryIsVisible = false;
        }
        if (state is ForecastBoundsState) {
          _forecastLatLngBounds = state.latLngBounds;
          // _printMapBounds(
          //     "ForecastBoundsState  bounds ", _forecastLatLngBounds!);
          _mapController.animatedFitBounds(_forecastLatLngBounds);
          return;
        }
        if (state is ShowEstimatedFlightButton){
          _showEstimatedFlightButton = state.showEstimatedFlightButton;
        }
      },
      child: SizedBox.shrink(),
    );
  }

  void _displayLocalForecastGraph(
      BuildContext context, LocalForecastInputData inputParms) async {
    var result = await Navigator.pushNamed(
      context,
      LocalForecastGraphRouteBuilder.routeName,
      arguments: inputParms,
    );
    if (result is LocalForecastOutputData) {
      _sendEvent(SelectedRaspModelEvent(result.model));
      _sendEvent(SelectRaspForecastDateEvent(result.date));
    }
  }

  void _updateTaskTurnpoints(List<TaskTurnpoint> taskTurnpoints) {
    print('number of task turnpoints ${taskTurnpoints.length.toString()} ');
    clearTaskFromMap(taskTurnpoints.length > 0);
    if (taskTurnpoints.length == 0) {
      //  _printMapBounds("TaskTurnpoints.length = 0 ", _forecastLatLngBounds);
      _mapController.animatedFitBounds(_forecastLatLngBounds);
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
            builder: (context) => _getTaskTurnpointMarker(taskTurnpoint),
            anchorPos: AnchorPos.align(AnchorAlign.top)));
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
      latLngBounds.pad(.2);
      // _printMapBounds("_updateTaskTurnpoints ", latLngBounds);
      _mapController.animatedFitBounds(latLngBounds);
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
      _mapController.animatedFitBounds(_forecastLatLngBounds);
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
      latLngBounds.pad(.2);
      // _printMapBounds("_updateTaskTurnpoints ", latLngBounds);
      _mapController.animatedFitBounds(latLngBounds);
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
            turnpointCode: taskTurnpoint.code);
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
          builder: (context) => _getTurnpointMarker(turnpoint),
          anchorPos: AnchorPos.align(AnchorAlign.top)));
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
          builder: (context) => _getSoundingMarker(sounding),
          anchorPos: AnchorPos.align(AnchorAlign.top)));
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
      _soundingsAreVisible = true;
    });
  }

  void _placeLocalForecastMarker(LatLngForecast latLngForecast) {
    _latLngMarkers.clear();
    var latLngMarker = Marker(
      width: 200.0,
      height: 200.0,
      point: latLngForecast.latLng,
      builder: (context) => _getLatLngForecastMarker(latLngForecast),
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
      String? turnpointCode}) {
    widget.stopAnimation();
    // debugPrint('Local forecast requested at : ${latLng.latitude.toString()}  :'
    //     '  ${latLng.longitude.toString()}');
    _sendEvent(DisplayLocalForecastEvent(latLng, turnpointName, turnpointCode));
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

  void _updateGeoJsonSuaDetails(String suaDetails) async {
    _suaPolygons.clear();
    geoJsonIndex = await geoJSON.createIndex(suaDetails,
        tileSize: tileSize,
        keepSource: true,
        buffer: 32,
        sourceIsGeoJson: true);
  }

  Widget _getGeoJsonWidget() {
    return GeoJSONWidget(
      drawClusters: false,
      drawFeatures: true,
      index: geoJsonIndex,
      options: GeoJSONOptions(
        featuresHaveSameStyle: false,
        overallStyleFunc: (TileFeature feature) {
          var paint = Paint()
            ..style = PaintingStyle.stroke
            ..color = Colors.blue.shade200
            ..strokeWidth = 5
            ..isAntiAlias = false;
          if (feature.type == 3) {
            // lineString
            ///paint.style = PaintingStyle.fill;
          }
          return paint;
        },
        // f
        ///clusterFunc: () { return Text("Cluster"); },
        ///lineStringFunc: () { if(CustomImages.imageLoaded) return CustomImages.plane;}
        lineStringStyle: (feature) {
          return Paint()
            ..style = PaintingStyle.stroke
            ..color = Colors.red
            ..strokeWidth = 2
            ..isAntiAlias = true;
        },
        polygonFunc: null,
        polygonStyle: (feature) {
          var suaColor = suaColors.firstWhere(
              (sua) => sua.suaClassType == feature.tags['TYPE'],
              orElse: (() => SUAColor.classUnKnown));
          suaColor.airspaceColor;
          var paint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..isAntiAlias = true
            ..color = suaColor.airspaceColor;
          paint.isAntiAlias = false;
          return paint;
        },
        polygonLabel: (feature, canvas, offsets) {
          Label.paintText(
            canvas,
            offsets,
            feature.tags['TYPE'],
            // If I don't include as TextStyle I get class conflict. Don't know why AS is showing that
            textStyleBlack87FontSize14,
            _mapController.rotation, // rotationRad,
            rotate: true, //polygonOpt.rotateLabel,
            labelPlacement:
                PolygonLabelPlacement.centroid, //polygonOpt.labelPlacement
          );
        },
      ),
    );
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
                widget.stopAnimation();
                var maybeGlider = await Navigator.pushNamed(
                    context, GliderPolarListBuilder.routeName);
                if (maybeGlider != null && maybeGlider is Glider) {
                  _sendEvent(GetEstimatedFlightAvgEvent(maybeGlider));
                }
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

  Widget _showOptimalFlightAvgTable() {
    return BlocConsumer<RaspDataBloc, RaspDataState>(
      listener: (context, state) {
        if (state is EstimatedFlightSummaryState) {
          _estimatedFlightSummary = state.estimatedFlightSummary;
        }
      },
      buildWhen: (previous, current) {
        return current is EstimatedFlightSummaryState;
      },
      builder: (context, state) {
        if (_estimatedFlightSummary != null) {
          return _getOptimalFlightSummary(_estimatedFlightSummary!);
        }
        return SizedBox.shrink();
      },
    );
  }


  Widget _getOptimalFlightSummary(EstimatedFlightSummary optimalTaskSummary) {
    const String title = "Flight Avg";
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(right: 8),
      child: Column(
        children: [Expanded(
          child: ListView(
            //crossAxisAlignment: CrossAxisAlignment.start,
            scrollDirection: Axis.vertical,
            children: [
              _getOptimalFlightParms(optimalTaskSummary),
              _getTurnpointsTableHeader(),
              _getTaskTurnpointsTable(optimalTaskSummary),
              _getLegTableHeader(),
              _getLegDetailsTable(optimalTaskSummary),
              _getWarningMsgDisplay(optimalTaskSummary),

            ],
          ),
        ),_getOptimalFlightCloseButton(),
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
          // TableRow(
          //   children: [
          //     _formattedTextCell(header!.valid ?? ""),
          //     _formattedTextCell(header!.region ?? ""),
          //   ],
          // ),
          TableRow(
            children: [
              _formattedTextCell("Glider " + (header!.glider ?? "")),
              _formattedTextCell("L/D= " +
                  double.parse(header!.maxLd ?? "0").toStringAsFixed(1)),
            ],
          ),
          TableRow(
            children: [
              _formattedTextCell("Polar Speed Adjustment"),
              _formattedTextCell(double.parse(header!.polarSpeedAdjustment ?? "0").toStringAsFixed(1)),
            ],
          ),
          TableRow(
            children: [
              _formattedTextCell("Thermalling Sink \nRate (ft/min)"),
              _formattedTextCell(double.parse(header!.thermalingSinkRate ?? "0").toStringAsFixed(1)),
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
    if (optimalTaskSummary.routeSummary?.legDetails != null) {
      var legData = optimalTaskSummary.routeSummary!.legDetails;
      var legDetailRows = _getLegTableRows(legData!);
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
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child:
            Container(margin: EdgeInsets.only(right: 8), child: legDetailTable),
      );
    }
    return SizedBox.shrink();
  }

  List<TableRow> _getLegTableRows(List<LegDetail> legDetails) {
    var legDetailTableRows = <TableRow>[];
    legDetailTableRows.add(_getLegDetailLabels());
    for (var legDetail in legDetails) {
      var tableRow = TableRow(
        children: [
          _formattedTextCell((legDetail.leg ??
              " ") +
                  (legDetail.message != null ? "\n" + legDetail.message! : "")),
          _formattedTextCell(legDetail.clockTime ?? " "),
          _formattedTextCell(double.parse(legDetail.optFlightTimeMin ?? "0")
              .toStringAsFixed(0)),
          _formattedTextCell(
             double.parse(legDetail.sptlAvgDistKm ?? "0").toStringAsFixed(1)),
          //  convert tailwind to headwind
         // _formattedTextCell(
          //    (double.parse(legDetail.sptlAvgTailWind ?? "0") * -1)
          //        .toStringAsFixed(0)),
        //  _formattedTextCell(double.parse(legDetail.sptlAvgClimbRate ?? "0")
        //      .toStringAsFixed(0)),
          //  convert tailwind to headwind
          _formattedTextCell(
              (double.parse(legDetail.optAvgTailWind ?? "0") * -1)
                  .toStringAsFixed(0)),
          _formattedTextCell(double.parse(legDetail.optAvgClimbRate ?? "0")
              .toStringAsFixed(0)),
          _formattedTextCell(double.parse(legDetail.optFlightGrndSpeedKt ?? "0")
              .toStringAsFixed(0)),
          _formattedTextCell(
              double.parse(legDetail.optFlightGrndSpeedKmh ?? "0")
                  .toStringAsFixed(0)),
          _formattedTextCell(double.parse(legDetail.optFlightAirSpeedKt ?? "0")
              .toStringAsFixed(0)),
          _formattedTextCell(double.parse(legDetail.optFlightThermalPct ?? "0")
              .toStringAsFixed(0)),
        ],
      );
      legDetailTableRows.add(tableRow);
    }
    return legDetailTableRows;
  }

  TableRow _getLegDetailLabels() {
    var legDetailLabels = <TableRow>[];
    return TableRow(
      children: [
        _formattedTextCell("L\nE\nG"),
        _formattedTextCell("ClockTime"),
        _formattedTextCell("Time\nMin"),
        _formattedTextCell("Dist\nkm"),
        //_formattedTextCell("Head\nWind\nkt"),
        //_formattedTextCell("Climb\nRate\nkt"),
        _formattedTextCell("Head\nWind\nkt"),
        _formattedTextCell("Clmb\nRate\nkt"),
        _formattedTextCell("Gnd\nSpd\nkt"),
        _formattedTextCell("Gnd\nSpd\nkm/h"),
        _formattedTextCell("Air\nSpd\nkt"),
        _formattedTextCell("Thermaling\nPct\n%"),
      ],
    );
  }

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
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity,
            40), // double.infinity is the width and 30 is the height
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      child: Text("Close"),
      onPressed: () {
        setState(() {
          _estimatedFlightSummary = null;
        });
      },
    );
  }
}
