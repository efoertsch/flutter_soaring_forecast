class WindyAltitude {
  static final String COMMA_DELIMITER = ",";
  late final int id;
  late final String metric;
  late final String imperial;
  late final String windyCode;

  WindyAltitude(String codeCommaName) {
    List<String> values = codeCommaName.split(COMMA_DELIMITER);
    id = ((values.length > 0) ? int.parse(values[0]) : 0);
    metric = ((values.length > 1) ? values[1].trim() : "");
    imperial = ((values.length > 2) ? values[2].trim() : "");
    windyCode = ((values.length > 3) ? values[3].trim() : "");
  }

  String toString() {
    return toStore();
  }

  bool equals(Object obj) {
    if (obj is WindyAltitude) {
      WindyAltitude c = obj;
      return (c.metric == metric) && (c.imperial == imperial);
    }
    return false;
  }

  String toStore() {
    return id.toString() +
        COMMA_DELIMITER +
        metric.trim() +
        COMMA_DELIMITER +
        imperial.trim() +
        COMMA_DELIMITER +
        windyCode.trim();
  }
}
