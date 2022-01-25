import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_list_view.dart';

//TODO - keep more data details in Bloc,
class TurnpointsSearchInAppBarScreen extends StatefulWidget {
  final BuildContext repositoryContext;

  TurnpointsSearchInAppBarScreen({Key? key, required this.repositoryContext})
      : super(key: key);

  @override
  State<TurnpointsSearchInAppBarScreen> createState() =>
      _TurnpointsSearchInAppBarScreenState();
}

class _TurnpointsSearchInAppBarScreenState
    extends State<TurnpointsSearchInAppBarScreen>
    with AfterLayoutMixin<TurnpointsSearchInAppBarScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool typing = false;

  // Make sure first layout occurs
  @override
  void afterFirstLayout(BuildContext context) {
    BlocProvider.of<TurnpointBloc>(context).add(TurnpointListEvent());
  }

  @override
  Widget build(BuildContext context) {
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
        }, builder: (context, state) {
          if (state is TurnpointsLoadingState) {
            return CommonWidgets.buildLoading();
          }
          if (state is TurnpointsLoadedState) {
            return TurnpointListView(
                    context: context, turnpoints: state.turnpoints)
                .getTurnpoinListView();
          }
          if (state is SearchingTurnpointsState) {
            return CommonWidgets.buildLoading();
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
          if (state is TurnpointErrorState) {
            WidgetsBinding.instance?.addPostFrameCallback((_) =>
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
              child: Text(
                  'Oops. Error occurred searching the turnpoint database.'),
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
        child: RotatedBox(
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
      ),
    ];
  }

  void handleClick(String value) {
    switch (value) {
      case TurnpointMenu.searchTurnpoints:
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
