import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/fileutils/file_utils.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

import '../../app/constants.dart';
import '../../app/web_launcher.dart';

class SeeYouImportScreen extends StatefulWidget {
  SeeYouImportScreen({Key? key}) : super(key: key);

  @override
  _SeeYouImportScreenState createState() => _SeeYouImportScreenState();
}

class _SeeYouImportScreenState extends State<SeeYouImportScreen>
    with AfterLayoutMixin<SeeYouImportScreen> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _isLoading = false;
  bool _userAborted = false;
  Widget _resultsWidget = const Row();

  bool importedTurnpoints = false;

// Make sure first layout occurs prior to map ready otherwise crash occurs
  @override
  void afterFirstLayout(BuildContext context) {
    BlocProvider.of<TurnpointBloc>(context).add(GetTurnpointFileNamesEvent());
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
      child: Scaffold(appBar: _getAppBar(), body: _getBody()),
    );
  }

  AppBar _getAppBar() {
    return AppBar(
        leading: BackButton(
          onPressed: _onWillPop,
        ),
        title: Text(TurnpointMenu.turnpointImport),
        actions: _getTurnpointMenu());
  }

  BlocConsumer<TurnpointBloc, TurnpointState> _getBody() {
    return BlocConsumer<TurnpointBloc, TurnpointState>(
        listener: (context, state) {
      if (state is TurnpointShortMessageState) {
        CommonWidgets.showInfoDialog(
            context: context,
            title: TurnpointMenu.importTurnpoints,
            msg: state.shortMsg,
            button1Text: StandardLiterals.OK,
            button1Function: Navigator.of(context).pop);
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     backgroundColor: Colors.green,
        //     content: Text(state.shortMsg),
        //   ),
        // );
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
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                    importedTurnpoints = true;
                  },
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                  visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        turnpointFile.state,
                        textAlign: TextAlign.left,
                        style: TextStyle(color: Colors.black, fontSize: 20),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              turnpointFile.description,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  color: Colors.black87, fontSize: 20),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                turnpointFile.date,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    color: Colors.black87, fontSize: 20),
                              ),
                            )
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
    });
  }

  List<Widget> _getTurnpointMenu() {
    return <Widget>[
      PopupMenuButton<String>(
        icon: Icon(Icons.more_vert),
        onSelected: _handleClick,
        itemBuilder: (BuildContext context) {
          return {
            TurnpointMenu.turnpointExchange,
            TurnpointMenu.customImport,
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

  void _handleClick(String value) {
    switch (value) {
      case TurnpointMenu.turnpointExchange:
        _goToWorldWideTurnpointExchange();
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
      case TurnpointMenu.customImport:
        //checkForCustomImportPermission();
        _pickFiles();
        break;
    }
  }

  Future<bool> _onWillPop() async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    Navigator.pop(context, importedTurnpoints);
    return true;
  }

  void _checkForCustomImportPermission() async {
    checkFileAccess(
        permissionGrantedFunction: _goToCustomSeeYouImport,
        requestPermissionFunction: _openAppSettingsFunction,
        permissionDeniedFunction: _openAppSettingsFunction);
  }

  void _goToCustomSeeYouImport() async {
    await Navigator.pushNamed(
        context, CustomTurnpointFileImportRouteBuilder.routeName);
    debugPrint("returned from CustomTurnpointFileImport");
  }

  Future<void> _openAppSettingsFunction() async {
    await openAppSettings();
  }

  _cancel() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // Function used in dialog (where you can't use _sendEvent as function directly
  // as it get immediately executed.
  _sendDeleteTurnpointsEvent() {
    Navigator.of(context, rootNavigator: true).pop();
    _sendEvent(DeleteAllTurnpointsEvent(refreshList: false));
  }

  void _sendEvent(TurnpointEvent event) {
    BlocProvider.of<TurnpointBloc>(context).add(event);
  }

  void _pickFiles() async {
    bool hasUserAborted = true;
    List<PlatformFile>? pickedFiles;
    try {
      pickedFiles = (await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        onFileLoading: (FilePickerStatus status) =>
            debugPrint(status.toString()),
        //allowedExtensions: <String>["cup"],
        dialogTitle: "Select CUP File",
        lockParentWindow: true,
        withData: false,
      ))
          ?.files;
      hasUserAborted = pickedFiles == null;
    } on PlatformException catch (e) {
      _logException('Unsupported operation: $e');
    } catch (e) {
      _logException(e.toString());
    }
    if (!mounted) return;

    if (!hasUserAborted) {
      _sendEvent(ImportTurnpointsFromFileEvent(File(pickedFiles!.first.path.toString())));
    } else {
      CommonWidgets.showInfoDialog(
          context: context,
          title: TurnpointMenu.importTurnpoints,
          msg: "No turnpoint file selected",
          button1Text: StandardLiterals.OK,
          button1Function: Navigator.of(context).pop);
    }
  }

  Widget _buildFilePickerResultsWidget({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.50,
      child: ListView.separated(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      ),
    );
  }

  void _logException(String message) {
    debugPrint(message);
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _goToWorldWideTurnpointExchange() {
    launchWebBrowser(TURNPOINTS_URL, "TP");
  }
}
