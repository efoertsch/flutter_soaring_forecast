import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/options/turnpoint_regions.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';
import 'package:permission_handler/permission_handler.dart';

class TurnpointBloc extends Bloc<TurnpointEvent, TurnpointState> {
  final Repository repository;
  final List<TurnpointFile> turnpointFiles = [];

  //TurnpointState get initialState => TurnpointsLoadingState();

  TurnpointBloc({required this.repository}) : super(TurnpointsInitialState()) {
    on<TurnpointListEvent>(_showAllTurnpoints);
    on<SearchTurnpointsEvent>(_searchTurnpointsEvent);
    on<GetTurnpointFileNamesEvent>(_getListOfTurnpointExchangeFiles);
    on<LoadTurnpointFileEvent>(_loadTurnpointFileFromTurnpointExchange);
    on<DeleteAllTurnpointsEvent>(_deleteAllTurnpoints);
    //on<GetCustomImportFileNamesEvent>(_getCustomImportFileNames);
  }

  void _searchTurnpointsEvent(
      SearchTurnpointsEvent event, Emitter<TurnpointState> emit) async {
    if (event.searchString.length < 3) {
      emit(TurnpointSearchMessage("Enter more than 2 characters"));
      return;
    }
    emit(SearchingTurnpointsState());
    try {
      var turnpoints = await repository.findTurnpoints(event.searchString);
      emit(TurnpointsLoadedState(turnpoints));
    } catch (e) {
      emit(TurnpointSearchErrorState(e.toString()));
    }
  }

  void _showAllTurnpoints(
      TurnpointListEvent event, Emitter<TurnpointState> emit) async {
    await _loadAllTurnpoints(emit);
  }

  FutureOr<void> _loadAllTurnpoints(Emitter<TurnpointState> emit) async {
    emit(TurnpointsInitialState());
    List<Turnpoint> turnpoints = [];
    try {
      turnpoints.addAll(await repository.getAllTurnpoints());
      emit(TurnpointsLoadedState(turnpoints));
    } catch (e) {
      emit(TurnpointErrorState(e.toString()));
    }
  }

  void _getListOfTurnpointExchangeFiles(
      GetTurnpointFileNamesEvent event, Emitter<TurnpointState> emit) async {
    await _loadTurnpointFileNames(emit);
  }

  Future<void> _loadTurnpointFileNames(Emitter<TurnpointState> emit) async {
    try {
      turnpointFiles.clear();
      turnpointFiles
          .addAll(await repository.getListOfTurnpointExchangeRegionFiles());
      emit(TurnpointFilesFoundState(turnpointFiles));
    } catch (e) {
      print(e.toString());
      emit(TurnpointErrorState(e.toString()));
    }
  }

  Future<List<Turnpoint>> _getTurnpointsFromTurnpointExchange(
      TurnpointFile turnpointfile) async {
    return await repository.downloadTurnpointsFromTurnpointExchange(
        turnpointfile.location + "/" + turnpointfile.filename);
  }

  void _loadTurnpointFileFromTurnpointExchange(
      LoadTurnpointFileEvent event, Emitter<TurnpointState> emit) async {
    emit(TurnpointsInitialState());
    try {
      List<Turnpoint> turnpoints =
          await _getTurnpointsFromTurnpointExchange(event.turnpointFile);
      emit(
          TurnpointShortMessageState("${turnpoints.length} turnpoints loaded"));
      emit(TurnpointFilesFoundState(turnpointFiles));
    } catch (e) {
      print(e.toString());
      emit(TurnpointErrorState(e.toString()));
    }
  }

  void _deleteAllTurnpoints(
      DeleteAllTurnpointsEvent event, Emitter<TurnpointState> emit) async {
    try {
      await repository.deleteAllTurnpoints();
      await _loadAllTurnpoints(emit);
    } catch (e) {
      print(e.toString());
      emit(TurnpointErrorState(e.toString()));
    }
  }

  // FutureOr<void> _getCustomImportFileNames(GetCustomImportFileNamesEvent event,
  //     Emitter<TurnpointState> emit) async {
  //   var ok = await _checkPermissionToDownloadsDir();
  //   if (ok) {
  //     List<File> = await repository.getCupFilesInDownloadsDirectory();
  //   }
  // }

  Future<bool> _checkPermissionToDownloadsDir() async {
    var status = await Permission.storage.status;
    if (status.isGranted) {
      return true;
    }
    if (status.isDenied) {
      // We didn't ask for permission yet or the permission has been denied before but not permanently.
      return await Permission.storage.request().isGranted;
    }
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
    return false;
  }
}
