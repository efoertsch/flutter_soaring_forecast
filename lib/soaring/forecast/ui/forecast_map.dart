import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:flutter_soaring_forecast/soaring/app/main.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/LatLngForecast.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/repository/options/special_use_airspace.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoint_utils.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_overhead_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

class ForecastMap extends StatefulWidget {
  final Function stopAnimation;

  ForecastMap({Key? key, required Function this.stopAnimation})
      : super(key: key);

  @override
  ForecastMapState createState() => ForecastMapState();
}

class ForecastMapState extends State<ForecastMap>
    with AfterLayoutMixin<ForecastMap> {
  late final MapController _mapController;
  final _forecastOverlayController = StreamController<Null>.broadcast();
  late final StreamSubscription _mapControllerStream;

  bool _firstLayoutComplete = false;
  SoaringForecastImageSet? soaringForecastImageSet;
  final List<Polyline> _taskTurnpointCourse = <Polyline>[];
  final List<Marker> _mapMarkers = <Marker>[];
  final List<Marker> _soundingMarkers = <Marker>[];
  final List<Marker> _turnpointMarkers = <Marker>[];
  final List<Polygon> _suaPolygons = <Polygon>[];
  final _taskMarkers = <Marker>[];
  final List<Marker> _latLngMarkers = <Marker>[];

  //Default values - NewEngland lat/lng of course!
  final LatLng _center = LatLng(43.1394043, -72.0759888);
  static final LatLngBounds _NewEnglandMapLatLngBounds = LatLngBounds(
      LatLng(41.2665329, -73.6473083), LatLng(45.0120811, -70.5046997));
  LatLngBounds _mapLatLngBounds = _NewEnglandMapLatLngBounds;

  /// Use to center task route in googleMap frame
  LatLng? southwest;
  double swLat = 0;
  double swLong = 0;
  double neLat = 0;
  double neLong = 0;

  bool _soundingsVisibility = false;
  double _forecastOverlayOpacity = 50;
  var _forecastOverlaySliderIsVisible = false;
  Timer? _hideOpacityTimer = null;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    // Anything?
    _mapControllerStream.cancel();
    _forecastOverlayController.close();
    super.dispose();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    print("First layout complete");
    _firstLayoutComplete = true;
    _sendEvent(InitialRaspRegionEvent());
    _mapController.onReady.then((value) {
      _sendEvent(MapReadyEvent());
      _processMapEvent();
    });
  }

  void _processMapEvent() {
    _mapControllerStream =
        _mapController.mapEventStream.listen((MapEvent mapEvent) {
      //print("MapEvent:  ${mapEvent.toString()}");
      if (mapEvent is MapEventFlingAnimationEnd) {
        _sendEvent(NewLatLngBoundsEvent(_mapController.bounds!));
      }
    });
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
      Container(
        alignment: Alignment.center,
        child: _forecastMap(),
      ),
      Container(
        alignment: Alignment.centerRight,
        child: _forecastLegend(),
      ),
      _getOpacitySlider(),
    ]);
  }

  Widget _forecastLegend() {
    return BlocBuilder<RaspDataBloc, RaspDataState>(
        buildWhen: (previous, current) {
      return current is RaspInitialState || current is RaspForecastImageSet;
    }, builder: (context, state) {
      if (state is RaspForecastImageSet) {
        print('Processing RaspForecastImageSet for forecastLegend');
        return InteractiveViewer(
          panEnabled: true,
          maxScale: 4.0,
          child: Image(
            image: NetworkImage(Constants.RASP_BASE_URL +
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
      print("state : $state");
      if (state is RaspInitialState ||
          state is RaspForecastImageSet ||
          state is RaspTaskTurnpoints ||
          state is LocalForecastState ||
          state is RaspSoundingsState ||
          state is TurnpointsInBoundsState ||
          state is RedisplayMarkersState ||
          state is SuaDetailsState ||
          state is ForecastOverlayOpacityState) {
        if (state is RaspForecastImageSet) {
          print('Received RaspForecastImageSet in ForecastMap');
          soaringForecastImageSet = state.soaringForecastImageSet;
          updateForecastOverlay();
          return;
        }
        if (state is RaspTaskTurnpoints) {
          _updateTaskTurnpoints(state.taskTurnpoints);
          return;
        }
        if (state is LocalForecastState) {
          _placeLocalForecastMarker(state.latLngForecast);
          return;
        }
        if (state is RaspSoundingsState) {
          print('Received Soundings in ForecastMap');
          _placeSoundingMarkers(state.soundings);
          return;
        }
        if (state is TurnpointsInBoundsState) {
          print('Received TurnpointsInBoundsState in ForecastMap');
          _updateTurnpointMarkers(state.turnpoints);
          return;
        }
        if (state is SuaDetailsState) {
          print('Received SuaDetailsState');
          _updateSuaDetails(state.suaDetails);
          return;
        }
        if (state is ForecastOverlayOpacityState) {
          _forecastOverlayOpacity = state.opacity;
          updateForecastOverlay();
          return;
        }
      }
      ;
    }, buildWhen: (previous, current) {
      //print("forecast state is:" + current.toString());
      return current is RaspInitialState ||
          current is RaspForecastImageSet ||
          current is RaspTaskTurnpoints ||
          current is LocalForecastState ||
          current is RaspSoundingsState ||
          current is TurnpointsInBoundsState ||
          current is RedisplayMarkersState ||
          current is SuaDetailsState ||
          current is ForecastOverlayOpacityState;
    }, builder: (context, state) {
      return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            bounds: _mapLatLngBounds,
            boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(8.0)),
            allowPanning: true,
            onTap: (tapPosition, latlng) => print(latlng.toString()),
            onLongPress: (longPressPostion, latLng) =>
                _getLocalForecast(latLng),
            onPositionChanged: ((mapPosition, hasGesture) =>
                _updateMapPositon(mapPosition, hasGesture)),
          ),
          layers: [
            TileLayerOptions(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: ['a', 'b', 'c'],
            ),
            OverlayImageLayerOptions(
              key: null,
              overlayImages: _overlayImages,
              rebuild: _forecastOverlayController.stream,
            ),
            PolylineLayerOptions(
              polylines: _taskTurnpointCourse,
            ),
            MarkerLayerOptions(
              markers: _mapMarkers,
            ),
            PolygonLayerOptions(polygons: _suaPolygons),
          ]);
    });
  }

  Widget _getSoundingDisplayWidget() {
    return BlocBuilder<RaspDataBloc, RaspDataState>(
        buildWhen: (previous, current) {
      return current is RaspInitialState || current is SoundingForecastImageSet;
    }, builder: (context, state) {
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
                      image: NetworkImage(Constants.RASP_BASE_URL + imageUrl),
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

  void _updateTaskTurnpoints(List<TaskTurnpoint> taskTurnpoints) {
    print('number of task turnpoints ${taskTurnpoints.length.toString()} ');
    clearTaskFromMap(taskTurnpoints.length > 0);
    if (taskTurnpoints.length == 0) return;
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
    LatLng southwest = new LatLng(swLat, swLong);
    LatLng northeast = new LatLng(neLat, neLong);
    _mapController.fitBounds(LatLngBounds(southwest, northeast),
        options: FitBoundsOptions(
            padding: EdgeInsets.only(left: 15.0, right: 15.0)));
    //_mapLatLngBounds = LatLngBounds(southwest, northeast);
  }

  Widget _getTaskTurnpointMarker(TaskTurnpoint taskTurnpoint) {
    return InkWell(
      onTap: () {
        _sendEvent(DisplayTaskTurnpointEvent(taskTurnpoint));
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
          width: 80.0,
          height: 40.0,
          point: turnpointLatLng,
          builder: (context) => _getTurnpointMarker(turnpoint),
          anchorPos: AnchorPos.align(AnchorAlign.top)));
    }
    _rebuildMarkerArray();
  }

  Widget _getTurnpointMarker(final Turnpoint turnpoint) {
    return InkWell(
      onTap: () {
        _displayTurnpointOverheadView(turnpoint);
      },
      child: ClipOval(
        child: Container(
            width: 24,
            height: 24,
            color: Colors.transparent,
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                SvgPicture.asset(
                  'assets/svg/ic_turnpoint_white_48dp.svg',
                  fit: BoxFit.scaleDown,
                  color:
                      TurnpointUtils.getColorForTurnpointIcon(turnpoint.style),
                ),
                Text(
                    turnpoint.title.length > 4
                        ? turnpoint.title.substring(0, 4)
                        : turnpoint.title,
                    style: Constants.textStyleBlackFontSize12,
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
                          style: Constants.textStyleBlackFontSize12,
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

  void _placeLocalForecastMarker(LatLngForecast latLngForecast) {
    _latLngMarkers.clear();
    var latLngMarker = Marker(
      width: 160.0,
      height: 160.0,
      point: latLngForecast.latLng,
      builder: (context) => _getLatLngForecastMarker(latLngForecast),
      anchorPos: AnchorPos.align(AnchorAlign.top),
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
    _taskMarkers.clear();
    if (taskDefined) {
      southwest = null;
    }
  }

  void updateForecastOverlay() {
    print('Using RaspForecastImageSet imageset to display map overlay');
    if (_firstLayoutComplete) {
      displayForecastNoAnimation();
    }
  }

  void displayForecastNoAnimation() {
    if (soaringForecastImageSet != null) {
      print(
          "forecast overlay: " + soaringForecastImageSet!.bodyImage!.imageUrl);
      var imageUrl = soaringForecastImageSet!.bodyImage!.imageUrl;
      var raspUrl = Constants.RASP_BASE_URL + imageUrl;
      var overlayImage = OverlayImage(
          bounds: _mapLatLngBounds,
          opacity: _forecastOverlayOpacity / 100,
          imageProvider: NetworkImage(raspUrl),
          gaplessPlayback: true);

      if (_overlayImages.length == 0) {
        _overlayImages.add(overlayImage);
      } else {
        _overlayImages[0] = overlayImage;
      }
      _forecastOverlayController.sink.add(null);
    }
  }

  _getLocalForecast(LatLng latLng) {
    widget.stopAnimation();
    _sendEvent(DisplayLocalForecastEvent(latLng));
  }

  void _sendEvent(RaspDataEvent event) {
    BlocProvider.of<RaspDataBloc>(context).add(event);
  }

  void updateMapLatLngCorner(LatLng latLng) {
    if (southwest == null) {
      southwest = latLng;
      swLat = latLng.latitude;
      swLong = latLng.longitude;

      neLat = latLng.latitude;
      neLong = latLng.longitude;
    }
    if (latLng.latitude < swLat) {
      swLat = latLng.latitude;
    }
    if (latLng.longitude < swLong) {
      swLong = latLng.longitude;
    }
    if (latLng.latitude > neLat) {
      neLat = latLng.latitude;
    }
    if (latLng.longitude > neLong) {
      neLong = latLng.longitude;
    }
  }

  void _rebuildMarkerArray() {
    _mapMarkers.clear();
    _mapMarkers.addAll(_turnpointMarkers);
    _mapMarkers.addAll(_soundingMarkers);
    _mapMarkers.addAll(_taskMarkers);
    _mapMarkers.addAll(_latLngMarkers);
  }

  // Currently only display max of 1, so if changes in future need to revisit logic
  void _removeLocalForecastMarker() {
    _latLngMarkers.clear();
    _rebuildMarkerArray();
    _sendEvent(RedisplayMarkersEvent());
  }

  void _displayTurnpointOverheadView(Turnpoint turnpoint) async {
    await Navigator.pushNamed(context, TurnpointView.routeName,
        arguments: TurnpointOverHeadArgs(turnpoint: turnpoint));
  }

  _updateMapPositon(MapPosition mapPosition, bool hasGesture) {
    LatLngBounds? latLngBounds = mapPosition.bounds;
    // print(
    //     "New bounds: : sw corner ${latLngBounds?.southWest?.latitude.toString()} "
    //     "/  ${latLngBounds?.southWest?.longitude.toString()}");
    // print(
    //     "New bounds: : ne corner ${latLngBounds!.northEast?.latitude.toString()} "
    //     "/  ${latLngBounds.northEast?.longitude.toString()}");
  }

  void _updateSuaDetails(SUA suaDetails) async {
    // print("Processing suaDetails");
    _suaPolygons.clear();

    suaDetails.features?.forEach((airspace) {
      Color? polygonColor = null;
      String? label = null;
      String? type = null;
      if (airspace.properties != null && airspace.properties!.type != null) {
        label = airspace.properties!.type!;
        for (var suaType in Constants.SUAColor.values) {
          if (suaType.suaClassType == airspace.properties!.type) {
            polygonColor = suaType.airspaceColor;
          }
        }
      }
      //print("SUA label: $label");
      _suaPolygons.add(Polygon(
          borderStrokeWidth: 2,
          points: airspace.geometry!.coordinates,
          label: label ?? "Unknown",
          isFilled: true,
          labelStyle: Constants.textStyleBlack87FontSize14,
          color: polygonColor ?? Color(0x400000F80),
          borderColor: (polygonColor ?? Color(0xFF0000F80)).withOpacity(1)));
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
                            style: Constants.textStyleBoldBlack87FontSize14),
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
                            style: Constants.textStyleBoldBlack87FontSize14),
                      ),
                    ),
                  ),
                ]),
          ),
        ));
  }

  showOverlayOpacitySlider() {
    setState(() {
      _forecastOverlaySliderIsVisible = !_forecastOverlaySliderIsVisible;
    });
  }

  void _startHideOpacityTimer() {
    _hideOpacityTimer = Timer(Duration(seconds: 4), () {
      setState(() {
        _forecastOverlaySliderIsVisible = false;
      });
    });
  }
}
