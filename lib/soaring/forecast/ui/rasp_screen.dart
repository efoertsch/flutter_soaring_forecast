import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide BuildContext;
//import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_soaring_forecast/soaring/app/app_drawer.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/app/main.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_state.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/rasp_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/display_ticker.dart';
import 'package:latlong2/latlong.dart';

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
        SingleTickerProviderStateMixin,
        AfterLayoutMixin<RaspScreen>,
        WidgetsBindingObserver {
  late final MapController _mapController;
  var _overlayImages = <OverlayImage>[];
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _firstLayoutComplete = false;

// TODO internationalize literals
  String _pauseAnimationLabel = "Pause";
  String _loopAnimationLabel = "Loop";

  // Tell map when to
  final _forecastOverlayController = StreamController<Null>.broadcast();

// Start forecast display with animation running
  bool _startAnimation = false;
  int _currentImageIndex = 0;
  int _lastImageIndex = 0;

  SoaringForecastImageSet? soaringForecastImageSet;
  DisplayTimer? _displayTimer;
  Stream<int>? _overlayPositionCounter;
  StreamSubscription<int>? _tickerSubscription;

  //GoogleMapController? _mapController;
// Default values - NewEngland lat/lng of course!
  final LatLng _center = LatLng(43.1394043, -72.0759888);
  LatLngBounds _mapLatLngBounds = LatLngBounds(
      LatLng(41.2665329, -73.6473083), LatLng(45.0120811, -70.5046997));

  // Executed only when class created
  @override
  void initState() {
    super.initState();
    _firstLayoutComplete = false;
    _mapController = MapController();
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    stopAnimation();
    WidgetsBinding.instance!.removeObserver(this);
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
    BlocProvider.of<RaspDataBloc>(context).add(InitialRaspRegionEvent());
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
      body:
          BlocConsumer<RaspDataBloc, RaspDataState>(listener: (context, state) {
        if (state is RaspDataLoadErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text(state.error),
            ),
          );
        }
      }, builder: (context, state) {
        //print('In forecastLayout State: $state');
        // print('Top of screen widgets. State is $state');
        if (state is RaspInitialState || state is RaspDataLoadErrorState) {
          // print('returning CircularProgressIndicator');
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        // print('creating/updating main screen');
        return Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            getForecastModelsAndDates(context),
            getForecastTypes(context),
            displayForecastTime(context),
            forecastWindow(),
            emptyWidgetForForecastImages(),
          ]),
        );
      }),
    );
  }

  Widget getForecastModelsAndDates(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: forecastModelDropDownList(),
          //ForecastModelsWidget(),
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
      // print(
      //     "ForecastModelDropDownList bloc buildwhen previous state: $previous current: $current");
      return current is RaspInitialState || current is RaspForecastModels;
    }, builder: (context, state) {
      if (state is RaspInitialState || !(state is RaspForecastModels)) {
        return Text("Getting Forecast Models");
      }
      var raspForecastModels = state;
      // print(
      //     'Creating dropdown for models. Model is ${raspForecastModels.selectedModelName}');
      return DropdownButton<String>(
        style: CustomStyle.bold18(context),
        value: (raspForecastModels.selectedModelName),
        hint: Text('Select Model'),
        isExpanded: true,
        iconSize: 24,
        elevation: 16,
        onChanged: (String? newValue) {
          print('Selected model onChanged: $newValue');
          BlocProvider.of<RaspDataBloc>(context)
              .add(SelectedRaspModelEvent(newValue!));
        },
        items: raspForecastModels.modelNames
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value.toUpperCase()),
          );
        }).toList(),
      );
    });
  }

// Display forecast dates for selected model (eg. GFS)
  Widget forecastDatesDropDownList(BuildContext context) {
    return BlocBuilder<RaspDataBloc, RaspDataState>(
        buildWhen: (previous, current) {
      return current is RaspInitialState || current is RaspModelDates;
    }, builder: (context, state) {
      if (state is RaspInitialState || !(state is RaspModelDates)) {
        return Text("Getting Forecast Dates");
      }
      var raspForecastDates = state;
      // print(
      //     'Creating dropdown for dates. Initial date is ${raspForecastDates.selectedForecastDate}');
      return DropdownButton<String>(
        style: CustomStyle.bold18(context),
        isExpanded: true,
        value: raspForecastDates.selectedForecastDate,
        onChanged: (String? newValue) {
          BlocProvider.of<RaspDataBloc>(context)
              .add(SelectRaspForecastDateEvent(newValue!));
        },
        items: raspForecastDates.forecastDates
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      );
    });
  }

