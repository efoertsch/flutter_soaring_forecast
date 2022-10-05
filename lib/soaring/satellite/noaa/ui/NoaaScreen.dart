import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';

class NoaaScreen extends StatefulWidget {
  const NoaaScreen({Key? key}) : super(key: key);

  @override
  _NoaaScreenState createState() => _NoaaScreenState();
}

class _NoaaScreenState extends State<NoaaScreen> {
  bool _displayCurrent = true;
  static final _noaaLoopOption =
      Text(GeosMenu.loop, style: TextStyle(color: Colors.white));
  static final _noaaCurrentOption =
      Text(GeosMenu.current, style: TextStyle(color: Colors.white));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: _getAppBar(context),
        body: _getBody(),
      ),
    );
  }

  AppBar _getAppBar(BuildContext context) {
    return AppBar(
      title: Text('NOAA'),
      leading: BackButton(
        onPressed: () => Navigator.pop(context),
      ),
      actions: _getMenu(),
    );
  }

  List<Widget> _getMenu() {
    return <Widget>[
      TextButton(
        child: _getGeosMenuOption(),
        onPressed: () {
          setState(() {
            _displayCurrent = !_displayCurrent;
          });
        },
      ),
      PopupMenuButton<String>(
        onSelected: handleClick,
        icon: Icon(Icons.more_vert),
        itemBuilder: (BuildContext context) {
          return {
            GeosMenu.noaa,
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

  void handleClick(String value) async {
    switch (value) {
      case GeosMenu.noaa:
        _displayNoaa();
        break;
    }
  }

  Widget _getGeosMenuOption() {
    if (_displayCurrent) {
      return _noaaLoopOption;
    } else {
      return _noaaCurrentOption;
    }
  }

  void _displayNoaa() {}

  Widget _getBody() {
    return SizedBox.expand(
      child: Container(
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(4.0),
          minScale: 1.0,
          maxScale: 3.0,
          child: Image.network(
            _displayCurrent ? GEOS_CURRENT : GEOS_GIF,
            fit: BoxFit.fitWidth,
          ),
        ),
      ),
    );
  }
}
