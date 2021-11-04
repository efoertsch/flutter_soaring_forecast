import 'package:floor/floor.dart';

@Entity(tableName: 'turnpoint', indices: [
  Index(value: ['name']),
  Index(value: ['state', 'name']),
  Index(value: ['municipality'])
])
class Turnpoint {
  @PrimaryKey(autoGenerate: true)
  late int id;
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

  // Turnpoint.getEmpty() {
  //   this.id = -1;
  //   this.title = "";
  //   this.code = "";
  //   this.country = "";
  //   this.latitudeDeg = 0;
  //   this.longitudeDeg = 0;
  //   this.elevation = "";
  //   this.style = "0";
  //   this.direction = "";
  //   this.length = "";
  //   this.frequency = "";
  //   this.description = "";
  //   this.runwayWidth = "";
  // }

  Turnpoint(
      {this.id = -1,
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
}
