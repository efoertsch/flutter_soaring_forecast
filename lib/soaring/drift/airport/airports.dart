import 'package:drift/drift.dart';
import '../converter/latlng_converter.dart';
//! This class is used when fetching from sqflite database for (currently) METAR/TAF
//TODO if any changes run  -  dart run build_runner build --delete-conflicting-outputs
@DataClassName('Airport')
@TableIndex(name: 'index_airport_name', columns: {#name})
@TableIndex(name: 'index_airport_state_name', columns: {#state ,  #name})
@TableIndex(name: 'index_airport_municipality', columns: {#municipality})
class Airports extends Table {
  late final ident = text()();
  late final type = text().withDefault(const Constant(''))();
  late final name = text().withDefault(const Constant('Unknown'))();
  late final latitudeDeg = real().map(const LatLngConverter())();
  late final longitudeDeg = real().map(const LatLngConverter())();
  late final elevationFt = integer().withDefault(const Constant(0))();
  late final state = text().withDefault(const Constant(''))();
  late final municipality = text().withDefault(const Constant(''))();

  String get tableName => 'airport';
}

