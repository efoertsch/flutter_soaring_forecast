// Display forecast time for model and date
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';

import '../../bloc/rasp_data_bloc.dart';
import '../../bloc/rasp_data_event.dart';
import '../../bloc/rasp_data_state.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';

import '../../forecast_data/rasp_widgets.dart';

class ForecastTimeDisplay extends StatefulWidget {
  final Function(RaspDataEvent) sendEvent;
  final Function(bool) runAnimation;

  ForecastTimeDisplay(
      {required Function(RaspDataEvent) this.sendEvent,
      required this.runAnimation});

  @override
  State<ForecastTimeDisplay> createState() => _ForecastTimeDisplayState();
}

class _ForecastTimeDisplayState extends State<ForecastTimeDisplay> {
  int currentImageIndex = 0;
  int lastImageIndex = 0;
  bool startImageAnimation = false;
  String pauseLoopLabel = StandardLiterals.PAUSE_LABEL;

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
                      startImageAnimation = false;
                      widget.runAnimation(startImageAnimation);
                      widget.sendEvent(PreviousTimeEvent());
                    });
                  },
                  child: IncrDecrIconWidget.getIncIconWidget('<'),
                )),
            Expanded(
              flex: 6,
              child: BlocBuilder<RaspDataBloc, RaspDataState>(
                  buildWhen: (previous, current) {
                return current is RaspInitialState ||
                    current is RaspForecastImageSet ||
                    current is SoundingForecastImageSet;
              }, builder: (context, state) {
                var localTime;
                //debugPrint('creating/updating ForecastTime value');
                if (state is RaspForecastImageSet ||
                    state is SoundingForecastImageSet) {
                  if (state is RaspForecastImageSet) {
                    localTime = state.soaringForecastImageSet.localTime;
                    currentImageIndex = state.displayIndex;
                    lastImageIndex = state.numberImages - 1;
                  }
                  if (state is SoundingForecastImageSet) {
                    localTime = state.soaringForecastImageSet.localTime;
                    currentImageIndex = state.displayIndex;
                    lastImageIndex = state.numberImages - 1;
                  }
                  localTime = localTime.startsWith("old ")
                      ? localTime.substring(4)
                      : localTime;
                  return Text(
                    localTime + " (Local)",
                    style: CustomStyle.bold18(context),
                  );
                } else {
                  return Text("Getting forecastTime");
                }
              }),
            ),
            Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      startImageAnimation = false;
                      widget.runAnimation(startImageAnimation);
                      widget.sendEvent(NextTimeEvent());
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
                  startImageAnimation = !startImageAnimation;
                  widget.runAnimation(startImageAnimation);
                });
              },
              child: Text(
                (startImageAnimation
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
