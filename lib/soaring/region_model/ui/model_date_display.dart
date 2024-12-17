import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';

import '../../app/constants.dart' show ForecastDateChange;
import '../../forecast/bloc/rasp_data_event.dart';
import '../../repository/rasp/regions.dart';
import '../bloc/region_model_event.dart';
import 'rasp_widgets.dart';
import '../../forecast/util/rasp_utils.dart';
import '../bloc/region_model_bloc.dart';
import '../bloc/region_model_state.dart';

class ModelDatesDisplay extends StatefulWidget {

  @override
  State<ModelDatesDisplay> createState() => _ModelDatesDisplayState();
}

class _ModelDatesDisplayState extends State<ModelDatesDisplay> {
  List<String> _modelNames = [];
  int _modelNameIndex = 0;
  List<String> _forecastDates =[];// array of dates like  2019-12-19
  int _forecastDateIndex = 0;
  List<String> _shortDOWs = [];
  String _selectedForecastDOW = '';

  void sendEvent(BuildContext context, RegionModelEvent event) {
    BlocProvider.of<RegionModelBloc>(context).add(event);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegionModelBloc, RegionModelState>(
        listener: (BuildContext context, RegionModelState state) {
      if (state is ForecastModelsAndDates){
        _modelNames = state.modelNames;
        _modelNameIndex = state.modelNameIndex;
        _forecastDates = state.forecastDates;
        _forecastDateIndex = state.forecastDateIndex;
        _shortDOWs = reformatDatesToDOW(_forecastDates);
       _selectedForecastDOW =  _forecastDateIndex >= 0? _shortDOWs[_forecastDateIndex]: "";
      };
    }, buildWhen: (previous, current) {
      return current is ForecastModelsAndDates;
    }, builder: (context, state) {
      if (state is ForecastModelsAndDates) {
        if (state.beginnerMode){
        return _getBeginnerForecast(
            context: context,
            selectedModelName: _modelNameIndex >= 0 ? _modelNames[_modelNameIndex] : "",
            selectedForecastDOW: _selectedForecastDOW,
            sendEvent: sendEvent);
        } else {
      // if first time called just display 'empty' models/dates
          return _getForecastModelsAndDates(
          context: context,
          selectedModelName: _modelNames[_modelNameIndex],
          modelNames: _modelNames,
          forecastDates: _forecastDates,
          selectedForecastDOW: _selectedForecastDOW,
          shortDOWs: _shortDOWs,
          sendEvent: sendEvent);
    }}
        else {
          return Text("Getting models and dates");
      }
    });
  }
}

Widget _getBeginnerForecast(
    {required BuildContext context,
    required String selectedModelName,
    required String selectedForecastDOW,
    required Function(BuildContext context, RegionModelEvent) sendEvent}) {
  return BeginnerForecast(
      context: context,
      leftArrowOnTap: (() {
        sendEvent(
            context, BeginnerDateSwitchEvent(ForecastDateChange.previous));
      }),
      rightArrowOnTap: (() {
        sendEvent(context, BeginnerDateSwitchEvent(ForecastDateChange.next));
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
    required Function(BuildContext context, RegionModelEvent) sendEvent}) {
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
            sendEvent(context, ModelChangeEvent(value));
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
                final selectedForecastDate =
                    forecastDates[shortDOWs.indexOf(value)];
                sendEvent(
                    context, DateChangeEvent(selectedForecastDate));
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
        widget.onModelChange(newValue!);
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
