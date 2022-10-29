import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/bloc/wxbrief_event.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/bloc/wxbrief_state.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/data/briefing_option.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/data/route_briefing_request.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/data/wxbrief_defaults.dart';
import 'package:intl/intl.dart';

class WxBriefBloc extends Bloc<WxBriefEvent, WxBriefState> {
  static const int ONE_HOUR_IN_MILLISECS = 60 * 60 * 1000;
  static const int ONE_DAY_IN_MILLISEC = 24 * ONE_HOUR_IN_MILLISECS;
  static const String DATE_FORMAT = 'yyyy-MM-dd';
  static const String ZULU_DATE_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSS";

  final Repository repository;

  //-------- Arrays to hold WxBrief
  // All product codes
  List<BriefingOption> _fullProductCodeList = <BriefingOption>[];

  // All tailoringOptions
  List<BriefingOption> _fullTailoringOptionList = <BriefingOption>[];

  // List of briefing dates
  final _briefingDates = <String>[];
  int _selectedBriefingDateIndex = 0;

  WxBriefFormat _selectedBriefFormat = WxBriefFormat.PDF;
  final List<WxBriefTypeOfBrief> _briefingTypes = <WxBriefTypeOfBrief>[];
  WxBriefTypeOfBrief _selectedTypeOfBrief = WxBriefTypeOfBrief.NOTAMS;

  final _routeBriefingRequest = RouteBriefingRequest();
  final _taskTurnpoints = <TaskTurnpoint>[];
  final _taskTurnpointIds = <String>[];

  //WxBriefState get initialState => WxBriefsLoadingState();

  WxBriefBloc({required this.repository}) : super(WxBriefInitialState()) {
    on<WxBriefInitNotamsEvent>(_getWxBriefNotamsDetails);
    on<WxBriefSetBriefFormatEvent>(_setBriefFormat);
    on<WxBriefSetTypeOfBriefEvent>(_setTypeOfBrief);
    on<WxBriefGetNotamsEvent>(_submitNotamsBriefRequest);
  }

  FutureOr<void> _getWxBriefNotamsDetails(
      WxBriefInitNotamsEvent event, Emitter<WxBriefState> emit) async {
    await _emitTaskDetails(emit);
    await _emitAircraftIdAndAccountEvent(emit);
    await _emitBriefingFormats(emit);
    _getProductCodesAndTailoringOptions();
  }

  Future<void> _emitAircraftIdAndAccountEvent(
      Emitter<WxBriefState> emit) async {
    String aircraftRegistration = await repository.getAircraftRegistration();
    String wxbriefAccountName = await repository.getWxBriefAccountName();
    emit(WxBriefDefaultsState(
        wxBriefDefaults: WxBriefDefaults(
            aircraftRegistration: aircraftRegistration,
            wxBriefAccountName: wxbriefAccountName)));
  }

  Future<void> _emitTaskDetails(Emitter<WxBriefState> emit) async {
    final taskId = await repository.getCurrentTaskId();
    _taskTurnpoints.clear();
    _taskTurnpointIds.clear();
    if (taskId > -1) {
      final task = await repository.getTask(taskId);
      if (task.id != null) {
        _taskTurnpoints.addAll(await repository.getTaskTurnpoints(task.id!));
      }
      _taskTurnpoints.forEach((taskTurnpoint) {
        _taskTurnpointIds.add(taskTurnpoint.code);
      });
      emit(WxBriefTaskTitleState(
          taskName: task.taskName, turnpointIds: _taskTurnpointIds));
    }
  }

  FutureOr<void> _emitBriefingFormats(Emitter<WxBriefState> emit) async {
    emit(WxBriefBriefFormatsState(WxBriefFormat.values));
  }

  FutureOr<void> _emitBriefingDepartureDatesState(
      Emitter<WxBriefState> emit) async {
    if (_briefingDates.isEmpty) {
      _createBriefingDates();
    }
    emit(WxBriefDepartureDatesState(_briefingDates));
  }

  FutureOr<void> _emitBriefingTypesState(Emitter<WxBriefState> emit) async {
    if (_briefingTypes.isEmpty) {
      _briefingTypes.addAll(WxBriefTypeOfBrief.values);
    }
    emit(WxBriefBriefingTypesState(_briefingTypes));
  }

