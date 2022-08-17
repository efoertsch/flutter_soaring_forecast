import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/region/bloc/region_event.dart';
import 'package:flutter_soaring_forecast/soaring/region/bloc/region_state.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/regions.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';

class RegionDataBloc extends Bloc<RegionDataEvent, RegionDataState> {
  final Repository repository;
  Regions? _regions;
  Region? _region;

  RegionDataBloc({required this.repository}) : super(RegionInitialState()) {
    on<ListRegionsEvent>(_getRegionList);
    on<RegionNameSelectedEvent>(_saveSelectedRegion);
  }

  Future<void> _getRegionList(
      ListRegionsEvent event, Emitter<RegionDataState> emit) async {
    final regionList = <String>[];
    _regions = await repository.getRegions();
    // print("_getRegionList #regions: ${_regions?.regions!.length}");
    // print(_regions?.regions!.toString());
    _regions?.regions!.forEach((region) {
      if (region.name != null) {
        regionList.add(region.name!);
      }
    });
    emit(RegionsLoadedState(regionList));
  }

  FutureOr<void> _saveSelectedRegion(
      RegionNameSelectedEvent event, Emitter<RegionDataState> emit) async {
    await repository.saveSelectedRegionName(event.regionName);
  }
}