// Display description of forecast types (eq. 'Thermal Updraft Velocity (W*)' for wstar)
  Widget getForecastTypes(BuildContext context) {
    return BlocBuilder<RaspDataBloc, RaspDataState>(
        buildWhen: (previous, current) {
      return current is RaspInitialState || current is RaspForecasts;
    }, builder: (context, state) {
      if (state is RaspInitialState || !(state is RaspForecasts)) {
        return Text("Getting Forecasts");
      }
      return DropdownButton<String>(
        style: CustomStyle.bold18(context),
        isExpanded: true,
        value: state.selectedForecast.forecastNameDisplay,
        onChanged: (String? newValue) {
          var selectedForecast = state.forecasts.firstWhere(
              (forecast) => forecast.forecastNameDisplay == newValue);
          BlocProvider.of<RaspDataBloc>(context)
              .add(SelectedRaspForecastEvent(selectedForecast));
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
    });
  }

// Display forecast time for model and date
  Widget displayForecastTime(BuildContext context) {
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
                    BlocProvider.of<RaspDataBloc>(context)
                        .add(PreviousTimeEvent());
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
                if (state is RaspInitialState ||
                    !(state is RaspForecastImageSet)) {
                  return Text("Getting forecastTime");
                }
                var localTime = state.soaringForecastImageSet.localTime;
                localTime = localTime.startsWith("old ")
                    ? localTime.substring(4)
                    : localTime;
                return Text(
                  localTime + " (Local)",
                  style: CustomStyle.bold18(context),
                );
              }),
            ),
            Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    stopAnimation();
                    BlocProvider.of<RaspDataBloc>(context).add(NextTimeEvent());
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
                  _startAnimation = !_startAnimation;
                  _startStopImageAnimation();
                });
              },
              child: Text(
                (_startAnimation ? _pauseAnimationLabel : _loopAnimationLabel),
                textAlign: TextAlign.end,
                style: CustomStyle.bold18(context),
              ),
            )),
      ],
    );
  }

  Widget forecastWindow() {
    // return forecastMap();
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

  Widget forecastMap() {
    return FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          bounds: _mapLatLngBounds,
          boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(8.0)),
          allowPanning: true,
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
          )
        ]);
  }

  Widget forecastLegend() {
    return BlocBuilder<RaspDataBloc, RaspDataState>(
        buildWhen: (previous, current) {
      return current is RaspInitialState || current is RaspForecastImageSet;
    }, builder: (context, state) {
      if (state is RaspForecastImageSet) {
        return Image(
            image: NetworkImage(Constants.RASP_BASE_URL +
                state.soaringForecastImageSet.sideImage!.imageUrl));
      }
      return SizedBox.shrink();
    });
  }

  // Sole purpose of this widget is to handle the forecast overlay
  Widget emptyWidgetForForecastImages() {
    return BlocBuilder<RaspDataBloc, RaspDataState>(
        buildWhen: (previous, current) {
      return current is RaspInitialState || current is RaspForecastImageSet;
    }, builder: (context, state) {
      if (state is RaspForecastImageSet) {
        _currentImageIndex = state.displayIndex;
        _lastImageIndex = state.numberImages - 1;
        soaringForecastImageSet = state.soaringForecastImageSet;
        updateForecastOverlay();
      }
      return SizedBox.shrink();
    });
  }

  void _startStopImageAnimation() {
    //TODO timer and subscription to convoluted. Make simpler
    if (_startAnimation) {
      _displayTimer = DisplayTimer(Duration(seconds: 3));
      _overlayPositionCounter = _displayTimer!.stream;
      _tickerSubscription = _overlayPositionCounter!.listen((int counter) {
        BlocProvider.of<RaspDataBloc>(context).add(NextTimeEvent());
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
    updateMapOverlay(soaringForecastImageSet);
    print('Posting imageSet soaringForecastImageSet');
  }

  void updateMapOverlay(SoaringForecastImageSet? soaringForecastImageSet) {
    if (_firstLayoutComplete) {
      print(
          "forecast overlay: " + soaringForecastImageSet!.bodyImage!.imageUrl);
    }
    _overlayImages.clear();
    if (soaringForecastImageSet != null) {
      var imageUrl = soaringForecastImageSet.bodyImage!.imageUrl;
      var raspUrl = Constants.RASP_BASE_URL + imageUrl;
      _overlayImages.add(OverlayImage(
          bounds: _mapLatLngBounds,
          opacity: .5,
          imageProvider: NetworkImage(raspUrl),
          gaplessPlayback: true));
    }

    _forecastOverlayController.sink.add(null);
  }

  void stopAnimation() {
    if (_startAnimation) {
      _startAnimation = false;
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
          Navigator.pushNamed(context, TaskList.routeName);
        },
      ),
      RotatedBox(
        quarterTurns: 1,
        child: PopupMenuButton<String>(
          onSelected: handleClick,
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
      ),
    ];
  }

  void handleClick(String value) {
    switch (value) {
      case RaspMenu.clearTask:
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
}
