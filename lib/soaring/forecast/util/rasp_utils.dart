import 'package:intl/intl.dart';

final abbrevDateformatter = DateFormat('E, MMM dd');

/// Convert date in yyyy-mm-dd format to something like Mon, Dec 05
List<String> reformatDatesToDOW(List<String> forecastDates) {
  final List<String> shortDOWs = [];
  forecastDates.forEach((date) {
    final String? reformatedDate = reformatDateToDOW(date);
    if (reformatedDate != null) {
      shortDOWs.add(reformatedDate);
    }
  });
  return shortDOWs;
}

String? reformatDateToDOW(String forecastDate){
  final realDate = DateTime.tryParse(forecastDate);
  if (realDate != null) {
    return abbrevDateformatter.format(realDate);
  }
  return null;
}
