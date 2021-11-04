import 'package:floor/floor.dart';

//TODO if any changes run  -  flutter packages pub run build_runner build
@Entity(tableName: 'task')
class Task {
  @PrimaryKey(autoGenerate: true)
  int id;
  String taskName = "";
  double distance = 0.0; //In Kilometers
  int taskOrder;

  Task({
    this.id = -1,
    required this.taskName,
    required this.distance,
    required this.taskOrder,
  });
}
