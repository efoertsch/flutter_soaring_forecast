import 'package:flutter_bloc/flutter_bloc.dart';
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

  Future<void> setRegionModelDateParms(EstimatedTaskRegionModel estimatedTaskRegionModel ) async {
    _indicateWorking(true);
    EstimatedTaskRegionModel info = estimatedTaskRegionModel;
    _regionName = info.regionName;
    _selectedModelName = info.selectedModelName; // nam
    _selectedForecastDate = info.selectedDate; // selected date  2019-12-19
    _forecastHours = info.forecastHours;
    _selectedHour = info.forecastHours[info.selectedHourIndex]; // 1300
    doCalc();
    _indicateWorking(false);
  }

  Future<void> doCalc() async {
    await _getTaskDetails();
    await _getGliderPolar();
    if (_gliderPolar != null) {
      _calculateTaskEstimates();
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

  Future<void> _calculateTaskEstimates()async {
    if (_gliderPolar != null && _taskLatLonString.isNotEmpty) {
      _getEstimatedFlightAvg();
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
      emit(TaskEstimateWorkingState(false));
      emit(EstimatedFlightSummaryState(optimizedTaskRoute!));
    }
  }

  Future<void> _getTaskDetails() async {
    if (_taskId >= 0){
      return;  // got task already
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

  void processModelDateChange( {required  regionName,
    required selectedModelName,
    required  selectedDate,
    required  forecastHours,
    required  selectedHourIndex}) {
    _regionName = regionName;
    _selectedModelName = selectedModelName;
    _selectedForecastDate = selectedDate;
    _forecastHours = _forecastHours;
    _selectedForecastTimeIndex = selectedHourIndex;
     _selectedHour = _forecastHours[_selectedForecastTimeIndex];
    _calculateTaskEstimates();
  }

  void processTimeChange(String forecastHour) {
    _selectedHour = forecastHour;
    _calculateTaskEstimates();
  }

  Future<void> displayExperimentalText(bool value) async {
    _repository.saveDisplayExperimentalOptimalTaskAlertFlag(value);
  }

  Future<void> resetExperimentalTextDisplay() async {
    displayExperimentalText(true);
    emit(DisplayEstimatedFlightText());
  }

  void updateTimeIndex(int incOrDec) {
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
      emit(CurrentHourState(_forecastHours[_selectedForecastTimeIndex]));
    }
  }

  Future<void> closedExperimentalDisclaimer() async {
    if (_startup) {
      String gliderName = await _repository.getLastSelectedGliderName();
      if (gliderName.isNotEmpty) {
        // get glider info and calc task estimates
      } else {
        // display glider polar
      }
    }
  }
}
