import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/repository/options/settings.dart';

@immutable
abstract class SettingsState {}

class SettingsInitialState extends SettingsState {}

class SettingOptionsState extends SettingsState {
  final List<Group>? settings;

  SettingOptionsState(this.settings);
}

class SettingsErrorState extends SettingsState {
  final String error;

  SettingsErrorState(this.error);

  @override
  List<Object?> get props => [error];
}
