import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
import 'package:media_store_plus/media_store_plus.dart';
import 'package:media_store_plus/src/dir_type.dart';

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


  Future<List<Turnpoint>> _getTurnpointsFromTurnpointExchange(
      TurnpointFile turnpointfile) async {
    return await repository.importTurnpointsFromTurnpointExchange(
        turnpointfile.location + "/" + turnpointfile.filename);
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
    double elevation = 0;
    var currentLocation;
    try {
      currentLocation = await location.getLocation();
    } catch (e) {
      emit(TurnpointErrorState("Oops. Can't find your location!"));
      return;
    }

    if (currentLocation.altitude != null && currentLocation.altitude == 0) {
      elevation = await _getUSGSElevationAtLocation(
          currentLocation.latitude ?? 0, currentLocation.longitude ?? 0, emit);
    } else {
      elevation = currentLocation.altitude;
    }
    // print("location: ${currentLocation.latitude} ${currentLocation.longitude}, elevation(m): ${currentLocation.altitude} ");
    emit(CurrentLocationState(currentLocation.latitude ?? 0,
        currentLocation.longitude ?? 0, elevation));
  }

  FutureOr<void> _getElevationAtLatLong(
      GetElevationAtLatLong event, Emitter<TurnpointState> emit) async {
    double elevation;
    elevation = await _getUSGSElevationAtLocation(
        event.latitude, event.longitude, emit);
    emit(LatLongElevationState(event.latitude, event.longitude, elevation));
  }

  Future<double> _getUSGSElevationAtLocation(
      double latitude, double longitude, Emitter<TurnpointState> emit) async {
    double elevation = 0;
    try {
      final nationalMap =
          await repository.getElevationAtLatLongPoint(latitude, longitude);
      elevation = (double.parse(nationalMap.value ?? "0.0"));
    } catch (e) {
      debugPrint("_getElevationAtLatLong exception: ${e.toString()}");
      emit(TurnpointErrorState(
          "Hmmm. An error occurred when getting elevation. Assuming elevation = 0"));
    }
    return elevation;
  }

  // Make sure user has file permissions before calling this method
  FutureOr<void> _downloadTurnpointsToFile(
      DownloadTurnpointsToFile event, Emitter<TurnpointState> emit) async {
    List<Turnpoint> turnpoints = [];
    turnpoints.addAll(await repository.getAllTurnpoints());
     await _writeTurnpointsToFile(turnpoints, emit);

  }

  // Make sure user has file permissions before calling this method
  FutureOr<void> _downloadTurnpointToFile(
      DownloadTurnpointToFile event, Emitter<TurnpointState> emit) async {
    final List<Turnpoint> turnpoints = <Turnpoint>[]..add(event.turnpoint);
     await _writeTurnpointsToFile(turnpoints, emit);
  }

  FutureOr<void> _writeTurnpointsToFile(
      List<Turnpoint> turnpoints, Emitter<TurnpointState> emit) async {
    try {
      String turnpointsFileName = "${turnpoints.length == 1
              ? ("Turnpoint_${turnpoints[0].code}_")
              : "Turnpoints_"}${_getCurrentDateAndTime()}.cup";
      File? file = await _createTurnpointFile(turnpointsFileName);
      if (file != null) {
        var sink = file.openWrite();
        sink.write(TurnpointUtils.getAllColumnHeaders());
        turnpoints.forEach((turnpoint) {
          sink.write(TurnpointUtils.getCupFormattedRecord(turnpoint) +
              Constants.NEW_LINE);
        });
        // Close the IOSink to free system resources.
        sink.close();
        if (Platform.isAndroid) {
          await _storeFileViaMediaManager(file, emit);
        }else {
          emit(TurnpointShortMessageState("Turnpoint(s) downloaded to ${file.path.split("/").last}"));
        }
      } else {
        emit(TurnpointErrorState("Error writing turnpoints to temp directory"));
      }

    } catch (e) {
      emit(TurnpointErrorState("Error on writing turnpoints to file"));
      debugPrint("Error on writing turnpoints to file: ${e.toString()}");
      return null;
    }
  }

  String _getCurrentDateAndTime() {
    DateTime now = DateTime.now();
    return DateFormat('yyyy_MM_dd').format(now);
  }

  Future<File?> _createTurnpointFile(String filename) async {
    File? file;
    try {
      Directory? directory = await repository.getTempOrIOSDocDirectory();
      if (directory != null) {
        file = File('${directory.absolute.path}/$filename');
      }
    } catch (e) {
      debugPrint("Exception creating download file: $e");
      rethrow;
    }
    return file;
  }

  FutureOr<List<File>> _getCustomImportFileNames(
      GetCustomImportFileNamesEvent event, Emitter<TurnpointState> emit) async {
    List<File> cupfiles = [];
    try {
      Directory? directory = await repository.getTempOrIOSDocDirectory();
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

  //https://github.com/SNNafi/media_store_plus/blob/7d3760c2948634fe200c51ab9633092600376db6/lib/media_store_plus.dart
  Future<void> _storeFileViaMediaManager(File file, Emitter<TurnpointState> emit) async {
    SaveInfo? saveInfo;
    await MediaStore.ensureInitialized();
    MediaStore mediaStore = MediaStore();
    List<String> dirParts = file.toString().split("/");
    String filename = dirParts.last;
    String dirToUse  = dirParts.length > 3 ? dirParts[dirParts.length - 3] : "";
    MediaStore.appFolder = dirToUse;
    saveInfo = await mediaStore.saveFile(tempFilePath: file.path
        , dirType: DirType.download
        , dirName: DirName.download);

  if (saveInfo != null){
    emit (TurnpointShortMessageState("Turnpoints saved to ${filename}"));
  }

  }
}
