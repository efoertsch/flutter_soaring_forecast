// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'airports_dao.dart';

// ignore_for_file: type=lint
mixin _$AirportsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AirportsTable get airports => attachedDatabase.airports;
  AirportsDaoManager get managers => AirportsDaoManager(this);
}

class AirportsDaoManager {
  final _$AirportsDaoMixin _db;
  AirportsDaoManager(this._db);
  $$AirportsTableTableManager get airports =>
      $$AirportsTableTableManager(_db.attachedDatabase, _db.airports);
}
