import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/bloc/bloc_provider.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/rasp_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/json/regions.dart';
import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';
import 'package:provider/provider.dart';

class RaspScreen extends StatelessWidget {
  var _forecastModels = ["GFS", "NAM", "RAP"];
  var _forecastDates = [
    "Weds. Oct 2",
    "Thurs. Oct 3",
    "Fri. Oct 4",
    'Sat. Oct 5'
  ];

  Repository repository;
  Regions regions;

  var selectedForecastModel;
  var selectedForecastDate;

  @override
  Widget build(BuildContext context) {
    repository = Provider.of<Repository>(context);

    selectedForecastModel = _forecastModels[0];
    selectedForecastDate = _forecastDates[0];
    return BlocProvider<RaspBloc>(
        bloc: RaspBloc(),
        child: Scaffold(
          appBar: AppBar(
            title: Text('RASP'),
            actions: <Widget>[
              IconButton(icon: Icon(Icons.list), onPressed: null),
            ],
          ),
          body: _forecastLayout(),
        ));
  }

  Widget _forecastLayout() {
    return Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      getForecastModels(),
    ]);
  }

  Widget getForecastModels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        forecastModelDropDownList(),
        forecastDatesDropDownList(),
      ],
    );
  }

  Widget forecastModelDropDownList() {
    return DropdownButton<String>(
      value: selectedForecastModel,
      //icon: Icon(Icons.arrow_downward),
      iconSize: 24,
      elevation: 16,
      style: TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: (String newValue) {
//        setState(() {
//          selectedForecastModel = newValue;
//        });
      },
      items: _forecastModels.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget forecastDatesDropDownList() {
    return DropdownButton<String>(
      value: selectedForecastDate,
      icon: Icon(Icons.arrow_downward),
//      iconSize: 24,
//      elevation: 16,
//      style: TextStyle(color: Colors.deepPurple),
//      underline: Container(
//        height: 2,
//        color: Colors.deepPurpleAccent,
//      ),
      onChanged: (String newValue) {
//        setState(() {
//          selectedForecastModel = newValue;
//        });
      },
      items: _forecastDates.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
