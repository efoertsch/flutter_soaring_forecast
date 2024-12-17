import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/glider_cubit.dart';
import '../cubit/glider_state.dart';


class TaskEstimateProgressIndicator extends StatelessWidget {
  TaskEstimateProgressIndicator();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GliderCubit, GliderCubitState>(
      listener: (context, state) {},
      buildWhen: (previous, current) {
        return current is GliderCubitWorkingState;
      },
      builder: (context, state) {
        if (state is GliderCubitWorkingState) {
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
