import 'dart:io';

import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_types/bloc/forecast_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_types/bloc/forecast_event.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_types/bloc/forecast_state.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_types/ui/common_forecast_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ForecastListArgs {
  Forecast? forecast;

  ForecastListArgs({
    this.forecast = null,
  });
}

class ReturnedForecastArgs {
  bool reorderedForecasts;
  Forecast? forecast;

  ReturnedForecastArgs({this.reorderedForecasts = false, this.forecast = null});
}

class ForecastListScreen extends StatefulWidget {
  final ForecastListArgs? forecastArgs;

  ForecastListScreen({Key? key, this.forecastArgs}) : super(key: key);

  @override
  State<ForecastListScreen> createState() => _ForecastListScreenState();
}

class _ForecastListScreenState extends State<ForecastListScreen> {
  bool _reorderedList = false;
  Forecast? _selectedForecast = null;
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<ForecastBloc>(context).add(ListForecastsEvent());
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: CommonWidgets.backArrowToHomeScreen(),
          title: Text('Forecasts'),
          actions: _getForecastMenu(),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: BlocConsumer<ForecastBloc, ForecastState>(
              listener: (context, state) {
                if (state is ForecastShortMessageState) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(state.shortMsg),
                    ),
                  );
                }
                if (state is ForecastErrorState) {
                  CommonWidgets.showErrorDialog(
                      context, 'Forecast Error', state.errorMsg);
                }
              },
              buildWhen: (previous, current) {
                return current is ForecastsLoadingState ||
                    current is ListOfForecastsState;
              },
              builder: (context, state) {
                if (state is ForecastsLoadingState) {
                  return CommonWidgets.buildLoading();
                }
                if (state is ListOfForecastsState) {
                  if (state.forecasts.length == 0) {
                    return Center(child: Text("Oh-oh! No Forecasts Found!"));
                  } else {
                    return Column(
                      children: [
                        _getCorrectListView(context, state.forecasts),
                      ],
                    );
                  }
                }
                if (state is ForecastErrorState) {
                  WidgetsBinding.instance.addPostFrameCallback((_) =>
                      CommonWidgets.showErrorDialog(
                          context, 'Forecast Error', state.errorMsg));
                  return Center(
                      child: Text(
                          'Oops. Error occurred getting available forecasts.'));
                }
                return Center(child: Text("Unhandled State"));
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _getCorrectListView(BuildContext context, List<Forecast> forecasts) {
    if (widget.forecastArgs != null && widget.forecastArgs!.forecast != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        itemScrollController.jumpTo(
            index: forecasts.indexOf(widget.forecastArgs!.forecast!));
      });
      return _getScrollToPositionListView(context, forecasts);
    }
    return _getDragAndDropListView(context, forecasts);
  }

  Widget _getScrollToPositionListView(
      BuildContext context, List<Forecast> forecasts) {
    return Expanded(
      flex: 15,
      child: Align(
        alignment: Alignment.topLeft,
        child: ScrollablePositionedList.builder(
          shrinkWrap: true,
          itemCount: forecasts.length,
          itemBuilder: (context, index) => _getForecastDisplayRow(
              context: context,
              forecast: forecasts[index],
              onTapText: () => _returnSelectedForecast(forecasts[index])),
          itemScrollController: itemScrollController,
          itemPositionsListener: itemPositionsListener,
        ),
      ),
    );
  }

  Widget _getDragAndDropListView(
      BuildContext context, List<Forecast> forecasts) {
    List<DragAndDropList> forecastDragAndDropList = [];
    List<DragAndDropItem> forecastDragAndDropItems = [];
    forecasts.forEach((forecast) {
      forecastDragAndDropItems.add(_createForecastItem(context, forecast));
    });
    forecastDragAndDropList
        .add(DragAndDropList(children: forecastDragAndDropItems));
    return Expanded(
      flex: 15,
      child: Align(
        alignment: Alignment.topLeft,
        child: DragAndDropLists(
          children: forecastDragAndDropList,
          onItemReorder: _onItemReorder,
          onListReorder: _onListReorder,
        ),
      ),
    );
  }

  _onItemReorder(
      int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
    _reorderedList = true;
    BlocProvider.of<ForecastBloc>(context)
        .add(SwitchOrderOfForecastsEvent(oldItemIndex, newItemIndex));
  }

  _onListReorder(int oldListIndex, int newListIndex) {
    // don't have more that 1 list so no reorder
  }

  DragAndDropItem _createForecastItem(BuildContext context, Forecast forecast) {
    return DragAndDropItem(
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: _getForecastDisplayRow(context: context, forecast: forecast),
      ),
    );
  }

  Row _getForecastDisplayRow(
      {required BuildContext context,
      required Forecast forecast,
      Function? onTapText = null}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(
        flex: 10,
        child: Material(
          color: Colors.white.withOpacity(0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add icon to display type of forecast thermal cloud, wave,..
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CommonForecastWidgets.getForecastDisplayNameAndIcon(
                    forecast,
                    onTapIcon: (() => CommonForecastWidgets
                        .showForecastDescriptionBottomSheet(context, forecast)),
                    onTapText: (() => onTapText != null ? onTapText() : null)),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                indent: 0,
                endIndent: 0,
                color: Colors.black12,
              ),
            ],
          ),
        ),
      )
    ]);
  }

  List<Widget> _getForecastMenu() {
    return <Widget>[
      TextButton(
        child: const Text('RESET', style: TextStyle(color: Colors.white)),
        onPressed: () {
          BlocProvider.of<ForecastBloc>(context)
              .add(ResetForecastListToDefaultEvent());
        },
      ),
    ];
  }

  Future<bool> _onWillPop() async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    Navigator.of(context).pop(ReturnedForecastArgs(
        reorderedForecasts: _reorderedList, forecast: _selectedForecast));
    return true;
  }

  void _returnSelectedForecast(forecast) {
    _selectedForecast = forecast;
    _onWillPop();
  }
}
