import 'package:drift/drift.dart';
import '../app_database.dart';

//TODO if any changes run  -  dart run build_runner build --delete-conflicting-outputs
@UseRowClass(Turnpoint)
@TableIndex(name: 'index_turnpoint_code', columns: {#code})
class Turnpoints extends Table {
  late final id = integer().autoIncrement()();
  late final title = text().withDefault(const Constant(''))();
  late final code = text().withDefault(const Constant(''))();
  late final country = text().withDefault(const Constant(''))();
  late final latitudeDeg = real().withDefault(const Constant(0.0))();
  late final longitudeDeg = real().withDefault(const Constant(0.0))();
  late final elevation = text().withDefault(const Constant(''))();
  late final style = text().withDefault(const Constant('0'))();
  late final direction = text().withDefault(const Constant(''))();
  late final length = text().withDefault(const Constant(''))();
  late final frequency = text().withDefault(const Constant(''))();
  late final description = text().withDefault(const Constant(''))();
  late final runwayWidth = text().withDefault(const Constant(''))();

  @override
  String get tableName => 'turnpoint';

  @override
  List<Set<Column>> get uniqueKeys => [
        {title, code},
      ];

}

class Turnpoint  implements Insertable<Turnpoint>{
  int  id;
  String title;
  String code;
  String country;
  double latitudeDeg;
  double longitudeDeg;
  String elevation;
  String style;
  String direction;
  String length;
  String frequency;
  String description;
  String runwayWidth;


  Turnpoint({
    this.id = -1 ,
    this.title = '',
    this.code = '',
    this.country = '',
    this.latitudeDeg = 0.0,
    this.longitudeDeg = 0.0,
    this.elevation = '',
    this.style = '',
    this.direction = '',
    this.length = '',
    this.frequency = '',
    this.description = '',
    this.runwayWidth = '',
  });


  TurnpointsCompanion toCompanion(bool nullToAbsent) {
    return TurnpointsCompanion(
      id: id == -1 && nullToAbsent ? const Value.absent() : Value(id!),
      title: Value(title),
      code: Value(code),
      country: Value(country),
      latitudeDeg: Value(latitudeDeg),
      longitudeDeg: Value(longitudeDeg),
      elevation: Value(elevation),
      style: Value(style),
      direction: Value(direction),
      length: Value(length),
      frequency: Value(frequency),
      description: Value(description),
      runwayWidth: Value(runwayWidth),
    );
  }

  TurnpointsCompanion copyToCompanion({bool nullToAbsent = false}) {
    return toCompanion(nullToAbsent);
  }

  Turnpoint clone() {
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
      runwayWidth: runwayWidth,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return TurnpointsCompanion(
        id:  id == -1 && nullToAbsent ? const Value.absent() : Value(id!),
        title:Value(title),
        code:Value(code),
        country:Value(country),
        latitudeDeg:Value(latitudeDeg),
        longitudeDeg:Value(longitudeDeg),
        elevation:Value(elevation),
        style:Value(style),
        direction:Value(direction),
        length:Value(length),
        frequency:Value(frequency),
        description:Value(description),
        runwayWidth:Value(runwayWidth),
    ).toColumns(nullToAbsent);
  }


}
