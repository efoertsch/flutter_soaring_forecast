import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return Provider(
      builder: (_) => Repository(context),
      dispose: (context, value) => value.dispose(),
      child:   MaterialApp(
        title: 'SoaringForecast',
        theme: ThemeData(
          // brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          primaryColor: Colors.blue,
        ),
        home: RaspLayout()));

  }
}

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

  var selectedForecastModel;
  var selectedForecastDate;

  @override
  Widget build(BuildContext context) {
    selectedForecastModel = _forecastModels[0];
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

}
