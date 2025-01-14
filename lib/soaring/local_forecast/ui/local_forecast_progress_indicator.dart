import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/local_forecast_bloc.dart';
import '../bloc/local_forecast_state.dart';


class LocalForecastProgressIndicator extends StatelessWidget {
  LocalForecastProgressIndicator();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocalForecastBloc, LocalForecastState>(
      listener: (context, state) {},
      buildWhen: (previous, current) {
        return current is LocalForecastWorkingState;
      },
      builder: (context, state) {
        if (state is LocalForecastWorkingState) {
          if (state.working) {
            return Container(
              child: AbsorbPointer(
                  absorbing: true,
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  )),
              alignment: Alignment.center,
              color: Colors.transparent,
            );
          }
        }
        return SizedBox.shrink();
      },
    );
  }
}
