import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide BuildContext;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/app/app_drawer.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/app/main.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_state.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/LatLngForecast.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/rasp_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/display_ticker.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/ui/task_list.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_overhead_view.dart';
import 'package:latlong2/latlong.dart';

import '../../floor/taskturnpoint/task_turnpoint.dart';
import '../bloc/rasp_data_bloc.dart';
import '../bloc/rasp_data_event.dart';

class RaspScreen extends StatefulWidget {
  final BuildContext repositoryContext;

  RaspScreen({Key? key, required this.repositoryContext}) : super(key: key);

  @override
  _RaspScreenState createState() => _RaspScreenState();
}

//TODO - keep more data details in Bloc,
class _RaspScreenState extends State<RaspScreen>
    with
        TickerProviderStateMixin,
        AfterLayoutMixin<RaspScreen>,
        WidgetsBindingObserver {
  late final MapController _mapController;
  var _overlayImages = <OverlayImage>[];
  var _taskTurnpointsLatLng = <LatLng>[];
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _firstLayoutComplete = false;

// TODO internationalize literals
  String _pauseAnimationLabel = "Pause";
  String _loopAnimationLabel = "Loop";

  // Tell map when to
  final _forecastOverlayController = StreamController<Null>.broadcast();

// Start forecast display with animation running
  bool _startImageAnimation = false;
  int _currentImageIndex = 0;
  int _lastImageIndex = 0;

  SoaringForecastImageSet? soaringForecastImageSet;
  DisplayTimer? _displayTimer;

  Stream<int>? _overlayPositionCounter;
  StreamSubscription<int>? _tickerSubscription;

  Animation<double>? _opacityAnimation;
  AnimationController? _mapOpacityController;

  List<Polyline> _taskTurnpointCourse = <Polyline>[];
  List<Marker> _mapMarkers = <Marker>[];
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

  // Executed only when class created
  @override
  void initState() {
    super.initState();
    _firstLayoutComplete = false;
    _mapController = MapController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    stopAnimation();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print("app in resumed");
        break;
      case AppLifecycleState.inactive:
        print("app in inactive");
        stopAnimation();
        break;
      case AppLifecycleState.paused:
        print("app in paused");
        stopAnimation();
        break;
      case AppLifecycleState.detached:
        print("app in detached");
        break;
    }
  }

  // Make sure first layout occurs prior to map ready otherwise crash occurs
  @override
  void afterFirstLayout(BuildContext context) {
    _firstLayoutComplete = true;
    // print("First layout complete.");
    // print('Calling series of APIs');
    fireEvent(context, InitialRaspRegionEvent());
    _mapController.onReady.then((value) => fireEvent(context, MapReadyEvent()));
    _setMapLatLngBounds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawer.getDrawer(context),
        appBar: AppBar(
          title: Text('RASP'),
          actions: getRaspMenu(),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
              getForecastModelsAndDates(context),
              getForecastTypes(context),
              displayForecastTime(context),
              forecastWindow(),
              //emptyWidgetForForecastImages(),
              widgetForSnackBarMessages(),
              //displayMarkersAndLines(),
            ]),
          ),
        )
        // }),
        );
  }

  Widget getForecastModelsAndDates(BuildContext context) {
    print('creating/updating main ForecastModelsAndDates');
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: forecastModelDropDownList(),
        ),
        Expanded(
            flex: 7,
            child: Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: forecastDatesDropDownList(context),
            )),
      ],
    );
  }

// Display GFS, NAM, ....
  Widget forecastModelDropDownList() {
    return BlocBuilder<RaspDataBloc, RaspDataState>(
        buildWhen: (previous, current) {
      return current is RaspInitialState || current is RaspForecastModels;
    }, builder: (context, state) {
      print('creating/updating forecastModelDropDown');
      if (state is RaspForecastModels) {
        return DropdownButton<String>(
          style: CustomStyle.bold18(context),
          value: (state.selectedModelName),
          hint: Text('Select Model'),
          isExpanded: true,
          iconSize: 24,
          elevation: 16,
          onChanged: (String? newValue) {
            print('Selected model onChanged: $newValue');
            fireEvent(context, SelectedRaspModelEvent(newValue!));
          },
          items: state.modelNames.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value.toUpperCase()),
            );
          }).toList(),
        );
      } else {
        return Text("Getting Forecast Models");
      }
    });
  }

// Display forecast dates for selected model (eg. GFS)
  Widget forecastDatesDropDownList(BuildContext context) {
    return BlocBuilder<RaspDataBloc, RaspDataState>(
        buildWhen: (previous, current) {
      return current is RaspInitialState || current is RaspModelDates;
    }, builder: (context, state) {
      print('creating/updating forecastDatesDropDown');
      if (state is RaspModelDates) {
        return DropdownButton<String>(
          style: CustomStyle.bold18(context),
          isExpanded: true,
          value: state.selectedForecastDate,
          onChanged: (String? newValue) {
            fireEvent(context, SelectRaspForecastDateEvent(newValue!));
          },
          items:
              state.forecastDates.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        );
      } else {
        return Text("Getting Forecast Dates");
      }
    });
  }

