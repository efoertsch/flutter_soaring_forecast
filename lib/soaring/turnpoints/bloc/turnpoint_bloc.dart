import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/options/turnpoint_regions.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/cup/cup_styles.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoint_utils.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';

class TurnpointBloc extends Bloc<TurnpointEvent, TurnpointState> {
  final Repository repository;
  final List<TurnpointFile> turnpointFiles = [];
  //final List<CupStyle> cupStyles = [];

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
    on<DownloadTurnpointsToFile>(_downloadTurnpointsToFile);
    on<DownloadTurnpointToFile>(_downloadTurnpointToFile);
    on<GetCustomImportFileNamesEvent>(_getCustomImportFileNames);
    on<ImportTurnpointsFromFileEvent>(_importTurnpointsFromFile);
  }

  void _searchTurnpointsEvent(
      SearchTurnpointsEvent event, Emitter<TurnpointState> emit) async {
    // if (event.searchString.length < 3) {
    //   emit(TurnpointSearchMessage("Enter more than 2 characters"));
    //   return;
    // }
    emit(SearchingTurnpointsState());
    try {
      if (event.searchString.isNotEmpty) {
        var turnpoints = await repository.findTurnpoints(event.searchString);
        await _getCupStylesIfNeeded();
        emit(TurnpointsLoadedState(turnpoints, TurnpointUtils.getCupStyles()));
      } else {
        await _loadAllTurnpoints(emit);
      }
    } catch (e) {
      emit(TurnpointSearchErrorState(e.toString()));
    }
  }

  Future<void> _getCupStylesIfNeeded() async {
    if (TurnpointUtils.getCupStyles().isEmpty) {
      final List<CupStyle> cupStyles = await _getCupStyles();
      TurnpointUtils.setCupStyles(cupStyles);
    }
  }

  Future<List<CupStyle>> _getCupStyles() async {
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
      await _getCupStylesIfNeeded();
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
    return await repository.importTurnpointsFromTurnpointExchange(
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
      if (event.refreshList) {
        await _loadAllTurnpoints(emit);
      }
    } catch (e) {
      print(e.toString());
      emit(TurnpointErrorState(e.toString()));
    }
  }

  void _checkIfDuplicateTurnpointCode(CheckIfDuplicateTurnpointCodeEvent event,
      Emitter<TurnpointState> emit) async {
    Turnpoint? turnpoint =
        await repository.getTurnpointByCode(event.turnpointCode);
    if (turnpoint != null) {
      emit(TurnpointDuplicateCodeState());
      emit(TurnpointErrorState("Duplicate turnpoint code"));
    }
  }

  void _getAllCupStyles(CupStylesEvent event, Emitter<TurnpointState> emit) {
    print("Emitting CupStyles");
    _getCupStylesIfNeeded();
    emit(TurnpointCupStylesState(TurnpointUtils.getCupStyles()));
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
    emit(EditTurnpointState(turnpoint));
  }

  FutureOr<void> _saveTurnpoint(
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
    emit(UpdatedTurnpointState(turnpoint));
  }

  FutureOr<void> _deleteTurnpoint(
      DeleteTurnpoint event, Emitter<TurnpointState> emit) async {
    try {
      await repository.deleteTurnpoint(event.id);
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
      double? elevation = 0;
      final currentLocation = await location.getLocation();
      if (currentLocation.altitude != null && currentLocation.altitude == 0) {
        elevation = await getUSGSElevationAtLocation(
            currentLocation.latitude ?? 0, currentLocation.longitude ?? 0);
      } else {
        elevation = currentLocation.altitude;
      }
      print(
          "location: ${currentLocation.latitude} ${currentLocation.longitude}, elevation(m): ${currentLocation.altitude} ");
      emit(CurrentLocationState(currentLocation.latitude ?? 0,
          currentLocation.longitude ?? 0, elevation!));
    } catch (e) {
      emit(TurnpointErrorState("Oops. Can't find your location!"));
    }
  }

  FutureOr<void> _getElevationAtLatLong(
      GetElevationAtLatLong event, Emitter<TurnpointState> emit) async {
    double elevation;
    try {
      elevation =
          await getUSGSElevationAtLocation(event.latitude, event.longitude);
      emit(LatLongElevationState(event.latitude, event.longitude, elevation));
    } catch (e) {
      emit(TurnpointErrorState("Ooops. Could not get elevation at that point"));
    }
  }

  Future<double> getUSGSElevationAtLocation(
      double latitude, double longitude) async {
    double elevation;
    final nationalMap =
        await repository.getElevationAtLatLongPoint(latitude, longitude);
    elevation =
        nationalMap.value ??
            0.0;
    return elevation;
  }

  // Make sure user has file permissions before calling this method
  FutureOr<void> _downloadTurnpointsToFile(
      DownloadTurnpointsToFile event, Emitter<TurnpointState> emit) async {
    List<Turnpoint> turnpoints = [];
    try {
      turnpoints.addAll(await repository.getAllTurnpoints());
      String filename = await _writeTurnpointsToFile(turnpoints);
      emit(TurnpointShortMessageState("Turnpoints written to :" + filename));
    } catch (e) {
      emit(TurnpointErrorState("Error on writing turnpoints to file"));
      print("Error on writing turnpoints to file: ${e.toString()}");
    }
  }

  FutureOr<void> _downloadTurnpointToFile(
      DownloadTurnpointToFile event, Emitter<TurnpointState> emit) async {
    final turnpoint = event.turnpoint;
    try {
      String filename = await _writeTurnpointToFile(turnpoint);
      emit(TurnpointShortMessageState("Turnpoint written to :" + filename));
    } catch (e) {
      emit(TurnpointErrorState("Error on writing turnpoint to file"));
      print("Error on writing turnpoint to file: ${e.toString()}");
    }
  }

  FutureOr<String> _writeTurnpointsToFile(
      List<Turnpoint> turnpointsList) async {
    String turnpointFileName =
        "Turnpoints_" + _getCurrentDateAndTime() + ".cup";
    File? file = await _createTurnpointFile(turnpointFileName);
    if (file != null) {
      var sink = file.openWrite();
      sink.write(TurnpointUtils.getAllColumnHeaders());
      turnpointsList.forEach((turnpoint) {
        sink.write(TurnpointUtils.getCupFormattedRecord(turnpoint) +
            Constants.NEW_LINE);
      });
      // Close the IOSink to free system resources.
      sink.close();
    }
    return turnpointFileName;
  }

  FutureOr<String> _writeTurnpointToFile(Turnpoint turnpoint) async {
    String turnpointFileName =
        "Turnpoint_" + turnpoint.code + "_" + _getCurrentDateAndTime() + ".cup";
    File? file = await _createTurnpointFile(turnpointFileName);
    if (file != null) {
      var sink = file.openWrite();
      sink.write(TurnpointUtils.getAllColumnHeaders());
      sink.write(
          TurnpointUtils.getCupFormattedRecord(turnpoint) + Constants.NEW_LINE);
      // Close the IOSink to free system resources.
      sink.close();
    };
    return turnpointFileName;
  }

  String _getCurrentDateAndTime() {
    DateTime now = DateTime.now();
    return DateFormat('yyyy_MM_dd.HH.mm').format(now);
  }

  Future<File?> _createTurnpointFile(String filename) async {
    File? file = null;
    try {
      Directory? directory = await repository.getDownloadDirectory();
      if (directory != null) {
        file = File(directory.absolute.path + '/' + filename);
      }
    } catch (e) {
      print("Exception creating download file: " + e.toString());
      throw (e);
    }
    return file;
  }



  FutureOr<List<File>> _getCustomImportFileNames(
      GetCustomImportFileNamesEvent event, Emitter<TurnpointState> emit) async {
    List<File> cupfiles = [];
    try {
      Directory? directory = await repository.getDownloadDirectory();
      if (directory != null) {
        directory
            .listSync()
            .where((file) => file is File && file.path.endsWith(".cup"))
            .forEach((file) {
          cupfiles.add(file as File);
        });
        emit(CustomTurnpointFileListState(cupfiles));
      }
    } catch (e) {
      emit(TurnpointErrorState("Error getting list of .cup files"));
      print("Exception getting list of cup files" + e.toString());
    }
    return cupfiles;
  }

  // import turnpoints from file in Download directory
  FutureOr<void> _importTurnpointsFromFile(
      ImportTurnpointsFromFileEvent event, Emitter<TurnpointState> emit) async {
    try {
      List<Turnpoint> turnpoints =
          await repository.importTurnpointsFromFile(event.turnpointFile);
      emit(
          TurnpointShortMessageState("${turnpoints.length} turnpoints loaded"));
      emit(TurnpointFilesFoundState(turnpointFiles));
    } catch (e) {
      print(e.toString());
      emit(TurnpointErrorState(e.toString()));
    }
  }

}
