import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TaskTurnpointMarkerWidget extends StatelessWidget {
  final Function stopAnimation;
  final GlobalKey globalKey;
  final TaskTurnpoint taskTurnpoint;

  TaskTurnpointMarkerWidget(
      {required this.globalKey,
      required this.taskTurnpoint,
      required Function this.stopAnimation});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
        key: globalKey,
        child: InkWell(
          onTap: () {
            // _sendEvent(DisplayTaskTurnpointEvent(taskTurnpoint));
          },
          onLongPress: () {
            _getLocalForecast(
                latLng: LatLng(
                    taskTurnpoint.latitudeDeg, taskTurnpoint.longitudeDeg),
                turnpointName:
                    ("${taskTurnpoint.title} (${taskTurnpoint.code})"));
          },
          child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Text(taskTurnpoint.title,
                      textAlign: TextAlign.center,
                      style: textStyleBoldBlackFontSize18),
                  Text(
                      '${taskTurnpoint.distanceFromPriorTurnpoint.toStringAsFixed(0)} '
                      '/ ${taskTurnpoint.distanceFromStartingPoint.toStringAsFixed(0)} km',
                      textAlign: TextAlign.center,
                      style: textStyleBoldBlackFontSize18),
                  Icon(Icons.arrow_drop_down_outlined, color: Colors.white)
                ],
              )),
        ));
  }

  _getLocalForecast({required LatLng latLng, String? turnpointName = null}) {
    stopAnimation();
    print('Local forecast requested at : ${latLng.latitude.toString()}  :'
        '  ${latLng.longitude.toString()}');
    //_sendEvent(DisplayLocalForecastEvent(latLng, turnpointName));
  }
}
