import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/airport/bloc/airport_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/airport/bloc/airport_event.dart';
import 'package:flutter_soaring_forecast/soaring/airport/bloc/airport_state.dart';
import 'package:flutter_soaring_forecast/soaring/airport/ui/common_airport_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show AirportLiterals, AirportMenu, StandardLiterals;
import 'package:flutter_soaring_forecast/soaring/app/upper_case_text_formatter.dart';
import 'package:flutter_soaring_forecast/soaring/floor/airport/airport.dart';

class AirportsSearch extends StatefulWidget {
  static const String PICK_ONE = "PICK_ONE";
  final List<Airport> airports = [];
  final String? option;

  AirportsSearch({Key? key, this.option = null}) : super(key: key);

  @override
  State<AirportsSearch> createState() => _AirportsSearchState();
}

class _AirportsSearchState extends State<AirportsSearch>
    with AfterLayoutMixin<AirportsSearch> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool typing = false;
  final airportsFromSearch = <Airport>[];

  // Make sure first layout occurs
  @override
  void afterFirstLayout(BuildContext context) {
    BlocProvider.of<AirportBloc>(context)
        .add(SeeIfAirportDownloadNeededEvent());
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
          current is AirportsErrorState ||
          current is AirportsBeingDownloadedState ||
          current is AirportsDownloadedOKState ||
          current is AirportsDownloadErrorState ||
          current is SeeIfOkToDownloadAirportsState;
    }, builder: (context, state) {
      if (state is AirportsInitialState) {
        return Center(
          child: Container(),
        );
      }
      if (state is AirportsBeingDownloadedState) {
        return Center(
          child: CircularProgressIndicator(),
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
      if (state is SeeIfOkToDownloadAirportsState) {
        WidgetsBinding.instance.addPostFrameCallback((_) =>
            CommonWidgets.showInfoDialog(
                context: context,
                title: AirportLiterals.DOWNLOAD_AIRPORTS,
                msg: AirportLiterals.NO_AIRPORTS_FOUND_MSG,
                button1Text: StandardLiterals.NO,
                button1Function: _cancel,
                button2Text: StandardLiterals.YES,
                button2Function: _downloadAirportsNow));
      }

      if (state is AirportsDownloadedOKState) {
        WidgetsBinding.instance.addPostFrameCallback((_) =>
            CommonWidgets.showInfoDialog(
                context: context,
                title: StandardLiterals.HURRAH,
                msg: AirportLiterals.DOWNLOAD_SUCCESSFUL,
                button1Text: StandardLiterals.OK,
                button1Function: _cancel));
      }

      if (state is AirportsDownloadErrorState) {
        WidgetsBinding.instance.addPostFrameCallback((_) =>
            CommonWidgets.showInfoDialog(
                context: context,
                title: StandardLiterals.UH_OH,
                msg: AirportLiterals.DOWNLOAD_UNSUCCESSFUL,
                button1Text: StandardLiterals.OK,
                button1Function: _cancel));
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
        actions: getSearchMenu());
  }

  List<Widget> getSearchMenu() {
    return <Widget>[
      PopupMenuButton<String>(
        icon: Icon(Icons.more_vert),
        onSelected: handleClick,
        itemBuilder: (BuildContext context) {
          return {
            AirportMenu.refresh,
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

  void handleClick(String value) {
    switch (value) {
      case AirportMenu.refresh:
        CommonWidgets.showInfoDialog(
            context: context,
            title: AirportLiterals.REFRESH_AIRPORTS,
            msg: AirportLiterals.CONFIRM_DELETE_RELOAD,
            button1Text: StandardLiterals.NO,
            button1Function: _cancel,
            button2Text: StandardLiterals.YES,
            button2Function: _downloadAirportsNow);

        break;
    }
  }

  Widget _getSearchTextBox() {
    return Container(
      alignment: Alignment.centerLeft,
      color: Colors.white,
      child: TextField(
        onChanged: (searchString) {
          if (searchString.length >= 2) {
            BlocProvider.of<AirportBloc>(context)
                .add(SearchAirportsEvent(searchString));
          }
        },
        inputFormatters: [UpperCaseTextFormatter()],
        textCapitalization: TextCapitalization.characters,
        enableSuggestions: false,
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
        if (widget.option == AirportsSearch.PICK_ONE) {
          Navigator.pop(context, airports[index].ident);
          return;
        }
        _sendEvent(AddAirportToSelectListEvent(airports[index]));
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
            CommonWidgets.getSnackBarForMessage(
                airports[index].ident + ' added to list.'));
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

  _cancel() {
    Navigator.of(context).pop();
  }

  _downloadAirportsNow() {
    Navigator.of(context).pop();
    _sendEvent(DownloadAirportsNowEvent());
  }
}
