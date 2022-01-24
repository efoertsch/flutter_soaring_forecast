import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/main.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/show_turnpoint_error_dialog.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_list_view.dart';

class TurnpointListScreen extends StatefulWidget {
  final BuildContext repositoryContext;

  TurnpointListScreen({Key? key, required this.repositoryContext})
      : super(key: key);

  @override
  _TurnpointListScreenState createState() => _TurnpointListScreenState();
}

//TODO - keep more data details in Bloc,
class _TurnpointListScreenState extends State<TurnpointListScreen>
    with AfterLayoutMixin<TurnpointListScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

// Make sure first layout occurs
  @override
  void afterFirstLayout(BuildContext context) {
    BlocProvider.of<TurnpointBloc>(context).add(TurnpointListEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: CommonWidgets.backArrowToHomeScreen(),
        title: Text('Turnpoints'),
        actions: getTurnpointMenu(),
      ),
      body: BlocConsumer<TurnpointBloc, TurnpointState>(
        listener: (context, state) {
          if (state is TurnpointShortMessageState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.green,
                content: Text(state.shortMsg),
              ),
            );
          }
          if (state is TurnpointErrorState) {
            TurnpointsDialogs.showTurnpointErrorDialog(context, state.errorMsg);
          }
        },
        buildWhen: (previous, current) {
          return current is TurnpointsLoadingState ||
              current is TurnpointsDownloadingState ||
              current is TurnpointsLoadedState;
        },
        builder: (context, state) {
          if (state is TurnpointsLoadingState) {
            print('returning CircularProgressIndicator');
            return Center(child: CircularProgressIndicator());
          }
          if (state is TurnpointsLoadedState) {
            return TurnpointListView(
                    context: context, turnpoints: state.turnpoints)
                .getTurnpoinListView();
          }

          return Center(child: Text("Unhandled State"));
        },
      ),
    );
  }

  Future<void> _showNoTurnpointsFoundDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('AlertDialog Title'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                    'No turnpoints found in database.\n Would you like to add some?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('NO'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('YES'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }



  List<Widget> getTurnpointMenu() {
    return <Widget>[
      IconButton(
        icon: Icon(Icons.search),
        onPressed: () {
          Navigator.pushNamed(context, TurnpointSearchList.routeName);
        },
      ),
      RotatedBox(
        quarterTurns: 1,
        child: PopupMenuButton<String>(
          onSelected: handleClick,
          itemBuilder: (BuildContext context) {
            return {
              TurnpointMenu.importTurnpoints,
              TurnpointMenu.addTurnpoint,
              TurnpointMenu.exportTurnpoint,
              TurnpointMenu.emailTurnpoint,
              TurnpointMenu.clearTurnpointDatabase
            }.map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          },
        ),
      ),
    ];
  }

  void handleClick(String value) {
    switch (value) {
      case RaspMenu.clearTask:
        break;
      case TurnpointMenu.importTurnpoints:
        break;
      case TurnpointMenu.addTurnpoint:
        break;
      case TurnpointMenu.exportTurnpoint:
        break;
      case TurnpointMenu.emailTurnpoint:
        break;
      case TurnpointMenu.clearTurnpointDatabase:
        break;
    }
  }
}
