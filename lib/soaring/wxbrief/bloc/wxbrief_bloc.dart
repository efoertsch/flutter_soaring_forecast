import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/bloc/wxbrief_event.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/bloc/wxbrief_state.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/data/wxbrief_defaults.dart';

class WxBriefBloc extends Bloc<WxBriefEvent, WxBriefState> {
  final Repository repository;

  //WxBriefState get initialState => WxBriefsLoadingState();

  WxBriefBloc({required this.repository}) : super(WxBriefInitialState()) {
    on<WxBriefGetTaskDetailsEvent>(_getWxBriefTaskDetails);
    on<WxBriefGetNotamsEvent>(_submitNotamsBriefRequest);
  }

  FutureOr<void> _getWxBriefTaskDetails(
      WxBriefGetTaskDetailsEvent event, Emitter<WxBriefState> emit) async {
    final taskId = await repository.getCurrentTaskId();
    final List<TaskTurnpoint> taskTurnpointList = <TaskTurnpoint>[];
    final List<String> taskTurnpointIds = <String>[];
    Task? task = null;
    if (taskId > -1) {
      final task = await repository.getTask(taskId);
      if (task.id != null) {
        taskTurnpointList.addAll(await repository.getTaskTurnpoints(task.id!));
      }
      taskTurnpointList.forEach((taskTurnpoint) {
        taskTurnpointIds.add(taskTurnpoint.code);
      });
      emit(WxBriefTaskTitleState(
          taskName: task.taskName, turnpointIds: taskTurnpointIds));
    }
    String aircraftRegistration = await repository.getAircraftRegistration();
    String wxbriefAccountName = await repository.getWxBriefAccountName();
    emit(WxBriefDefaultsState(
        wxBriefDefaults: WxBriefDefaults(
            aircraftRegistration: aircraftRegistration,
            wxBriefAccountName: wxbriefAccountName)));
  }

  FutureOr<void> _submitNotamsBriefRequest(
      WxBriefGetNotamsEvent event, Emitter<WxBriefState> emit) async {}
}
