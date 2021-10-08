import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide BuildContext;
import 'package:flutter_soaring_forecast/soaring/app/app_drawer.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_state.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/rasp_selection_values.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image_set.dart';
import 'package:flutter_soaring_forecast/soaring/json/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/json/regions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'bloc/rasp_data_bloc.dart';
import 'bloc/rasp_data_event.dart';

class RaspScreen extends StatefulWidget {
  final BuildContext repositoryContext;
  RaspScreen({Key? key, required this.repositoryContext}) : super(key: key);

  @override
  _RaspScreenState createState() => _RaspScreenState();
}

//TODO - keep more data details in Bloc,
class _RaspScreenState extends State<RaspScreen>
    with SingleTickerProviderStateMixin, AfterLayoutMixin<RaspScreen> {
  late RaspDataBloc _raspDataBloc;
  late Region _region;
  late List<String> _modelNames;
  late String _selectedModelName;
  late List<String> _forecastDates;
  late String _selectedForecastDate;
  late List<String> _forecastTimes;
  int _selectedForecastTimeIndex = 0;
  late List<Forecast> _forecasts;
  late Forecast _selectedForecast;
  bool _firstLayoutComplete = false;
// TODO internationalize literals
  String _pauseAnimationLabel = "Pause";
  String _loopAnimationLabel = "Loop";

// Start forecast display with animation running
  bool _animationRunning = true;
  AnimationController? _forecastImageAnimationController;
  Animation<double>? _forecastImageAnimation;
  bool _runAnimation = true;
  List<SoaringForecastImageSet>? _soaringForecastImageSets;
  SoaringForecastImageSet? _soaringForecastImageSet;
  int lastImageIndex = 0;
  int controllerIndex = 0;

  GoogleMapController? _mapController;
// Default values - NewEngland lat/lng of course!
  final LatLng _center = const LatLng(43.1394043, -72.0759888);
  LatLngBounds _mapLatLngBounds = LatLngBounds(
      southwest: LatLng(41.2665329, -73.6473083),
      northeast: LatLng(45.0120811, -70.5046997));

  /// Make sure first layout occurs prior to map ready otherwise crash occurs
  @override
  void afterFirstLayout(BuildContext context) {
    _firstLayoutComplete = true;
    print(
        "First layout complete. mapcontroller is set ${_mapController != null}");
    if (_mapController != null) {
      _setMapLatLngBounds();
    }
  }

  /// This can cause crash if map ready prior to first layout
  /// so check first if screen ready
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    print(
        "Mapcontroller is defined. FirstLayoutComplete =  $_firstLayoutComplete");
    if (_firstLayoutComplete) {
      _setMapLatLngBounds();
    }
  }

// Executed only when class created
  @override
  void initState() {
    super.initState();
    _firstLayoutComplete = false;
    _raspDataBloc = BlocProvider.of<RaspDataBloc>(context);
    _raspDataBloc.add(GetInitialRaspSelections());
  }

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _forecastLayout() {
    return Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          getForecastModelsAndDates(),
          getForecastTypes(),
          displayForecastTimes(),
          displayGoogleMap()
        ]));
  }

  Expanded displayGoogleMap() {
    return Expanded(
        child: GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 11.0,
      ),
    ));
  }

  Widget getForecastModelsAndDates() {
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
              child: forecastDatesDropDownList(),
            )),
      ],
    );
  }

// Display GFS, NAM, ....
  Widget forecastModelDropDownList() {
    return DropdownButton<String>(
      value: (_selectedModelName),
      isExpanded: true,
      iconSize: 24,
      elevation: 16,
      onChanged: (String? newValue) {
        setState(() {
          _selectedModelName = newValue!;
          _raspDataBloc.add(SelectedRaspModel(_selectedModelName));
        });
      },
      items: _modelNames.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value.toUpperCase()),
        );
      }).toList(),
    );
  }

// Display forecast dates for selected model (eg. GFS)
  Widget forecastDatesDropDownList() {
    return DropdownButton<String>(
      isExpanded: true,
      value: _selectedForecastDate,
      onChanged: (String? newValue) {
        setState(() {
          _selectedForecastDate = newValue!;
          _raspDataBloc.add(SetRaspForecastDate(_selectedForecastDate));
        });
      },
      items: _forecastDates.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

// Display description of forecast types (eq. 'Thermal Updraft Velocity (W*)' for wstar)
  Widget getForecastTypes() {
    return DropdownButton<String>(
      isExpanded: true,
      value: _selectedForecast.forecastNameDisplay,
      onChanged: (String? newValue) {
        setState(() {
          _selectedForecast = _forecasts.firstWhere(
              (forecast) => forecast.forecastNameDisplay == newValue);
        });
      },
      items: _forecasts
          .map((forecast) => forecast.forecastNameDisplay)
          .toList()
          .map<DropdownMenuItem<String>>((String? value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value!),
        );
      }).toList(),
    );
  }

// Display forecast time for model and date
  Widget displayForecastTimes() {
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
                    setState(() {
                      if (--_selectedForecastTimeIndex < 0)
                        _selectedForecastTimeIndex = _forecastTimes.length - 1;
                    });
//                final snackBar = SnackBar(content: Text("Back"));
//                _scaffoldKey.currentState..showSnackBar(snackBar);
                  },
                  child: Text(
                    '<',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                        color: Colors.blueAccent),
                  ),
                )),
            Expanded(
              flex: 6,
              child: Text(
                _forecastTimes[_selectedForecastTimeIndex] + " (Local)",
                style: TextStyle(fontSize: 20),
              ),
            ),
            Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (++_selectedForecastTimeIndex >
                          _forecastTimes.length - 1)
                        _selectedForecastTimeIndex = 0;
                    });
