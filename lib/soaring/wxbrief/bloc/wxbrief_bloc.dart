import 'dart:async';
import 'dart:convert';

import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:dio/dio.dart';
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

  WxBriefFormat _selectedBriefFormat = WxBriefFormat.NGBV2; //i.e. PDF
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
    emit(WxBriefWorkingState(working: true));
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
    _addProductCodesToRouteBriefingRequest();
    _addTailoringOptions();
    await _submitBriefingRequest(emit);
    emit(WxBriefWorkingState(working: false));
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
      departureTimeZulu = DateFormat(ZULU_DATE_FORMAT)
          .format(DateTime.now().toUtc().add(const Duration(hours: 1)));
    } else {
      // assume 9AM local time departure
      departureTimeZulu = DateFormat(ZULU_DATE_FORMAT).format(DateTime.parse(
              _briefingDates[_selectedBriefingDateIndex] + " 09:00:00.000")
          .toUtc());
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

  FutureOr<void> _submitBriefingRequest(Emitter<WxBriefState> emit) async {
    final restParmString = _routeBriefingRequest.getRestParmString();
    debugPrint(restParmString);
    await repository
        .submitWxBriefBriefingRequest(restParmString)
        .then((routeBriefing) async {
      if ((routeBriefing.returnStatus ?? false) &&
          routeBriefing.returnCodedMessage!.length == 0) {
        if (_selectedBriefFormat == WxBriefFormat.EMAIL) {
          emit(WxBriefMessageState(WxBriefLiterals.WXBRIEF_SENT_TO_MAILBOX));
        } else if (_selectedBriefFormat == WxBriefFormat.NGBV2) {
          // need to get NGBV2 briefing from
          await _createRouteBriefingPDF(routeBriefing.ngbv2PdfBriefing!, emit);
        }
      }
    }).catchError((Object obj) {
      // non-200 error goes here.
      switch (obj.runtimeType) {
        case DioError:
          // Here's the sample to get the failed response error code and message
          final res = (obj as DioError).response;
          print(
              "Got error on 1800WxBriefCall : ${res?.statusCode} -> ${res?.statusMessage}");
          break;
        default:
          break;
      }
    });
  }

  // Load product codes and tailoring options from CSV
  void _getProductCodesAndTailoringOptions() async {
    _fullProductCodeList.clear();
    _fullProductCodeList
        .addAll(await repository.getWxBriefProductCodes(_selectedTypeOfBrief));
    _fullTailoringOptionList.clear();
    if (_selectedBriefFormat == WxBriefFormat.EMAIL) {
      // Non NGBV2
      _fullTailoringOptionList.addAll(await repository
          .getWxBriefNonNGBV2TailoringOptions(_selectedTypeOfBrief));
    } else {
      // NGBV2
      _fullTailoringOptionList.addAll(await repository
          .getWxBriefNGBV2TailoringOptions(_selectedTypeOfBrief));
    }
  }

  void _addProductCodesToRouteBriefingRequest() {
    final productCodes = <String>[];
    _fullProductCodeList.forEach((productCode) {
      if (productCode.selectForBrief) {
        productCodes.add(productCode.wxBriefParameterName);
      }
    });
    _routeBriefingRequest.setProductCodes(productCodes);
  }

  void _addTailoringOptions() {
    final tailoringOptions = <String>[];
    _fullTailoringOptionList.forEach((tailoringOption) {
      // Option was checked
      // Note that NGBV2 are 'EXCLUDE...' but non NGBV2 are INCLUDE so need to handle differently
      if ((_selectedBriefFormat == WxBriefFormat.NGBV2 &&
              !tailoringOption.selectForBrief) ||
          _selectedBriefFormat != WxBriefFormat.NGBV2 &&
              tailoringOption.selectForBrief) {
        tailoringOptions.add(tailoringOption.wxBriefParameterName);
      }
    });
    _routeBriefingRequest.setTailoringOptions(tailoringOptions);
  }

  FutureOr<void> _createRouteBriefingPDF(
      String ngbv2pdfBriefing, Emitter<WxBriefState> emit) async {
    Uint8List bytes = base64Decode(ngbv2pdfBriefing);
    final file = await repository.writeBytesToDirectory("WxBrief.pdf", bytes);
    if (file == null) {
      // send error
    } else {
      //display PDF
      PDFDocument document = await PDFDocument.fromFile(file);
      emit(WxBriefPdfDocState(document));
    }
  }
}
