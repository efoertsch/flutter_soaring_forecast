
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/cubit/polar_state.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/polars.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';

class GliderPolarCubit extends Cubit<PolarDataState> {
  bool _isWorking = false;
  late final Repository _repository;

  GliderPolarCubit({required Repository repository}) : _repository = repository, super(GliderPolarInitialState()) {
  }

  void  indicateWorking(bool isWorking){
    emit(GliderPolarIsWorkingState(isWorking));
  }

  void getListOfGliders() async {
    indicateWorking(true);
    List<String> gliders = [];
    List<Polar>? defaultList = await _repository.getDefaultListOfGliderPolars();
    gliders.addAll( defaultList?.map((polar) => polar.glider) ?? <String>[]);
    emit(GliderListState(gliders));
    indicateWorking(false);
  }

  void getGliderPolar(String glider) async {
    indicateWorking(true);
    Polar? polar = await _repository.getGliderPolar(glider);
    emit(GliderPolarState(polar));
    indicateWorking(false);
  }

}