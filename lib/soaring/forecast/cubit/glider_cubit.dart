import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/cubit/polar_state.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/gliders.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';

enum VelocityConversion { kmh2kts, kts2kmh }

enum SinkRateConversion { mpsec2ftpmin, ftpmin2mpsec }

enum MassConversion { kg2lbs, lbs2kg }

class GliderCubit extends Cubit<GliderState> {
  late final Repository _repository;
  static const String ftPerMin = "ft/min";
  static const String mPerSec = "m/sec";
  static String kmPerHr = "km/hr";
  static const String knots = "kts";
  static const String pounds = "lbs";
  static const String kilos = "kgs";
  DisplayUnits? _displayUnits;
  Glider? _defaultGlider;
  Glider? _customGlider;
  String _velocityUnits = "";
  String _sinkRateUnits = "";
  String _massUnits = "";

  GliderCubit({required Repository repository})
      : _repository = repository,
        super(GliderPolarInitialState()) {}

  void _indicateWorking(bool isWorking) {
    emit(GliderPolarIsWorkingState(isWorking));
  }

  void getListOfGliders() async {
    _indicateWorking(true);
    List<String> gliders = [];
    List<Glider>? defaultList = await _repository.getDefaultListOfGliders();
    gliders.addAll(defaultList?.map((polar) => polar.glider) ?? <String>[]);
    emit(GliderListState(
        gliders, await _repository.getLastSelectedGliderName()));
    String selectedGlider = await _repository.getLastSelectedGliderName();
    if (selectedGlider.isNotEmpty) {
      await getGliderPolar(selectedGlider);
    }
    _indicateWorking(false);
  }

  Future<void> getGliderPolar(String glider) async {
    _indicateWorking(true);
    await _repository.saveLastSelectedGliderName(glider);
    _displayUnits = await _repository.getDisplayUnits();
    _assignDisplayUnitLabels();
    var gliderRecord =
        await _repository.getDefaultAndCustomGliderDetails(glider);
    // repository always have glider details in metric units
    _defaultGlider = gliderRecord.defaultGlider;
    _customGlider = gliderRecord.customGlider;
    // May need to convert to American units,
    var defaultGliderLocalUnits = _convertGliderValues(
        _defaultGlider!.copyWith(), DisplayUnits.Metric, _displayUnits!);
   var  customGliderLocalUnits = _convertGliderValues(
        _customGlider!.copyWith(), DisplayUnits.Metric, _displayUnits!);

    emit(GliderPolarState(defaultGliderLocalUnits, customGliderLocalUnits,
        _displayUnits!, _sinkRateUnits, _velocityUnits, _massUnits));
    _indicateWorking(false);
  }


  Future<void> saveDisplayUnits(DisplayUnits newDisplayUnits, Glider customGlider) async {
    _indicateWorking(true);
    if (_displayUnits == newDisplayUnits) return;
    _displayUnits = newDisplayUnits;
    await _repository.saveDisplayUnits(newDisplayUnits);
    _assignDisplayUnitLabels();
    //TODO very similar to above logic. Consolidate?
    var defaultGliderLocalUnits;
    var  customGliderLocalUnits;
    if (newDisplayUnits == DisplayUnits.American){
      // previously displaying metric, now want display in american units
      defaultGliderLocalUnits = _convertGliderValues(
          _defaultGlider!.copyWith(), DisplayUnits.Metric, _displayUnits!);
      customGliderLocalUnits = _convertGliderValues(
           customGlider.copyWith(), DisplayUnits.Metric, _displayUnits!);
    } else { // was american, now show in metric
      defaultGliderLocalUnits = _defaultGlider!.copyWith(); //
      customGliderLocalUnits =  _convertGliderValues(customGlider.copyWith(),
          DisplayUnits.American, DisplayUnits.Metric);
    }
      emit(GliderPolarState(defaultGliderLocalUnits, customGliderLocalUnits,
          _displayUnits!, _sinkRateUnits, _velocityUnits, _massUnits));
    _indicateWorking(false);
     }

  //
  // // Must pass in the glider with default(XCSOAR) values
  // // Will replace any existing customized glider polar values
  // Future<void> resetGliderToDefault(Glider glider) async {
  //   _customPolar = glider.copyWith();
  //  // await _repository.saveCustomPolar(newGlider);
  //  // Convert polar info to current units.
  //   emit(GliderPolarState(glider, newGlider, displayUnits));
  // }

