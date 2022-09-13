import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/windy/bloc/windy_event.dart';
import 'package:flutter_soaring_forecast/soaring/windy/bloc/windy_state.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class WindyBloc extends Bloc<WindyEvent, WindyState> {
  final Repository repository;
  Task currentTask = Task();
  List<TaskTurnpoint> _taskTurnpoints = [];

  WindyBloc({required this.repository}) : super(WindyLoadingState()) {
    on<WindyInitEvent>(_getWindyInitData);
  }
  FutureOr<void> _getWindyInitData(
      WindyInitEvent event, Emitter<WindyState> emit) async {
    final models = await repository.getWindyModels();
    emit(WindyModelListState(models));
    final layers = await repository.getWindyLayers();
    emit(WindyLayerListState(layers));
    final altitudes = await repository.getWindyAltitudes();
    emit(WindyAltitudeListState(altitudes));
    final customWindHtml = await repository.getCustomWindyHtml();
    emit(WindyHtmlState(customWindHtml));
  }

  Future<LatLng> _getRegionModels() async {
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
}