// Display description of forecast types (eq. 'Thermal Updraft Velocity (W*)' for wstar)
  Widget getForecastTypes(BuildContext context) {
    return BlocBuilder<RaspDataBloc, RaspDataState>(
        buildWhen: (previous, current) {
      return current is RaspInitialState || current is RaspForecasts;
    }, builder: (context, state) {
      print('creating/updating ForecastTypes');
      if (state is RaspForecasts) {
        return DropdownButton<String>(
          style: CustomStyle.bold18(context),
          isExpanded: true,
          value: state.selectedForecast.forecastNameDisplay,
          onChanged: (String? newValue) {
            var selectedForecast = state.forecasts.firstWhere(
                (forecast) => forecast.forecastNameDisplay == newValue);
            fireEvent(context, SelectedRaspForecastEvent(selectedForecast));
          },
          items: state.forecasts
              .map((forecast) => forecast.forecastNameDisplay)
              .toList()
              .map<DropdownMenuItem<String>>((String? value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value!),
            );
          }).toList(),
        );
      } else {
        return Text("Getting Forecasts");
      }
    });
  }

// Display forecast time for model and date
  Widget displayForecastTime(BuildContext context) {
    print('creating/updating ForecastTime');
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(' '),
        ),
        Expanded(
          flex: 5,
          child: Row(children: [
            Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    stopAnimation();
                    fireEvent(context, PreviousTimeEvent());
                  },
                  child: IncrDecrIconWidget.getIncIconWidget('<'),
                )),
            Expanded(
              flex: 6,
              child: BlocBuilder<RaspDataBloc, RaspDataState>(
                  buildWhen: (previous, current) {
                return current is RaspInitialState ||
                    current is RaspForecastImageSet;
              }, builder: (context, state) {
                print('creating/updating ForecastTime value');
                if (state is RaspForecastImageSet) {
                  var localTime = state.soaringForecastImageSet.localTime;
                  localTime = localTime.startsWith("old ")
                      ? localTime.substring(4)
                      : localTime;
                  return Text(
                    localTime + " (Local)",
                    style: CustomStyle.bold18(context),
                  );
                } else {
                  return Text("Getting forecastTime");
                }
              }),
            ),
            Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    stopAnimation();
                    fireEvent(context, NextTimeEvent());
                  },
                  child: IncrDecrIconWidget.getIncIconWidget('>'),
                )),
          ]),
        ),
        Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _startImageAnimation = !_startImageAnimation;
                  _startStopImageAnimation();
                });
              },
              child: Text(
                (_startImageAnimation
                    ? _pauseAnimationLabel
                    : _loopAnimationLabel),
                textAlign: TextAlign.end,
                style: CustomStyle.bold18(context),
              ),
            )),
      ],
    );
  }

  void fireEvent(BuildContext context, RaspDataEvent event) {
    BlocProvider.of<RaspDataBloc>(context).add(event);
  }

  Widget forecastWindow() {
    // return forecastMap();
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
        _currentImageIndex = state.displayIndex;
        _lastImageIndex = state.numberImages - 1;
        soaringForecastImageSet = state.soaringForecastImageSet;
        updateForecastOverlay();
      }
      if (state is RaspTaskTurnpoints) {
        List<TaskTurnpoint> taskTurnpoints = state.taskTurnpoints;
        print('number of task turnpoints ${taskTurnpoints.length.toString()} ');
        clearTaskFromMap();
        List<LatLng> points = <LatLng>[];
        for (var taskTurnpoint in taskTurnpoints) {
          print('adding taskturnpoint: ${taskTurnpoint.title}');
          var turnpointLatLng =
              LatLng(taskTurnpoint.latitudeDeg, taskTurnpoint.longitudeDeg);
          points.add(turnpointLatLng);
          _mapMarkers.add(Marker(
              width: 80.0,
              height: 40.0,
              point: turnpointLatLng,
              builder: (context) => _getTaskTurnpointMarker(taskTurnpoint),
              anchorPos: AnchorPos.align(AnchorAlign.top)));
          updateMapLatLngCorner(turnpointLatLng);
        }
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

  // Sole purpose of this widget is to handle the forecast overlay
  // Widget emptyWidgetForForecastImages() {
  //   return BlocBuilder<RaspDataBloc, RaspDataState>(
  //       buildWhen: (previous, current) {
  //     return current is RaspInitialState || current is RaspForecastImageSet;
  //   }, builder: (context, state) {
  //     print('creating/updating ForecastImages');
  //     if (state is RaspForecastImageSet) {
  //       _currentImageIndex = state.displayIndex;
  //       _lastImageIndex = state.numberImages - 1;
  //       soaringForecastImageSet = state.soaringForecastImageSet;
  //       updateForecastOverlay();
  //     }
  //     return SizedBox.shrink();
  //   });
  // }

  Widget widgetForSnackBarMessages() {
    return BlocConsumer<RaspDataBloc, RaspDataState>(
        listener: (context, state) {
      if (state is RaspDataLoadErrorState) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(state.error),
          ),
        );
      }
      if (state is TurnpointFoundState) {
        displayTurnpointView(context, state);
      }
    }, builder: (context, state) {
      if (state is RaspDataLoadErrorState) {
        return SizedBox.shrink();
      } else {
        return SizedBox.shrink();
      }
    });
  }

  // Create any markers and task lines
  // Widget displayMarkersAndLines() {
  //   return BlocBuilder<RaspDataBloc, RaspDataState>(
  //       buildWhen: (previous, current) {
  //     return current is RaspInitialState ||
  //         current is RaspTaskTurnpoints ||
  //         current is LatLngForecastState;
  //   }, builder: (context, state) {
  //     if (state is RaspTaskTurnpoints) {
  //       List<TaskTurnpoint> taskTurnpoints = state.taskTurnpoints;
  //       print('number of task turnpoints ${taskTurnpoints.length.toString()} ');
  //       clearTaskFromMap();
  //       List<LatLng> points = <LatLng>[];
  //       for (var taskTurnpoint in taskTurnpoints) {
  //         print('adding taskturnpoint: ${taskTurnpoint.title}');
  //         var turnpointLatLng =
  //             LatLng(taskTurnpoint.latitudeDeg, taskTurnpoint.longitudeDeg);
  //         points.add(turnpointLatLng);
  //         _mapMarkers.add(Marker(
  //             width: 80.0,
  //             height: 40.0,
  //             point: turnpointLatLng,
  //             builder: (context) => _getTaskTurnpointMarker(taskTurnpoint),
  //             anchorPos: AnchorPos.align(AnchorAlign.top)));
  //         updateMapLatLngCorner(turnpointLatLng);
  //       }
  //       _taskTurnpointCourse.add(Polyline(
  //         points: points,
  //         strokeWidth: 2.0,
  //         color: Colors.red,
  //       ));
  //       LatLng southwest = new LatLng(swLat, swLong);
  //       LatLng northeast = new LatLng(neLat, neLong);
  //       _mapController.fitBounds(LatLngBounds(southwest, northeast),
  //           options: FitBoundsOptions(
  //               padding: EdgeInsets.only(left: 15.0, right: 15.0)));
  //       //_mapLatLngBounds = LatLngBounds(southwest, northeast);
  //
  //     }
  //     if (state is LatLngForecastState) {
  //       final latLngForecast = state.latLngForecast;
  //       _mapMarkers.add(Marker(
  //           width: 160.0,
  //           height: 160.0,
  //           point: latLngForecast.latLng,
  //           builder: (context) => _getLatLngForecastMarker(latLngForecast),
  //           anchorPos: AnchorPos.align(AnchorAlign.top)));
  //     }
  //     _forecastOverlayController.sink.add(null);
  //     return SizedBox.shrink();
  //   });
  // }

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
    _mapMarkers.clear();
    southwest = null;
  }

  void _startStopImageAnimation() {
    //TODO timer and subscription to convoluted. Make simpler
    if (_startImageAnimation) {
      _displayTimer = DisplayTimer(Duration(seconds: 3));
      _overlayPositionCounter = _displayTimer!.stream;
      _tickerSubscription = _overlayPositionCounter!.listen((int counter) {
        fireEvent(context, NextTimeEvent());
      });
      _displayTimer!.setStartAndLimit(_currentImageIndex, _lastImageIndex);
      _displayTimer!.startTimer();
      print('Started timer');
    } else {
      print('Stopping timer');
      if (_tickerSubscription != null) {
        _tickerSubscription!.cancel();
        _displayTimer!.cancelTimer();
        _displayTimer = null;
      }
      print('Stopped timer');
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

  void _startMapOpacityAnimation(final String raspUrl) {
    _mapOpacityController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500))
          ..addListener(() {
            //OverlayImages values are final so need to recreate each time.
            OverlayImage newOverlayImage;
            OverlayImage? oldOverlayImage;
            print("_opacityAnimation!.value = ${_opacityAnimation!.value}");
            var newImageOpacity = .5 * (_opacityAnimation!.value / 500);
            // first image is always the new one so fade it in
            newOverlayImage = OverlayImage(
                bounds: _mapLatLngBounds,
                opacity: (newImageOpacity),
                imageProvider: NetworkImage(raspUrl),
                gaplessPlayback: true);
            print("New image  opacity: ${newImageOpacity}");

            var oldImageOpacity = .5 * ((500 - _opacityAnimation!.value) / 500);
            if (_overlayImages.length > 1) {
              //if exists this is old image so fade it out
              oldOverlayImage = _overlayImages[1];
              OverlayImage(
                  bounds: _mapLatLngBounds,
                  opacity: (oldImageOpacity),
                  imageProvider: oldOverlayImage.imageProvider,
                  gaplessPlayback: true);
              print("Old image  opacity: ${oldImageOpacity}");
            }
            if (_overlayImages.length == 0) {
              _overlayImages.add(newOverlayImage);
            } else {
              _overlayImages.insert(0, newOverlayImage);
            }
            if (_overlayImages.length == 2 && oldOverlayImage != null) {
              _overlayImages.insert(1, oldOverlayImage);
            }
            if (_overlayImages.length > 2) {
              _overlayImages.removeAt(2);
            }
            _forecastOverlayController.sink.add(null);
          });
    _opacityAnimation =
        Tween<double>(begin: 0, end: 500).animate(_mapOpacityController!);
    _mapOpacityController!.forward();
  }

  void stopAnimation() {
    if (_startImageAnimation) {
      _startImageAnimation = false;
      _startStopImageAnimation();
    }
  }

