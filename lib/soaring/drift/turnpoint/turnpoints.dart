import 'package:drift/drift.dart';

//TODO if any changes run  -  dart run build_runner build --delete-conflicting-outputs
@DataClassName('Turnpoint')
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

  String get tableName => 'turnpoint';

  @override
  List<Set<Column>> get uniqueKeys => [
    {title, code},
  ];

}