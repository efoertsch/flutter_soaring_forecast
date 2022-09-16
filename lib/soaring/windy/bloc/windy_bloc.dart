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
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class WindyBloc extends Bloc<WindyEvent, WindyState> {
  final Repository repository;
  Task currentTask = Task();
  List<TaskTurnpoint> _taskTurnpoints = [];
  late final List<WindyModel> models;
  late final List<WindyAltitude> altitudes;
  late final List<WindyLayer> layers;

  WindyBloc({required this.repository}) : super(WindyLoadingState()) {
    on<WindyInitEvent>(_getWindyInitData);
    on<WindyWidgetSizeEvent>(_setWindyWidgetSize);
    on<WindyModelEvent>(_setWindyModel);
    on<WindyAltitudeEvent>(_setWindyAltitude);
    on<WindyLayerEvent>(_setWindyLayer);
    on<SelectTaskEvent>(_selectTask);
    on<ClearTaskEvent>(_clearTask);
  }

  FutureOr<void> _getWindyInitData(
      WindyInitEvent event, Emitter<WindyState> emit) async {
    final key = await _getWindyApiKey();
    emit(WindyKeyState(key));
    final latLng = await _getRegionLatLng();
    emit(WindyLatLngState(latLng));

    models = await repository.getWindyModels();
    emit(WindyModelListState(models));
    layers = await repository.getWindyLayers();
    emit(WindyLayerListState(layers));
    altitudes = await repository.getWindyAltitudes();
    emit(WindyAltitudeListState(altitudes));
    await _emitWindyHtml(emit);
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
      WindyLayerEvent event, Emitter<WindyState> emit) {}

  FutureOr<void> _setWindyAltitude(
      WindyAltitudeEvent event, Emitter<WindyState> emit) {}

  FutureOr<void> _setWindyModel(
      WindyModelEvent event, Emitter<WindyState> emit) {}

  _sendJavaScriptCommand(Emitter<WindyState> emit, String javaScript) {
    emit(WindyJavaScriptState(javaScript));
  }

  FutureOr<void> _selectTask(
      SelectTaskEvent event, Emitter<WindyState> emit) async {
    int taskId = event.taskId;
    repository.setCurrentTaskId(taskId);
    if (taskId > -1) {
      final List<TaskTurnpoint> taskTurnpoints =
          await repository.getTaskTurnpoints(taskId);
      final jsonString = jsonEncode(taskTurnpoints);
      _sendJavaScriptCommand(emit, "drawTask(" + jsonString + ")");
    }
  }

  FutureOr<void> _clearTask(ClearTaskEvent event, Emitter<WindyState> emit) {
    _sendJavaScriptCommand(emit, "drawTask()");
  }

  FutureOr<void> _setWindyWidgetSize(
      WindyWidgetSizeEvent event, Emitter<WindyState> emit) async {
    final customWindyHtml = await repository.getCustomWindyHtml();
    customWindyHtml.replaceFirst("XXXHEIGHTXXX", event.size.height.toString());
    emit(WindyHtmlState(customWindyHtml));
  }

  FutureOr<void> _emitWindyHtml(Emitter<WindyState> emit) async {
    final customWindyHtml = await repository.getCustomWindyHtml();
    //customWindyHtml.replaceFirst("XXXHEIGHTXXX", event.size.height.toString());
    emit(WindyHtmlState(customWindyHtml));
  }
}
