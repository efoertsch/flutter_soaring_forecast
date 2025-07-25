import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/fileutils/file_utils.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/cup/cup_styles.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_edit_view.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_overhead_view.dart';
import 'package:permission_handler/permission_handler.dart';

import '../turnpoint_utils.dart';

class TurnpointsList extends StatefulWidget {
  final String? viewOption;
  static const String TASK_TURNPOINT_OPTION = 'TaskTurnpointOption';
  final List<Turnpoint> turnpointsForTask = [];

  TurnpointsList({Key? key, String? this.viewOption = null}) : super(key: key);

  @override
  State<TurnpointsList> createState() => _TurnpointsListState();
}

class _TurnpointsListState extends State<TurnpointsList>
    with AfterLayoutMixin<TurnpointsList> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool typing = false;
  String _searchString = "";

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
    return BlocConsumer<TurnpointBloc, TurnpointState>(
        listener: (context, state) {
      if (state is TurnpointShortMessageState) {
        CommonWidgets.showInfoDialog(
            context: context,
            title: TurnpointMenu.turnpoints,
            msg: state.shortMsg,
            button1Text: StandardLiterals.OK,
            button1Function: Navigator.of(context).pop);
      }
      // if (state is TempTurnpointsDownloadDirectory ){
      //    _downloadTurnpointsToFinalDirectory(state.tempFile);
      // }
    }, buildWhen: (previous, current) {
      return current is TurnpointsInitialState ||
          current is SearchingTurnpointsState ||
          current is TurnpointsLoadedState ||
          current is TurnpointErrorState ||
          current is TurnpointSearchMessageState ||
          current is TurnpointSearchErrorState;
    }, builder: (context, state) {
      if (state is TurnpointsInitialState) {
        return CommonWidgets.buildLoading();
      }

      if (state is TurnpointsLoadedState) {
        if (state.turnpoints.isEmpty && _searchString.isEmpty) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => CommonWidgets.showInfoDialog(
                    context: context,
                    msg: "No turnpoints found. Would you like to add some?",
                    title: "No Turnpoints",
                    button1Text: "No",
                    button1Function: _cancel,
                    button2Text: "Yes",
                    button2Function: _goToSeeYouImportFromDialog,
                  ));
          return Center(
            child: Text('No turnpoints found.'),
          );
        }
        if (state.turnpoints.isEmpty) {
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
      if (state is TurnpointSearchMessageState) {
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
    });
  }

  AppBar _getAppBar() {
    return AppBar(
        title: typing ? _getSearchTextBox() : Text("Turnpoints"),
        leading: BackButton(
          onPressed: _onWillPop,
        ),
        actions: getTurnpointMenu());
  }

  Widget _getSearchTextBox() {
    return Container(
      alignment: Alignment.centerLeft,
      color: Colors.white,
      child: TextField(
        onChanged: (searchString) {
          _searchString = searchString;
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
      required List<CupStyle> cupStyles}) {
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
              TurnpointViewRouteBuilder.routeName,
              arguments: TurnpointOverHeadArgs(turnpoint: turnpoints[index]),
            ),
          ),
          title: TextButton(
            onPressed: () {
              if (widget.viewOption == TurnpointsList.TASK_TURNPOINT_OPTION) {
                _searchString = "";
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
    var value = await Navigator.pushNamed(
        context, TurnpointEditRouteBuilder.routeName,
        arguments: turnpoints[index].id);
    processTurnpointEditResult(value);
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
              //TurnpointMenu.emailTurnpoints,
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
        _goToSeeYouImport();
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

  Future<void> _addNewTurnpoint() async {
    var object = await Navigator.pushNamed(
        context, TurnpointEditRouteBuilder.routeName);
    processTurnpointEditResult(object);
  }

  void processTurnpointEditResult(Object? object) {
    if (object is TurnpointEditResult) {
      if (object.returnResult == TurnpointEditReturn.noChange) {
        return;
      } else {
        // refresh list
        BlocProvider.of<TurnpointBloc>(context).add(TurnpointListEvent());
        return;
      }
    }
    return;
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

  void _goToSeeYouImportFromDialog() async {
    // Remove dialog
    Navigator.of(context).pop();
    _goToSeeYouImport();
  }

  void _goToSeeYouImport() async {
    var object = await Navigator.pushNamed(
        context, TurnpointFileImportRouteBuilder.routeName);
      BlocProvider.of<TurnpointBloc>(context).add(TurnpointListEvent());
    if (object is bool && object) {
      BlocProvider.of<TurnpointBloc>(context).add(TurnpointListEvent());
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

  _sendEvent(TurnpointEvent event) {
    BlocProvider.of<TurnpointBloc>(context).add(event);
  }

  void _exportTurnpoints() async {
    checkFileAccess(
        permissionGrantedFunction: _sendDownloadTurnpointsToFileEvent,
        requestPermissionFunction: _openAppSettingsFunction,
        permissionDeniedFunction: _openAppSettingsFunction);
  }
  void _sendDownloadTurnpointsToFileEvent() {
    _sendEvent(DownloadTurnpointsToFile());
  }

  Future<void> _openAppSettingsFunction() async {
    await openAppSettings();
  }

  // void _downloadTurnpointsToFinalDirectory(File tempFile) async {
  //   if (!await FlutterFileDialog.isPickDirectorySupported()) {
  //     if (context.mounted) {
  //       CommonWidgets.showInfoDialog(
  //           context: context,
  //           title: "Download Error",
  //           msg: "Picking directory not supported",
  //           button1Text: StandardLiterals.OK,
  //           button1Function: Navigator
  //               .of(context)
  //               .pop);
  //       return;
  //     }
  //   }
  //   DirectoryLocation? pickedDirectory = await FlutterFileDialog.pickDirectory();
  //   if (pickedDirectory != null) {
  //      await FlutterFileDialog.saveFileToDirectory(
  //       directory: pickedDirectory,
  //       data: tempFile.readAsBytesSync(),
  //       mimeType: "text/plain",
  //       fileName: tempFile.path.split('/').last,
  //       replace: true,
  //     );
  //   }
  // }


}
