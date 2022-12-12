import 'package:flutter/foundation.dart';
import 'package:flutter_soaring_forecast/soaring/repository/options/setttings.dart';

@immutable
abstract class SettingsState {}

class SettingsInitialState extends SettingsState {}

class SettingOptionsState extends SettingsState {
  final List<Settings>? settings;

  SettingOptionsState(this.settings);
}

class SettingsErrorState extends SettingsState {
  final String error;

  SettingsErrorState(this.error);

  @override
  List<Object?> get props => [error];
}
