import '../app/constants.dart';

abstract class RaspPreferenceOptionState {
}

class RaspPreferenceOptionInitialState extends RaspPreferenceOptionState {
}

class RaspPreferenceOptionsState extends RaspPreferenceOptionState {
  final List<PreferenceOption> preferenceOptions;
  RaspPreferenceOptionsState(this.preferenceOptions);
}