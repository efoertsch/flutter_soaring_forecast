import 'package:floor/floor.dart';

//TODO if any changes run  -  dart run build_runner build --delete-conflicting-outputs
@Entity(tableName: 'task')
class Task {
  @PrimaryKey(autoGenerate: true)
  late int? id;
  late String taskName;
  late double distance = 0.0; //In Kilometers
  late int taskOrder;
  late bool forecastFavorite;

  Task({
    this.id,
    this.taskName = "",
    this.distance = 0.0,
    this.taskOrder = 0,
    this.forecastFavorite = false
  });
}
