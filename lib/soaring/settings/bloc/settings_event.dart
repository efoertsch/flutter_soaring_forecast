import 'package:flutter/foundation.dart';

@immutable
abstract class SettingsEvent {}

class GetInitialSettingsEvent extends SettingsEvent {}

class SettingsSetBoolEvent extends SettingsEvent {
  final String key;
  final bool value;

  SettingsSetBoolEvent(this.key, this.value);
}


class SettingsSetStringEvent extends SettingsEvent {
  final String key;
  final String value;

  SettingsSetStringEvent(this.key, this.value);
}

