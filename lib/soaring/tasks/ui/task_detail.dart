import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
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
  List<DragAndDropList> _taskTurnpointDragAndDropList = [];

  @override
  void afterFirstLayout(BuildContext context) {
    setState(() {
      BlocProvider.of<TaskBloc>(context)
          .add(LoadTaskTurnpointsEvent(widget.taskId));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return _buildScaffold(context);
    } else {
      //iOS
      return GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.direction >= 0) {
            Navigator.of(context).pop();
          }
        },
        child: _buildScaffold(context),
      );
    }
  }

  Scaffold _buildScaffold(BuildContext context) {
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
          return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                _taskTitle(state.task),
                _taskDistance(state.task),
                _turnpointsLabel(),
                _taskTurnpointsListView(state.taskTurnpoints),
                _spacerBetweenListandTurnpointsButton(),
                _addTurnpointsButton(),
              ]);
        }
        return Center(child: Text("Unhandled State"));
      }),
      floatingActionButton: _displayFloatingActionButton(context),
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
              child: TextField(
                controller: TextEditingController()..text = task.taskName,
                onChanged: (text) => {
                  BlocProvider.of<TaskBloc>(context)
                      .add(TaskNamedChangedEvent(text))
                },
              )
              // child: TextFormField(
              //     initialValue: task.taskName,
              //     style: Theme.of(context).textTheme.subtitle1,
              //     onChanged: (text) {
              //       BlocProvider.of<TaskBloc>(context)
              //           .add(TaskNamedChangedEvent(text));
              //     }),
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
    _taskTurnpointDragAndDropList.clear();
    List<DragAndDropItem> taskTurnpointDragAndDropItems = [];
    taskTurnpoints.forEach((taskTurnpoint) {
      taskTurnpointDragAndDropItems
          .add(_createTaskTurnpointItem(taskTurnpoint));
    });
    _taskTurnpointDragAndDropList
        .add(DragAndDropList(children: taskTurnpointDragAndDropItems));
    return Expanded(
      flex: 15,
      child: Align(
        alignment: Alignment.topLeft,
        child: DragAndDropLists(
          children: _taskTurnpointDragAndDropList,
          onItemReorder: _onItemReorder,
          onListReorder: _onListReorder,
        ),
      ),
    );
  }

  _onItemReorder(
      int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
    // setState(() {
    //   var movedItem = _taskTurnpointDragAndDropList[oldListIndex]
    //       .children
    //       .removeAt(oldItemIndex);
    //   _taskTurnpointDragAndDropList[newListIndex]
    //       .children
    //       .insert(newItemIndex, movedItem);
    // });
    BlocProvider.of<TaskBloc>(context)
        .add(SwitchOrderOfTaskTurnpointsEvent(oldItemIndex, newItemIndex));
  }

  _onListReorder(int oldListIndex, int newListIndex) {
    setState(() {
      var movedList = _taskTurnpointDragAndDropList.removeAt(oldListIndex);
      _taskTurnpointDragAndDropList.insert(newListIndex, movedList);
    });
  }

  DragAndDropItem _createTaskTurnpointItem(TaskTurnpoint taskTurnpoint) {
    return DragAndDropItem(
      child: Dismissible(
        key: UniqueKey(),
        onDismissed: (direction) {
          BlocProvider.of<TaskBloc>(context)
              .add(SwipeDeletedTaskTurnpointEvent(taskTurnpoint.taskOrder));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Removed ${taskTurnpoint.title}'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                BlocProvider.of<TaskBloc>(context)
                    .add(AddBackTaskTurnpointEvent(taskTurnpoint));
              },
            ),
          ));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                      icon: Icon(Icons.location_searching),
                      color: Colors.blue,
                      onPressed: () {
                        _displayTaskTurnpoint(context, taskTurnpoint);
                      }),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  taskTurnpoint.title,
                                  textAlign: TextAlign.left,
                                  style: textStyleBoldBlackFontSize16,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  taskTurnpoint.taskOrder == 0
                                      ? 'Start'
                                      : (taskTurnpoint.lastTurnpoint
                                          ? 'Finish'
                                          : ''),
                                  textAlign: TextAlign.right,
                                  style: textStyleBoldBlack87FontSize14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Visibility(
                          visible: taskTurnpoint.taskOrder != 0,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                            child: Text(
                              'From prior point: ' +
                                  taskTurnpoint.distanceFromPriorTurnpoint
                                      .toStringAsFixed(1) +
                                  'km',
                              textAlign: TextAlign.left,
                              style: textStyleBoldBlack87FontSize14,
                            ),
                          ),
                        ),
                        Visibility(
                          visible: taskTurnpoint.taskOrder != 0,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                            child: Text(
                              'From start: ' +
                                  taskTurnpoint.distanceFromStartingPoint
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
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: Divider(
                thickness: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spacerBetweenListandTurnpointsButton() {
    return Spacer();
  }

  void _displayTaskTurnpoint(
      BuildContext context, TaskTurnpoint taskTurnpoint) {
    BlocProvider.of<TaskBloc>(context)
        .add(DisplayTaskTurnpointEvent(taskTurnpoint));
  }

  Widget _addTurnpointsButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 8.0, right: 8.0),
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

  void _getTurnpointsForTask() async {
    final result = await Navigator.pushNamed(
      context,
      TurnpointsForTask.routeName,
      arguments: TurnpointsSearchInAppBarScreen.TASK_TURNPOINT_OPTION,
    );
    if (result is List<Turnpoint>) {
      BlocProvider.of<TaskBloc>(context)
          .add(TurnpointsAddedToTaskEvent(result));
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
