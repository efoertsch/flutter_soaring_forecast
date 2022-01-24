import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/main.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';

import '../turnpoint_utils.dart';

class SeeYouImportScreen extends StatefulWidget {
  final BuildContext repositoryContext;

  SeeYouImportScreen({Key? key, required this.repositoryContext})
      : super(key: key);

  @override
  _SeeYouImportScreenState createState() => _SeeYouImportScreenState();
}

//TODO - keep more data details in Bloc,
class _SeeYouImportScreenState extends State<SeeYouImportScreen>
    with AfterLayoutMixin<SeeYouImportScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

// Make sure first layout occurs prior to map ready otherwise crash occurs
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
          actions: <Widget>[
            IconButton(icon: Icon(Icons.list), onPressed: null),
          ],
        ),
        body: BlocConsumer<TurnpointBloc, TurnpointState>(
            listener: (context, state) {
          if (state is TurnpointErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.green,
                content: Text(state.errorMsg),
              ),
            );
          }
        }, buildWhen: (previous, current) {
          return current is TurnpointsLoadingState ||
              current is TurnpointErrorState ||
              current is TurnpointsDownloadingState ||
              current is TurnpointsLoadedState;
        }, builder: (context, state) {
          if (state is! TurnpointsLoadedState) {
            print('returning CircularProgressIndicator');
            return Center(child: CircularProgressIndicator());
          }
          return new ListView.separated(
            itemCount: state.turnpoints.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                leading: IconButton(
                  icon: Icon(Icons.location_searching),
                  color: TurnpointUtils.getColorForTurnpointIcon(
                      state.turnpoints[index]),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    TurnpointView.routeName,
                    arguments: state.turnpoints[index],
                  ),
                ),
                title: TextButton(
                  onPressed: () => print('clicked text'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          state.turnpoints[index].code +
                              '   ' +
                              state.turnpoints[index].title,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 20),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          TurnpointUtils.getStyleName(
                              state.turnpoints[index].style),
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 15),
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
}
