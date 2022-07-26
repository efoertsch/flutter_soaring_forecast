import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_event.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_state.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/LatLngForecast.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:latlong2/latlong.dart';

class ForecastMap extends StatefulWidget {
  late final Function stopAnimation;
  ForecastMap({Key? key, required Function stopAnimation}) : super(key: key);

  @override
  _ForecastMapState createState() => _ForecastMapState();
}

class _ForecastMapState extends State<ForecastMap>
    with AfterLayoutMixin<ForecastMap> {
  late final MapController _mapController;
  final _forecastOverlayController = StreamController<Null>.broadcast();

  bool _firstLayoutComplete = false;
  SoaringForecastImageSet? soaringForecastImageSet;
  List<Polyline> _taskTurnpointCourse = <Polyline>[];
  List<Marker> _mapMarkers = <Marker>[];
  List<Marker> _soundingMarkers = <Marker>[];
  List<Marker> _turnpointMarkerrs = <Marker>[];
  List<Marker> _taskMarkers = <Marker>[];

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

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _firstLayoutComplete = true;
    // print("First layout complete.");
    // print('Calling series of APIs');
    _sendEvent(InitialRaspRegionEvent());
    _mapController.onReady.then((value) => _sendEvent(MapReadyEvent()));
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
          current is RemoveLocalForecastState;
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
        final latLngForecast = state.latLngForecast;
        _latLngMarker = Marker(
          width: 160.0,
          height: 160.0,
          point: latLngForecast.latLng,
          builder: (context) => _getLatLngForecastMarker(latLngForecast),
          anchorPos: AnchorPos.align(AnchorAlign.top),
        );
        _mapMarkers.add(_latLngMarker!);
      }

      if (state is RemoveLocalForecastState) {
        if (_latLngMarker != null) {
          _mapMarkers.remove(_latLngMarker);
          _latLngMarker = null;
        }
      }

      return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            bounds: _mapLatLngBounds,
            boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(8.0)),
            allowPanning: true,
            onTap: (tapPosition, latlng) => print(latlng.toString()),
            onLongPress: (longPressPostion, latLng) =>
                _getLocalForecast(latLng),
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

  void _updateTaskTurnpoints(List<TaskTurnpoint> taskTurnpoints) {
    print('number of task turnpoints ${taskTurnpoints.length.toString()} ');
    clearTaskFromMap();
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
                _sendEvent(RemoveLocalForecastEvent());
              }),
        ),
        Icon(Icons.arrow_drop_down, color: Colors.white),
      ],
    );
  }

  void clearTaskFromMap() {
    _taskTurnpointCourse.clear();
    _taskMarkers.clear();
    southwest = null;
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
    _mapMarkers.addAll(_turnpointMarkerrs);
    _mapMarkers.addAll(_soundingMarkers);
    _mapMarkers.addAll(_taskMarkers);
  }
}
