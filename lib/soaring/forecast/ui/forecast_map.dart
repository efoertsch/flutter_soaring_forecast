import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/main.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_event.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_state.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/LatLngForecast.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_overhead_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

class ForecastMap extends StatefulWidget {
  final Function stopAnimation;
  final StreamController<PreferenceOption> displayOptionsController;

  ForecastMap(
      {Key? key,
      required Function this.stopAnimation,
      required StreamController<PreferenceOption>
          this.displayOptionsController})
      : super(key: key);

  @override
  _ForecastMapState createState() => _ForecastMapState();
}

class _ForecastMapState extends State<ForecastMap>
    with AfterLayoutMixin<ForecastMap> {
  late final MapController _mapController;
  final _forecastOverlayController = StreamController<Null>.broadcast();
  late final StreamSubscription _mapControllerStream;

  bool _firstLayoutComplete = false;
  SoaringForecastImageSet? soaringForecastImageSet;
  List<Polyline> _taskTurnpointCourse = <Polyline>[];
  List<Marker> _mapMarkers = <Marker>[];
  List<Marker> _soundingMarkers = <Marker>[];
  List<Marker> _turnpointMarkers = <Marker>[];
  final _taskMarkers = <Marker>[];
  List<Polyline> _suaPolyLines = <Polyline>[];

  Marker? _latLngMarker;

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

  bool _displaySoundings = false;
  bool _displaySua = false;
  bool _displayTurnpoints = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    widget.displayOptionsController.stream
        .listen((displayOption) => _processDisplayOption(displayOption));
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
    _firstLayoutComplete = true;
    // print("First layout complete.");
    // print('Calling series of APIs');
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
    print('creating/updating forecastWindow window');
    return Expanded(
      child: Stack(children: [
        Container(
          alignment: Alignment.center,
          child: forecastMap(),
        ),
        Container(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: .15,
            child: InteractiveViewer(
              child: forecastLegend(),
              panEnabled: true,
              maxScale: 4.0,
            ),
          ),
        ),
      ]),
    );
  }

  Widget forecastLegend() {
    return BlocBuilder<RaspDataBloc, RaspDataState>(
        buildWhen: (previous, current) {
      return current is RaspInitialState || current is RaspForecastImageSet;
    }, builder: (context, state) {
      print('creating/updating forecastLegend');
      if (state is RaspForecastImageSet) {
        return Image(
          image: NetworkImage(Constants.RASP_BASE_URL +
              state.soaringForecastImageSet.sideImage!.imageUrl),
          gaplessPlayback: true,
        );
      }
      return SizedBox.shrink();
    });
  }

  Widget forecastMap() {
    return BlocBuilder<RaspDataBloc, RaspDataState>(
        buildWhen: (previous, current) {
      return current is RaspInitialState ||
          current is RaspForecastImageSet ||
          current is RaspTaskTurnpoints ||
          current is LocalForecastState ||
          // current is RemoveLocalForecastState ||
          current is RaspSoundingsState ||
          current is TurnpointsInBoundsState;
    }, builder: (context, state) {
      print('creating/updating ForecastImages');
      if (state is RaspForecastImageSet) {
        soaringForecastImageSet = state.soaringForecastImageSet;
        updateForecastOverlay();
      }
      if (state is RaspTaskTurnpoints) {
        _updateTaskTurnpoints(state.taskTurnpoints);
      }
      if (state is LocalForecastState) {
        _placeLocalForecastMarker(state.latLngForecast);
      }
      if (state is RaspSoundingsState) {
        _placeSoundingMarkers(state.soundings);
      }
      if (state is TurnpointsInBoundsState) {
        _updateTurnpointMarkers(state.turnpoints);
      }

      // if (state is DisplayTurnpointsState) {
      //
      // }

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
              attributionBuilder: (_) {
                return Text("© OpenStreetMap contributors");
              },
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
            )
          ]);
    });
  }

  void _placeLocalForecastMarker(LatLngForecast latLngForecast) {
    _latLngMarker = Marker(
      width: 160.0,
      height: 160.0,
      point: latLngForecast.latLng,
      builder: (context) => _getLatLngForecastMarker(latLngForecast),
      anchorPos: AnchorPos.align(AnchorAlign.top),
    );
    _mapMarkers.add(_latLngMarker!);
  }

  void _updateTaskTurnpoints(List<TaskTurnpoint> taskTurnpoints) {
    print('number of task turnpoints ${taskTurnpoints.length.toString()} ');
    clearTaskFromMap(taskTurnpoints.length > 0);
    if (taskTurnpoints.length == 0) return;
    List<LatLng> points = <LatLng>[];
    for (var taskTurnpoint in taskTurnpoints) {
      print('adding taskturnpoint: ${taskTurnpoint.title}');
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

  void _updateTurnpointMarkers(List<Turnpoint> turnpoints) {
    print('number of turnpoints ${turnpoints.length.toString()} ');
    _turnpointMarkers.clear();
    List<LatLng> points = <LatLng>[];
    for (var turnpoint in turnpoints) {
      print('adding turnpoint: ${turnpoint.title}');
      var turnpointLatLng =
          LatLng(turnpoint.latitudeDeg, turnpoint.longitudeDeg);
      points.add(turnpointLatLng);
      _taskMarkers.add(Marker(
          width: 80.0,
          height: 40.0,
          point: turnpointLatLng,
          builder: (context) => _getTurnpointMarker(turnpoint),
          anchorPos: AnchorPos.align(AnchorAlign.top)));
    }
    _rebuildMarkerArray();
  }

  Widget _getSoundingMarker(Turnpoint turnpoint) {
    return InkWell(
      onTap: () {
        // display sounding and allow stepping through time
        print("Implement soundngs logic");
      },
      child: Container(
          color: Colors.white,
          width: 30,
          height: 30,
          child: Stack(
            children: [
              Positioned.fill(child: Image.asset('assets/svg/skew_t.png')),
              Positioned.fill(
                child: Text(
                    turnpoint.title.length > 4
                        ? turnpoint.title.substring(0, 4)
                        : turnpoint.title,
                    textAlign: TextAlign.center),
              ),
            ],
          )),
    );
  }

  Widget _getTurnpointMarker(Turnpoint turnpoint) {
    return InkWell(
      onTap: () {
        _displayTurnpointOverheadView(turnpoint);
      },
      child: Container(
          width: 30,
          height: 30,
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                  child:
                      SvgPicture.asset('assets/svg/ic_turnpoint_red_48dp.svg')),
              Positioned.fill(
                child: Text(
                    style: textStyleWhiteFontSize12,
                    turnpoint.title.length > 4
                        ? turnpoint.title.substring(0, 4)
                        : turnpoint.title,
                    textAlign: TextAlign.center),
              ),
            ],
          )),
    );
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
    print('Posting imageSet soaringForecastImageSet');
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
          opacity: (.5),
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
    if (_latLngMarker != null) {
      _mapMarkers.add(_latLngMarker!);
    }
  }

  // this is only used to *remove* particular types of markers
  // states will be processed to *add* markers to map
  _processDisplayOption(PreferenceOption displayOption) {
    switch (displayOption.key) {
      case RaspDisplayOptionsMenu.soundings:
        _soundingMarkers.clear();
        _rebuildMarkerArray();
        break;
      case RaspDisplayOptionsMenu.sua:
        _suaPolyLines.clear();
        break;
      case RaspDisplayOptionsMenu.turnpoints:
        _turnpointMarkers.clear();
        _rebuildMarkerArray();
        break;
    }
    setState(() {});
  }

  // Currently only display max of 1, so if changes in future need to revisit logic
  void _removeLocalForecastMarker() {
    if (_latLngMarker != null) {
      _latLngMarker = null;
      _rebuildMarkerArray();
    }
    _sendEvent(RedisplayMarkersEvent());
  }

  void _displayTurnpointOverheadView(Turnpoint turnpoint) async {
    await Navigator.pushNamed(context, TurnpointView.routeName,
        arguments: TurnpointOverHeadArgs(turnpoint: turnpoint));
  }

  _updateMapPositon(MapPosition mapPosition, bool hasGesture) {
    LatLngBounds? latLngBounds = mapPosition.bounds;
    print(
        "New bounds: : sw corner ${latLngBounds?.southWest?.latitude.toString()} "
        "/  ${latLngBounds?.southWest?.longitude.toString()}");
    print(
        "New bounds: : ne corner ${latLngBounds!.northEast?.latitude.toString()} "
        "/  ${latLngBounds.northEast?.longitude.toString()}");
  }

  void _placeSoundingMarkers(List<Soundings> soundings) {}
}
