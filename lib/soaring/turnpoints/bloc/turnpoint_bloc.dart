import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/options/turnpoint_regions.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/cup/cup_styles.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoint_utils.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

class TurnpointBloc extends Bloc<TurnpointEvent, TurnpointState> {
  final Repository repository;
  final List<TurnpointFile> turnpointFiles = [];
  final List<Style> cupStyles = [];

  //TurnpointState get initialState => TurnpointsLoadingState();

  TurnpointBloc({required this.repository}) : super(TurnpointsInitialState()) {
    on<TurnpointListEvent>(_showAllTurnpoints);
    on<SearchTurnpointsEvent>(_searchTurnpointsEvent);
    on<GetTurnpointFileNamesEvent>(_getListOfTurnpointExchangeFiles);
    on<LoadTurnpointFileEvent>(_loadTurnpointFileFromTurnpointExchange);
    on<DeleteAllTurnpointsEvent>(_deleteAllTurnpoints);
    on<CheckIfDuplicateTurnpointCodeEvent>(_checkIfDuplicateTurnpointCode);
    on<TurnpointViewEvent>(_getTurnpoint);
    on<CupStylesEvent>(_getAllCupStyles);
    on<SaveTurnpointEvent>(_saveTurnpoint);
    on<DeleteTurnpoint>(_deleteTurnpoint);
    on<GetCurrentLocation>(_getCurrentLocation);
    on<GetElevationAtLatLong>(_getElevationAtLatLong);
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
      if (TurnpointUtils.getCupStyles().isEmpty) {
        final List<Style> cupStyles = await _getCupStyles();
        TurnpointUtils.setCupStyles(cupStyles);
      }
      emit(TurnpointsLoadedState(turnpoints, TurnpointUtils.getCupStyles()));
    } catch (e) {
      emit(TurnpointSearchErrorState(e.toString()));
    }
  }

  Future<List<Style>> _getCupStyles() async {
    return await repository.getCupStyles();
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
      if (TurnpointUtils.getCupStyles().isEmpty) {
        final List<Style> cupStyles = await _getCupStyles();
        TurnpointUtils.setCupStyles(cupStyles);
      }
      emit(TurnpointsLoadedState(turnpoints, TurnpointUtils.getCupStyles()));
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

  void _checkIfDuplicateTurnpointCode(CheckIfDuplicateTurnpointCodeEvent event,
      Emitter<TurnpointState> emit) async {
    Turnpoint? turnpoint =
        await repository.getTurnpointByCode(event.turnpointCode);
    if (turnpoint != null) {
      emit(TurnpointDuplicateCode());
      emit(TurnpointErrorState("Duplicate turnpoint code"));
    }
  }

  void _getAllCupStyles(CupStylesEvent event, Emitter<TurnpointState> emit) {
    print("Emitting CupStyles");
    emit(TurnpointCupStyles(TurnpointUtils.getCupStyles()));
  }

  FutureOr<void> _getTurnpoint(
      TurnpointViewEvent event, Emitter<TurnpointState> emit) async {
    Turnpoint? turnpoint;
    if (event.turnpointId == null) {
      turnpoint = Turnpoint();
    } else {
      turnpoint = await repository.getTurnpointById(event.turnpointId!);
      if (turnpoint == null) {
        turnpoint = Turnpoint();
      }
    }
    emit(EditTurnpoint(turnpoint));
  }

  FutureOr<int?> _saveTurnpoint(
      SaveTurnpointEvent event, Emitter<TurnpointState> emit) async {
    final turnpoint = event.turnpoint;
    int? id = turnpoint.id;
    try {
      if (turnpoint.id == null) {
        id = await repository.saveTurnpoint(turnpoint);
      } else {
        id = await repository.updateTurnpoint(turnpoint);
      }
    } catch (e) {
      emit(TurnpointErrorState(
          "Oops. An error occurred adding/updating the turnpoint!"));
      return null;
    }
    emit(TurnpointShortMessageState("Turnpoint updated."));
    turnpoint.id = id;
    emit(UpdatedTurnpoint(turnpoint));
  }

  FutureOr<void> _deleteTurnpoint(
      DeleteTurnpoint event, Emitter<TurnpointState> emit) {
    try {
      repository.deleteTurnpoint(event.id);
      emit(TurnpointDeletedState());
    } catch (e) {
      emit(TurnpointErrorState(
          "Oops. An error occurred deleting the turnpoint!"));
      return null;
    }
  }

  // only call when sure that user has given permission
  FutureOr<void> _getCurrentLocation(
      GetCurrentLocation event, Emitter<TurnpointState> emit) async {
    Location location = Location();
    try {
      final currentLocation = await location.getLocation();
      if (currentLocation.altitude != null && currentLocation.altitude == 0) {
        double? elevation = await getUSGSElevationAtLocation(
            currentLocation.latitude ?? 0, currentLocation.longitude ?? 0);
      }
      print(
          "location: ${currentLocation.latitude} ${currentLocation.longitude}, elevation(m): ${currentLocation.altitude} ");
      emit(CurrentLocationState(currentLocation!.latitude ?? 0,
          currentLocation!.longitude ?? 0, currentLocation.altitude ?? 0));
    } catch (e) {
      emit(TurnpointErrorState("Oops. Can't find your location!"));
    }
  }

  FutureOr<double?> _getElevationAtLatLong(
      GetElevationAtLatLong event, Emitter<TurnpointState> emit) async {
    double elevation;
    try {
      elevation =
          await getUSGSElevationAtLocation(event.latitude, event.longitude);
      emit(LatLongElevationState(event.latitude, event.longitude, elevation));
    } catch (e) {
      emit(TurnpointErrorState("Ooops. Could not get elevation at that point"));
      return 0;
    }
  }

  Future<double> getUSGSElevationAtLocation(
      double latitude, double longitude) async {
    double elevation;
    final nationalMap =
        await repository.getElevationAtLatLongPoint(latitude, longitude);
    elevation =
        nationalMap.uSGSElevationPointQueryService!.elevationQuery!.elevation ??
            0.0;
    return elevation;
  }
}
