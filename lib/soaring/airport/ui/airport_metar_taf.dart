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
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/floor/airport/airport.dart';
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
    _sendEvent(GetAirportMetarAndTafsEvent());
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
        title: Text(MetarOrTAF.METAR_TAF),
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
            MetarTafMenu.refresh,
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
      case MetarTafMenu.refresh:
        _refreshTafAndMetars();
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
            child: Text(MetarOrTAF.NO_AIRPORTS_SELECTED_YET),
          );
        }
        return _getAirportsListView(context: context, airports: state.airports);
      }

      if (state is AirportsErrorState) {
        WidgetsBinding.instance.addPostFrameCallback((_) =>
            CommonWidgets.showErrorDialog(
                context, MetarOrTAF.AIRPORTS_ERROR, state.errorMsg));
      }
      return Center(
        child: Text(StandardLiterals.UNDEFINED_STATE),
      );
    });
  }

  Widget _getAirportsListView(
      {required BuildContext context, required List<Airport> airports}) {
    final metarTafWidgets = <Widget>[];
    airports.forEach((airport) {
      metarTafWidgets.add(_getAirportMetarAndTafWidget(airport));
    });

    return Padding(
      padding: const EdgeInsets.all(8.0),
      // not using ListView. If airport off screen, listview won't draw and state
      // not processed.
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
          return SingleChildScrollView(
              child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.maxHeight,
            ),
            child: Column(
              children: metarTafWidgets,
            ),
          ));
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
    await Navigator.pushNamed(context, AirportsSearchRouteBuilder.routeName);
    _sendEvent(GetAirportMetarAndTafsEvent());
  }

  Future<void> _showSelectedAirports() async {
    await Navigator.pushNamed(context, SelectedAirportsRouteBuilder.routeName);
    _sendEvent(GetAirportMetarAndTafsEvent());
  }

  Widget _getAirportMetarAndTafWidget(Airport airport) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Container(
              width: MediaQuery.of(context).size.width,
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.blueAccent)),
              child: Column(
                children: [
                  _getAirportHeader(airport),
                  _getDivider(),
                  _getMetarOrTAFWidget(
                      ident: airport.ident, type: MetarOrTAF.METAR),
                  _getDivider(),
                  _getMetarOrTAFWidget(
                      ident: airport.ident, type: MetarOrTAF.TAF),
                ],
              )),
        ],
      ),
    );
  }

  Widget _getAirportHeader(Airport airport) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Row(
        children: [
          Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  airport.name,
                  overflow: TextOverflow.ellipsis,
                  style: textStyleBlackFontSize20,
                ),
              )),
          Expanded(
              flex: 2,
              child: Padding(
                child: Text(
                  airport.ident,
                  style: textStyleBlackFontSize18,
                ),
                padding: const EdgeInsets.only(left: 4.0),
              )),
          Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  "${MetarOrTAF.ELEV}:  ${airport.elevationFt} ${MetarOrTAF.FT}",
                  style: textStyleBlackFontSize18,
                ),
              ))
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
          _response = _getMetarOrTafResponse(state);
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
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4.0),
              child: Text(
                style: textStyleBoldBlackFontSize18,
                type,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _response,
                style: textStyleBlackFontSize14,
              ),
            ),
          ),
        ],
      );
    });
  }

  String _getMetarOrTafResponse(AirportMetarTafState airportMetarTafState) {
    final metarTafResponse = airportMetarTafState.metarTafResponse;
    if (metarTafResponse.returnStatus ?? false) {
      if (airportMetarTafState.type == MetarOrTAF.METAR) {
        return _formatMetarResponse(metarTafResponse.plainText);
      } else if (airportMetarTafState.type == MetarOrTAF.TAF) {
        return _formatTafResponse(metarTafResponse.plainText);
      }
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

  String _formatMetarResponse(String? plainText) {
    if (plainText != null) {
      return plainText
          .replaceFirst(". ", ".\n\n")
          .replaceFirst(" Remarks", "\n\nRemarks");
    } else {
      return MetarOrTAF.UNDEFINED_ERROR;
    }
  }

  String _formatTafResponse(String? plainText) {
    if (plainText != null) {
      return plainText
          .replaceFirst("Wind", "\n\nWind")
          .replaceAll(" From", '\n\nFrom');
    } else {
      return MetarOrTAF.UNDEFINED_ERROR;
    }
  }

  void _refreshTafAndMetars() {
    _sendEvent(GetAirportMetarAndTafsEvent());
  }

  Widget _getDivider() {
    return Padding(
      padding: EdgeInsets.only(left: 8.0, right: 8.0),
      child: Divider(
        height: 4,
        thickness: 2,
      ),
    );
  }
}
