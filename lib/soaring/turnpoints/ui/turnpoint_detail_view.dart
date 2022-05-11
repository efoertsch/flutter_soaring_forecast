import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoint_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TurnpointOverheadView extends StatefulWidget {
  final Turnpoint turnpoint;

  TurnpointOverheadView({Key? key, required this.turnpoint}) : super(key: key);

  @override
  _TurnpointOverheadViewState createState() => _TurnpointOverheadViewState();
}

//TODO - keep more data details in Bloc,
class _TurnpointOverheadViewState extends State<TurnpointOverheadView>
    with AfterLayoutMixin<TurnpointOverheadView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _firstLayoutComplete = false;
  GoogleMapController? mapController;

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
          actions: <Widget>[
            IconButton(icon: Icon(Icons.list), onPressed: null),
          ],
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
              widget.turnpoint, false)),
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
          target: LatLng(
              widget.turnpoint.latitudeDeg, widget.turnpoint.longitudeDeg),
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
    Turnpoint turnpoint = widget.turnpoint;
    return Marker(
      markerId: MarkerId(turnpoint.code),
      position: LatLng(turnpoint.latitudeDeg, turnpoint.longitudeDeg),
    );
  }
}
