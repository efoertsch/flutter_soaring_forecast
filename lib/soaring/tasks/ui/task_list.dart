import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/main.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_event.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_state.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/ui/task_list_view.dart';

class TaskListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    BlocProvider.of<TaskBloc>(context).add(TaskListEvent());
    return Scaffold(
      appBar: AppBar(
        leading: CommonWidgets.backArrowToHomeScreen(),
        title: Text('Task List'),
      ),
      body: BlocConsumer<TaskBloc, TaskState>(
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
            CommonWidgets.showErrorDialog(
                context, 'Task Error', state.errorMsg);
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
              return TaskListView(context: context, tasks: state.tasks)
                  .getTaskListView();
            }
          }
          if (state is TaskErrorState) {
            WidgetsBinding.instance?.addPostFrameCallback((_) =>
                CommonWidgets.showErrorDialog(
                    context, 'Tasks Error', state.errorMsg));
            return Center(
                child:
                    Text('Oops. Error occurred searching the task database.'));
          }
          return Center(child: Text("Unhandled State"));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _goToTaskDetail(context, -1);
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showNoTasksFoundDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Defined Tasks'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                    'No tasks found in database.\n Would you like to add one?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('NO'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
                child: const Text('YES'),
                onPressed: () {
                  _goToTaskDetail(context, -1);
                }),
          ],
        );
      },
    );
  }

  void _goToTaskDetail(BuildContext context, int taskId) {
    Navigator.pushNamed(
      context,
      TaskDetail.routeName,
      arguments: taskId,
    );
  }
}
