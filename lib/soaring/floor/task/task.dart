import 'package:floor/floor.dart';

//TODO if any changes run  -  flutter packages pub run build_runner build
@Entity(tableName: 'task')
class Task {
  @PrimaryKey(autoGenerate: true)
  late int id;
  late String taskName;
  late double distance = 0.0; //In Kilometers
  late int taskOrder;

  Task({
    this.id = -1,
    this.taskName = "",
    this.distance = 0.0,
    this.taskOrder = 0,
  });
}
