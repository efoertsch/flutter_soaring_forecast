import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
as Constants;
import 'package:flutter_soaring_forecast/soaring/app/web_launcher.dart';
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

  TurnpointOverHeadArgs({required this.turnpoint,
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
  GoogleMapController? _mapController;
  bool _isDecimalDegreesFormat = true;
  bool _isReadOnly = false;
  bool _draggable = false;
  Set<Marker> _mapMarkers = Set();
  bool _displaySaveResetButtons = false;
  bool _displaySaveButton = false;
  bool _gotLocation = false;
  late final Turnpoint turnpoint;
  late final Turnpoint originalTurnpoint;
  Key? _turnpointInfoKey;
  var _displayCloseButton = false;


  @override
  initState() {
    originalTurnpoint = widget.turnpointOverHeadArgs.turnpoint.clone();
    _isReadOnly = widget.turnpointOverHeadArgs.isReadOnly;
    turnpoint = originalTurnpoint.clone();
    _displayCloseButton =
        (Platform.isIOS && _isReadOnly) || turnpoint.latitudeDeg != 0;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

// Make sure first layout occurs prior to map ready otherwise crash occurs
  @override
  void afterFirstLayout(BuildContext context) {
    _sendEvent(CupStylesEvent());
    if (turnpoint.latitudeDeg == 0 || turnpoint.longitudeDeg == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkForLocationPermission();
      });
      setState(() {});
    } else {
      _updateTurnpointMarker();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _animateCameraToNewPosition();
  }

  @override
  Widget build(BuildContext context) {
    return _buildSafeArea(context);
  }

  Widget _buildSafeArea(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: _getAppBar(),
        body: getBodyWidget(),
      ),
    );
  }

  AppBar _getAppBar() {
    return AppBar(
      title: _isReadOnly
          ? Text(TurnpointEditText.viewTurnpoint)
          : Text(TurnpointEditText.editTurnpoint),
      leading: BackButton(
        onPressed: _onWillPop,
      ),
      actions: _getMenu(),
    );
  }

  Widget getBodyWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          _getTurnpointInfoTextWidget(),
          _googleMap(),
          _getButtons(),
          _getLocationListener(),
        ],
      ),
    );
  }

  void _animateCameraToNewPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  Widget _getTurnpointInfoTextWidget() {
    return BlocBuilder<TurnpointBloc, TurnpointState>(
      buildWhen: (previous, current) {
        return current is TurnpointsInitialState ||
            current is TurnpointCupStylesState ||
            current is LatLongElevationState;
      },
      builder: (context, state) {
        if (state is LatLongElevationState) {
          turnpoint.elevation = state.elevation.toStringAsFixed(1) + "ft";
          print("elevation is: ${turnpoint.elevation}");
        }

          return Text(
              TurnpointUtils.getFormattedTurnpointDetails(
                  turnpoint, _isDecimalDegreesFormat),
              key: _turnpointInfoKey,
              textAlign: TextAlign.start);
      },
    );
  }

  Widget _getLocationListener() {
    return BlocListener<TurnpointBloc, TurnpointState>(
      listenWhen: (previous, current){
        return current is CurrentLocationState ;
      },
        listener: (context, state) {
          if (state is CurrentLocationState) {
            turnpoint.latitudeDeg = state.latitude;
            turnpoint.longitudeDeg = state.longitude;
            turnpoint.elevation =
                TurnpointUtils.convertMetersToFeet(state.altitude)
                    .toStringAsFixed(1) +
                    Constants.ft;
            if (originalTurnpoint.latitudeDeg == 0) {
              originalTurnpoint.latitudeDeg = turnpoint.latitudeDeg;
              originalTurnpoint.longitudeDeg = turnpoint.longitudeDeg;
              originalTurnpoint.elevation = turnpoint.elevation;
              _gotLocation = true;
              _displayCloseButton = false;
              _displaySaveButton = true;
            }
            print(
                "lat/long ${turnpoint.latitudeDeg} ${turnpoint.longitudeDeg}");
            if (state.altitude == 0) {
              findElevationAtLatLong();
            }
          }
          _updateTurnpointMarker();
          _turnpointInfoKey = ObjectKey(Object());
          _animateCameraToNewPosition();
        }, child: SizedBox.shrink(),
    );
  }

  Widget _googleMap() {
    return BlocBuilder<TurnpointBloc, TurnpointState>(
      buildWhen: (previous, current) {
        return current is TurnpointsInitialState;
      },
      builder: (context, state) {
        return Flexible(
          child: GoogleMap(
            myLocationButtonEnabled: !_isReadOnly,
            onMapCreated: _onMapCreated,
            mapType: MapType.satellite,
            initialCameraPosition: CameraPosition(
              target: LatLng(turnpoint.latitudeDeg, turnpoint.longitudeDeg),
              zoom: 14.0,
            ),
            markers: _mapMarkers,
          ),
        );
      },
    );
  }

  Widget _getButtons() {
    return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      _closeButton(),
      _saveButton(),
      _saveResetButtons(),
    ]);
  }

  _closeButton() {
    return Visibility(
      visible: _displayCloseButton,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity,
              40), // double.infinity is the width and 30 is the height
          foregroundColor: Colors.white,
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .primary,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text(
          TurnpointEditText.close,
        ),
      ),
    );
  }

  Widget _saveButton() {
    return Visibility(
      visible: _displaySaveButton,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity,
              40), // double.infinity is the width and 30 is the height
          foregroundColor: Colors.white,
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .primary,
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
        foregroundColor: Colors.white,
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .primary,
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
        foregroundColor: Colors.white,
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .primary,
      ),
      onPressed: () {
        setState(() {
          _displaySaveResetButtons = false;
          _displayCloseButton =
              (Platform.isIOS && _isReadOnly) || !_gotLocation;
          _displaySaveButton = _gotLocation;
          turnpoint.latitudeDeg = originalTurnpoint.latitudeDeg;
          turnpoint.longitudeDeg = originalTurnpoint.longitudeDeg;
          turnpoint.elevation = originalTurnpoint.elevation;
        });
        _updateTurnpointMarker();
        _animateCameraToNewPosition();
      },
      child: Text(
        TurnpointEditText.reset,
      ),
    );
  }

  void _updateTurnpointMarker() {
    print(
        "creating marker location: ${turnpoint.latitudeDeg} ${turnpoint
            .longitudeDeg} ");
    final marker = Marker(
      draggable: _draggable,
      //onDrag: _draggable ? _dragListener : null,
      onDragEnd: _draggable ? _markerDragListener : null,
      markerId: MarkerId(turnpoint.code),
      position: LatLng(turnpoint.latitudeDeg, turnpoint.longitudeDeg),
    );
    //
    _mapMarkers.clear();
    _mapMarkers.add(marker);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });

  }

  List<Widget> _getMenu() {
    return <Widget>[
      TextButton(
        onPressed: () {
          launchWebBrowser("www.airnav.com", "/airport/" + turnpoint.code);
        },
        child: Text(
          TurnpointEditMenu.airNav,
          style: TextStyle(color: Colors.white),
        ),
      ),
      PopupMenuButton<String>(
        onSelected: _handleClick,
        icon: Icon(Icons.more_vert),
        itemBuilder: (BuildContext context) {
          return _getMenuOptions().map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
      ),
    ];
  }

  // _dragListener(LatLng latLng) {
  //   print("Dragging current lat: ${latLng.latitude} long: ${latLng.longitude}");
  // }

 void  _markerDragListener(LatLng latLng) {
    turnpoint.latitudeDeg = latLng.latitude;
    turnpoint.longitudeDeg = latLng.longitude;
    findElevationAtLatLong();
    setState(() {
      _displaySaveButton = false;
      _displayCloseButton = false;
      if (turnpoint.latitudeDeg != originalTurnpoint.latitudeDeg ||
          turnpoint.latitudeDeg != originalTurnpoint.longitudeDeg) {
        _displaySaveResetButtons = true;
      } else {
        _displaySaveButton = true;
        _displaySaveResetButtons = false;
      }
    });
  }

  List<String> _getMenuOptions() {
    List<String> optionList = [];
    optionList.add(TurnpointEditMenu.toggleLatLongFormat);
    if (!_isReadOnly) {
      optionList.add(TurnpointEditMenu.dragMarker);
    }
    return optionList;
  }

  void _handleClick(String value) {
    switch (value) {
      case TurnpointEditMenu.toggleLatLongFormat:
        setState(() {
          _isDecimalDegreesFormat = !_isDecimalDegreesFormat;
        });
        break;
      case TurnpointEditMenu.dragMarker:
        setState(() {
          _draggable = !_draggable;
          print("draggable marker: ${_draggable}");
          _updateTurnpointMarker();
        });
        break;
    }
  }

  /// Only needed for adding new turnpoint (lat/long are 0)
  void checkForLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      // We didn't ask for permission yet or the permission has been denied before but not permanently.
      if (await Permission.location
          .request()
          .isGranted) {
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


  Future<bool> _onWillPop() async {
    if (_displaySaveButton || _displaySaveResetButtons) {
      CommonWidgets.showInfoDialog(
          context: context,
          title: "Unsaved Changes!",
          msg: "Changes will be lost. Continue?",
          button1Text: "No",
          button1Function: _dismissDialogFunction,
          button2Text: "Yes",
          button2Function: _cancelUpdateFunction);
    } else {
      Navigator.pop(context);
    }
    return true;
  }

  void _dismissDialogFunction() {
    Navigator.pop(context);
  }

  void _cancelUpdateFunction() {
    Navigator.pop(context); // remove dialog
    Navigator.pop(context); // return to prior screen
  }

  void _sendEvent(TurnpointEvent event) {
    BlocProvider.of<TurnpointBloc>(context).add(event);
  }
}
