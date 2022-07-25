import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';
import 'package:path/path.dart' hide context;

import '../../app/constants.dart';

//TODO implement once you can get to Downloads directory and/or implement equivalent logic
// (current libraries don't support read/write access to download directory
class CustomSeeYouImportScreen extends StatefulWidget {
  CustomSeeYouImportScreen({Key? key}) : super(key: key);

  @override
  _CustomSeeYouImportScreenState createState() =>
      _CustomSeeYouImportScreenState();
}

class _CustomSeeYouImportScreenState extends State<CustomSeeYouImportScreen>
    with AfterLayoutMixin<CustomSeeYouImportScreen> {
// Make sure first layout occurs prior to map ready otherwise crash occurs
  @override
  void afterFirstLayout(BuildContext context) {
    _sendEvent(GetCustomImportFileNamesEvent());
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return ConditionalWillPopScope(
        onWillPop: _onWillPop,
        shouldAddCallback: true,
        child: _buildScaffold(context),
      );
    } else {
      //iOS
      return GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.direction >= 0) {
            _onWillPop();
          }
        },
        child: _buildScaffold(context),
      );
    }
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
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
          },
          buildWhen: (previous, current) {
            return current is TurnpointsInitialState ||
                current is CustomTurnpointFileList ||
                current is TurnpointErrorState;
          },
          builder: (context, state) {
            if (state is CustomTurnpointFileList) {
              if (state.customTurnpointFiles.isEmpty) {
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
                        itemCount: state.customTurnpointFiles.length,
                        itemBuilder: (BuildContext context, int index) {
                          final fileName =
                              basename(state.customTurnpointFiles[index].path);
                          return ListTile(
                            onTap: () {
                              _sendEvent(LoadCustomTurnpointFileEvent(
                                  state.customTurnpointFiles[index]));
                            },
                            dense: true,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8.0),
                            visualDensity:
                                VisualDensity(horizontal: 0, vertical: -4),
                            title: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      _sendEvent(ImportTurnpointsFromFileEvent(
                                          state.customTurnpointFiles[index]));
                                    },
                                    child: Text(
                                      fileName,
                                      maxLines: 2,
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 20),
                                    ),
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
          },
        ));
  }

  List<Widget> getTurnpointMenu() {
    return <Widget>[
      PopupMenuButton<String>(
        icon: Icon(Icons.more_vert),
        onSelected: _handleMenuClick,
        itemBuilder: (BuildContext context) {
          return {
            TurnpointMenu.clearTurnpointDatabase,
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

  void _handleMenuClick(String value) {
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
    }
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

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop();
    return true;
  }
}
