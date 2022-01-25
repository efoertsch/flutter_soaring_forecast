import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';

class TaskDetailScreen extends StatefulWidget {
  final BuildContext repositoryContext;
  final Task? task;

  TaskDetailScreen(
      {Key? key, required this.repositoryContext, required this.task})
      : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

//TODO - keep more data details in Bloc,
class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Task Detail'),
        leading: CommonWidgets.backArrowToHomeScreen(),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.list), onPressed: null),
        ],
      ),
      body: Container(
        child: Text('Add list of task turnpoints'),
      ),
    );
  }

  Widget getWidget() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          closeButton(),
        ],
      ),
    );
  }

  Widget closeButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity,
            40), // double.infinity is the width and 30 is the height
        onPrimary: Colors.white,
        primary: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () {
        Navigator.pop(context);
      },
      child: Text(
        'CLOSE',
      ),
    );
  }
}
