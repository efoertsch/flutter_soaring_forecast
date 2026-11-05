import 'package:drift/drift.dart';

class LatLngConverter extends TypeConverter<dynamic, double> {
  const LatLngConverter();

  @override
  double fromSql(double fromDb) {
    // It should already be a double in the database
    return fromDb;
  }

  @override
  double toSql(dynamic value) {
    return value != ''
        ? (value is double
            ? value
            : (value is int)
                ? value.toDouble()
                : 0.0)
        : 0.0;
  }
}
