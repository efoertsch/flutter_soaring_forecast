import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';

class GeosScreen extends StatefulWidget {
  const GeosScreen({Key? key}) : super(key: key);

  @override
  _GeosScreenState createState() => _GeosScreenState();
}

class _GeosScreenState extends State<GeosScreen> {
  bool _displayCurrent = true;
  static final _geosLoopOption =
      Text(GeosMenu.loop, style: TextStyle(color: Colors.white));
  static final _geosCurrentOption =
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
      title: Text('GOES NE'),
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
      return _geosLoopOption;
    } else {
      return _geosCurrentOption;
    }
  }

  void _displayNoaa() {}

  Widget _getBody() {
    return SizedBox.expand(
      child: Container(
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(4.0),
          minScale: 1.0,
          maxScale: 4.0,
          child: Image.network(
            _displayCurrent ? GEOS_CURRENT : GEOS_GIF,
            fit: BoxFit.fitWidth,
            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null)
                return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
              return Text('Failed to load image');
            },),
        ),
      ),
    );
  }
}
