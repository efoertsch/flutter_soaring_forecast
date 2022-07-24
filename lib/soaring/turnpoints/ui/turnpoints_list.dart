import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/main.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/cup/cup_styles.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_overhead_view.dart';
import 'package:permission_handler/permission_handler.dart';

import '../turnpoint_utils.dart';

class TurnpointsList extends StatefulWidget {
  final String? viewOption;
  static const String TASK_TURNPOINT_OPTION = 'TaskTurnpointOption';
  final List<Turnpoint> turnpointsForTask = [];
  String _searchString = "";
  bool _hasChanges = false;

  TurnpointsList({Key? key, String? this.viewOption = null}) : super(key: key);

  @override
  State<TurnpointsList> createState() => _TurnpointsListState();
}

class _TurnpointsListState extends State<TurnpointsList>
    with AfterLayoutMixin<TurnpointsList> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool typing = false;

  // Make sure first layout occurs
  @override
  void afterFirstLayout(BuildContext context) {
    BlocProvider.of<TurnpointBloc>(context).add(TurnpointListEvent());
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
    ;
  }

  Scaffold _buildScaffold(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: getAppBar(),
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
        }, buildWhen: (previous, current) {
          return current is TurnpointsInitialState ||
              current is SearchingTurnpointsState ||
              current is TurnpointsLoadedState ||
              current is TurnpointErrorState ||
              current is TurnpointSearchMessage ||
              current is TurnpointSearchErrorState;
        }, builder: (context, state) {
          if (state is TurnpointsInitialState) {
            return CommonWidgets.buildLoading();
          }

          if (state is SearchingTurnpointsState) {
            return CommonWidgets.buildLoading();
          }

          if (state is TurnpointsLoadedState) {
            if (state.turnpoints.isEmpty) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => CommonWidgets.showInfoDialog(
                        context: context,
                        msg: "No turnpoints found. Would you like to add some?",
                        title: "No Turnpoints",
                        button1Text: "No",
                        button1Function: _cancel,
                        button2Text: "Yes",
                        button2Function: _goToSeeYouImport,
                      ));
              return Center(
                child: Text('No turnpoints found.'),
              );
            }
            return _getTurnpointListView(
                context: context,
                turnpoints: state.turnpoints,
                cupStyles: state.cupStyles);
          }

          if (state is TurnpointErrorState) {
            WidgetsBinding.instance.addPostFrameCallback((_) =>
                CommonWidgets.showErrorDialog(
                    context, 'Turnpoints Error', state.errorMsg));
          }
          if (state is TurnpointSearchMessage) {
            return Center(
              child: Text(state.msg),
            );
          }
          if (state is TurnpointSearchErrorState) {
            return Center(
              child: Text(state.errorMsg),
            );
          }
          return Center(
            child: Text('Hmmm. Undefined state.'),
          );
        }));
  }

  AppBar getAppBar() {
    return AppBar(
        title: typing ? getSearchTextBox() : Text("Turnpoints"),
        leading: CommonWidgets.backArrowToHomeScreen(),
        actions: getTurnpointMenu());
  }

  Widget getSearchTextBox() {
    return Container(
      alignment: Alignment.centerLeft,
      color: Colors.white,
      child: TextField(
        onSubmitted: (searchString) {
          widget._searchString = searchString;
          BlocProvider.of<TurnpointBloc>(context)
              .add(SearchTurnpointsEvent(searchString));
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Enter a search term',
        ),
        // decoration:
        //     InputDecoration(border: InputBorder.none, hintText: 'Search'),
        autofocus: true,
      ),
    );
  }

  Widget _getTurnpointListView(
      {required BuildContext context,
      required List<Turnpoint> turnpoints,
      required List<Style> cupStyles}) {
    return ListView.separated(
      itemCount: turnpoints.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
          visualDensity: VisualDensity(horizontal: 0, vertical: -4),
          leading: IconButton(
            icon: Icon(Icons.location_searching),
            color: TurnpointUtils.getColorForTurnpointIcon(
                turnpoints[index].style),
            onPressed: () => Navigator.pushNamed(
              context,
              TurnpointView.routeName,
              arguments: TurnpointOverHeadArgs(turnpoint: turnpoints[index]),
            ),
          ),
          title: TextButton(
            onPressed: () {
              if (widget.viewOption == TurnpointsList.TASK_TURNPOINT_OPTION) {
                widget._searchString = "";
                widget._hasChanges = true;
                widget.turnpointsForTask.add(turnpoints[index]);
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                    CommonWidgets.getSnackBarForMessage(
                        turnpoints[index].title + ' added to task '));
              } else {
                _displayTurnpointDetails(context, turnpoints, index);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    turnpoints[index].code + '   ' + turnpoints[index].title,
                    textAlign: TextAlign.left,
                    style: textStyleBoldBlackFontSize20,
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    TurnpointUtils.getStyleDescriptionFromStyle(
                        cupStyles, turnpoints[index].style),
                    textAlign: TextAlign.left,
                    style: textStyleBoldBlack87FontSize15,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context, index) {
        return Divider();
      },
    );
  }

  Future<void> _displayTurnpointDetails(
      BuildContext context, List<Turnpoint> turnpoints, int index) async {
    var turnpoint = await Navigator.pushNamed(context, TurnpointEdit.routeName,
        arguments: turnpoints[index].id);
    if (turnpoint == null) {
      turnpoints.removeAt(index);
    } else {
      if (turnpoint is Turnpoint) {
        turnpoints.removeAt(index);
        turnpoints.insert(index, turnpoint);
        // setState(() {});
      }
    }
  }

  List<Widget> getTurnpointMenu() {
    return <Widget>[
      Visibility(
        visible: !typing,
        child: IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                typing = !typing;
              });
            }),
      ),
      Visibility(
        visible: typing,
        child: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              setState(() {
                typing = !typing;
                if (!typing) {
                  BlocProvider.of<TurnpointBloc>(context)
                      .add(TurnpointListEvent());
                }
              });
            }),
      ),
      Visibility(
        visible: !typing,
        child: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          onSelected: handleClick,
          itemBuilder: (BuildContext context) {
            return {
              TurnpointMenu.importTurnpoints,
              TurnpointMenu.addTurnpoint,
              TurnpointMenu.exportTurnpoints,
              TurnpointMenu.emailTurnpoints,
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
      case TurnpointMenu.searchTurnpoints:
        break;
      case TurnpointMenu.importTurnpoints:
        Navigator.pushNamed(context, TurnpointFileImport.routeName);
        break;
      case TurnpointMenu.addTurnpoint:
        _addNewTurnpoint();
        break;
      case TurnpointMenu.exportTurnpoints:
        _exportTurnpoints();
        break;
      case TurnpointMenu.emailTurnpoints:
        break;
      case TurnpointMenu.clearTurnpointDatabase:
        CommonWidgets.showTwoButtonAlertDialog(context,
            "Are you sure you want to delete all turnpoints in the database?",
            title: "No Turning Back If You Do!",
            cancelButtonText: "No",
            cancelButtonFunction: _cancel,
            continueButtonText: "Yes",
            continueButtonFunction: _sendDeleteTurnpointsEvent);

        break;
    }
  }

  Future<void> _addNewTurnpoint() async {
    await Navigator.pushNamed(context, TurnpointEdit.routeName,
        arguments: null);
  }

  Future<bool> _onWillPop() async {
    if (widget.viewOption == TurnpointsList.TASK_TURNPOINT_OPTION) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      Navigator.of(context).pop(widget.turnpointsForTask);
    } else {
      Navigator.of(context).pop();
    }
    return true;
  }

  _goToSeeYouImport() async {
    Navigator.of(context, rootNavigator: true).pop();
    var object =
        await Navigator.pushNamed(context, TurnpointFileImport.routeName);
    BlocProvider.of<TurnpointBloc>(context).add(TurnpointListEvent());
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

  _sendEvent(TurnpointEvent event) {
    BlocProvider.of<TurnpointBloc>(context).add(event);
  }

  void _exportTurnpoints() async {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      // We didn't ask for permission yet or the permission has been denied before but not permanently.
      if (await Permission.storage.request().isGranted) {
        // Fire event to export turnpoints
        _sendEvent(DownloadTurnpointsToFile());
      }
    }
    if (status.isPermanentlyDenied) {
      // display msg to user they need to go to settings to re-enable
      openAppSettings();
    }
    if (status.isGranted) {
      _sendEvent(DownloadTurnpointsToFile());
      ;
    }
  }
}
