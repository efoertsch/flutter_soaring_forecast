import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/web_mixin.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoint_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  GoogleMapController? mapController;
  bool isDecimalDegreesFormat = true;
  bool isReadOnly = false;

// Make sure first layout occurs prior to map ready otherwise crash occurs
  @override
  void afterFirstLayout(BuildContext context) {
    setState(() {
      _firstLayoutComplete = true;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('View Turnpoint'),
          leading: CommonWidgets.backArrowToHomeScreen(),
          actions: _getMenu(),
        ),
        body: getWidget(),
      ),
    );
  }

  Widget getWidget() {
    if (!_firstLayoutComplete) {
      return CommonWidgets.buildLoading();
    }
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text(TurnpointUtils.getFormattedTurnpointDetails(
              widget.turnpointOverHeadArgs.turnpoint, isDecimalDegreesFormat)),
          forecastMap(),
          closeButton(),
        ],
      ),
    );
  }

  Widget forecastMap() {
    return Expanded(
      child: GoogleMap(
        onMapCreated: _onMapCreated,
        mapType: MapType.satellite,
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.turnpointOverHeadArgs.turnpoint.latitudeDeg,
              widget.turnpointOverHeadArgs.turnpoint.longitudeDeg),
          zoom: 14.0,
        ),
        markers: Set<Marker>.of({getTurnpointMarker()}),
      ),
    );
  }

  Widget closeButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity,
            40), // double.infinity is the width and 30 is the height
        onPrimary: Colors.white,
        primary: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () {
        Navigator.pop(context);
      },
      child: Text(
        'CLOSE',
      ),
    );
  }

  Marker getTurnpointMarker() {
    Turnpoint turnpoint = widget.turnpointOverHeadArgs.turnpoint;
    return Marker(
      markerId: MarkerId(turnpoint.code),
      position: LatLng(turnpoint.latitudeDeg, turnpoint.longitudeDeg),
    );
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

  List getMenuOptions() {
    List<String> optionList = [];
    optionList.add(TurnpointEditMenu.toggleLatLongFormat);
    if (isReadOnly) {
      optionList.add(TurnpointEditMenu.dragMarker);
    }
    return optionList;
  }

  void handleClick(String value) {
    switch (value) {
      case TurnpointEditMenu.toggleLatLongFormat:
        setState(() {
          isDecimalDegreesFormat = !isDecimalDegreesFormat;
        });
        break;
      case TurnpointEditMenu.dragMarker:
        //TODO drag marker logic
        print("Implement drag marker logic");
        break;
    }
  }
}
