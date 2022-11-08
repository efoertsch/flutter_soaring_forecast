import 'package:floor/floor.dart';

//! This class is used when fetching from sqflite database for (currently) METAR/TAF
//TODO if any changes run  -  flutter packages pub run build_runner build
@Entity(tableName: 'airport', indices: [
  Index(value: ['name']),
  Index(value: ['state', 'name']),
  Index(value: ['municipality'])
])
class Airport {
  @primaryKey
  String ident;
  String type;
  String name;
  double latitudeDeg;
  double longitudeDeg;
  int elevationFt;
  String state;
  String municipality;

  Airport({
    required this.ident,
    this.type = "",
    this.name = "Unknown",
    this.latitudeDeg = 0,
    this.longitudeDeg = 0,
    this.elevationFt = 0,
    this.state = "",
    this.municipality = "",
  });

  factory Airport.fromList(List<dynamic> list) => Airport(
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

  factory Airport.fromMap(Map<String, dynamic> map) => Airport(
        ident: map[1],
        type: map[2],
        name: map[3],
        latitudeDeg: map[4],
        longitudeDeg: map[5],
        elevationFt: map[6],
        state: map[9],
        municipality: map[10],
      );

  @override
  String toString() {
    return (ident +
        " " +
        type +
        " " +
        name +
        " " +
        latitudeDeg.toString() +
        " " +
        longitudeDeg.toString() +
        " " +
        elevationFt.toString() +
        " " +
        state +
        " " +
        municipality);
  }
}
