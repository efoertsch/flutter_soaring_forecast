import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/estimated_flight_avg_summary.dart';
import 'package:flutter_soaring_forecast/soaring/task_estimate/cubit/task_estimate_state.dart';

import '../../floor/taskturnpoint/task_turnpoint.dart';
import '../../region_model/data/region_model_data.dart';
import '../../repository/rasp/gliders.dart';
import '../../repository/repository.dart';

class TaskEstimateCubit extends Cubit<TaskEstimateState> {
  late final Repository _repository;

  String _regionName = "";
  String _selectedModelName = ""; // nam
  String _selectedForecastDate = ""; // selected date  2019-12-19
  String _selectedHour = "";
  int _taskId = -1;
  bool _startup = false;
  String _taskLatLonString = "";
  String _gliderName = "";
  Glider? _gliderPolar;
  int _selectedForecastTimeIndex = 0;
  List<String> _forecastHours = [];

  TaskEstimateCubit({required Repository repository})
      : _repository = repository,
        super(TaskEstimateInitialState()) {}

  void _indicateWorking(bool isWorking) {
    emit(TaskEstimateWorkingState(isWorking));
  }

  Future<void> setRegionModelDateParms(
      EstimatedTaskRegionModel estimatedTaskRegionModel) async {
    _indicateWorking(true);
    EstimatedTaskRegionModel info = estimatedTaskRegionModel;
    _regionName = info.regionName;
    _selectedModelName = info.selectedModelName; // nam
    _selectedForecastDate = info.selectedDate; // selected date  2019-12-19
    _forecastHours = info.forecastHours;
    _selectedHour = info.forecastHours[info.selectedHourIndex]; // 1300
    var showExperimental =
        await _repository.getDisplayExperimentalEstimatedTaskAlertFlag();
    if (showExperimental) {
      emit(DisplayExperimentalHelpText(showExperimental, true));
    } else {
      doCalc();
    }
  }

  Future<void> doCalc() async {
    await _getTaskDetails();
    await _getGliderPolar();
    if (_gliderPolar != null) {
      await _calculateTaskEstimates();
    }
  }

  Future<Glider?> _getGliderPolar() async {
    _gliderName = await _repository.getLastSelectedGliderName();
    if (_gliderName == "") {
      emit(DisplayGlidersState());
      return null;
    }
    // Since a glider was previously selected, it *should* be in custom glider
    // list;
    _gliderPolar = await _repository.getCustomGliderPolar(_gliderName);
    return _gliderPolar;
  }

  Future<bool> checkToDisplayExperimentalText() async {
    var displayText =
        await _repository.getShowEstimatedFlightExperimentalText();
    if (displayText) {
      emit(DisplayEstimatedFlightText());
    }
    return displayText;
  }

  // User selected new glider or maybe changed glider polar
  Future<void> calcEstimatedTaskWithNewGlider() async {
    await _getGliderPolar();
    await _calculateTaskEstimates();
  }

  Future<void> _calculateTaskEstimates() async {
    if (_gliderPolar != null && _taskLatLonString.isNotEmpty) {
      await _getEstimatedFlightAvg();
    }
  }

  Future<void> _getEstimatedFlightAvg() async {
    emit(TaskEstimateWorkingState(true));

    //Note per Dr Jack. thermalMultiplier was a fudge factor that could be added if you want to bump up or down
    // wstar value used in sink rate calc. For now just use 1
    var optimizedTaskRoute = await _repository.getEstimatedFlightSummary(
        _regionName,
        _selectedForecastDate,
        _selectedModelName,
        'd2',
        _selectedHour + 'x',
        _gliderPolar!.glider,
        _gliderPolar!.polarWeightAdjustment,
        _gliderPolar!.getPolarCoefficientsAsString(),
        // string of a,b,c
        _gliderPolar!.ballastAdjThermalingSinkRate,
        1,
        _taskLatLonString);
    if (optimizedTaskRoute?.routeSummary?.error != null) {
      emit(TaskEstimateErrorState(optimizedTaskRoute!.routeSummary!.error!));
      emit(TaskEstimateWorkingState(false));
    } else {
      _eliminateDuplicateFootingText(optimizedTaskRoute!.routeSummary!.footers);
      emit(TaskEstimateWorkingState(false));
      emit(EstimatedFlightSummaryState(optimizedTaskRoute));
    }
  }