  Glider _convertGliderValues(
      Glider gliderPolar, DisplayUnits fromUnits, DisplayUnits toUnits) {
    if (fromUnits == toUnits) return gliderPolar;
    VelocityConversion? velocityConversion;
    SinkRateConversion? sinkRateConversion;
    MassConversion? massConversion;

    if (toUnits == DisplayUnits.American) {
      velocityConversion = VelocityConversion.kmh2kts;
      sinkRateConversion = SinkRateConversion.mpsec2ftpmin;
      massConversion = MassConversion.kg2lbs;
    } else {
      velocityConversion = VelocityConversion.kts2kmh;
      sinkRateConversion = SinkRateConversion.ftpmin2mpsec;
      massConversion = MassConversion.lbs2kg;
    }

    gliderPolar.v1 = _convertVelocity(gliderPolar.v1, velocityConversion);
    gliderPolar.v2 = _convertVelocity(gliderPolar.v2, velocityConversion);
    gliderPolar.v3 = _convertVelocity(gliderPolar.v3, velocityConversion);

    gliderPolar.w1 = _convertSinkRate(gliderPolar.w1, sinkRateConversion);
    gliderPolar.w2 = _convertSinkRate(gliderPolar.w2, sinkRateConversion);
    gliderPolar.w3 = _convertSinkRate(gliderPolar.w3, sinkRateConversion);

    gliderPolar.gliderAndMaxPilotWgt =
        _convertMass(gliderPolar.gliderAndMaxPilotWgt, massConversion);
    gliderPolar.maxBallast =
        _convertMass(gliderPolar.maxBallast, massConversion);
    gliderPolar.gliderEmptyMass =
        _convertMass(gliderPolar.gliderEmptyMass, massConversion);
    gliderPolar.pilotMass =
        _convertMass(gliderPolar.pilotMass, massConversion);
    gliderPolar.thermallingSinkRate =
        _convertSinkRate(gliderPolar.thermallingSinkRate, sinkRateConversion);
    gliderPolar.minSinkSpeed =
        _convertVelocity(gliderPolar.minSinkSpeed, velocityConversion);
    gliderPolar.minSinkRate = _convertSinkRate(gliderPolar.minSinkRate, sinkRateConversion);
    return gliderPolar;
  }

  void _assignDisplayUnitLabels() {
    _velocityUnits = (_displayUnits == DisplayUnits.Metric) ? "km/hr" : "kts";
    _sinkRateUnits =
        (_displayUnits == DisplayUnits.Metric) ? "m/sec" : "ft/min";
    _massUnits = (_displayUnits == DisplayUnits.Metric) ? "kg" : "lbs";
  }

  double _convertVelocity(
      double? velocity, VelocityConversion velocityConversion) {
    if (velocity == null) return 0;
    if (velocityConversion == VelocityConversion.kmh2kts) {
      // input in metric (km/h) so convert velocity to kts
      return velocity * .539957;
    } else {
      // convert kts to km/h
      return velocity / .539957;
    }
  }

// Input value is always metric
  double _convertSinkRate(
      double? sinkRate, SinkRateConversion sinkRateConversion) {
    if (sinkRate == null) return 0;
    if (sinkRateConversion == SinkRateConversion.mpsec2ftpmin) {
      // input is m/sec so convert to ft/min
      return sinkRate * 3.28084 * 60.0;
    } else {
      // input is ft/min, convert to m/23
      return sinkRate / (3.28084 * 60.0);
    }
  }

  double _convertMass(double? mass, MassConversion massConversion) {
    if (mass == null) return 0;
    if (massConversion == MassConversion.kg2lbs) {
      // convert from kg to lbs
      return mass * 2.20462;
    } else {
      // convert lbs to kg
      return mass / 2.20462;
    }
  }

  void calcOptimalTaskTime() async {
    _indicateWorking(true);
    _customGlider = _convertGliderValues(
      _customGlider!,
      DisplayUnits.American,
      DisplayUnits.Metric,
    );
    await _repository.saveCustomPolar(_customGlider!);

    _customGlider!.calculatePolarAdjustmentFactor(_defaultGlider!);

    //  call repository
    _indicateWorking(false);
  }


}
