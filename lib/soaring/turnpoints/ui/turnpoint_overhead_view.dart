import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:flutter_soaring_forecast/soaring/app/web_mixin.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoint_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bloc/turnpoint_bloc.dart';
import '../bloc/turnpoint_event.dart';
import '../bloc/turnpoint_state.dart';

class TurnpointOverHeadArgs {
  Turnpoint turnpoint;
  bool isReadOnly;
  bool isDecimalDegreesFormat;

  TurnpointOverHeadArgs(
      {required this.turnpoint,
      this.isReadOnly = true,
      this.isDecimalDegreesFormat = true});
}

class TurnpointOverheadView extends StatefulWidget {
  final TurnpointOverHeadArgs turnpointOverHeadArgs;

  TurnpointOverheadView({required this.turnpointOverHeadArgs}) : super();

  @override
  _TurnpointOverheadViewState createState() => _TurnpointOverheadViewState();
}

//TODO - keep more data details in Bloc,
class _TurnpointOverheadViewState extends State<TurnpointOverheadView>
    with AfterLayoutMixin<TurnpointOverheadView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _firstLayoutComplete = false;
  GoogleMapController? _mapController;
  bool _isDecimalDegreesFormat = true;
  bool _isReadOnly = false;
  bool _draggable = false;
  late Marker _marker;
  bool _displaySaveResetButtons = false;
  bool _displaySaveButton = true;
  late final Turnpoint turnpoint;
  late final Turnpoint originalTurnpoint;
  Key? _mapKey;

  GoogleMap? _googleMapWidget;

  @override
  initState() {
    originalTurnpoint = widget.turnpointOverHeadArgs.turnpoint;
    turnpoint = originalTurnpoint.clone();
    _mapKey = ObjectKey("");
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

// Make sure first layout occurs prior to map ready otherwise crash occurs
  @override
  void afterFirstLayout(BuildContext context) {
    if (turnpoint.latitudeDeg == 0 || turnpoint.longitudeDeg == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkForLocationPermission();
      });
      setState(() {
        _firstLayoutComplete = true;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }

  @override
  Widget _buildScaffold(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: widget.turnpointOverHeadArgs.isReadOnly
              ? Text(TurnpointEditText.viewTurnpoint)
              : Text(TurnpointEditText.editTurnpoint),
          leading: CommonWidgets.backArrowToHomeScreen(),
          actions: _getMenu(),
        ),
        body: getBodyWidget(),
      ),
    );
  }

  Widget getBodyWidget() {
    return BlocListener<TurnpointBloc, TurnpointState>(
      listener: (context, state) {
        if (state is TurnpointsInitialState) {}
        if (state is CurrentLocationState) {
          turnpoint.latitudeDeg = state.latitude;
          turnpoint.longitudeDeg = state.longitude;
          if (originalTurnpoint.latitudeDeg == 0) {
            originalTurnpoint.latitudeDeg = state.latitude;
            originalTurnpoint.longitudeDeg = state.longitude;
            originalTurnpoint.elevation =
                TurnpointUtils.convertMetersToFeet(state.altitude)
                        .toStringAsFixed(1) +
                    Constants.ft;
          }
          print("lat/long ${turnpoint.latitudeDeg} ${turnpoint.longitudeDeg}");
          if (state.altitude == 0) {
            findElevationAtLatLong();
          }
        }
        if (state is LatLongElevationState) {
          turnpoint.elevation = state.elevation.toStringAsFixed(1) + "ft";
          print("elevation is: ${turnpoint.elevation}");
        }
        _mapKey = ObjectKey(state);
        _getTurnpointMarker();
        _animateCameraToNewPosition();
        delaySetState(200);
      },
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            _getTurnpointInfoWidget(),
            _googleMap(),
            _getButtons(),
          ],
        ),
      ),
    );
  }

  void _animateCameraToNewPosition() {
    Future.delayed(Duration(milliseconds: 60), () {
      var newPosition = CameraPosition(
          target: LatLng(
            turnpoint.latitudeDeg,
            turnpoint.longitudeDeg,
          ),
          zoom: 14);
      CameraUpdate update = CameraUpdate.newCameraPosition(newPosition);
      _mapController!.moveCamera(update);
    });
  }

  Widget _getTurnpointInfoWidget() {
    // putting swipe here as can't get 'right swipe to go back' to work if swiping
    // over google map
    if (Platform.isIOS) {
      //iOS
      return GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onHorizontalDragUpdate: (details) {
          if (details.delta.direction >= 0) {
            Navigator.of(context).pop();
          }
        },
        child: _getTurnpointInfoTextWidget(),
      );
    }
    return _getTurnpointInfoTextWidget();
  }

  Text _getTurnpointInfoTextWidget() {
    return Text(
        TurnpointUtils.getFormattedTurnpointDetails(
            turnpoint, _isDecimalDegreesFormat),
        key: _mapKey);
  }

  Widget _googleMap() {
    _googleMapWidget = GoogleMap(
      myLocationButtonEnabled: true,
      onMapCreated: _onMapCreated,
      mapType: MapType.satellite,
      initialCameraPosition: CameraPosition(
        target: LatLng(turnpoint.latitudeDeg, turnpoint.longitudeDeg),
        zoom: 14.0,
      ),
      markers: Set<Marker>.of({_getTurnpointMarker()}),
    );
    return Expanded(child: _googleMapWidget!);
  }

  Widget _getButtons() {
    return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      _saveButton(),
      _saveResetButtons(),
    ]);
  }

  Widget _saveButton() {
    return Visibility(
      visible: _displaySaveButton,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity,
              40), // double.infinity is the width and 30 is the height
          onPrimary: Colors.white,
          primary: Theme.of(context).colorScheme.primary,
        ),
        onPressed: () {
          if (_isReadOnly) {
            Navigator.pop(context);
          } else {
            Navigator.pop(context, turnpoint);
          }
        },
        child: Text(
          TurnpointEditText.saveLocation,
        ),
      ),
    );
  }

  Widget _saveResetButtons() {
    return Visibility(
      visible: _displaySaveResetButtons,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: _saveLocationButton(),
          ),
          Expanded(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: _resetButton(),
              )),
        ],
      ),
    );
  }

  Widget _saveLocationButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity,
            40), // double.infinity is the width and 30 is the height
        onPrimary: Colors.white,
        primary: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () {
        Navigator.pop(context, turnpoint);
      },
      child: Text(
        TurnpointEditText.saveLocation,
      ),
    );
  }

  Widget _resetButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity,
            40), // double.infinity is the width and 30 is the height
        onPrimary: Colors.white,
        primary: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () {
        setState(() {
          _displaySaveResetButtons = false;
          _displaySaveButton = true;
          turnpoint.latitudeDeg = originalTurnpoint.latitudeDeg;
          turnpoint.longitudeDeg = originalTurnpoint.longitudeDeg;
          turnpoint.elevation = originalTurnpoint.elevation;
        });
        _getTurnpointMarker();
        _animateCameraToNewPosition();
        delaySetState(200);
      },
      child: Text(
        TurnpointEditText.reset,
      ),
    );
  }

  Marker _getTurnpointMarker() {
    print(
        "creating marker location: ${turnpoint.latitudeDeg} ${turnpoint.longitudeDeg} ");
    _marker = Marker(
      draggable: _draggable,
      onDrag: _draggable ? _dragListener : null,
      onDragEnd: _draggable ? _markerDragListener : null,
      markerId: MarkerId(turnpoint.code),
      position: LatLng(turnpoint.latitudeDeg, turnpoint.longitudeDeg),
    );
    return _marker;
  }

  List<Widget> _getMenu() {
    return <Widget>[
      TextButton(
        onPressed: () {
          launchWebBrowser("www.airnav.com",
              "/airport/" + widget.turnpointOverHeadArgs.turnpoint.code);
        },
        child: Text(
          TurnpointEditMenu.airNav,
          style: TextStyle(color: Colors.white),
        ),
      ),
      PopupMenuButton<String>(
        onSelected: handleClick,
        icon: Icon(Icons.more_vert),
        itemBuilder: (BuildContext context) {
          return {
            TurnpointEditMenu.toggleLatLongFormat,
            TurnpointEditMenu.dragMarker,
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

  _dragListener(LatLng latLng) {
    print("Dagging current lat: ${latLng.latitude} long: ${latLng.longitude}");
  }

  _markerDragListener(LatLng latLng) {
    turnpoint.latitudeDeg = latLng.latitude;
    turnpoint.longitudeDeg = latLng.longitude;
    findElevationAtLatLong();
    setState(() {
      _displaySaveButton = false;
      if (turnpoint.latitudeDeg != originalTurnpoint.latitudeDeg ||
          turnpoint.latitudeDeg != originalTurnpoint.longitudeDeg) {
        _displaySaveResetButtons = true;
      } else {
        _displaySaveButton = true;
        _displaySaveResetButtons = false;
      }
      print(
          "New lat/long after dragging: ${turnpoint.latitudeDeg}, ${turnpoint.latitudeDeg}");
      print(
          "_displaySaveButton ${_displaySaveButton} _displaySaveResetButtons ${_displaySaveResetButtons}");
      print("draggable : ${_draggable}");
    });
  }

  List getMenuOptions() {
    List<String> optionList = [];
    optionList.add(TurnpointEditMenu.toggleLatLongFormat);
    if (_isReadOnly) {
      optionList.add(TurnpointEditMenu.dragMarker);
    }
    return optionList;
  }

  void handleClick(String value) {
    switch (value) {
      case TurnpointEditMenu.toggleLatLongFormat:
        setState(() {
          _isDecimalDegreesFormat = !_isDecimalDegreesFormat;
        });
        break;
      case TurnpointEditMenu.dragMarker:
        //TODO drag marker logic
        setState(() {
          _draggable = !_draggable;
          print("draggable marker: ${_draggable}");
        });
        break;
    }
  }

  /// Only needed for adding new turnpoint (lat/long are 0)
  void checkForLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      // We didn't ask for permission yet or the permission has been denied before but not permanently.
      if (await Permission.location.request().isGranted) {
        // Fire event to get the current location
        getLocation();
      }
    }
    if (status.isPermanentlyDenied) {
      // display msg to user they need to go to settings to re-enable
      openAppSettings();
    }
    if (status.isGranted) {
      getLocation();
    }
  }

  void getLocation() async {
    BlocProvider.of<TurnpointBloc>(context).add(GetCurrentLocation());
  }

  void findElevationAtLatLong() {
    BlocProvider.of<TurnpointBloc>(context).add(
        GetElevationAtLatLong(turnpoint.latitudeDeg, turnpoint.longitudeDeg));
  }

  void delaySetState(int delay) {
    Future.delayed(Duration(milliseconds: delay), () {
      setState(() {});
    });
  }
}
