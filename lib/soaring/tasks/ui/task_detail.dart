import 'package:after_layout/after_layout.dart';
import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show StandardLiterals, TaskLiterals;
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_event.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_state.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_overhead_view.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoints_list.dart';

//ignore: must_be_immutable
class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  bool displaySaveButton = false;

  TaskDetailScreen({Key? key, required this.taskId}) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen>
    with AfterLayoutMixin<TaskDetailScreen> {
  final TextEditingController textEditingController = TextEditingController();

  @override
  void afterFirstLayout(BuildContext context) {
    setState(() {
      BlocProvider.of<TaskBloc>(context)
          .add(LoadTaskTurnpointsEvent(widget.taskId));
    });
  }

  @override
  Widget build(BuildContext context) {
    // no right swipe to return as can conflict with right swipe to delete
    // taskturnpoint
    return ConditionalWillPopScope(
      onWillPop: _onWillPop,
      shouldAddCallback: true,
      child: _buildSafeArea(context),
    );
  }

  Widget _buildSafeArea(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: _getAppBar(),
        body: _getBody(),
      ),
    );
  }

  AppBar _getAppBar() {
    return AppBar(
      title: Text(TaskLiterals.TASK_DETAIL),
      leading: BackButton(
        onPressed: _onWillPop,
      ),
      actions: _getMenu(),
    );
  }

  List<Widget> _getMenu() {
    return <Widget>[
      Visibility(
        visible: widget.displaySaveButton,
        child: TextButton(
          child: const Text(TaskLiterals.SAVE_TASK,
              style: TextStyle(color: Colors.white)),
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            BlocProvider.of<TaskBloc>(context).add(SaveTaskTurnpointsEvent());
            widget.displaySaveButton = false;
          },
        ),
      ),
    ];
  }

  BlocConsumer<TaskBloc, TaskState> _getBody() {
    return BlocConsumer<TaskBloc, TaskState>(listener: (context, state) {
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
            context, TaskLiterals.TASK_ERROR, state.errorMsg);
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
              //_spacerBetweenListAndTurnpointsButton(),
              _addTurnpointsButton(),
            ]);
      }
      return Center(child: Text(StandardLiterals.UNDEFINED_STATE));
    });
  }

  Widget _taskTitle(Task task) {
    textEditingController.text = task.taskName;
    textEditingController.selection =
        TextSelection.collapsed(offset: textEditingController.text.length);
    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Padding(
            padding: const EdgeInsets.only(
                left: 8.0, top: 16.0, right: 8.0, bottom: 8.0),
            child: Text(
              TaskLiterals.TASK_NAME,
              style: textStyleBoldBlackFontSize16,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                style: textStyleBoldBlackFontSize18,
                minLines: 1,
                maxLines: 2,
                controller: textEditingController,
                decoration: new InputDecoration.collapsed(
                    hintText: TaskLiterals.LEAVE_BLANK_FOR_DEFAULT_NAME),
                onChanged: (text) {
                  //task.taskName = text;
                  // textEditingController.selection = TextSelection.collapsed(
                  //     offset: textEditingController.text.length);
                  BlocProvider.of<TaskBloc>(context)
                      .add(TaskNamedChangedEvent(text));
                },
              ),
            ),
          ),
        ]);
  }

  Widget _taskDistance(Task task) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              TaskLiterals.DISTANCE,
              style: textStyleBoldBlackFontSize16,
            ),
            Text(
              " ${task.distance.toStringAsFixed(1)} ${TaskLiterals.KM}",
              style: textStyleBoldBlackFontSize18,
            ),
          ],
        ));
  }

  Widget _turnpointsLabel() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          TaskLiterals.TURNPOINTS,
          style: Theme.of(context).textTheme.subtitle1,
        ),
      ),
    );
  }

  Widget _taskTurnpointsListView(List<TaskTurnpoint> taskTurnpoints) {
    return Expanded(
      child: ReorderableListView(
        children: _getTaskTurnpointDetailList(taskTurnpoints),
        onReorder: (int oldIndex, int newIndex) {
          // ReorderableListView has known index bug
          if (newIndex > taskTurnpoints.length)
            newIndex = taskTurnpoints.length;
          if (oldIndex < newIndex) newIndex--;
          BlocProvider.of<TaskBloc>(context)
              .add(SwitchOrderOfTaskTurnpointsEvent(oldIndex, newIndex));
        },
      ),
    );
  }

  List<Widget> _getTaskTurnpointDetailList(List<TaskTurnpoint> taskTurnpoints) {
    final taskTurnpointsWidgetsList = <Widget>[];
    taskTurnpoints.forEach((taskTurnpoint) {
      taskTurnpointsWidgetsList.add(
        Align(
          key: Key('${taskTurnpoint.taskOrder}'),
          alignment: Alignment.topLeft,
          child: _createTaskTurnpointItem(taskTurnpoint),
        ),
      );
    });
    return taskTurnpointsWidgetsList;
  }

  // Creates a row within the listview for task turnpoint info
  Widget _createTaskTurnpointItem(TaskTurnpoint taskTurnpoint) {
    return Dismissible(
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red,
        padding: EdgeInsets.only(left: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.delete,
            ),
            Text(
              taskTurnpoint.title,
              style: textStyleBoldBlackFontSize16,
            )
          ],
        ),
      ),
      key: UniqueKey(),
      onDismissed: (direction) {
        BlocProvider.of<TaskBloc>(context)
            .add(SwipeDeletedTaskTurnpointEvent(taskTurnpoint.taskOrder));
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${StandardLiterals.REMOVED} ${taskTurnpoint.title}'),
          action: SnackBarAction(
            label: StandardLiterals.UNDO,
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
                    color: taskTurnpoint.turnpointColor,
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
                                    ? TaskLiterals.START
                                    : (taskTurnpoint.lastTurnpoint
                                        ? TaskLiterals.FINISH
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
                            TaskLiterals.FROM_PRIOR_POINT +
                                ' ' +
                                taskTurnpoint.distanceFromPriorTurnpoint
                                    .toStringAsFixed(1) +
                                TaskLiterals.KM,
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
                            TaskLiterals.FROM_START +
                                ' ' +
                                taskTurnpoint.distanceFromStartingPoint
                                    .toStringAsFixed(1) +
                                TaskLiterals.KM,
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
    );
  }

  void _displayTaskTurnpoint(
      BuildContext context, TaskTurnpoint taskTurnpoint) {
    BlocProvider.of<TaskBloc>(context)
        .add(DisplayTaskTurnpointEvent(taskTurnpoint));
  }

  Widget _addTurnpointsButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
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
            TaskLiterals.ADD_TURNPOINTS,
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
      TurnpointsForTaskRouteBuilder.routeName,
      arguments: TurnpointsList.TASK_TURNPOINT_OPTION,
    );
    if (result is List<Turnpoint>) {
      BlocProvider.of<TaskBloc>(context)
          .add(TurnpointsAddedToTaskEvent(result));
    }
  }

  void displayTurnpointView(
      BuildContext context, TurnpointFoundState state) async {
    await Navigator.pushNamed(
      context,
      TurnpointViewRouteBuilder.routeName,
      arguments: TurnpointOverHeadArgs(turnpoint: state.turnpoint),
    );
  }

  Future<bool> _onWillPop() async {
    // TODO check for changes
    if (widget.displaySaveButton) {
      CommonWidgets.showInfoDialog(
          context: context,
          title: StandardLiterals.UNSAVED_CHANGES,
          msg: StandardLiterals.CHANGES_WILL_BE_LOST,
          button1Text: StandardLiterals.NO,
          button1Function: _dismissDialogFunction,
          button2Text: StandardLiterals.YES,
          button2Function: _cancelUpdateFunction);
    } else {
      Navigator.pop(context);
    }
    return true;
  }

  void _dismissDialogFunction() {
    Navigator.pop(context);
  }

  void _cancelUpdateFunction() {
    Navigator.pop(context); // remove dialog
    Navigator.pop(context); // return to prior screen
  }
}
