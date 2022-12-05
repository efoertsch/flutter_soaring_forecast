import 'package:intl/intl.dart';

final abbrevDateformatter = DateFormat('E, MMM dd');

/// Convert date in yyyy-mm-dd format to something like Mon, Dec 05
List<String> reformatDatesToDOW(List<String> forecastDates) {
  final List<String> shortDOWs = [];
  forecastDates.forEach((date) {
    final realDate = DateTime.tryParse(date);
    if (realDate != null) {
      shortDOWs.add(abbrevDateformatter.format(realDate));
    }
  });
  return shortDOWs;
}
