import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/airport/bloc/airport_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/airport/bloc/airport_event.dart';
import 'package:flutter_soaring_forecast/soaring/airport/bloc/airport_state.dart';
import 'package:flutter_soaring_forecast/soaring/airport/ui/common_airport_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/floor/airport/airport.dart';

class SelectedAirportsList extends StatefulWidget {
  final List<Airport> selectedAirports = [];

  SelectedAirportsList({Key? key}) : super(key: key);

  @override
  State<SelectedAirportsList> createState() => _SelectedAirportsListState();
}

class _SelectedAirportsListState extends State<SelectedAirportsList>
    with AfterLayoutMixin<SelectedAirportsList> {
  // Make sure first layout occurs
  @override
  void afterFirstLayout(BuildContext context) {
    BlocProvider.of<AirportBloc>(context).add(GetSelectedAirportsListEvent());
  }

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
      child: Scaffold(appBar: _getAppBar(), body: _getBody()),
    );
  }

  AppBar _getAppBar() {
    return AppBar(
        title: Text("METAR/TAF Airports"),
        leading: BackButton(
          onPressed: _onWillPop,
        ),
        actions: getAirportMenu());
  }

  List<Widget> getAirportMenu() {
    return <Widget>[
      TextButton(
        child: Text("ADD"),
        onPressed: () {
          _addNewAirport();
        },
      )
    ];
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
    }, buildWhen: (previous, current) {
      return current is AirportsInitialState ||
          current is AirportsLoadedState ||
          current is AirportsErrorState;
    }, builder: (context, state) {
      if (state is AirportsInitialState) {
        return CommonWidgets.buildLoading();
      }

      if (state is AirportsLoadedState) {
        if (state.airports.isEmpty) {
          return Center(
            child: Text('No airports found.'),
          );
        }
        return _getAirportListView(context: context, airports: state.airports);
      }

      if (state is AirportsErrorState) {
        WidgetsBinding.instance.addPostFrameCallback((_) =>
            CommonWidgets.showErrorDialog(
                context, 'Airports Error', state.errorMsg));
      }
      return Center(
        child: Text('Hmmm. Undefined state.'),
      );
    });
  }

  Widget _getAirportListView(
      {required BuildContext context, required List<Airport> airports}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ReorderableListView(
        children: _getAirportList(airports),
        onReorder: (int oldIndex, int newIndex) {
          // ReorderableListView has known index bug
          if (newIndex > airports.length) newIndex = airports.length;
          if (oldIndex < newIndex) newIndex--;
          BlocProvider.of<AirportBloc>(context)
              .add(SwitchOrderOfSelectedAirportsEvent(oldIndex, newIndex));
        },
      ),
    );
  }

  List<Widget> _getAirportList(List<Airport> airports) {
    final airportsWidgetList = <Widget>[];
    int index = 0;
    airports.forEach((airport) {
      airportsWidgetList.add(
        Align(
          key: Key('${index}'),
          alignment: Alignment.topLeft,
          child: _createAirportItem(airport, index),
        ),
      );
      ++index;
    });
    return airportsWidgetList;
  }

  Widget _createAirportItem(Airport airport, int index) {
    return Dismissible(
      background: Container(
        color: Colors.red,
        padding: EdgeInsets.only(left: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.delete,
            )
          ],
        ),
      ),
      key: UniqueKey(),
      onDismissed: (direction) {
        BlocProvider.of<AirportBloc>(context)
            .add(SwipeDeletedAirportEvent(airport));
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Removed ${airport.name}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              BlocProvider.of<AirportBloc>(context)
                  .add(AddBackAirportEvent(airport, index));
            },
          ),
        ));
      },
      child: Column(
        children: [
          Container(
              alignment: Alignment.centerLeft,
              child: getAirportWidget(airport)),
          Divider(
            thickness: 2,
          ),
        ],
      ),
    );
  }

  Future<void> _addNewAirport() async {
    await Navigator.pushNamed(context, AirportsSearchRouteBuilder.routeName,
        arguments: null);
    _sendEvent(GetSelectedAirportsListEvent());
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop();
    return true;
  }

  _sendEvent(AirportEvent event) {
    BlocProvider.of<AirportBloc>(context).add(event);
  }
}
