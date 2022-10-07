import 'dart:io';

import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/airport/bloc/airport_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/airport/bloc/airport_event.dart';
import 'package:flutter_soaring_forecast/soaring/airport/bloc/airport_state.dart';
import 'package:flutter_soaring_forecast/soaring/airport/ui/common_airport_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/floor/airport/airport.dart';

class AirportsSearch extends StatefulWidget {
  final List<Airport> airports = [];

  AirportsSearch({Key? key}) : super(key: key);

  @override
  State<AirportsSearch> createState() => _AirportsSearchState();
}

class _AirportsSearchState extends State<AirportsSearch> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool typing = false;
  String _searchString = "";
  bool _hasChanges = false;
  final airportsFromSearch = <Airport>[];

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return ConditionalWillPopScope(
        onWillPop: _onWillPop,
        shouldAddCallback: true,
        child: _buildSafeArea(),
      );
    } else {
      //iOS
      return GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.direction >= 0) {
            _onWillPop();
          }
        },
        child: _buildSafeArea(),
      );
    }
  }

  Widget _buildSafeArea() {
    return SafeArea(
      maintainBottomViewPadding: true,
      child:
          Scaffold(key: _scaffoldKey, appBar: _getAppBar(), body: _getBody()),
    );
  }

  Widget _getBody() {
    return BlocConsumer<AirportBloc, AirportState>(listener: (context, state) {
      if (state is AirportShortMessageState) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(state.shortMsg),
          ),
        );
      }
      if (state is AirportsLoadedState) {
        airportsFromSearch.clear();
        airportsFromSearch.addAll(state.airports);
      }
    }, buildWhen: (previous, current) {
      return current is AirportsInitialState ||
          current is AirportsLoadedState ||
          current is AirportsErrorState;
    }, builder: (context, state) {
      if (state is AirportsInitialState) {
        return Center(
          child: Container(),
        );
      }
      if (state is AirportsLoadedState) {
        if (state.airports.isEmpty) {
          return Center(
            child: Text('No airports found.'),
          );
        }
        return _getAirportsListView(
          context: context,
          airports: state.airports,
        );
      }
      if (state is AirportsErrorState) {
        WidgetsBinding.instance.addPostFrameCallback((_) =>
            CommonWidgets.showErrorDialog(
                context, 'Airports Error', state.errorMsg));
      }
      return Container();
    });
  }

  AppBar _getAppBar() {
    return AppBar(
      title:
          _getSearchTextBox(), // typing ? _getSearchTextBox() : Text("Airports"),
      leading: BackButton(
        onPressed: _onWillPop,
      ),
    );
  }

  Widget _getSearchTextBox() {
    return Container(
      alignment: Alignment.centerLeft,
      color: Colors.white,
      child: TextField(
        onChanged: (searchString) {
          if (searchString.length >= 2) {
            _searchString = searchString;
            BlocProvider.of<AirportBloc>(context)
                .add(SearchAirportsEvent(searchString));
          }
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'ICAO code, name, city, state',
        ),
        // decoration:
        //     InputDecoration(border: InputBorder.none, hintText: 'Search'),
        autofocus: true,
      ),
    );
  }

  Widget _getAirportsListView(
      {required BuildContext context, required List<Airport> airports}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.separated(
        itemCount: airports.length,
        itemBuilder: (BuildContext context, int index) {
          return _getClickableAirportWidget(airports, index);
        },
        separatorBuilder: (context, index) {
          return Divider(
            height: 4,
            thickness: 2,
          );
        },
      ),
    );
  }

  Widget _getClickableAirportWidget(List<Airport> airports, int index) {
    return InkWell(
      child: getAirportWidget(airports[index]),
      onTap: (() {
        _sendEvent(AddAirportToSelectList(airports[index]));
      }),
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop();
    return true;
  }

  _sendEvent(AirportEvent event) {
    BlocProvider.of<AirportBloc>(context).add(event);
  }
}
