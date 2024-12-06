import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_bloc.dart';

import '../../../app/constants.dart';
import '../../forecast_data/rasp_widgets.dart';
import '../../util/rasp_utils.dart';

class ModelDatesDisplay<T extends Bloc<RaspDataEvent, RaspDataState>>
    extends StatelessWidget {
  final Function(RaspDataEvent) sendEvent;
  final Function? stopAnimation;

  ModelDatesDisplay(
      {required Function(RaspDataEvent) this.sendEvent,
      Function? this.stopAnimation});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<T, RaspDataState>(
        listener: (BuildContext context, RaspDataState state) {
      if (state is BeginnerForecastDateModelState ||
          state is RaspForecastModelsAndDates) ;
    }, buildWhen: (previous, current) {
      return current is BeginnerForecastDateModelState ||
          current is RaspForecastModelsAndDates;
    }, builder: (context, state) {
      String selectedModelName = "";
      List<String> modelNames = [];
      List<String> shortDOWs = [];
      String selectedForecastDOW = '';
      List<String> forecastDates = [];
      if (state is BeginnerForecastDateModelState) {
        return _getBeginnerForecast(
            context: context,
            selectedModelName: state.model,
            selectedForecastDOW: reformatDateToDOW(state.date) ?? '',
            stopAnimation: stopAnimation,
            sendEvent: sendEvent);
      } else if (state is RaspForecastModelsAndDates) {
        selectedModelName = state.selectedModelName;
        modelNames = state.modelNames;
        forecastDates = state.forecastDates;
        shortDOWs = reformatDatesToDOW(state.forecastDates);
        selectedForecastDOW =
            shortDOWs[state.forecastDates.indexOf(state.selectedForecastDate)];
      }
      // if first time called just display 'empty' models/dates
      return _getForecastModelsAndDates(
          context: context,
          selectedModelName: selectedModelName,
          modelNames: modelNames,
          forecastDates: forecastDates,
          selectedForecastDOW: selectedForecastDOW,
          shortDOWs: shortDOWs,
          stopAnimation: stopAnimation,
          sendEvent: sendEvent);
    });
  }
}

Widget _getBeginnerForecast(
    {required BuildContext context,
    required String selectedModelName,
    required String selectedForecastDOW,
    required Function? stopAnimation,
    required Function(RaspDataEvent) sendEvent}) {
  return BeginnerForecast(
      context: context,
      leftArrowOnTap: (() {
        if (stopAnimation != null) {
          stopAnimation();
        }
        sendEvent(ForecastDateSwitchEvent(ForecastDateChange.previous));
      }),
      rightArrowOnTap: (() {
        if (stopAnimation != null) {
          stopAnimation();
        }
        sendEvent(ForecastDateSwitchEvent(ForecastDateChange.next));
      }),
      displayText: "(${selectedModelName.toUpperCase()}) $selectedForecastDOW");
}

Widget _getForecastModelsAndDates(
    {required BuildContext context,
    required String selectedModelName,
    required List<String> modelNames,
    required List<String> forecastDates,
    required String selectedForecastDOW,
    required List<String> shortDOWs,
    required Function? stopAnimation,
    required Function(RaspDataEvent) sendEvent}) {
  //debugPrint('creating/updating main ForecastModelsAndDates');
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Expanded(
        flex: 3,
        child: ModelDropDownList(
          selectedModelName: selectedModelName,
          modelNames: modelNames,
          onModelChange: (String value) {
            if (stopAnimation != null) {
              stopAnimation();
            }
            sendEvent(SelectedModelEvent(value));
          },
        ),
      ),
      Expanded(
          flex: 7,
          child: Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: ForecastDatesDropDown(
              selectedForecastDate: selectedForecastDOW,
              forecastDates: shortDOWs,
              onForecastDateChange: (String value) {
                if (stopAnimation != null) {
                  stopAnimation();
                }
                final selectedForecastDate =
                    forecastDates[shortDOWs.indexOf(value)];
                sendEvent(SelectForecastDateEvent(selectedForecastDate));
              },
            ),
          )),
    ],
  );
}

Widget BeginnerForecast(
    {required BuildContext context,
    required Function leftArrowOnTap,
    required Function rightArrowOnTap,
    required String displayText}) {
//debugPrint('creating/updating main ForecastModelsAndDates');
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    mainAxisSize: MainAxisSize.max,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: () {
            leftArrowOnTap();
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 24.0),
            child: IncrDecrIconWidget.getIncIconWidget('<'),
          ),
        ),
      ),
      Spacer(),
      Align(
          alignment: Alignment.center,
          child: Text(
            displayText,
            style: CustomStyle.bold18(context),
          )),
      Spacer(),
      Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          onTap: () {
            rightArrowOnTap();
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 8.0),
            child: IncrDecrIconWidget.getIncIconWidget('>'),
          ),
        ),
      ),
    ],
  );
}

// Display GFS, NAM, ....
//ignore: must_be_immutable
class ModelDropDownList extends StatefulWidget {
  String selectedModelName;
  late final List<String> modelNames;
  late final Function onModelChange;

  ModelDropDownList(
      {Key? key,
      required this.selectedModelName,
      required this.modelNames,
      required Function this.onModelChange})
      : super(key: key);

  @override
  _ModelDropDownListState createState() => _ModelDropDownListState();
}

class _ModelDropDownListState extends State<ModelDropDownList> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      style: CustomStyle.bold18(context),
      value: widget.selectedModelName,
      hint: Text('Select Model'),
      isExpanded: true,
      iconSize: 24,
      elevation: 16,
      onChanged: (String? newValue) {
        widget.onModelChange(
            newValue!); //_sendEvent(SelectedRaspModelEvent(newValue!));
      },
      items: widget.modelNames.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value.toUpperCase()),
        );
      }).toList(),
    );
  }
}

// Display forecast dates for selected model (eg. GFS)
//ignore: must_be_immutable
class ForecastDatesDropDown extends StatefulWidget {
  late String selectedForecastDate;
  late final List<String> forecastDates;
  late final Function onForecastDateChange;

  ForecastDatesDropDown(
      {Key? key,
      required this.selectedForecastDate,
      required this.forecastDates,
      required this.onForecastDateChange})
      : super(key: key);

  @override
  _ForecastDatesDropDownState createState() => _ForecastDatesDropDownState();
}

class _ForecastDatesDropDownState extends State<ForecastDatesDropDown> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      style: CustomStyle.bold18(context),
      isExpanded: true,
      value: widget.selectedForecastDate,
      onChanged: (String? newValue) {
        // final selectedForecastDate =
        // _forecastDates[_shortDOWs.indexOf(newValue!)];
        // _sendEvent(SelectRaspForecastDateEvent(selectedForecastDate));
        widget.onForecastDateChange(newValue);
      },
      items: widget.forecastDates.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
