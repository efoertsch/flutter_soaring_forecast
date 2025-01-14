// Display description of forecast types (eq. 'Thermal Updraft Velocity (W*)' for wstar)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;

import '../../../../main.dart';
import '../../../app/custom_styles.dart';
import '../../../forecast_types/ui/common_forecast_widgets.dart';
import '../../../forecast_types/ui/forecast_list.dart';
import '../../../repository/rasp/forecast_types.dart';
import '../../bloc/rasp_bloc.dart';


class SelectedForecastDisplay extends StatelessWidget {


  void sendEvent(BuildContext context, RaspDataEvent event) {
    BlocProvider.of<RaspDataBloc>(context).add(event);
  }
  SelectedForecastDisplay();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RaspDataBloc, RaspDataState>(
        buildWhen: (previous, current) {
      return current is RaspInitialState || current is RaspForecasts;
    }, builder: (context, state) {
      //debugPrint('creating/updating ForecastTypes');
      if (state is RaspForecasts) {
        List<Forecast> forecasts = state.forecasts;
        int initialIndex = forecasts.indexWhere(
            (forecast) => forecast.forecastName == state.selectedForecast.forecastName);
        return SizedBox(
          height: 50,
          child: PageView.builder(
            key: ObjectKey(Object()),
            scrollDirection: Axis.horizontal,
            controller: PageController(
                viewportFraction: 1.0,
                initialPage: initialIndex >= 0 ? initialIndex : 0,
                keepPage: false),
            itemCount: forecasts.length,
            onPageChanged: ((int index) {
                sendEvent(context,SelectedRaspForecastEvent(forecasts[index]));
            }),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _getSelectedForecastIcon(context, forecasts[index]),
                    _getForecastTextWidget(
                        context: context,
                        sendEvent: sendEvent,
                        forecast: forecasts[index]),
                    _getForecastDropDownIconWidget(
                        context: context,
                        sendEvent: sendEvent,
                        forecast: forecasts[index])
                  ],
                ),
              );
            },
          ),
        );
      } else {
        return Text("Getting Forecasts");
      }
    });
  }
}

Widget _getSelectedForecastIcon(BuildContext context, Forecast forecast) {
  return Padding(
    padding: const EdgeInsets.only(left: 8.0, right: 8.0),
    child: InkWell(
        onTap: () {
          BottomSheetWidgets.showForecastDescriptionBottomSheet(
              context, forecast);
        },
        child: Constants.getForecastIcon(forecast.forecastCategory.toString())),
  );
}

Widget _getForecastTextWidget(
    {required BuildContext context,
    required Function sendEvent,
    required Forecast forecast}) {
  return Expanded(
      child: InkWell(
    onTap: () {
      displayForecastList(
          context: context, sendEvent: sendEvent, forecast: forecast);
    },
    child: Text(
      forecast.forecastNameDisplay,
      style: CustomStyle.bold18(context),
      maxLines: 2,
      overflow: TextOverflow.fade,
    ),
  ));
}

InkWell _getForecastDropDownIconWidget(
    {required BuildContext context,
    required Function sendEvent,
    Forecast? forecast}) {
  return InkWell(
    onTap: () {
      displayForecastList(
          context: context, sendEvent: sendEvent, forecast: forecast);
    },
    child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Icon(Icons.arrow_drop_down_outlined)),
  );
}

Future<void> displayForecastList(
    {required BuildContext context,
    required Function sendEvent,
    Forecast? forecast = null}) async {
  final result = await Navigator.pushNamed(
      context, ForecastListRouteBuilder.routeName,
      arguments: ForecastListArgs(forecast: forecast));
  if (result != null) {
    if (result is ReturnedForecastArgs) {
      if (result.reorderedForecasts) {
        // the list was reordered so send the list in the new order
        sendEvent(context,LoadForecastTypesEvents());
      }
      if (result.forecast != null) {
        // a new forecast was selected from the list. Store the forecast
        // selected and then request resend of state
        sendEvent(context,SelectedRaspForecastEvent(result.forecast!,resendForecasts: true));
      }
    }
  }
}
