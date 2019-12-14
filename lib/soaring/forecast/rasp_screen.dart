import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/bloc/rasp_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/json/forecast_types.dart';
import 'package:flutter_soaring_forecast/soaring/json/regions.dart';
import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';

class RaspScreen extends StatefulWidget {
  final BuildContext repositoryContext;
  Repository repository;
  RaspScreen({Key key, @required this.repositoryContext}) : super(key: key);

  @override
  _RaspScreenState createState() => _RaspScreenState();
}

class _RaspScreenState extends State<RaspScreen> {
  //TODO replace with repository api calls
//  var _forecastModels = ["GFS", "NAM", "RAP"];
//  var _forecastDates = [
//    "Weds. Oct 2",
//    "Thurs. Oct 3",
//    "Fri. Oct 4",
//    'Sat. Oct 5'
//  ];
//
//  var _forecastTypes = [
//    "Thermal Updraft Velocity & B/S Ratio",
//    "Thermal Updraft Velocity (W*)",
//    "Buoyancy/Shear Ratio"
//  ];
//
//  var _forecastTimes = [
//    "0900(Local)",
//    "1000(Local)",
//    "1100(Local)",
//    "1200(Local)",
//    "1300(Local)",
//    "1400(Local)",
//    "1500(Local)",
//    "1600(Local)",
//    "1700(Local)",
//    "1800(Local)"
//  ];

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

  Widget forecastModelDropDownList() {
    return DropdownButton<String>(
      value: (_selectedModelDates == null
          ? "Loading"
          : _selectedModelDates.modelName),
      isExpanded: true,
      //icon: Icon(Icons.arrow_downward),
      iconSize: 24,
      elevation: 16,
      onChanged: (String newValue) {
        setState(() {
          _selectedModelDates = _modelDates
              .firstWhere((modelDates) => modelDates.modelName == newValue);
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

  Widget forecastDatesDropDownList() {
    return DropdownButton<String>(
      isExpanded: true,
      value: _selectedForecastDate,
      onChanged: (String newValue) {
        setState(() {
          _selectedForecastDate = newValue;
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

  Widget getForecastTypes() {
    return DropdownButton<String>(
      isExpanded: true,
      value: (_selectedForecast == null
          ? "Loading"
          : _selectedForecast.forecastNameDisplay),
      //icon: Icon(Icons.arrow_downward),
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
        _forecastDates = _selectedModelDates
            .getModelDateDetailList()
            .map((modelDateDetails) => modelDateDetails.printDate)
            .toList();
        _forecastTimes =
            _selectedModelDates.getModelDateDetailList().first.model.times;
        _selectedForecastTimeIndex = 0;
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
          _forecasts == null) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }

      return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text('RASP'),
            actions: <Widget>[
              IconButton(icon: Icon(Icons.list), onPressed: null),
            ],
          ),
          body: _forecastLayout());
    }));
  }
}