// TODO fix  Unhandled Exception: PlatformException(error
//  , Error using newLatLngBounds(LatLngBounds, int):
//  Map size can't be 0. Most likely, layout has not yet occurred for the map view.
//  Either wait until layout has occurred or use
//  newLatLngBounds(LatLngBounds, int, int, int) which allows you to specify
//  the map's dimensions., null)
  void _setMapLatLngBounds() {
    // print("animating camera to lat/lng bounds");
    // _mapController!.animateCamera(
    //   CameraUpdate.newLatLngBounds(
    //     _mapLatLngBounds,
    //     8,
    //   ),
    // );
    //_animatedMapMove()
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Create some tweens. These serve to split up the transition from one location to another.
    // In our case, we want to split the transition be<tween> our current map center and the destination.
    final _latTween = Tween<double>(
        begin: _mapController.center.latitude, end: destLocation.latitude);
    final _lngTween = Tween<double>(
        begin: _mapController.center.longitude, end: destLocation.longitude);
    final _zoomTween = Tween<double>(begin: _mapController.zoom, end: destZoom);

    // Create a animation controller that has a duration and a TickerProvider.
    var controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    // The animation determines what path the animation will take. You can try different Curves values, although I found
    // fastOutSlowIn to be my favorite.
    Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
          LatLng(_latTween.evaluate(animation), _lngTween.evaluate(animation)),
          _zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  List<Widget> getRaspMenu() {
    return <Widget>[
      TextButton(
        child: const Text('SELECT TASK', style: TextStyle(color: Colors.white)),
        onPressed: () {
          _selectTask();
        },
      ),
      PopupMenuButton<String>(
        onSelected: handleClick,
        icon: Icon(Icons.more_vert),
        itemBuilder: (BuildContext context) {
          return {
            RaspMenu.clearTask,
            RaspMenu.displayOptions,
            RaspMenu.mapBackground,
            RaspMenu.orderForecasts,
            RaspMenu.opacity,
            RaspMenu.selectRegion
          }.map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
      ),
    ];
  }

  _selectTask() async {
    final result = await Navigator.pushNamed(context, TaskList.routeName,
        arguments: TaskListScreen.SELECT_TASK_OPTION);
    if (result != null && result is int && result > -1) {
      print('Draw task for ' + result.toString());
      fireEvent(context, GetTaskTurnpointsEvent(result));
    }
  }

  void handleClick(String value) {
    switch (value) {
      case RaspMenu.clearTask:
        fireEvent(context, ClearTaskEvent());
        break;
      case RaspMenu.displayOptions:
        break;
      case RaspMenu.mapBackground:
        break;
      case RaspMenu.orderForecasts:
        break;
      case RaspMenu.opacity:
        break;
      case RaspMenu.selectRegion:
        break;
    }
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

  void displayTurnpointView(
      BuildContext context, TurnpointFoundState state) async {
    final result = await Navigator.pushNamed(
      context,
      TurnpointView.routeName,
      arguments: TurnpointOverHeadArgs(turnpoint: state.turnpoint),
    );
  }

  void _sendEvent(RaspDataEvent event) {
    BlocProvider.of<RaspDataBloc>(context).add(event);
  }

  _getLocalForecast(LatLng latLng) {
    _startImageAnimation = false;
    _startStopImageAnimation();
    _sendEvent(DisplayLocalForecastEvent(latLng));
  }
}
