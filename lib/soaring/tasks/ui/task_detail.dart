import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/main.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_event.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_state.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_search_in_appbar.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;

  TaskDetailScreen({Key? key, required this.taskId}) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen>
    with AfterLayoutMixin<TaskDetailScreen> {
  @override
  void afterFirstLayout(BuildContext context) {
    setState(() {
      BlocProvider.of<TaskBloc>(context)
          .add(LoadTaskTurnpointsEvent(widget.taskId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Task Detail'),
          leading: CommonWidgets.backArrowToHomeScreen(),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.list), onPressed: null),
          ],
        ),
        body: BlocConsumer<TaskBloc, TaskState>(listener: (context, state) {
          if (state is TaskShortMessageState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.green,
                content: Text(state.shortMsg),
              ),
            );
          }
          if (state is TaskErrorState) {
            CommonWidgets.showErrorDialog(
                context, 'Task Error', state.errorMsg);
          }
        }, buildWhen: (previous, current) {
          return current is TasksLoadingState ||
              current is TasksTurnpointsLoadedState;
        }, builder: (context, state) {
          if (state is TasksLoadingState) {
            return CommonWidgets.buildLoading();
          }
          if (state is TasksTurnpointsLoadedState) {
            return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _taskTitle(state.task),
                  _taskDistance(state.task),
                  _turnpointsLabel(),
                  _taskTurnpointsListView(state.taskTurnpoints),
                ]);
          }
          return Center(child: Text("Unhandled State"));
        }),
        bottomSheet: _addTurnpointsButton());
  }

  Widget _turnpointsLabel() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Turnpoints:',
          style: Theme.of(context).textTheme.subtitle1,
        ),
      ),
    );
  }

  Widget _taskTitle(Task task) {
    return Flexible(
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Task:', style: Theme.of(context).textTheme.subtitle1)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _taskDistance(Task task) {
    return Flexible(
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Distance:',
                style: Theme.of(context).textTheme.subtitle1)),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            task.distance.toStringAsFixed(1),
            style: Theme.of(context).textTheme.subtitle1,
          ),
        ),
      ]),
    );
  }

  Widget _taskTurnpointsListView(List<TaskTurnpoint> taskTurnpoints) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: taskTurnpoints.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
          visualDensity: VisualDensity(horizontal: 0, vertical: -4),
          leading: IconButton(
              icon: Icon(Icons.location_searching),
              color: Colors.blue,
              //TurnpointUtils.getColorForTurnpointIcon(taskTurnpoints[index].code),
              onPressed: () => print('Implement code to display turnpoint ')
              //   Navigator.pushNamed(
              // context,
              // TurnpointView.routeName,
              // arguments: taskTurnpoints[index],
              ),
          title: TextButton(
              onPressed: () => print('clicked text'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            taskTurnpoints[index].title,
                            textAlign: TextAlign.left,
                            style: textStyleBoldBlackFontSize20,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            taskTurnpoints[index].taskOrder == 0
                                ? 'Start'
                                : (taskTurnpoints[index].lastTurnpoint
                                    ? 'Finish'
                                    : ''),
                            textAlign: TextAlign.left,
                            style: textStyleBoldBlack87FontSize15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )),
        );
      },
      separatorBuilder: (context, index) {
        return Divider();
      },
    );
  }

  Widget _addTurnpointsButton() {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity,
                40), // double.infinity is the width and 30 is the height
            onPrimary: Colors.white,
            primary: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () {
            _getTurnpointsForTask();
          },
          child: Text(
            'Add Turnpoints',
            style: TextStyle(
              color: Colors.white,
              fontSize: Theme.of(context).textTheme.subtitle1?.fontSize,
            ),
          ),
        ));
  }

  void _getTurnpointsForTask() async {
    final result = await Navigator.pushNamed(
      context,
      TurnpointsForTask.routeName,
      arguments: TurnpointsSearchInAppBarScreen.TASK_TURNPOINT_OPTION,
    );
    if (result is List<Turnpoint>) {
      BlocProvider.of<TaskBloc>(context)
          .add(TurnpointsAddedToTaskEvent(result as List<Turnpoint>));
    }
  }

}
