import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart'
    show Task, WxBriefFormat;
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/bloc/wxbrief_event.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/bloc/wxbrief_state.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/data/briefing_option.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/data/wxbrief_defaults.dart';

class WxBriefBloc extends Bloc<WxBriefEvent, WxBriefState> {
  final Repository repository;

  //-------- Arrays to hold WxBrief
  List<BriefingOption> _fullProductCodeList = <BriefingOption>[];
  //A subset of the full productCodes that are pertinent to the type of brief (Standard, Outlook, Abbreviated)
  List<String> _productCodeDescriptions = <String>[];
  // only associated products with a 'true' value are to be included in the wxbrief api call
  // same size as productCodeDescriptions
  List<bool> _productCodesSelected = <bool>[];
  // index of this option back to the full set of productCodes
  // same size as productCodeDescriptions
  List<int> _productCodeListIndex = <int>[];

  // Full set of tailoringOptions
  List<BriefingOption> _fullTailoringOptionList = <BriefingOption>[];
  //A subset of the full tailoringOptions that are pertinent to the type of brief (Standard, Outlook, Abbreviated)
  List<String> _tailorOptionDescriptions = <String>[];
  // only associated options with a 'true' value are to be included in the wxbrief api call
  // same size as tailorOptionDescriptions
  List<bool> _tailoringOptionsSelected = <bool>[];
  // index of this option back to the full set of tailoringOptions
  // same size as tailorOptionDescriptions
  List<int> _tailoringOptionListIndex = <int>[];

  WxBriefFormat _briefingFormat = WxBriefFormat.PDF;
  WxBriefTypeOfBriefing _wxBriefTypeOfBriefing = WxBriefTypeOfBriefing.NOTAMS;

  //WxBriefState get initialState => WxBriefsLoadingState();

  WxBriefBloc({required this.repository}) : super(WxBriefInitialState()) {
    on<WxBriefGetTaskDetailsEvent>(_getWxBriefTaskDetails);
    on<WxBriefSetBriefFormatEvent>(_setWxBriefFormat);
    on<WxBriefSetTypeOfBriefEvent>(_setWxTypeOfBrief);
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
      WxBriefGetNotamsEvent event, Emitter<WxBriefState> emit) async {
    // creat parm string for the briefing request
  }

  FutureOr<void> _setWxBriefFormat(
      WxBriefSetBriefFormatEvent event, Emitter<WxBriefState> emit) async {
    _briefingFormat = event.wxBriefFormat;
  }

  FutureOr<void> _setWxTypeOfBrief(
      WxBriefSetTypeOfBriefEvent event, Emitter<WxBriefState> emit) async {
    _wxBriefTypeOfBriefing = event.wxBriefTypeOfBriefing;
  }
}
