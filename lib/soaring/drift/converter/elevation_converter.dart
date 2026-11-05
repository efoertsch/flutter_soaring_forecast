import 'package:drift/drift.dart';

class ElevationConverter extends TypeConverter<dynamic, int> {
  const ElevationConverter();

  @override
  int fromSql(int fromDb) {
    // database should be an int. no conversion needed
    return fromDb;
  }

  @override
  int toSql(dynamic value) {
    // Convert whatever to an int
    return value != ''
        ? value is int
            ? value
            : value.toInt()
        : 0;
  }
}
