import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_event.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_state.dart';

class ForecastModelsWidget extends StatefulWidget {
  ForecastModelsWidget({Key? key}) : super(key: key);
  @override
  _ForecastModelsWidget createState() => _ForecastModelsWidget();
}

class _ForecastModelsWidget extends State<ForecastModelsWidget> {
  late String currentSelection;
  late List<String> selectionList;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RaspDataBloc, RaspDataState>(
        buildWhen: (previous, current) {
      print(
          "ForecastModelDropDownList bloc buildwhen previous state: $previous current: $current");
      return current is RaspInitialState || current is RaspForecastModels;
    }, builder: (context, state) {
      if (state is RaspInitialState || !(state is RaspForecastModels)) {
        return Text("Getting Forecast Models");
      }
      print(
          'Creating dropdown for models. Model is ${state.selectedModelName}');
      currentSelection = state.selectedModelName;
      selectionList = state.modelNames;
      return DropdownButton<String>(
        value: currentSelection,
        isExpanded: true,
        iconSize: 24,
        elevation: 16,
        onChanged: (String? newValue) {
          setState(() {
            currentSelection = newValue!;
            BlocProvider.of<RaspDataBloc>(context)
                .add(SelectedRaspModelEvent(currentSelection));
          });
        },
        items: selectionList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value.toUpperCase()),
          );
        }).toList(),
      );
    });
  }
}

class IncrDecrIconWidget {
  static Widget getIncIconWidget(String symbol) {
    return Text(
      symbol,
      style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 30, color: Colors.blueAccent),
    );
  }
}
