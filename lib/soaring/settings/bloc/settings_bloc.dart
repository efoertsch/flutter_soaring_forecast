import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/settings/bloc/settings_event.dart';
import 'package:flutter_soaring_forecast/soaring/settings/bloc/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final Repository repository;

//TaskState get initialState => TasksLoadingState();

  SettingsBloc({required this.repository}) : super(SettingsInitialState()) {
    on<GetInitialSettingsEvent>(_getInitialSettings);
    on<SettingsSetBoolEvent>(_saveBoolSetting);
    on<SettingsSetStringEvent>(_saveStringSetting);
  }

  FutureOr<void> _getInitialSettings(event, Emitter<SettingsState> emit) async {
    await repository
        .getSettingOptionsFromAssets()
        .then((settings) => emit(SettingOptionsState(settings)), onError: (e) {
      emit(SettingsErrorState(e.toString()));
    });
  }

  FutureOr<void> _saveBoolSetting(
      SettingsSetBoolEvent event, Emitter<SettingsState> emit) {
    repository.saveGenericBool(key: event.key, value: event.value);
  }

  FutureOr<void> _saveStringSetting(
      SettingsSetStringEvent event, Emitter<SettingsState> emit) {
    repository.saveGenericString(key: event.key, value: event.value);
  }
}
