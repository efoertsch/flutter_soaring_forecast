import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/rasp_bloc.dart';

class RaspProgressIndicator extends StatelessWidget {
  RaspProgressIndicator();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RaspDataBloc, RaspDataState>(
      listener: (context, state) {},
      buildWhen: (previous, current) {
        return current is RaspWorkingState;
      },
      builder: (context, state) {
        if (state is RaspWorkingState) {
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
