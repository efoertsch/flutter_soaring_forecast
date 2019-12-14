import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/bloc/rasp_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/json/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/json/regions.dart';
import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';
import 'package:url_launcher/url_launcher.dart';

class RaspScreen extends StatefulWidget {
  final BuildContext repositoryContext;
  Repository repository;
  RaspScreen({Key key, @required this.repositoryContext}) : super(key: key);

  @override
  _RaspScreenState createState() => _RaspScreenState();
}

class _RaspScreenState extends State<RaspScreen> {
  RaspDataBloc _raspDataBloc;
  Region _region;
  List<ModelDates> _modelDates = List();
  ModelDates _selectedModelDates;
  List<String> _forecastDates = List();
  String _selectedForecastDate;
  List<Forecast> _forecasts = List();
  Forecast _selectedForecast;
  List<String> _forecastTimes = List();
  int _selectedForecastTimeIndex = 0;

  // Executed only when class created
  @override
  void initState() {
    super.initState();
    _raspDataBloc = BlocProvider.of<RaspDataBloc>(context);
    _raspDataBloc.add(GetDefaultRaspRegion());
    _raspDataBloc.add(LoadForecastTypes());
    _selectedForecastTimeIndex = 0;
  }

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _forecastLayout() {
    return Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          getForecastModelsAndDates(),
          getForecastTypes(),
          displayForecastTimes(),
        ]));
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
      value: (_selectedModelDates.modelName),
      isExpanded: true,
      //icon: Icon(Icons.arrow_downward),
      iconSize: 24,
      elevation: 16,
      onChanged: (String newValue) {
        setState(() {
          _selectedModelDates = _modelDates
              .firstWhere((modelDates) => modelDates.modelName == newValue);
          updateForecastDates();
        });
      },
      items: _modelDates
          .map((modelDates) => modelDates.modelName)
          .toList()
          .map<DropdownMenuItem<String>>((String value) {
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
      onChanged: (String newValue) {
        setState(() {
          _selectedForecastDate = newValue;
          updateForecastTimesList();
        });
      },
      items: _selectedModelDates
          .getModelDateDetailList()
          .map((modelDateDetails) => modelDateDetails.printDate)
          .toList()
          .map<DropdownMenuItem<String>>((String value) {
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
      onChanged: (String newValue) {
        setState(() {
          _selectedForecast = _forecasts.firstWhere(
              (forecast) => forecast.forecastNameDisplay == newValue);
        });
      },
      items: _forecasts
          .map((forecast) => forecast.forecastNameDisplay)
          .toList()
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
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
                _forecastTimes[_selectedForecastTimeIndex],
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
          child: Text(
            'Pause',
            textAlign: TextAlign.end,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RaspDataBloc, RaspDataState>(
        listener: (context, state) {
      if (state is RaspRegionLoaded) {
        _modelDates = state.region.getModelDates();
      } else if (state is RaspModelDatesSelected) {
        _selectedModelDates = state.modelDates;
        updateForecastDates();
      } else if (state is RaspForecastTypesLoaded) {
        _forecasts = state.forecasts;
        _selectedForecast = _forecasts.first;
      }
    }, child:
            BlocBuilder<RaspDataBloc, RaspDataState>(builder: (context, state) {
      if (state is InitialRaspDataState ||
          _modelDates == null ||
          _selectedModelDates == null ||
          _forecastTimes == null ||
          _forecasts == null ||
          _selectedForecast == null) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }

      return Scaffold(
          key: _scaffoldKey,
          drawer: getDrawer(context),
          appBar: AppBar(
            title: Text('RASP'),
            actions: <Widget>[
              IconButton(icon: Icon(Icons.list), onPressed: null),
            ],
          ),
          body: _forecastLayout());
    }));
  }

  // Dependent on having
  void updateForecastDates() {
    _forecastDates = _selectedModelDates
        .getModelDateDetailList()
        .map((modelDateDetails) => modelDateDetails.printDate)
        .toList();
    // stay on same date if new model has forecast for that date
    if (!_forecastDates.contains(_selectedForecastDate)) {
      _selectedForecastDate = _forecastDates.first;
    }
    updateForecastTimesList();
  }

  void updateForecastTimesList() {
    _forecastTimes = _selectedModelDates
        .getModelDateDetailList()
        .firstWhere((modelDateDetails) =>
            modelDateDetails.printDate == _selectedForecastDate)
        .model
        .times;
    // Stay on same time if new forecastTimes has same time as previous
    // Making reasonable assumption that times in same order across models/dates
    if (_selectedForecastTimeIndex > _forecastTimes.length - 1) {
      _selectedForecastTimeIndex = 0;
    }
  }

  Widget getDrawer(BuildContext context) {
    return Drawer(
// Add a ListView to the drawer. This ensures the user can scroll
// through the options in the drawer if there isn't enough vertical
// space to fit everything.
      child: ListView(
// Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: <Widget>[
          new SizedBox(
            height: 120.0,
            child: DrawerHeader(
              child: Text(
                'SoaringForecast',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
          ),
          ListTile(
            title: Text('Windy'),
            onTap: () {
// Update the state of the app
// ...
// Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('SkySight'),
            onTap: () {
              _launchWebBrowser("https://skysight.io/");
            },
          ),
          ListTile(
            title: Text('Dr Jacks'),
            onTap: () {
              _launchWebBrowser("http://www.drjack.info/BLIP/univiewer.html");
            },
          ),
          ListTile(
            title: Text('Airport METAR/TAF'),
            onTap: () {
// Update the state of the app
// ...
// Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('NOAA'),
            onTap: () {
// Update the state of the app
// ...
// Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('GEOS NE'),
            onTap: () {
// Update the state of the app
// ...
// Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Airport List'),
            onTap: () {
// Update the state of the app
// ...
// Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Task List'),
            onTap: () {
// Update the state of the app
// ...
// Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Import Turnpoints'),
            onTap: () {
// Update the state of the app
// ...
// Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Settings'),
            onTap: () {
// Update the state of the app
// ...
// Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('About'),
            onTap: () {
// Update the state of the app
// ...
// Then close the drawer
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

void _launchWebBrowser(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}
