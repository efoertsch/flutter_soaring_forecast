import 'dart:io';

import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
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
        appBar: _getAppBar(),
        body: _getBody(),
        floatingActionButton: _getTaskDetailFAB(context),
      ),
    );
  }

  AppBar _getAppBar() {
    return AppBar(
      leading: BackButton(
        onPressed: () => Navigator.pop(_context),
      ),
      title: Text('Task List'),
    );
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

  FloatingActionButton _getTaskDetailFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        _goToTaskDetail(context, -1);
      },
      backgroundColor: Colors.green,
      child: const Icon(Icons.add),
    );
  }

  Widget _getTaskListView(List<Task> tasks) {
    if (tasks.length == 0) {
      return Center(
        child: Text('No tasks found'),
      );
    }
    List<DragAndDropList> taskDragAndDropList = [];
    List<DragAndDropItem> taskDragAndDropItems = [];
    tasks.forEach((task) {
      taskDragAndDropItems.add(_createTaskItem(task));
    });
    taskDragAndDropList.add(DragAndDropList(children: taskDragAndDropItems));
    return Expanded(
      flex: 15,
      child: Align(
        alignment: Alignment.topLeft,
        child: DragAndDropLists(
          children: taskDragAndDropList,
          onItemReorder: _onItemReorder,
          onListReorder: _onListReorder,
        ),
      ),
    );
  }

  _onItemReorder(
      int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
    BlocProvider.of<TaskBloc>(_context)
        .add(SwitchOrderOfTasksEvent(oldItemIndex, newItemIndex));
  }

  _onListReorder(int oldListIndex, int newListIndex) {
    // don't have more that 1 list so no reorder
  }

  DragAndDropItem _createTaskItem(Task task) {
    return DragAndDropItem(
      child: Dismissible(
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
                child: const Divider(
                    height: 2, thickness: 2, color: Colors.black12),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _goToTaskDetail(BuildContext context, int taskId) async {
    await Navigator.pushNamed(
      context,
      TaskDetail.routeName,
      arguments: taskId,
    );
    BlocProvider.of<TaskBloc>(context).add(TaskListEvent());
  }
}
