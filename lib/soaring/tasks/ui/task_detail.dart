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
  bool displaySaveButton = false;

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
          CommonWidgets.showErrorDialog(context, 'Task Error', state.errorMsg);
        }
        if (state is TaskModifiedState) {
          setState(() {
            widget.displaySaveButton = true;
          });
        }
        if (state is TaskSavedState) {
          setState(() {
            widget.displaySaveButton = false;
          });
        }
        if (state is TurnpointFoundState) {
          displayTurnpointView(context, state);
        }
      }, buildWhen: (previous, current) {
        return current is TasksLoadingState ||
            current is TasksTurnpointsLoadedState;
      }, builder: (context, state) {
        if (state is TasksLoadingState) {
          return CommonWidgets.buildLoading();
        }
        if (state is TasksTurnpointsLoadedState) {
          return Stack(
            children: [
              Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    _taskTitle(state.task),
                    _taskDistance(state.task),
                    _turnpointsLabel(),
                    _taskTurnpointsListView(state.taskTurnpoints),
                    _spacerBetweenListandTurnpointsButton(),
                  ]),
              _addTurnpointsButton(),
            ],
          );
        }
        return Center(child: Text("Unhandled State"));
      }),
      floatingActionButton: _displayFloatingActionButton(context),
    );
  }

  Visibility _displayFloatingActionButton(BuildContext context) {
    return Visibility(
      visible: widget.displaySaveButton,
      child: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.update),
        onPressed: () {
          BlocProvider.of<TaskBloc>(context).add(SaveTaskTurnpointsEvent());
          widget.displaySaveButton = false;
        },
      ),
    );
  }

  Widget _taskTitle(Task task) {
    return Expanded(
      flex: 2,
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.only(
                left: 8.0, top: 16.0, right: 8.0, bottom: 8.0),
            child: Text('Task:', style: Theme.of(context).textTheme.subtitle1)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
                initialValue: task.taskName,
                style: Theme.of(context).textTheme.subtitle1,
                onChanged: (text) {
                  BlocProvider.of<TaskBloc>(context)
                      .add(TaskNamedChangedEvent(text));
                }),
          ),
        ),
      ]),
    );
  }

  Widget _taskDistance(Task task) {
    return Flexible(
      flex: 2,
      child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Distance: ' + task.distance.toStringAsFixed(1) + 'km',
              style: Theme.of(context).textTheme.subtitle1)),
    );
  }

  Widget _turnpointsLabel() {
    return Flexible(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            'Turnpoints:',
            style: Theme.of(context).textTheme.subtitle1,
          ),
        ),
      ),
    );
  }

  Widget _taskTurnpointsListView(List<TaskTurnpoint> taskTurnpoints) {
    return Expanded(
      flex: 15,
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ListView.separated(
            scrollDirection: Axis.vertical,
            itemCount: taskTurnpoints.length,
            shrinkWrap: false,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                dense: false,
                contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                leading: IconButton(
                    icon: Icon(Icons.location_searching),
                    color: Colors.blue,
                    //TurnpointUtils.getColorForTurnpointIcon(taskTurnpoints[index].code),
                    onPressed: () {
                      displayTaskTurnpoint(context, taskTurnpoints[index]);
                    }),
                title: TextButton(
                  onPressed: () => print('clicked text'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            taskTurnpoints[index].title,
                            textAlign: TextAlign.left,
                            style: textStyleBoldBlackFontSize16,
                          ),
                          Text(
                            taskTurnpoints[index].taskOrder == 0
                                ? 'Start'
                                : (taskTurnpoints[index].lastTurnpoint
                                    ? 'Finish'
                                    : ''),
                            textAlign: TextAlign.left,
                            style: textStyleBoldBlack87FontSize14,
                          ),
                        ],
                      ),
                      Visibility(
                        visible: taskTurnpoints[index].taskOrder != 0,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                          child: Text(
                            'From prior point: ' +
                                taskTurnpoints[index]
                                    .distanceFromPriorTurnpoint
                                    .toStringAsFixed(1) +
                                'km',
                            textAlign: TextAlign.left,
                            style: textStyleBoldBlack87FontSize14,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: taskTurnpoints[index].taskOrder != 0,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                          child: Text(
                            'From start: ' +
                                taskTurnpoints[index]
                                    .distanceFromStartingPoint
                                    .toStringAsFixed(1) +
                                'km',
                            textAlign: TextAlign.left,
                            style: textStyleBoldBlack87FontSize14,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) {
              return Divider();
            },
          ),
        ),
      ),
    );
  }

  Widget _spacerBetweenListandTurnpointsButton() {
    return Spacer();
  }

  void displayTaskTurnpoint(BuildContext context, TaskTurnpoint taskTurnpoint) {
    BlocProvider.of<TaskBloc>(context)
        .add(DisplayTaskTurnpointEvent(taskTurnpoint));
  }

  Widget _addTurnpointsButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: FractionalOffset.bottomCenter,
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
        ),
      ),
    );
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

  void displayTurnpointView(
      BuildContext context, TurnpointFoundState state) async {
    final result = await Navigator.pushNamed(
      context,
      TurnpointView.routeName,
      arguments: state.turnpoint,
    );
  }
}
