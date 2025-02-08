import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_models.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/windy/bloc/windy_event.dart';
import 'package:flutter_soaring_forecast/soaring/windy/bloc/windy_state.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_altitude.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_layer.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_model.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_startup_parms.dart';
import 'package:intl/intl.dart';

class WindyBloc extends Bloc<WindyEvent, WindyState> {
  final Repository repository;
  late final List<WindyModel> _models;
  late final List<WindyAltitude> _altitudes;
  late final List<WindyLayer> _layers;
  final int _zoom = 8;
  String? _regionName;

  WindyBloc({required this.repository}) : super(WindyLoadingState()) {
    on<WindyInitEvent>(_getWindyInitData);
    on<LoadWindyHTMLEvent>(_getWindyHTML);
    on<WindyModelEvent>(_setWindyModel);
    on<WindyAltitudeEvent>(_setWindyAltitude);
    on<WindyLayerEvent>(_setWindyLayer);
    on<DisplayTaskIfAnyEvent>(_displayTaskIfAny);
    on<SelectTaskEvent>(_selectTask);
    on<ClearTaskEvent>(_clearTask);
    on<DisplayTopoMapTypeEvent>(_displayTopoMap);
    on<AssignWindyStartupParms>(_assignWindyStartupParms);
  }

  FutureOr<void> _getWindyInitData(
      WindyInitEvent event, Emitter<WindyState> emit) async {

    _models = await repository.getWindyModels();
    emit(WindyModelListState(_models));
    _layers = await repository.getWindyLayers();
    emit(WindyLayerListState(_layers));
    _altitudes = await repository.getWindyAltitudes();
    emit(WindyAltitudeListState(_altitudes));
    _setAltitudeVisiblity(emit, 0);
    emit(WindyInitComplete());
  }

  Future<Model> _getRegionLatLngBounds() async {
    _regionName = await repository.getSelectedRegionName();
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final forecastModels =
        await repository.getforecastModelsForRegionAndDate(_regionName!, date);
    return forecastModels.models[0];
  }

  Future<String> _getWindyApiKey() async {
    return await repository.getWindyKey();
  }

  FutureOr<void> _setWindyLayer(
      WindyLayerEvent event, Emitter<WindyState> emit) {
    emit(WindyJavaScriptState(
        "setLayer(" + "'" + _layers[event.index].code + "')"));
    _setAltitudeVisiblity(emit, event.index);
  }

  FutureOr<void> _setWindyAltitude(
      WindyAltitudeEvent event, Emitter<WindyState> emit) {
    emit(WindyJavaScriptState(
        "setAltitude(" + "'" + _altitudes[event.index].windyCode + "')"));
  }

  void _setAltitudeVisiblity(Emitter<WindyState> emit, int index) {
    emit(WindyAltitudeVisibleState(_layers[index].byAltitude));
  }

  FutureOr<void> _setWindyModel(
      WindyModelEvent event, Emitter<WindyState> emit) {
    emit(WindyJavaScriptState(
        "setModel(" + "'" + _models[event.index].code + "')"));
  }

  FutureOr<void> _displayTopoMap(
      DisplayTopoMapTypeEvent event, Emitter<WindyState> emit) {
    if (event.displayTopoMap) {
      emit(WindyJavaScriptState("setBaseLayerToArcGisMap()"));
    } else {
      emit(WindyJavaScriptState("setBaseLayerToDefault()"));
    }
  }

  FutureOr<void> _sendJavaScriptCommand(
      Emitter<WindyState> emit, String javaScript) async {
    print("Sending Javascript command:" + javaScript);
    emit(WindyJavaScriptState(javaScript));
  }

  FutureOr<void> _selectTask(
      SelectTaskEvent event, Emitter<WindyState> emit) async {
    int taskId = event.taskId;
    repository.setCurrentTaskId(taskId);
    await _loadTask(taskId, emit);
  }

  FutureOr<void> _displayTaskIfAny(
      DisplayTaskIfAnyEvent event, Emitter<WindyState> emit) async {
    final taskId = await repository.getCurrentTaskId();
    if (taskId > -1) {
      await _loadTask(taskId, emit);
    }
  }

  Future<void> _loadTask(int taskId, Emitter<WindyState> emit) async {
    if (taskId > -1) {
      final List<TaskTurnpoint> taskTurnpoints =
          await repository.getTaskTurnpoints(taskId);
      final jsonString = jsonEncode(taskTurnpoints);
      _sendJavaScriptCommand(emit, "drawTask(" + jsonString + ")");
      // bit of hack. Let UI know task sent to javascript method
      emit(TaskDrawnState(true));
    }
  }

  FutureOr<void> _clearTask(
      ClearTaskEvent event, Emitter<WindyState> emit) async {
    repository.setCurrentTaskId(-1);
    _sendJavaScriptCommand(emit, "drawTask()");
  }

  FutureOr<void> _getWindyHTML(
      LoadWindyHTMLEvent event, Emitter<WindyState> emit) async {
    final baseWindyHtml = await repository.getCustomWindyHtml();
    final customWindyHtml = baseWindyHtml.replaceFirst(
        "XXXHEIGHTXXX", event.widgetHeight.toString());
    emit(WindyHtmlState(customWindyHtml));
  }

  FutureOr<void> _assignWindyStartupParms(
      AssignWindyStartupParms event, Emitter<WindyState> emit) async {
    final windyKey = await _getWindyApiKey();
    final model = await _getRegionLatLngBounds();
    final windyStartupParms = WindyStartupParms(
        key: windyKey,
        lat: model.center[0],
        long: model.center[1],
        mapLatLngBounds: model.latLngBounds,
        zoom: _zoom);
    final jsonString = jsonEncode(windyStartupParms);
    _sendJavaScriptCommand(emit, "assignWindyStartupParms(" + jsonString + ")");
  }
}
