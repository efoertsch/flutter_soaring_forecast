import 'package:drift/drift.dart';

import '../app_database.dart';
import '../base_dao.dart';
import 'turnpoints.dart';

part 'turnpoints_dao.g.dart';

//TODO if any changes run  -  dart run build_runner build --delete-conflicting-outputs
@DriftAccessor(tables: [Turnpoints])
class TurnpointsDao extends DatabaseAccessor<AppDatabase>
    with _$TurnpointsDaoMixin , BaseDao< Turnpoints,  Turnpoint, TurnpointsCompanion>{
  TurnpointsDao(AppDatabase db) : super(db);

  @override
  TableInfo< Turnpoints,  Turnpoint> get table =>  turnpoints;

  @override
  GeneratedDatabase get db => attachedDatabase;


  // @Query("Select * from turnpoint order by title")
  Future<List<Turnpoint>> listAllTurnpoints() async {
    return  await (select(turnpoints)
      ..orderBy([(t) => OrderingTerm(expression: t.title)])).get();
  }

  // @Query("Delete from turnpoint")
  Future<int?> deleteAllTurnpoints() async {
    return await (delete(turnpoints)).go();
  }

  // @Query("Delete from turnpoint where id = :id")
  Future<int?> deleteTurnpoint(int id) async {
    return await (delete(turnpoints)..where((tbl) => tbl.id.equals(id))).go();
  }

  // @Query(
  //     "Select * from turnpoint where title like :searchTerm or code like :searchTerm  order by title, code collate nocase")
  Future<List<Turnpoint>> findTurnpoints(String searchTerm) async {
    return await (select(turnpoints)
      ..where((tbl) =>
          tbl.title.collate(Collate.noCase).like(searchTerm) |
          tbl.code.collate(Collate.noCase).like(searchTerm))).get();
  }

  // @Query("Select * from turnpoint  order by id")
  Future<List<Turnpoint>> selectAllTurnpointsForDownload() async {
    return (select(turnpoints)
      ..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
  }

//  @Query("Select * from turnpoint where code = :code limit 1 collate nocase")
  Future<Turnpoint?> getTurnpointByCode(String code) async {
    return  await (select(turnpoints)
          ..where((tbl) => tbl.code.collate(Collate.noCase).equals(code)))
        .getSingleOrNull();
  }

  //@Query(
  //    "Select * from turnpoint where title = :title and code = :code collate nocase")
  Future<Turnpoint?> getTurnpoint(String title, String code) async {
    return  await (select(turnpoints)
          ..where((tbl) =>
              tbl.title.collate(Collate.noCase).equals(title) &
              tbl.code.collate(Collate.noCase).equals(code)))
        .getSingleOrNull();
  }

  // @Query("Select * from turnpoint where id = :id")
  Future<Turnpoint?> getTurnpointById(int id) async {
    return  await (select(turnpoints)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  // //@Query("Select count(*) from turnpoint")
  // Future<int?> getTurnpointCount() async {
  //   return  await (select(turnpoints)..where((tbl) => tbl.id.isNotNull())).count();
  // }

  // @Query("Select * from turnpoint  ORDER BY id ASC LIMIT 1")
  Future<Turnpoint?> checkForAtLeastOneTurnpoint() async {
    return  await (select(turnpoints)
          ..orderBy([(t) => OrderingTerm(expression: t.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  // @Query(
  //     "Select * from turnpoint where latitudeDeg between :swLatitudeDeg and :neLatitudeDeg  and longitudeDeg between :swLongitudeDeg and :neLongitudeDeg")
  Future<List<Turnpoint>> getTurnpointsWithinBounds(double swLatitudeDeg,
      double swLongitudeDeg, double neLatitudeDeg, double neLongitudeDeg) {
    return (select(turnpoints)
          ..where((tbl) =>
              tbl.latitudeDeg.isBetweenValues(swLatitudeDeg, neLatitudeDeg) &
              tbl.longitudeDeg.isBetweenValues(swLongitudeDeg, neLongitudeDeg)))
        .get();
  }

  //@Query(
  //   "Select * from turnpoint where latitudeDeg between :swLatitudeDeg and :neLatitudeDeg  and longitudeDeg between :swLongitudeDeg and :neLongitudeDeg and style between '2' and '5'")
  Future<List<Turnpoint>> getLandableTurnpointsWithinBounds(
      double swLatitudeDeg,
      double swLongitudeDeg,
      double neLatitudeDeg,
      double neLongitudeDeg) {
    return (select(turnpoints)
          ..where((tbl) =>
              tbl.latitudeDeg.isBetweenValues(swLatitudeDeg, neLatitudeDeg) &
              tbl.longitudeDeg.isBetweenValues(swLongitudeDeg, neLongitudeDeg) &
              tbl.style.isIn(['2', '3', '4', '5'])))
        .get();
  }
}
