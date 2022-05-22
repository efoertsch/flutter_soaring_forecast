import 'package:floor/floor.dart';

//TODO if any changes run  -  flutter packages pub run build_runner build
@Entity(tableName: 'turnpoint', indices: [
  Index(value: ['code'], unique: false),
  Index(value: ['title', 'code'], unique: true)
])
class Turnpoint {
  @PrimaryKey(autoGenerate: true)
  late int? id;
  late String title;
  late String code;
  late String country;
  late double latitudeDeg;
  late double longitudeDeg;
  late String elevation;
  late String style;
  late String direction;
  late String length;
  late String frequency;
  late String description;
  late String runwayWidth;

  Turnpoint(
      {this.id,
      this.title = "",
      this.code = "",
      this.country = "",
      this.latitudeDeg = 0,
      this.longitudeDeg = 0,
      this.elevation = "",
      this.style = "0",
      this.direction = "",
      this.length = "",
      this.frequency = "",
      this.description = "",
      this.runwayWidth = ""});

  clone() {
    return Turnpoint(
        id: id,
        title: title,
        code: code,
        country: country,
        latitudeDeg: latitudeDeg,
        longitudeDeg: longitudeDeg,
        elevation: elevation,
        style: style,
        direction: direction,
        length: length,
        frequency: frequency,
        description: description,
        runwayWidth: runwayWidth);
  }
}
