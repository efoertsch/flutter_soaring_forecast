import 'package:drift/drift.dart';

class StateConverter extends TypeConverter<dynamic, String> {
  const StateConverter();

  @override
  String fromSql(String fromDb) {
    // Already String
    return fromDb;
  }

  @override
  String toSql(dynamic value) {
    // Convert the Dart int to a double before storing it
    return value.toString().replaceAll('US-', '');
  }
}