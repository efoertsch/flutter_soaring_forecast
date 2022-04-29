import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';

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
    return Scaffold(
        appBar: AppBar(
          leading: CommonWidgets.backArrowToHomeScreen(),
          title: Text('Turnpoint Import'),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.list), onPressed: null),
          ],
        ),
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      turnpointFile.location,
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          color: Colors.black87, fontSize: 20),
                                    ),
                                    Text(
                                      turnpointFile.date,
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          color: Colors.black87, fontSize: 20),
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
            WidgetsBinding.instance?.addPostFrameCallback((_) =>
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
        }));
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

  void _sendEvent(TurnpointEvent event) {
    BlocProvider.of<TurnpointBloc>(context).add(event);
  }
}
