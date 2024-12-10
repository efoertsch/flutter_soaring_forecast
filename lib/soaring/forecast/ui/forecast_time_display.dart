// Display forecast time for model and date
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';

import '../bloc/rasp_data_bloc.dart';
import '../bloc/rasp_data_event.dart';
import '../bloc/rasp_data_state.dart';
import '../../region_model/ui/rasp_widgets.dart';


/// The forecast time is driven by the RaspDataBloc when it sends out a
/// new forecast image overlay or sounding. The goal is to keep the time in
/// sync with the forecast image/sounding  time.
class ForecastTimeDisplay extends StatefulWidget {
  final Function(bool) runAnimation;
  final Function(int) timeIndexChangeFunction;


  ForecastTimeDisplay({required this.runAnimation, required this.timeIndexChangeFunction});

  @override
  State<ForecastTimeDisplay> createState() => _ForecastTimeDisplayState();
}

class _ForecastTimeDisplayState extends State<ForecastTimeDisplay> {
  // int currentImageIndex = 0;
  // int lastImageIndex = 0;
  bool _startImageAnimation = false;
 String  _localTime = "";

  void _sendEvent(RaspDataEvent event) {
    BlocProvider.of<RaspDataBloc>(context).add(event);
  }

  @override
  Widget build(BuildContext context) {
    //debugPrint('creating/updating ForecastTime');
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(' '),
        ),
        Expanded(
          flex: 5,
          child: Row(children: [
            Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _startImageAnimation = false;
                      widget.runAnimation(_startImageAnimation);
                      _sendEvent(PreviousTimeEvent());
                    });
                  },
                  child: IncrDecrIconWidget.getIncIconWidget('<'),
                )),
            Expanded(
                flex: 6,
                child: BlocConsumer<RaspDataBloc, RaspDataState>(
                    listener: (BuildContext context,RaspDataState state) {
                  if (state is RaspTimeState) {
                    _localTime = state.forecastTime;
                  }
                }, buildWhen: (previous, current) {
                  return current is RaspTimeState;
                }, builder: (context, state) {
                  //debugPrint('creating/updating ForecastTime value');
                  if (state is RaspTimeState) {
                      var forecastTime = state.forecastTime.startsWith("old ")
                          ? state.forecastTime.substring(4)
                          : state.forecastTime;
                    return Text(
                    forecastTime + " (Local)",
                      style: CustomStyle.bold18(context),
                    );
                  } else {
                    return Text("Getting forecastTime");
                  }
                })),
            Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _startImageAnimation = false;
                      widget.runAnimation(_startImageAnimation);
                      _sendEvent(NextTimeEvent());
                    });
                  },
                  child: IncrDecrIconWidget.getIncIconWidget('>'),
                )),
          ]),
        ),
        Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _startImageAnimation = !_startImageAnimation;
                  widget.runAnimation(_startImageAnimation);
                });
              },
              child: Text(
                (_startImageAnimation
                    ? StandardLiterals.PAUSE_LABEL
                    : StandardLiterals.LOOP_LABEL),
                textAlign: TextAlign.end,
                style: CustomStyle.bold18(context),
              ),
            )),
      ],
    );
  }
}