  FutureOr<void> _submitNotamsBriefRequest(
      WxBriefGetNotamsEvent event, Emitter<WxBriefState> emit) async {
    _saveAccountNameAndAircraftId(
        aircraftRegistration: event.aircraftRegistration,
        accountName: event.accountName);
    _routeBriefingRequest.setAircraftIdentifier(event.aircraftRegistration);
    _routeBriefingRequest.setEmailAddress(event.accountName);
    _routeBriefingRequest.setWebUserName(event.accountName);
    _routeBriefingRequest.setNotABriefing(true);
    _routeBriefingRequest.setSelectedBriefFormat(_selectedBriefFormat.name);
    _setDepartureRouteAndDestination();
    _formatDepartureInstant();
    _submitBriefingRequest();
  }

  void _setDepartureRouteAndDestination() {
    for (int i = 0; i < _taskTurnpoints.length; ++i) {
      if (i == 0) {
        _routeBriefingRequest.setDeparture(_taskTurnpoints[0].code);
      } else if (i == _taskTurnpoints.length - 1) {
        _routeBriefingRequest.setDestination(_taskTurnpoints[i].code);
      } else {
        _taskTurnpointIds.add(_taskTurnpoints[i].code);
      }
    }
    _routeBriefingRequest.setRoute(_taskTurnpointIds.join(" "));
  }

  void _saveAccountNameAndAircraftId(
      {required String aircraftRegistration, required String accountName}) {
    repository.setAircraftRegistration(aircraftRegistration);
    repository.setWxBriefAccountName(accountName);
  }

  /**
   * Convert selected local/date and  time to Zulu
   * Time must be in format of yyyy-MM-ddTHH:mm:ss.S
   */
  void _formatDepartureInstant() {
    String departureTimeZulu = "";
    // if today assume flight 1 hr in future
    if (_selectedBriefingDateIndex == 0) {
      departureTimeZulu = DateFormat(ZULU_DATE_FORMAT).format(
          DateTime.fromMillisecondsSinceEpoch(
              DateTime.now().toUtc().millisecond + ONE_HOUR_IN_MILLISECS));
    } else {
      // assume 9AM local time departure

      departureTimeZulu = DateFormat(ZULU_DATE_FORMAT).format(
          DateTime.fromMillisecondsSinceEpoch(DateTime.parse(
                  _briefingDates[_selectedBriefingDateIndex] + " 09:00:00.000")
              .toUtc()
              .millisecond));
    }
    _routeBriefingRequest.setDepartureInstant(departureTimeZulu);
  }

  FutureOr<void> _setBriefFormat(
      WxBriefSetBriefFormatEvent event, Emitter<WxBriefState> emit) async {
    _selectedBriefFormat = event.wxBriefFormat;
  }

  FutureOr<void> _setTypeOfBrief(
      WxBriefSetTypeOfBriefEvent event, Emitter<WxBriefState> emit) async {
    _selectedTypeOfBrief = event.wxBriefTypeOfBriefing;
  }

  void _createBriefingDates() {
    _briefingDates.clear();
    // Date.now() gives local time
    _briefingDates.add(DateFormat(DATE_FORMAT).format(DateTime.now()));
    final tomorrow = DateTime.now().millisecond + ONE_DAY_IN_MILLISEC;
    _briefingDates.add(DateFormat(DATE_FORMAT)
        .format(DateTime.fromMillisecondsSinceEpoch(tomorrow)));
    _briefingDates.add(DateFormat(DATE_FORMAT).format(
        DateTime.fromMillisecondsSinceEpoch(tomorrow + ONE_DAY_IN_MILLISEC)));
  }

  void _submitBriefingRequest() {
    final restParmString = _routeBriefingRequest.getRestParmString();
    debugPrint(restParmString);
  }

  void _getProductCodesAndTailoringOptions() async {
    _fullProductCodeList.clear();
    _fullProductCodeList
        .addAll(await repository.getWxBriefProductCodes(_selectedTypeOfBrief));
    _fullTailoringOptionList.clear();
    if (_selectedTypeOfBrief == BriefingFormat.EMAIL) {
      _fullTailoringOptionList.addAll(await repository
          .getWxBriefNonNGBV2TailoringOptions(_selectedTypeOfBrief));
    } else {
      _fullTailoringOptionList.addAll(await repository
          .getWxBriefNGBV2TailoringOptions(_selectedTypeOfBrief));
    }
  }
}
