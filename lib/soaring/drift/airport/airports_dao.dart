import 'package:drift/drift.dart';
import '../app_database.dart';
import '../base_dao.dart';
import 'airports.dart';

part 'airports_dao.g.dart';

//TODO if any changes run  -  dart run build_runner build --delete-conflicting-outputs

@DriftAccessor(tables: [Airports])
class AirportsDao extends DatabaseAccessor<AppDatabase>
    with _$AirportsDaoMixin, BaseDao<Airports, Airport, AirportsCompanion> {
  AirportsDao(super.attachedDatabase);

  @override
  TableInfo<Airports, Airport> get table => airports;

  @override
  GeneratedDatabase get db => attachedDatabase;

  Future<List<Airport>> findAirports(String searchTerm) async {
    return await (select(airports)
      ..where((tbl) =>
          tbl.ident.collate(Collate.noCase).like(searchTerm) |
          tbl.name.collate(Collate.noCase).like(searchTerm) |
          tbl.municipality.collate(Collate.noCase).like(searchTerm))).get();
  }

  Future<Airport?> getAirportsByIdent(String ident) async {
    return await (select(airports)
          ..where((tbl) => tbl.ident.collate(Collate.noCase).equals(ident)))
        .getSingleOrNull();
  }

  Future<List<Airport>?> listAllAirports() async {
    return await (select(airports)
      ..orderBy(
          [(t) => OrderingTerm(expression: t.state, mode: OrderingMode.asc)])).get();
  }

  Future<List<Airport>?> selectIcaoIdAirportss(List<String> iacoAirportss) async {
    return await (select(airports)..where((tbl) => tbl.ident.isIn(iacoAirportss)))
        .get();
  }

  Future<int> getAirportsCount() async {
    return await getCount();
  }
}
