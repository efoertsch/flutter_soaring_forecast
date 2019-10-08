import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/json/regions.dart';
import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';
import 'package:provider/provider.dart';

class RaspLayout extends StatefulWidget {
  @override
  RaspLayoutState createState() => RaspLayoutState();
}

class RaspLayoutState extends State<RaspLayout> {
  var _forecastModels = ["GFS", "NAM", "RAP"];
  var _forecastDates = [
    "Weds. Oct 2",
    "Thurs. Oct 3",
    "Fri. Oct 4",
    'Sat. Oct 5'
  ];

  var Repository repository;
  var Regions regions;

  var selectedForecastModel;
  var selectedForecastDate;

  @override
  Widget build(BuildContext context) {
    repository = Provider.of<Repository>(context);
    getRegions();

    selectedForecastModel =  _forecastModels[0];
    selectedForecastDate = _forecastDates[0];
    return Scaffold(
      appBar: AppBar(
        title: Text('RASP'),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.list),
              onPressed: null),
        ],
      ),
      body: _forecastLayout(),
    );
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
        setState(() {
          selectedForecastModel = newValue;
        });
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
        setState(() {
          selectedForecastModel = newValue;
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

  Widget _forecastDatesDropDownList() {
    return DropdownButton<String>(
      value: selectedForecastDate,
      icon: Icon(Icons.arrow_downward),
      onChanged: (String newValue) {
        setState(() {
          selectedForecastModel = newValue;
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

  void getRegions() async  {
    try {
      regions = await repository.getRegions();
      var region = regions?.regions[1];
      var dates = region.printDates;
      printDates.

      selectedForecastModel = region.printDates;

  } catch (Exception e){
      // do something
    }
  }
}