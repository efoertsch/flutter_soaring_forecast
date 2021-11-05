import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';

class TurnpointSearchScreen extends StatefulWidget {
  final BuildContext repositoryContext;

  TurnpointSearchScreen({Key? key, required this.repositoryContext})
      : super(key: key);

  @override
  _TurnpointSearchScreenState createState() => _TurnpointSearchScreenState();
}

//TODO - keep more data details in Bloc,
class _TurnpointSearchScreenState extends State<TurnpointSearchScreen>
    with AfterLayoutMixin<TurnpointSearchScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

// Make sure first layout occurs prior to map ready otherwise crash occurs
  @override
  void afterFirstLayout(BuildContext context) {
    BlocProvider.of<TurnpointBloc>(context).add(TurnpointSearchInitialEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('Turnpoints'),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.list), onPressed: null),
          ],
        ),
        body: BlocConsumer<TurnpointBloc, TurnpointState>(
            listener: (context, state) {
          if (state is TurnpointsLoadErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.green,
                content: Text(state.error),
              ),
            );
          }
        }, buildWhen: (previous, current) {
          return current is TurnpointInitialState ||
              current is TurnpointsLoadingState ||
              current is TurnpointsLoadErrorState ||
              current is TurnpointsDownloadingState ||
              current is TurnpointSearchResultsState;
        }, builder: (context, state) {
          if (state is TurnpointInitialState ||
              state is TurnpointsLoadingState ||
              state is TurnpointsLoadErrorState ||
              state is TurnpointsDownloadingState) {
            print('returning CircularProgressIndicator');
            return Center(child: CircularProgressIndicator());
          }
          var turnpointSearchResultsState =
              state as TurnpointSearchResultsState;
          return new ListView.builder(
              itemCount: turnpointSearchResultsState.turnpoints.length,
              itemBuilder: (BuildContext context, int index) {
                return Text(turnpointSearchResultsState.turnpoints[index].code);
              });
        }));
  }
}
