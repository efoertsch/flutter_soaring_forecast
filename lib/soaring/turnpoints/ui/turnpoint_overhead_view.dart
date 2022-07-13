import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/web_mixin.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoint_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool _displaySaveReset = false;
  late final Turnpoint turnpoint;
  late final Turnpoint originalTurnpoint;
  late final ValueNotifier<LatLng> _markerLocation;

  @override
  initState() {
    originalTurnpoint = widget.turnpointOverHeadArgs.turnpoint;
    turnpoint = originalTurnpoint.clone();
    _markerLocation = ValueNotifier<LatLng>(
        LatLng(turnpoint.latitudeDeg, turnpoint.longitudeDeg));
    super.initState();
  }

// Make sure first layout occurs prior to map ready otherwise crash occurs
  @override
  void afterFirstLayout(BuildContext context) {
    setState(() {
      _firstLayoutComplete = true;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (turnpoint.latitudeDeg == 0 || turnpoint.longitudeDeg == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkForLocationPermission();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //return _buildScaffold(context);
    if (Platform.isAndroid) {
      return _buildScaffold(context);
    } else {
      //iOS
      return GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onHorizontalDragUpdate: (details) {
          if (details.delta.direction >= 0) {
            Navigator.of(context).pop();
          }
        },
        child: _buildScaffold(context),
      );
    }
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
    if (!_firstLayoutComplete) {
      return CommonWidgets.buildLoading();
    }
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          getTurnpointText(),
          googleMap(),
          saveCloseButtons(),
        ],
      ),
    );
  }

  Widget getTurnpointText() {
    return Text(TurnpointUtils.getFormattedTurnpointDetails(
        turnpoint, _isDecimalDegreesFormat));
  }

  Widget googleMap() {
    return ValueListenableBuilder<LatLng>(
        valueListenable: _markerLocation,
        builder: (BuildContext context, LatLng latLng, Widget? child) {
          return Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              mapType: MapType.satellite,
              initialCameraPosition: CameraPosition(
                target: LatLng(turnpoint.latitudeDeg, turnpoint.longitudeDeg),
                zoom: 14.0,
              ),
              markers: Set<Marker>.of({getTurnpointMarker()}),
            ),
          );
        });
  }

  Widget saveCloseButtons() {
    return Visibility(
      visible: _displaySaveReset,
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
        print("add save location logic");
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
          _displaySaveReset = false;
          turnpoint.latitudeDeg = originalTurnpoint.latitudeDeg;
          turnpoint.longitudeDeg = originalTurnpoint.longitudeDeg;
        });
      },
      child: Text(
        TurnpointEditText.reset,
      ),
    );
  }

  Marker getTurnpointMarker() {
    print("creating marker: _draggable = ${_draggable}");
    _marker = Marker(
      draggable: _draggable,
      onDrag: _draggable ? _markerDragListener : null,
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

  _markerDragListener(LatLng latLng) {
    turnpoint.latitudeDeg = latLng.latitude;
    turnpoint.longitudeDeg = latLng.longitude;
    setState(() {
      if (turnpoint.latitudeDeg != originalTurnpoint.latitudeDeg ||
          turnpoint.latitudeDeg != originalTurnpoint.longitudeDeg) {
        _displaySaveReset = true;
      } else {
        _displaySaveReset = false;
      }
      print(
          "New lat/long after dragging: ${turnpoint.latitudeDeg}, ${turnpoint.latitudeDeg}");
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
    Location location = new Location();
    try {
      final currentLocation = await location.getLocation();
      turnpoint.latitudeDeg = currentLocation.latitude!;
      turnpoint.longitudeDeg = currentLocation.longitude!;
      print("location: ${turnpoint.latitudeDeg} ${turnpoint.longitudeDeg} ");
      _mapController!.animateCamera(CameraUpdate.newLatLng(
          LatLng(turnpoint.longitudeDeg, turnpoint.longitudeDeg)));
    } catch (e) {
      print(e.toString());
    }
  }
}
