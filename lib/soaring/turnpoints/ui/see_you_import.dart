import 'package:after_layout/after_layout.dart';
import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/main.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';

import '../../app/constants.dart';

class SeeYouImportScreen extends StatefulWidget {
  SeeYouImportScreen({Key? key}) : super(key: key);

  @override
  _SeeYouImportScreenState createState() => _SeeYouImportScreenState();
}

class _SeeYouImportScreenState extends State<SeeYouImportScreen>
    with AfterLayoutMixin<SeeYouImportScreen> {
// Make sure first layout occurs prior to map ready otherwise crash occurs
  @override
  void afterFirstLayout(BuildContext context) {
    BlocProvider.of<TurnpointBloc>(context).add(GetTurnpointFileNamesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalWillPopScope(
      onWillPop: _onWillPop,
      shouldAddCallback: true,
      child: Scaffold(
          appBar: AppBar(
              leading: CommonWidgets.backArrowToHomeScreen(),
              title: Text('Turnpoint Import'),
              actions: getTurnpointMenu()),
          body: BlocConsumer<TurnpointBloc, TurnpointState>(
              listener: (context, state) {
            //TODO handle error msg
            if (state is TurnpointShortMessageState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green,
                  content: Text(state.shortMsg),
                ),
              );
            }
          }, buildWhen: (previous, current) {
            return current is TurnpointsInitialState ||
                current is TurnpointFilesFoundState ||
                current is TurnpointErrorState;
          }, builder: (context, state) {
            if (state is TurnpointFilesFoundState) {
              if (state.turnpointFiles.isEmpty) {
                return Center(
                  child: Text('No turnpoint files found.'),
                );
              }
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                      child: Center(
                        child: Text(
                          "Available Turnpoint Files",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontSize: 24),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: state.turnpointFiles.length,
                        itemBuilder: (BuildContext context, int index) {
                          final turnpointFile = state.turnpointFiles[index];
                          return ListTile(
                            onTap: () {
                              _sendEvent(LoadTurnpointFileEvent(turnpointFile));
                            },
                            dense: true,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8.0),
                            visualDensity:
                                VisualDensity(horizontal: 0, vertical: -4),
                            title: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  turnpointFile.state,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 20),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        turnpointFile.location,
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 20),
                                      ),
                                      Text(
                                        turnpointFile.date,
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 20),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (context, index) {
                          return Divider();
                        },
                      ),
                    ),
                  ]);
            }
            if (state is TurnpointErrorState) {
              WidgetsBinding.instance.addPostFrameCallback((_) =>
                  CommonWidgets.showErrorDialog(
                      context, 'Turnpoints Error', state.errorMsg));
            }
            if (state is TurnpointsInitialState) {
              print('returning CircularProgressIndicator');
              return Center(child: CircularProgressIndicator());
            }
            return Center(
              child: Text('Hmmm. Undefined state.'),
            );
          })),
    );
  }

  List<Widget> getTurnpointMenu() {
    return <Widget>[
      PopupMenuButton<String>(
        icon: Icon(Icons.more_vert),
        onSelected: handleClick,
        itemBuilder: (BuildContext context) {
          return {
            TurnpointMenu.clearTurnpointDatabase,
            TurnpointMenu.customImport,
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
      case TurnpointMenu.clearTurnpointDatabase:
        CommonWidgets.showInfoDialog(
            context: context,
            title: "No Turning Back If You Do!",
            msg:
                "Are you sure you want to delete all turnpoints in the database?",
            button1Text: "No",
            button1Function: _cancel,
            button2Text: "Yes",
            button2Function: _sendDeleteTurnpointsEvent);
        break;
      case TurnpointMenu.customImport:
        _goToCustomSeeYouImport();
        break;
    }
  }

  Future<bool> _onWillPop() async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    Navigator.of(context).popUntil((route) => route.isFirst);
    return true;
  }

  void _goToCustomSeeYouImport() async {
    await Navigator.pushNamed(context, CustomTurnpointFileImport.routeName);
  }

  _cancel() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // Function used in dialog (where you can't use _sendEvent as function directly
  // as it get immediately executed.
  _sendDeleteTurnpointsEvent() {
    Navigator.of(context, rootNavigator: true).pop();
    _sendEvent(DeleteAllTurnpointsEvent());
  }

  void _sendEvent(TurnpointEvent event) {
    BlocProvider.of<TurnpointBloc>(context).add(event);
  }
}
