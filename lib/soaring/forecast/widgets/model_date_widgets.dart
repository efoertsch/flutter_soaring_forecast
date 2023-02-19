import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/rasp_widgets.dart';


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
