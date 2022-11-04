import 'dart:async';
import 'dart:convert';

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
import 'package:flutter_soaring_forecast/soaring/wxbrief/ui/wxbrief_request.dart';
import 'package:intl/intl.dart';

class WxBriefBloc extends Bloc<WxBriefEvent, WxBriefState> {
  static const int ONE_HOUR_IN_MILLISECS = 60 * 60 * 1000;
  static const int ONE_DAY_IN_MILLISEC = 24 * ONE_HOUR_IN_MILLISECS;
  static const String DATE_FORMAT = 'yyyy-MM-dd';
  static const String ZULU_DATE_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSS";

  final Repository repository;

  String _wxbriefAccountName = "";
  String _aircraftRegistration = "";

  //-------- Arrays to hold WxBrief
  // All product codes
  List<BriefingOption> _fullProductCodeList = <BriefingOption>[];

  // All tailoringOptions
  List<BriefingOption> _fullTailoringOptionList = <BriefingOption>[];

  // List of briefing dates
  final _briefingDates = <String>[];
  String _selectedDepartureDate = "";

  WxBriefFormat _selectedBriefFormat = WxBriefFormat.NGBV2; //i.e. PDF
  final List<WxBriefTypeOfBrief> _briefingTypes = <WxBriefTypeOfBrief>[];
  WxBriefTypeOfBrief _selectedTypeOfBrief = WxBriefTypeOfBrief.NOTAMS;

  final _routeBriefingRequest = RouteBriefingRequest();
  final _taskTurnpoints = <TaskTurnpoint>[];
  final _taskTurnpointIds = <String>[];

  //WxBriefState get initialState => WxBriefsLoadingState();

  WxBriefBloc({required this.repository}) : super(WxBriefInitialState()) {
    on<WxBriefInitEvent>(_getWxBriefRequestData);
    on<WxBriefSetBriefFormatEvent>(_setBriefFormat);
    on<WxBriefSetTypeOfBriefEvent>(_setTypeOfBrief);
    on<WxBriefUpdateDepartureDateEvent>(_setDepartureDate);
    on<WxBriefSubmitEvent>(_submitWxBriefRequest);
    on<WxBriefUpdateAircraftRegistrationEvent>(_updateAircraftRegistration);
    on<WxBriefUpdateAccountNameEvent>(_updateAccountName);
    on<WxBriefUpdateReportingOptionsEvent>(_updateReportingOptions);
    on<WxBriefUpdateProductOptionsEvent>(_updateProductOptions);
  }

  FutureOr<void> _getWxBriefRequestData(
      WxBriefInitEvent event, Emitter<WxBriefState> emit) async {
    await _emitTaskDetails(emit);
    await _emitAircraftIdAndAccountEvent(emit);
    await _emitBriefingFormats(emit);
    await _getProductCodesAndTailoringOptions();
    await _createBriefingDates();
    if (event.request == WxBriefRequest.ROUTE_REQUEST) {
      await _emitBriefingDepartureDatesState(emit);
      await _emitBriefingTypesState(emit);
      await _emitReportingOptions(emit);
      await _emitProductOptions(emit);
    }
    ;
  }

  Future<void> _emitAircraftIdAndAccountEvent(
      Emitter<WxBriefState> emit) async {
    _aircraftRegistration = await repository.getAircraftRegistration();
    _wxbriefAccountName = await repository.getWxBriefAccountName();
    emit(WxBriefDefaultsState(
        wxBriefDefaults: WxBriefDefaults(
            aircraftRegistration: _aircraftRegistration,
            wxBriefAccountName: _wxbriefAccountName)));
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
    emit(WxBriefDepartureDatesState(_briefingDates));
  }

  FutureOr<void> _emitBriefingTypesState(Emitter<WxBriefState> emit) async {
    if (_briefingTypes.isEmpty) {
      _briefingTypes.addAll(WxBriefTypeOfBrief.values);
    }
    emit(WxBriefBriefingTypesState(_briefingTypes));
  }

  FutureOr<void> _emitReportingOptions(Emitter<WxBriefState> emit) {
    emit(WxBriefReportingOptionsState(_fullTailoringOptionList));
  }

  FutureOr<void> _emitProductOptions(Emitter<WxBriefState> emit) {
    emit(WxBriefProductOptionsState(_fullProductCodeList));
  }

  FutureOr<void> _submitWxBriefRequest(
      WxBriefSubmitEvent event, Emitter<WxBriefState> emit) async {
    emit(WxBriefWorkingState(working: true));
    _routeBriefingRequest.setAircraftIdentifier(_aircraftRegistration);
    _routeBriefingRequest.setEmailAddress(_wxbriefAccountName);
    _routeBriefingRequest.setWebUserName(_wxbriefAccountName);
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

  /**
   * Convert selected local/date and  time to Zulu
   * Time must be in format of yyyy-MM-ddTHH:mm:ss.S
   */
  void _formatDepartureInstant() {
    String departureTimeZulu = "";
    // if today assume flight 1 hr in future
    if (_selectedDepartureDate == _briefingDates[0]) {
      departureTimeZulu = DateFormat(ZULU_DATE_FORMAT)
          .format(DateTime.now().toUtc().add(const Duration(hours: 1)));
    } else {
      // assume 9AM local time departure
      departureTimeZulu = DateFormat(ZULU_DATE_FORMAT).format(
          DateTime.parse(_selectedDepartureDate + " 09:00:00.000").toUtc());
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

  FutureOr<void> _createBriefingDates() async {
    _briefingDates.clear();
    // Date.now() gives local time
    _briefingDates.add(DateFormat(DATE_FORMAT).format(DateTime.now()));
    _briefingDates.add(
        DateFormat(DATE_FORMAT).format(DateTime.now().add(Duration(days: 1))));
    _briefingDates.add(
        DateFormat(DATE_FORMAT).format(DateTime.now().add(Duration(days: 2))));
    _selectedDepartureDate = _briefingDates[0];
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
          emit(WxBriefErrorState(
              "Got error on 1800WxBriefCall : ${res?.statusCode} -> ${res?.statusMessage}"));
          print(
              "Got error on 1800WxBriefCall : ${res?.statusCode} -> ${res?.statusMessage}");
          break;
        default:
          break;
      }
    });
  }

  // Load product codes and tailoring options from CSV
  FutureOr<void> _getProductCodesAndTailoringOptions() async {
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
      emit(WxBriefPdfDocState(file.path));
    }
  }

  FutureOr<void> _updateAircraftRegistration(
      WxBriefUpdateAircraftRegistrationEvent event,
      Emitter<WxBriefState> emit) async {
    await repository.setAircraftRegistration(event.registration);
  }

  FutureOr<void> _updateAccountName(
      WxBriefUpdateAccountNameEvent event, Emitter<WxBriefState> emit) async {
    repository.setWxBriefAccountName(event.accountName);
  }

  FutureOr<void> _updateReportingOptions(
      WxBriefUpdateReportingOptionsEvent event, Emitter<WxBriefState> emit) {
    _fullTailoringOptionList = event.briefingOptions;
  }

  FutureOr<void> _updateProductOptions(
      WxBriefUpdateProductOptionsEvent event, Emitter<WxBriefState> emit) {
    _fullProductCodeList = event.briefingOptions;
  }

  FutureOr<void> _setDepartureDate(
      WxBriefUpdateDepartureDateEvent event, Emitter<WxBriefState> emit) {
    _selectedDepartureDate = event.departureDate;
  }
}
