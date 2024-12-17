import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast_hour/forecast_hour_cubit.dart';

import '../app/constants.dart';
import '../app/custom_styles.dart';
import 'forecast_hour_state.dart';
import 'inc_decr_icon_widgets.dart';

/// The forecast time is driven by other Blocs that control the time and animation

ForecastHourCubit getForecastHourCubit(BuildContext context) {
  return BlocProvider.of<ForecastHourCubit>(context);
}

class ForecastHourDisplay extends StatelessWidget {
  final bool displayPauseLoop;

  ForecastHourDisplay({bool this.displayPauseLoop = true});


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
                    getForecastHourCubit(context). incrDecrHourIndex(-1);
                  },
                  child: IncrDecrIconWidget.getIncIconWidget('<'),
                )),
            Expanded(
                flex: 6,
                child: BlocConsumer<ForecastHourCubit, ForecastHourState>(
                    listener: (BuildContext context, ForecastHourState state) {
                    }, buildWhen: (previous, current) {
                  return current is CurrentForecastHourState;
                }, builder: (context, state) {
                  //debugPrint('creating/updating ForecastTime value');
                  if (state is CurrentForecastHourState) {
                    var forecastTime = state.forecastHour.startsWith("old ")
                        ? state.forecastHour.substring(4)
                        : state.forecastHour;
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
                    getForecastHourCubit(context). incrDecrHourIndex(1);
                  },
                  child: IncrDecrIconWidget.getIncIconWidget('>'),
                )),
          ]),
        ),
        (displayPauseLoop) ? ForecastLoopPauseText() :  Expanded( flex:1 , child: SizedBox.shrink()),
      ],
    );
  }
}

class ForecastLoopPauseText extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    bool runAnimation = false;
    return Expanded(
        flex: 3,
        child: BlocConsumer<ForecastHourCubit, ForecastHourState>(
            listener: (BuildContext context, ForecastHourState state) {
              if (state is RunHourAnimationState) {
                runAnimation = state.runAnimation;
              }
            }, buildWhen: (previous, current) {
          return current is RunHourAnimationState;
        }, builder: (context, state) {
          return GestureDetector(
            onTap: () {
              getForecastHourCubit(context).runAnimation(!runAnimation);
            },
            child: Text(
              (runAnimation
                  ? StandardLiterals.PAUSE_LABEL
                  : StandardLiterals.LOOP_LABEL),
              textAlign: TextAlign.end,
              style: CustomStyle.bold18(context),
            ),
          );
        }));
  }
}