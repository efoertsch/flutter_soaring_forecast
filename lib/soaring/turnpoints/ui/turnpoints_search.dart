import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/common/loading.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/show_turnpoint_error_dialog.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_list_view.dart';

//TODO - keep more data details in Bloc,
class TurnpointsSearchScreen extends StatefulWidget {
  final BuildContext repositoryContext;

  TurnpointsSearchScreen({Key? key, required this.repositoryContext})
      : super(key: key);

  @override
  State<TurnpointsSearchScreen> createState() => _TurnpointsSearchScreenState();
}

class _TurnpointsSearchScreenState extends State<TurnpointsSearchScreen>
    with AfterLayoutMixin<TurnpointsSearchScreen> {
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
        appBar: AppBar(actions: <Widget>[
          IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(
                    context: context,
                    delegate: TurnpointSearchDelegate(
                        turnpointBloc:
                            BlocProvider.of<TurnpointBloc>(context)));
              }),
        ]),
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
        }, buildWhen: (previous, current) {
          return current is TurnpointsLoadingState ||
              current is TurnpointsLoadedState;
        }, builder: (context, state) {
          if (state is TurnpointsLoadingState) {
            return buildLoading();
          }
          if (state is TurnpointsLoadedState) {
            return TurnpointListView(
                    context: context, turnpoints: state.turnpoints)
                .getTurnpoinListView();
          }
          return Container(
              child: Text('Hmm. Unhandled state in Turnpoints Search!'));
        }));
  }

  List<Widget> getTurnpointMenu() {
    return <Widget>[
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

//--------------------------------------------------------------------
// https://www.youtube.com/watch?v=2Ctffs0FEHA
// TODO More to it's own file after getting this going
class TurnpointSearchDelegate extends SearchDelegate<List> {
  late TurnpointBloc turnpointBloc;
  String queryString = '';

  TurnpointSearchDelegate({required this.turnpointBloc});

  @override
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    assert(theme != null);
    return theme;
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    // actions for app bar
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    //leading icon on left of the app bar
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, []); // example passes null rather than []
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }

  @override
  Widget buildResults(BuildContext context) {
    queryString = query; // query comes from abstract class
    // to do implement
    if (query.length < 3) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Text(
              "Search term must be longer than two letters.",
            ),
          )
        ],
      );
    }
    turnpointBloc.add(SearchTurnpointsEvent(queryString));
    return BlocBuilder<TurnpointBloc, TurnpointState>(
        bloc: turnpointBloc,
        builder: (BuildContext context, TurnpointState state) {
          if (state is SearchingTurnpointsState) {
            return buildLoading();
          }
          if (state is TurnpointsFoundState) {
            if (state.turnpoints.isEmpty) {
              return Center(
                child: Text('No turnpoints found.'),
              );
            }
            return new TurnpointListView(
                    context: context, turnpoints: state.turnpoints)
                .getTurnpoinListView();
          }
          if (state is TurnpointSearchErrorState) {
            return Center(
              child: Text('Oops. Error occurred reading turnpoint database.'),
            );
          }
          return Center(
            child: Text('Oops. Undefined search state.'),
          );
        });
  }
}
