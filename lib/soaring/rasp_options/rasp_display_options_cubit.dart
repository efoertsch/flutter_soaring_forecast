import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/constants.dart';
import '../repository/repository.dart';
import 'rasp_display_option_state.dart';

class RaspDisplayOptionsCubit extends Cubit<RaspPreferenceOptionState> {
  late final Repository _repository;

  RaspDisplayOptionsCubit({required Repository repository})
      : _repository = repository,
        super(RaspPreferenceOptionInitialState()) {}

  Future<void> getRaspPreferenceOptions() async {
    final preferenceOptions = await _repository.getRaspDisplayOptions();
    emit(RaspPreferenceOptionsState(preferenceOptions));
  }

  Future<void> saveRaspPreferenceOption(PreferenceOption displayOption) async {
    await _repository.saveRaspDisplayOption(displayOption);
  }
}