  Future<void> _getTaskDetails() async {
    if (_taskId >= 0) {
      return; // got task already
    }
    _taskId = await _repository.getCurrentTaskId();
    List<TaskTurnpoint> taskTurnpoints = [];
    if (_taskId > -1) {
      taskTurnpoints.addAll(await _repository.getTaskTurnpoints(_taskId));
      // print('emitting taskturnpoints');
    }
    StringBuffer turnpointLatLons = StringBuffer();
    _taskLatLonString = "";
    int index = 1;
    for (var taskTurnpoints in taskTurnpoints) {
      turnpointLatLons.write(index.toString());
      turnpointLatLons.write(",");
      turnpointLatLons.write(taskTurnpoints.latitudeDeg.toString());
      turnpointLatLons.write(",");
      turnpointLatLons.write(taskTurnpoints.longitudeDeg.toString());
      turnpointLatLons.write(",");
      turnpointLatLons.write(taskTurnpoints.title.substring(0,
          taskTurnpoints.title.length > 4 ? 4 : taskTurnpoints.title.length));
      turnpointLatLons.write(",");
      index++;
    }
    if (turnpointLatLons.length > 0) {
      _taskLatLonString =
          turnpointLatLons.toString().substring(0, turnpointLatLons.length - 1);
    }
  }

  void processModelDateChange(
      {required regionName,
      required selectedModelName,
      required selectedDate,
      required forecastHours,
      required selectedHourIndex}) async {
    _regionName = regionName;
    _selectedModelName = selectedModelName;
    _selectedForecastDate = selectedDate;
    _forecastHours = _forecastHours;
    _selectedForecastTimeIndex = selectedHourIndex;
    _selectedHour = _forecastHours[_selectedForecastTimeIndex];
    await _calculateTaskEstimates();
  }

  void processTimeChange(String forecastHour) async {
    _selectedHour = forecastHour;
    await _calculateTaskEstimates();
  }

  Future<void> displayExperimentalText(bool value) async {
    _repository.saveDisplayExperimentalEstimatedTaskAlertFlag(value);
  }

  Future<void> resetExperimentalTextDisplay() async {
    displayExperimentalText(true);
    emit(DisplayEstimatedFlightText());
  }

  void updateTimeIndex(int incOrDec) async {
    // print('Current _selectedForecastTimeIndex $_selectedForecastTimeIndex'
    //     '  incOrDec $incOrDec');
    if (incOrDec > 0) {
      _selectedForecastTimeIndex =
          (_selectedForecastTimeIndex == _forecastHours.length - 1)
              ? 0
              : _selectedForecastTimeIndex + incOrDec;
    } else {
      _selectedForecastTimeIndex = (_selectedForecastTimeIndex == 0)
          ? _forecastHours.length - 1
          : _selectedForecastTimeIndex + incOrDec;
    }
    _selectedHour = _forecastHours[_selectedForecastTimeIndex];
    emit(CurrentHourState(_forecastHours[_selectedForecastTimeIndex]));
    await _calculateTaskEstimates();
  }

  // This is used for when user hits help button
  Future<void> showExperimentalTextHelp() async {
    var showExperimentalText =
        await _repository.getDisplayExperimentalEstimatedTaskAlertFlag();
    emit(DisplayExperimentalHelpText(showExperimentalText, false));
  }
}

// eliminate duplicate text like (this comes across as 1 long string not by line as shown below
// WARNING: Data unavailable after 1700 so assumed constant conditions after that time.
// Data unavailable after 1700 so assumed constant conditions after that time.
// Data unavailable after 1700 so assumed constant conditions after that time.
// Data unavailable after 1700 so assumed constant conditions after that time.
_eliminateDuplicateFootingText(List<Footer>? footers) {
  List<Footer> footerText = [];
  if (footers == null) {
    return;
  }
  for (Footer footer in footers) {
    if (footer.message != null) {
      //List<String> pieces = footer.message!.split(RegExp(r'[\.:]'));
      List<String> pieces = footer.message!.split("\n");
      for (String piece in pieces) {
        if (footerText.isEmpty ||
            (footerText.last.message!.trim() != piece.trim() &&
                piece.isNotEmpty)) {
          footerText.add(Footer(message: piece));
        }
      }
    }
  }

  footers.clear();
  footers.addAll(footerText);
}
