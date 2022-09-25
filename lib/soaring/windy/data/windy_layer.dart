class WindyLayer {
  static final String COMMA_DELIMITER = ",";
  late final int id;
  late final String code;
  late final String name;
  late final bool byAltitude;

  WindyLayer(String codeCommaName) {
    List<String> values = codeCommaName.split(COMMA_DELIMITER);
    id = ((values.length > 0) ? int.parse(values[0]) : 0);
    code = ((values.length > 1) ? values[1].trim() : "");
    name = ((values.length > 2) ? values[2].trim() : "");
    byAltitude = ((values.length > 3) && (values[3].trim() == "1"));
  }

  String toString() {
    return toStore();
  }

  bool equals(Object obj) {
    if (obj is WindyLayer) {
      WindyLayer c = obj;
      return (c.code == code) && (c.name == name);
    }
    return false;
  }

  String toStore() {
    return id.toString() +
        COMMA_DELIMITER +
        code.trim() +
        COMMA_DELIMITER +
        name.trim() +
        COMMA_DELIMITER +
        (byAltitude ? "1" : "0");
  }
}
