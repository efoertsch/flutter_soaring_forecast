class SatelliteType {
  static final String COMMA_DELIMITER = ",";

  late final int id;
  late final String code;
  late final String name;

  SatelliteType(String codeCommaName) {
    List<String> values = codeCommaName.split(COMMA_DELIMITER);
    id = values.length > 0 ? int.parse(values[0]) : 0;
    code = values.length > 1 ? values[1].trim() : "";
    name = values.length > 2 ? values[2].trim() : "";
  }

  String toString() {
    return name;
  }

  bool equals(Object obj) {
    if (obj is SatelliteType) {
      SatelliteType c = obj;
      return c.code == code && c.name == name;
    }
    return false;
  }

  // For storing selected region in SharedPreferences
  String toStore() {
    return id.toString() +
        COMMA_DELIMITER +
        code.trim() +
        COMMA_DELIMITER +
        name.trim();
  }
}
