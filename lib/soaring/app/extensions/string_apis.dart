extension BoolParsing on String {
  bool parseBool() {
    return this.toLowerCase() == 'true';
  }

  bool equals(String value) {
    return this == value;
  }
}