//                final snackBar = SnackBar(content: Text("Forward"));
//                _scaffoldKey.currentState..showSnackBar(snackBar);
                  },
                  child: Text(
                    '>',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                        color: Colors.blueAccent),
                  ),
                )),
          ]),
        ),
        Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _animationRunning = !_animationRunning;
                });
              },
              child: Text(
                (_animationRunning
                    ? _pauseAnimationLabel
                    : _loopAnimationLabel),
                textAlign: TextAlign.end,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RaspDataBloc, RaspDataState>(
        listener: (context, state) {
      if (state is RaspSelectionsState) {
        RaspSelectionValues raspSelectionValues = state.raspSelectionValues;
        _assignRaspSelectionValues(raspSelectionValues);
      } else if (state is RaspMapLatLngBounds) {
        _mapLatLngBounds = state.regionLatLngBounds;
      } else if (state is RaspForecastImageSets) {
        _startRaspImageAnimation(state.soaringForecastImageSets);
      }
    }, child:
            BlocBuilder<RaspDataBloc, RaspDataState>(builder: (context, state) {
      if (state is InitialRaspDataState ||
          state is RaspDataLoadErrorState ||
          _modelNames == null ||
          _forecastDates == null ||
          _forecastTimes == null ||
          _forecasts == null ||
          _selectedForecast == null) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }

      return Scaffold(
          key: _scaffoldKey,
          drawer: AppDrawer.getDrawer(context),
          appBar: AppBar(
            title: Text('RASP'),
            actions: <Widget>[
              IconButton(icon: Icon(Icons.list), onPressed: null),
            ],
          ),
          body: _forecastLayout());
    }));
  }

  void _assignRaspSelectionValues(RaspSelectionValues raspSelectionValues) {
    if (raspSelectionValues.modelNames != null) {
      _modelNames = raspSelectionValues.modelNames!;
    }
    if (raspSelectionValues.selectedModelName != null) {
      _selectedModelName = raspSelectionValues.selectedModelName!;
    }
    if (raspSelectionValues.forecastDates != null) {
      _forecastDates = raspSelectionValues.forecastDates!;
    }
    if (raspSelectionValues.selectedForecastDate != null) {
      _selectedForecastDate = raspSelectionValues.selectedForecastDate!;
    }
    if (raspSelectionValues.forecastTimes != null) {
      _forecastTimes = raspSelectionValues.forecastTimes!;
    }
    _selectedForecastTimeIndex = raspSelectionValues.selectedForecastTimeIndex!;
    if (raspSelectionValues.forecasts != null) {
      _forecasts = raspSelectionValues.forecasts!;
    }
    if (raspSelectionValues.selectedForecast != null) {
      _selectedForecast = raspSelectionValues.selectedForecast!;
    }

    if (raspSelectionValues.latLngBounds != null) {
      _mapLatLngBounds = raspSelectionValues.latLngBounds!;
    }
  }

// TODO fix  Unhandled Exception: PlatformException(error
//  , Error using newLatLngBounds(LatLngBounds, int):
//  Map size can't be 0. Most likely, layout has not yet occurred for the map view.
//  Either wait until layout has occurred or use
//  newLatLngBounds(LatLngBounds, int, int, int) which allows you to specify
//  the map's dimensions., null)
  void _setMapLatLngBounds() {
    print("animating camera to lat/lng bounds");
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        _mapLatLngBounds,
        8,
      ),
    );
  }

  void _startRaspImageAnimation(
      List<SoaringForecastImageSet> soaringForecastImageSets) {
    this._soaringForecastImageSets = soaringForecastImageSets;
    if (_forecastImageAnimationController != null &&
        _forecastImageAnimationController!.isAnimating) {
      print("Already animating!");
      return;
    }
    print("Starting Image Animation");
    _forecastImageAnimationController = AnimationController(
        value: 0,
        duration: Duration(milliseconds: 15000),
        lowerBound: 0,
        upperBound: _forecastTimes.length.toDouble(),
        vsync: this);

    _forecastImageAnimation =
        Tween<double>(begin: 0, end: _forecastTimes.length.toDouble())
            .animate(_forecastImageAnimationController!);
    _forecastImageAnimationController!.addListener(() => _setMapRaspOverly());
    _forecastImageAnimationController!
        .repeat(period: Duration(milliseconds: 15000));
    // _forecastImageAnimationController.forward();
  }

  _setMapRaspOverly() {
    //print("Animation value: $_forecastImageAnimationController.value");
    controllerIndex = _forecastImageAnimationController!.value.toInt();
    if (controllerIndex != lastImageIndex &&
        controllerIndex < _soaringForecastImageSets!.length &&
        controllerIndex != lastImageIndex &&
        _forecastTimes[controllerIndex] ==
            _soaringForecastImageSets![controllerIndex].localTime) {
      lastImageIndex = controllerIndex;
      updateMapOverly(_soaringForecastImageSets![controllerIndex]);
      print("Posting imageSet[$controllerIndex]");
    }
  }

  void updateMapOverly(SoaringForecastImageSet soaringForecastImageSet) {
    if (_mapController != null && _firstLayoutComplete) {
      print("forecast overlay: " + soaringForecastImageSet.bodyImage!.imageUrl);
    }
  }
}
