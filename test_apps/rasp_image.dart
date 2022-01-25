import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/values/strings.dart';
import 'package:intl/intl.dart';

void main() => runApp(RaspImageTest());

class RaspImageTest extends StatefulWidget {
  // This widget is the root of your application.

  @override
  _RaspImageTestState createState() => _RaspImageTestState();
}

class _RaspImageTestState extends State<RaspImageTest> {
  Repository? repository;
  Image? image;
  final f = new DateFormat('yyyy-MM-dd');
  String? today;

  Key raspImageKey = Key("raspImage");
  Key progressIndicatorKey = Key("progessIndicator");

  var stackIndex = 0;

  @override
  void initState() {
    repository = Repository(context);
    today = f.format(DateTime.now());
    _getImage();
    super.initState();
  }

  _getImage() async {
    String url = Constants.RASP_BASE_URL +
        "/NewEngland/$today/gfs/wstar_bsratio.1500local.d2.body.png";
    image = await repository!.getRaspForecastImage(url);
    setState(() {
      stackIndex = 1;
      print("image found");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: Strings.appTitle,
        theme: ThemeData(
          // brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          primaryColor: Colors.blue,
        ),
        home: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: new AppBar(
            title: new Text("test"),
          ),
          body: _stackDisplay(),
        ));
  }

  Widget _stackDisplay() {
    return IndexedStack(index: stackIndex, children: <Widget>[
      Center(child: CircularProgressIndicator(key: progressIndicatorKey)),
      Container(key: raspImageKey, child: image),
    ]);
  }
}
