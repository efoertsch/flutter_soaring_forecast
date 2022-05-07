import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/main.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoint_utils.dart';

class TurnpointEditView extends StatelessWidget {
  final Turnpoint turnpoint;
  late final BuildContext _context;

  TurnpointEditView({Key? key, required this.turnpoint}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Scaffold(
      appBar: AppBar(
        title: Text('Turnpoint'),
        leading: CommonWidgets.backArrowToHomeScreen(),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.list), onPressed: null),
        ],
      ),
      body: getDisplayWidget(),
    );
  }

  Widget getDisplayWidget() {
    return SafeArea(
      child: ListView(children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 8, right: 8),
          child: TextFormField(
            initialValue: turnpoint.title,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Waypoint Name',
              labelText: 'Waypoint Name',
            ),
            onChanged: (text) {
              turnpoint.title = text;
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            initialValue: turnpoint.code,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Waypoint Code',
              labelText: 'Waypoint Code',
            ),
            onChanged: (text) {
              turnpoint.code = text;
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            initialValue: (turnpoint.country),
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Country Code',
              labelText: 'Country Code',
            ),
            onChanged: (text) {
              turnpoint.country = text;
            },
          ),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  initialValue: turnpoint.latitudeDeg.toStringAsFixed(5),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Latitude (-)dd.mmmmm',
                    labelText: 'Latitude (-)dd.mmmmm',
                  ),
                  onChanged: (text) {
                    turnpoint.latitudeDeg = double.parse(text);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  initialValue: turnpoint.longitudeDeg.toStringAsFixed(5),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Longitude (-)ddd.mmmmm',
                    labelText: 'Longitude (-)ddd.mmmmm',
                  ),
                  onChanged: (text) {
                    turnpoint.latitudeDeg = double.parse(text);
                  },
                ),
              ),
            ]),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: Icon(Icons.location_searching),
                color: TurnpointUtils.getColorForTurnpointIcon(turnpoint),
                onPressed: () => Navigator.pushNamed(
                  _context,
                  TurnpointView.routeName,
                  arguments: turnpoint,
                ),
              ),
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            initialValue: turnpoint.elevation,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Elevation ending in ft or m',
              labelText: 'Elevation ending in ft or m',
            ),
            onChanged: (text) {
              turnpoint.elevation = text;
            },
          ),
        ),
        // DropdownButton<String>(
        //   style: CustomStyle.bold18(context),
        //   value: (TurnpointUtils.getStyleName(turnpoint.style)),
        //   hint: Text('Select Model'),
        //   isExpanded: true,
        //   iconSize: 24,
        //   elevation: 16,
        //   onChanged: (String? newValue) {
        //     print('Selected model onChanged: $newValue');
        //    // _sendEvent(context, );
        //   },
        //   items: state.modelNames.map<DropdownMenuItem<String>>((String value) {
        //     return DropdownMenuItem<String>(
        //       value: value,
        //       child: Text(value.toUpperCase()),
        //     );
        //   }).toList(),
        // )
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            initialValue: turnpoint.direction,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Runway direction - 3 digit number',
              labelText: 'Runway direction - 3 digit number',
            ),
            onChanged: (text) {
              turnpoint.direction = text;
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            initialValue: turnpoint.length,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Runway length - ending in ft or m',
              labelText: 'Runway length - ending in ft or m',
            ),
            onChanged: (text) {
              turnpoint.length = text;
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            initialValue: turnpoint.runwayWidth,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Runway width',
              labelText: 'Runway width',
            ),
            onChanged: (text) {
              turnpoint.runwayWidth = text;
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            initialValue: turnpoint.frequency,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Airport Frequency nnn.nn(0|5)',
              labelText: 'Airport Frequency nnn.nn(0|5)',
            ),
            onChanged: (text) {
              turnpoint.frequency = text;
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            initialValue: turnpoint.description,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Description',
              labelText: 'Description',
            ),
            onChanged: (text) {
              turnpoint.description = text;
            },
          ),
        ),
      ]),
    );
  }

  _sendEvent(TurnpointEvent event) {
    BlocProvider.of<TurnpointBloc>(_context).add(event);
  }
}
