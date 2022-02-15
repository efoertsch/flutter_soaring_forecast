import 'package:floor/floor.dart';

//TODO if any changes run  -  flutter packages pub run build_runner build --delete-conflicting-outputs
abstract class BaseDao<T> {
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<int?> insert(T obj);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<List<int?>> insertAll(List<T> obj);

  @Update()
  Future<int> update(T obj);
}
