import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/windy/bloc/windy_event.dart';
import 'package:flutter_soaring_forecast/soaring/windy/bloc/windy_state.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_altitude.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_layer.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_model.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_startup_parms.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class WindyBloc extends Bloc<WindyEvent, WindyState> {
  final Repository repository;
  Task currentTask = Task();
  List<TaskTurnpoint> _taskTurnpoints = [];
  late final List<WindyModel> models;
  late final List<WindyAltitude> altitudes;
  late final List<WindyLayer> layers;
  final int zoom = 8;

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
  }

  FutureOr<void> _getWindyInitData(
      WindyInitEvent event, Emitter<WindyState> emit) async {
    // if (Platform.isAndroid) {
    //   await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
    // }
    models = await repository.getWindyModels();
    emit(WindyModelListState(models));
    layers = await repository.getWindyLayers();
    emit(WindyLayerListState(layers));
    altitudes = await repository.getWindyAltitudes();
    _setAltitudeVisiblity(emit, 0);
    emit(WindyAltitudeListState(altitudes));
    await _getInitialWindyStartupParms(emit);
  }

  Future<void> _getInitialWindyStartupParms(Emitter<WindyState> emit) async {
    final windyKey = await _getWindyApiKey();
    final latLng = await _getRegionLatLng();
    emit(WindyStartupParmsState(WindyStartupParms(
        key: windyKey,
        lat: latLng.latitude,
        long: latLng.longitude,
        zoom: zoom)));
  }

  Future<LatLng> _getRegionLatLng() async {
    final regionName = await repository.getSelectedRegionName();
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final forecastModels =
        await repository.getforecastModelsForRegionAndDate(regionName, date);
    final firstModel = forecastModels.models[0];
    return LatLng(firstModel.center[0], firstModel.center[1]);
  }

  Future<String> _getWindyApiKey() async {
    return await repository.getWindyKey();
  }

  FutureOr<void> _setWindyLayer(
      WindyLayerEvent event, Emitter<WindyState> emit) {
    emit(WindyJavaScriptState(
        "setLayer(" + "'" + layers[event.index].code + "')"));
    _setAltitudeVisiblity(emit, event.index);
  }

  FutureOr<void> _setWindyAltitude(
      WindyAltitudeEvent event, Emitter<WindyState> emit) {
    emit(WindyJavaScriptState(
        "setAltitude(" + "'" + altitudes[event.index].windyCode + "')"));
  }

  void _setAltitudeVisiblity(Emitter<WindyState> emit, int index) {
    emit(WindyAltitudeVisibleState(layers[index].byAltitude));
  }

  FutureOr<void> _setWindyModel(
      WindyModelEvent event, Emitter<WindyState> emit) {
    emit(WindyJavaScriptState(
        "setModel(" + "'" + models[event.index].code + "')"));
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
    }
  }

  FutureOr<void> _clearTask(
      ClearTaskEvent event, Emitter<WindyState> emit) async {
    _sendJavaScriptCommand(emit, "drawTask()");
  }

  FutureOr<void> _getWindyHTML(
      LoadWindyHTMLEvent event, Emitter<WindyState> emit) async {
    final baseWindyHtml = await repository.getCustomWindyHtml();
    final customWindyHtml = baseWindyHtml.replaceFirst(
        "XXXHEIGHTXXX", event.widgetHeight.toString());
    emit(WindyHtmlState(customWindyHtml));
  }
}
