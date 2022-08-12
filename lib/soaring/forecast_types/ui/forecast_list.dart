import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:flutter_soaring_forecast/soaring/forecast_types/bloc/forecast_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_types/bloc/forecast_event.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_types/bloc/forecast_state.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';

class ForecastListScreen extends StatelessWidget {
  ForecastListScreen({Key? key}) : super(key: key);
  late final BuildContext _context;

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<ForecastBloc>(context).add(ListForecastsEvent());
    _context = context;
    return Scaffold(
      appBar: AppBar(
        leading: CommonWidgets.backArrowToHomeScreen(),
        title: Text('Forecasts'),
        actions: _getForecastMenu(),
      ),
      body: BlocConsumer<ForecastBloc, ForecastState>(
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
                  SizedBox(height: 8),
                  _getForecastListView(context, state.forecasts),
                ],
              );
            }
          }
          if (state is ForecastErrorState) {
            WidgetsBinding.instance.addPostFrameCallback((_) =>
                CommonWidgets.showErrorDialog(
                    context, 'Forecast Error', state.errorMsg));
            return Center(
                child:
                    Text('Oops. Error occurred getting available forecasts.'));
          }
          return Center(child: Text("Unhandled State"));
        },
      ),
    );
  }

  Widget _getForecastListView(BuildContext context, List<Forecast> forecasts) {
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
    BlocProvider.of<ForecastBloc>(_context)
        .add(SwitchOrderOfForecastsEvent(oldItemIndex, newItemIndex));
  }

  _onListReorder(int oldListIndex, int newListIndex) {
    // don't have more that 1 list so no reorder
  }

  DragAndDropItem _createForecastItem(BuildContext context, Forecast forecast) {
    return DragAndDropItem(
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            flex: 10,
            child: Material(
              color: Colors.white.withOpacity(0.0),
              child: InkWell(
                onTap: () {
                  _showForecastDescription(context, forecast);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Add icon to display type of forecast thermal cloud, wave,..
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _getForecastDisplayNameAndIcon(forecast),
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
            ),
          ),
        ]),
      ),
    );
  }

  Row _getForecastDisplayNameAndIcon(Forecast forecast) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _getForecastIcon(forecast.forecastCategory.toString()),
        ),
        Expanded(
          child: Text(
            forecast.forecastNameDisplay,
            textAlign: TextAlign.left,
            softWrap: true,
            style: textStyleBlackFontSize20,
          ),
        ),
      ],
    );
  }

  Widget _getForecastIcon(String forecastCategory) {
    if (forecastCategory == ForecastCategory.THERMAL.toString()) {
      return Constants.thermalIcon;
    }
    if (forecastCategory == ForecastCategory.WIND.toString()) {
      return Constants.windIcon;
    }
    if (forecastCategory == ForecastCategory.WAVE.toString()) {
      return Constants.waveIcon;
    }
    if (forecastCategory == ForecastCategory.CLOUD.toString()) {
      return Constants.cloudIcon;
    }
    return Icon(Icons.help);
  }

  List<Widget> _getForecastMenu() {
    return <Widget>[
      TextButton(
        child: const Text('RESET', style: TextStyle(color: Colors.white)),
        onPressed: () {
          BlocProvider.of<ForecastBloc>(_context)
              .add(ResetForecastListToDefaultEvent());
        },
      ),
    ];
  }

  void _showForecastDescription(BuildContext context, Forecast forecast) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
              _getForecastDisplayNameAndIcon(forecast),
              Padding(
                padding: const EdgeInsets.only(
                    top: 16, left: 8.0, right: 8.0, bottom: 8.0),
                child: Text(forecast.forecastDescription,
                    style: textStyleBlackFontSize18),
              ),
              ElevatedButton(
                child: Text('Close'),
                onPressed: () => Navigator.pop(context),
              ),
            ]));
  }
}
