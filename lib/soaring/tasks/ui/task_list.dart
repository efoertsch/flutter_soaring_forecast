import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show TaskLiterals;
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_event.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_state.dart';

class TaskListScreen extends StatelessWidget {
  final String? viewOption;
  static const String SELECT_TASK_OPTION = 'SELECT_TASK_OPTION';
  late final BuildContext _context;

  TaskListScreen({Key? key, String? this.viewOption = null}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    _context = context;
    BlocProvider.of<TaskBloc>(context).add(TaskListEvent());
    if (Platform.isAndroid) {
      return _buildScaffold(context);
    } else {
      //iOS
      return GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onHorizontalDragUpdate: (details) {
          if (details.delta.direction >= 0) {
            Navigator.of(context).pop();
          }
        },
        child: _buildScaffold(context),
      );
    }
  }

  SafeArea _buildScaffold(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: _getAppBar(context),
        body: _getBody(),
      ),
    );
  }

  AppBar _getAppBar(BuildContext context) {
    return AppBar(
        leading: BackButton(
          onPressed: () => Navigator.pop(_context),
        ),
        title: Text(TaskLiterals.TASK_LIST),
        actions: _getMenu(context));
  }

  List<Widget> _getMenu(BuildContext context) {
    return <Widget>[
      TextButton(
        child: const Text(TaskLiterals.ADD_TASK,
            style: TextStyle(color: Colors.white)),
        onPressed: () {
          _goToTaskDetail(context, -1);
        },
      ),
    ];
  }

  BlocConsumer<TaskBloc, TaskState> _getBody() {
    return BlocConsumer<TaskBloc, TaskState>(
      listener: (context, state) {
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
      },
      buildWhen: (previous, current) {
        return current is TasksLoadingState ||
            current is TasksLoadedState ||
            current is TaskErrorState;
      },
      builder: (context, state) {
        if (state is TasksLoadingState) {
          return CommonWidgets.buildLoading();
        }
        if (state is TasksLoadedState) {
          if (state.tasks.length == 0) {
            // WidgetsBinding.instance?.addPostFrameCallback(
            //     (_) => _showNoTasksFoundDialog(context));
            return Center(child: Text("No Tasks Found"));
          } else {
            return Column(
              children: [
                SizedBox(height: 8),
                _getTaskListView(state.tasks),
              ],
            );
          }
        }
        if (state is TaskErrorState) {
          WidgetsBinding.instance.addPostFrameCallback((_) =>
              CommonWidgets.showErrorDialog(
                  context, 'Tasks Error', state.errorMsg));
          return Center(
              child: Text('Oops. Error occurred searching the task database.'));
        }
        return Center(child: Text("Unhandled State"));
      },
    );
  }

  Widget _getTaskListView(List<Task> tasks) {
    return Expanded(
      child: ReorderableListView(
          children: _getTaskListWidgets(tasks),
          onReorder: (int oldIndex, int newIndex) {
            // ReorderableListView has known index bug
            if (newIndex > tasks.length) newIndex = tasks.length;
            if (oldIndex < newIndex) newIndex--;
            BlocProvider.of<TaskBloc>(_context)
                .add(SwitchOrderOfTasksEvent(oldIndex, newIndex));
          }),
    );
  }

  List<Widget> _getTaskListWidgets(List<Task> tasks) {
    final taskListWidgets = <Widget>[];
    tasks.forEach((task) {
      taskListWidgets.add(
        Align(
          key: Key('${task.taskOrder}'),
          alignment: Alignment.topLeft,
          child: _createTaskItem(task),
        ),
      );
    });
    return taskListWidgets;
  }

  Widget _createTaskItem(Task task) {
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
            Expanded(
                child: Text(task.taskName, style: textStyleBlackFontSize20)),
          ],
        ),
      ),
      key: UniqueKey(),
      onDismissed: (direction) {
        BlocProvider.of<TaskBloc>(_context)
            .add(SwipeDeletedTaskEvent(task.taskOrder));
        ScaffoldMessenger.of(_context).showSnackBar(SnackBar(
          content: Text('Removed ${task.taskName}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              BlocProvider.of<TaskBloc>(_context).add(AddBackTaskEvent(task));
            },
          ),
        ));
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                flex: 10,
                child: Material(
                  color: Colors.white.withOpacity(0.0),
                  child: InkWell(
                    onTap: () {
                      if (viewOption == TaskListScreen.SELECT_TASK_OPTION) {
                        Navigator.of(_context).pop(task.id);
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            task.taskName,
                            textAlign: TextAlign.left,
                            style: textStyleBlackFontSize20,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Text(
                            task.distance.toStringAsFixed(1) + 'km',
                            textAlign: TextAlign.left,
                            style: textStyleBlack87FontSize15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _goToTaskDetail(_context, task.id!),
                  ),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child:
                  const Divider(height: 2, thickness: 2, color: Colors.black12),
            )
          ],
        ),
      ),
    );
  }

  void _goToTaskDetail(BuildContext context, int taskId) async {
    await Navigator.pushNamed(
      context,
      TaskDetailRouteBuilder.routeName,
      arguments: taskId,
    );
    BlocProvider.of<TaskBloc>(context).add(TaskListEvent());
  }
}
