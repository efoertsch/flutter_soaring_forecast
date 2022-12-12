import 'package:flutter/foundation.dart';

@immutable
abstract class SettingsEvent {}

class GetInitialSettingsEvent extends SettingsEvent {}

class SettingsSetEvent extends SettingsEvent {
  final String key;
  final bool value;

  SettingsSetEvent(this.key, this.value);
}
