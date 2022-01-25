import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/app/main.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';

class TaskListView {
  BuildContext context;
  final List<Task> tasks;

  TaskListView({required this.context, required this.tasks});

  Widget getTaskListView() {
    if (tasks.length == 0) {
      return Center(
        child: Text('No tasks found'),
      );
    }
    return ListView.separated(
      itemCount: tasks.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
          visualDensity: VisualDensity(horizontal: 0, vertical: -4),
          trailing: IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(
              context,
              TaskDetail.routeName,
              arguments: tasks[index],
            ),
          ),
          title: Row(
            children: [
              Text(
                tasks[index].taskName,
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 20),
              ),
              Text(
                tasks[index].distance.toStringAsFixed(1),
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 15),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (context, index) {
        return Divider();
      },
    );
  }
}
