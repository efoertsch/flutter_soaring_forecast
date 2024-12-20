import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/task_estimate_cubit.dart';
import '../cubit/task_estimate_state.dart';




class TaskEstimateProgressIndicator extends StatelessWidget {
  TaskEstimateProgressIndicator();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskEstimateCubit, TaskEstimateState>(
      listener: (context, state) {},
      buildWhen: (previous, current) {
        return current is TaskEstimateWorkingState;
      },
      builder: (context, state) {
        if (state is TaskEstimateWorkingState) {
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
