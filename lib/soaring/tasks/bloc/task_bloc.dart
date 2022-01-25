import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/floor/task/task.dart';
import 'package:flutter_soaring_forecast/soaring/floor/taskturnpoint/task_turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_event.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/bloc/task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final Repository repository;

//TaskState get initialState => TasksLoadingState();

  TaskBloc({required this.repository}) : super(TasksLoadingState()) {
    on<TaskListEvent>(_showAllTasks);
    on<TaskTurnpointsEvent>(_showTaskTurnpoints);
  }

  void _showAllTasks(TaskListEvent event, Emitter<TaskState> emit) async {
    emit(TasksLoadingState());
    List<Task> tasks = [];
    try {
      tasks.addAll(await repository.getAlltasks());
      emit(TasksLoadedState(tasks));
    } catch (e) {
      emit(TaskErrorState(e.toString()));
    }
  }

  void _showTaskTurnpoints(
      TaskTurnpointsEvent event, Emitter<TaskState> emit) async {
    emit(TasksTurnpointsLoadingState());
    List<TaskTurnpoint> taskturnpoints = [];
    try {
      taskturnpoints.addAll(await repository.getTaskTurnpoints(event.task.id));
      emit(TasksTurnpointsLoadiedState(taskturnpoints));
    } catch (e) {
      emit(TaskErrorState(e.toString()));
    }
  }
}
