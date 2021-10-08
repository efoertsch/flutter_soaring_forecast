import 'package:floor/floor.dart';

//TODO if any changes run  -  flutter packages pub run build_runner build
abstract class BaseDao<T> {
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<int?> insert(T obj);

  @Insert()
  Future<List<int?>> insertAll(List<T> obj);

  @Update()
  Future<void> update(T obj);
}