import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/airport/bloc/airport_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/airport/bloc/airport_event.dart';
import 'package:flutter_soaring_forecast/soaring/airport/bloc/airport_state.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/floor/airport/airport.dart';
import 'package:flutter_soaring_forecast/soaring/repository/one800wxbrief/metar_taf_response.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';

class AirportMetarTaf extends StatefulWidget {
  final List<Airport> selectedAirports = [];
  final Repository repository;

  AirportMetarTaf({Key? key, required Repository this.repository})
      : super(key: key);

  @override
  State<AirportMetarTaf> createState() => _AirportMetarTafState();
}

class _AirportMetarTafState extends State<AirportMetarTaf>
    with AfterLayoutMixin<AirportMetarTaf> {
  // Make sure first layout occurs
  @override
  void afterFirstLayout(BuildContext context) {
    BlocProvider.of<AirportBloc>(context).add(GetAirportMetarAndTafs());
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
        title: Text("METAR/TAF"),
        leading: BackButton(
          onPressed: _onWillPop,
        ),
        actions: _getMetarTafMenu());
  }

  List<Widget> _getMetarTafMenu() {
    return <Widget>[
      PopupMenuButton<String>(
        onSelected: handleClick,
        icon: Icon(Icons.more_vert),
        itemBuilder: (BuildContext context) {
          return {
            MetarTafMenu.add,
            MetarTafMenu.list,
          }.map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
      ),
    ];
  }

  void handleClick(String value) async {
    switch (value) {
      case MetarTafMenu.list:
        _showSelectedAirports();
        break;
      case MetarTafMenu.add:
        _addNewAirport();
        break;
    }
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
            child: Text('No airports selected yet.'),
          );
        }
        return _getAirportsListView(context: context, airports: state.airports);
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

  Widget _getAirportsListView(
      {required BuildContext context, required List<Airport> airports}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.separated(
        itemCount: airports.length,
        itemBuilder: (BuildContext context, int index) {
          return _getAirportMetarAndTafWidget(airports[index]);
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

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop();
    return true;
  }

  _sendEvent(AirportEvent event) {
    BlocProvider.of<AirportBloc>(context).add(event);
  }

  Future<void> _addNewAirport() async {
    await Navigator.pushNamed(context, AirportsSearchRouteBuilder.routeName,
        arguments: null);
    _sendEvent(GetSelectedAirportsList());
  }

  Future<void> _showSelectedAirports() async {
    await Navigator.pushNamed(context, SelectedAirportsRouteBuilder.routeName,
        arguments: null);
    _sendEvent(GetSelectedAirportsList());
  }

  Widget _getAirportMetarAndTafWidget(Airport airport) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  flex: 4,
                  child: Text(
                    airport.name,
                    overflow: TextOverflow.ellipsis,
                  )),
              Expanded(flex: 2, child: Text(airport.ident)),
              Expanded(flex: 2, child: Text("Elev:  ${airport.elevationFt} ft"))
            ],
          ),
          Container(
              width: MediaQuery.of(context).size.width,
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.blueAccent)),
              child: Column(
                children: [
                  _getMetarOrTAFWidget(
                      ident: airport.ident, type: MetarOrTAF.METAR),
                  _getMetarOrTAFWidget(
                      ident: airport.ident, type: MetarOrTAF.TAF),
                ],
              )),
        ],
      ),
    );
  }

  Widget _getMetarOrTAFWidget(
      {required final ident, required final String type}) {
    String _response = MetarOrTAF.FETCHING_INFORMATION;
    bool firstTime = true;
    return BlocConsumer<AirportBloc, AirportState>(listener: (context, state) {
      if (state is AirportMetarTafState) {
        if (state.location == ident && state.type == type) {
          _response = _getMetartOrTafResponse(state.metarTafResponse);
        }
      }
    }, buildWhen: (previous, current) {
      return ((current is AirportMetarTafState &&
              current.location == ident &&
              current.type == type) ||
          firstTime);
    }, builder: (context, state) {
      firstTime = false;
      return Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              type,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _response,
            ),
          ),
        ],
      );
    });
  }

  String _getMetartOrTafResponse(MetarTafResponse metarTafResponse) {
    if (metarTafResponse.returnStatus ?? false) {
      return metarTafResponse.plainText ?? MetarOrTAF.UNDEFINED_ERROR;
    } else if (metarTafResponse.returnCodedMessage != null) {
      final sb = StringBuffer();
      metarTafResponse.returnCodedMessage!.forEach((codedMessage) {
        sb.write("${codedMessage.code} : ${codedMessage.message}");
      });
      return sb.toString();
    }
    return MetarOrTAF.UNDEFINED_ERROR;
  }
}
