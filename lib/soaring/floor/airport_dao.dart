import 'package:floor/floor.dart';
import 'package:flutter_soaring_forecast/soaring/floor/airport.dart';
import 'package:flutter_soaring_forecast/soaring/floor/base_dao.dart';

//TODO if any changes run  -  flutter packages pub run build_runner build
@dao
abstract class AirportDao extends BaseDao<Airport> {
  @Query(
      "SELECT * FROM airport WHERE ident like :searchTerm or name like :searchTerm  or " +
          "municipality like :searchTerm  collate nocase")
  Future<List<Airport>?> findAirports(String searchTerm);

  @Query("SELECT * FROM airport WHERE ident = :ident  collate nocase")
  Future<Airport?> getAirportByIdent(String ident);

  @Query("Select * from airport order by state, name")
  Future<List<Airport>?> listAllAirports();

  @Query("Select * from airport where ident in (:iacoAirports)")
  Future<List<Airport>?> selectIcaoIdAirports(List<String> iacoAirports);

  @Query("SELECT count(*) FROM airport")
  Future<int?> getCountOfAirports();

  @Query("Delete from airport")
  Future<int?> deleteAll();
}
