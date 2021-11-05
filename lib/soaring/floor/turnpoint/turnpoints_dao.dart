import 'package:floor/floor.dart';
import 'package:flutter_soaring_forecast/soaring/floor/base_dao.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';

//TODO if any changes run  -  flutter packages pub run build_runner build --delete-conflicting-outputs
@dao
abstract class TurnpointDao extends BaseDao<Turnpoint> {
  @Query("Select * from turnpoint order by title")
  Future<List<Turnpoint>> listAllTurnpoints();

  @Query("Delete from turnpoint")
  Future<int?> deleteAllTurnpoints();

  @Query("Delete from turnpoint where id = :id")
  Future<int?> deleteTurnpoint(int id);

  @Query(
      "Select * from turnpoint where title like :searchTerm or code like :searchTerm  order by title, code collate nocase")
  Future<List<Turnpoint>> findTurnpoints(String searchTerm);

  @Query("Select * from turnpoint  order by id")
  Future<List<Turnpoint>> selectAllTurnpointsForDownload();

  @Query("Select * from turnpoint where code = :code collate nocase")
  Future<Turnpoint?> getTurnpointByCode(String code);

  @Query(
      "Select * from turnpoint where title = :title and code = :code collate nocase")
  Future<Turnpoint?> getTurnpoint(String title, String code);

  @Query("Select * from turnpoint where id = :id")
  Future<Turnpoint?> getTurnpointById(int id);

  @Query("Select count(*) from turnpoint")
  Future<int?> getTurnpointCount();

  @Query("Select * from turnpoint  ORDER BY id ASC LIMIT 1")
  Future<Turnpoint?> checkForAtLeastOneTurnpoint();

  @Query(
      "Select * from turnpoint where latitudeDeg between :swLatitudeDeg and :neLatitudeDeg  and longitudeDeg between :swLongitudeDeg and :neLongitudeDeg")
  Future<List<Turnpoint?>> getTurnpointsInRegion(double swLatitudeDeg,
      double swLongitudeDeg, double neLatitudeDeg, double neLongitudeDeg);
}
