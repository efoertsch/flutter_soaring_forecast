// !!!This class is only used in the download process.
class Airport_CSV {
  late int id;
  late String ident;
  late String type;
  late String name;
  late double latitudeDeg;
  late double longitudeDeg;
  late int elevationFt;
  late String state;
  late String municipality;

  Airport_CSV(
      {this.id = -1,
      this.ident = '',
      this.type = '',
      this.name = '',
      this.latitudeDeg = 0.0,
      this.longitudeDeg = 0,
      this.elevationFt = 0,
      this.state = '',
      this.municipality = ''});

  factory Airport_CSV.fromList(List<dynamic> list) => Airport_CSV(
        ident: list[1],
        type: list[2],
        name: list[3],
        latitudeDeg: list[4] != ''
            ? (list[4] is double
                ? list[4]
                : (list[4] is int)
                    ? list[4].toDouble()
                    : 0.0)
            : 0.0,
        longitudeDeg: list[5] != ''
            ? (list[4] is double
                ? list[4]
                : (list[4] is int)
                    ? list[4].toDouble()
                    : 0.0)
            : 0.0,
        elevationFt: list[6] != '' ? list[6] : 0,
        state: list[9].toString().replaceAll('US-', ''),
        municipality: list[10],
      );

  factory Airport_CSV.fromMap(Map<String, dynamic> map) => Airport_CSV(
        ident: map[1],
        type: map[2],
        name: map[3],
        latitudeDeg: map[4],
        longitudeDeg: map[5],
        elevationFt: map[6],
        state: map[9],
        municipality: map[10],
      );
}
