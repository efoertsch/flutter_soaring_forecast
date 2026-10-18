import 'package:drift/drift.dart';

/// A generic Base DAO for standard CRUD operations using Drift.
/// [T] represents the Drift Table class (e.g., Tasks).
/// [D] represents the generated DataClass (e.g., Task).
/// [C] represents the UpdateCompanion class (e.g., TasksCompanion).
mixin BaseDao<T extends Table, D, C extends UpdateCompanion<D>> {
  TableInfo<T, D> get table;

  GeneratedDatabase get db;

  /// Fetch all records from the table
  Future<List<D>> getAll() async => await db.select(table).get();

  /// Insert or replace a record if it already exists
  Future<int> insert(C companion) async =>
      await db.into(table).insert(companion, mode: InsertMode.insertOrReplace);

  /// Insert or update multiple records in a batch
  Future<int> insertAll(Iterable<Insertable<D>> list) async {
    return await db.transaction(() async {
      int insertedCount = 0;

      for (final entry in list) {
        // insert() returns the generated row ID (or 0/null if ignored)
        final id = await db.into(table).insert(
          entry,
          mode: InsertMode.insertOrIgnore,
        );

        if (id > 0) {
          insertedCount++;
        }
      }

      return insertedCount;
    });
  }

  /// Update a specific record using a companion (returns number of updated rows)
  Future<int> updateRecord(Insertable<D> companion) async =>
      await db.update(table).write(companion);

  /// Delete a specific record
  Future<int> deleteEntity(Insertable<D> companion) async =>
      await db.delete(table).delete(companion);

  /// Delete all rows in the table
  Future<int> deleteAll() async =>
      await db.delete(table).go();


  /// Get total count of rows in the table
  Future<int> getCount() async {
    final countExpression = table.columnsByName.values.first.count();
    final query = db.selectOnly(table)..addColumns([countExpression]);
    final result = await query.map((row) => row.read(countExpression)).getSingle();
    return result ?? 0;
  }
}
