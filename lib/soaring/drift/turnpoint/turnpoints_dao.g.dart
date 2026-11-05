// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turnpoints_dao.dart';

// ignore_for_file: type=lint
mixin _$TurnpointsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TurnpointsTable get turnpoints => attachedDatabase.turnpoints;
  TurnpointsDaoManager get managers => TurnpointsDaoManager(this);
}

class TurnpointsDaoManager {
  final _$TurnpointsDaoMixin _db;
  TurnpointsDaoManager(this._db);
  $$TurnpointsTableTableManager get turnpoints =>
      $$TurnpointsTableTableManager(_db.attachedDatabase, _db.turnpoints);
}
