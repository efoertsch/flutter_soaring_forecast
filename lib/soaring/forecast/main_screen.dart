import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/bloc/rasp_data_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/bloc/regions_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/rasp_screen.dart';
import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => Repository(context),
      child: MyChild(),
    );
  }
}

class MyChild extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RaspDataBloc>(
            create: (BuildContext context) => RaspDataBloc(
                repository: RepositoryProvider.of<Repository>(context))),
        BlocProvider<RegionsBloc>(
            create: (BuildContext context) => RegionsBloc(
                repository: RepositoryProvider.of<Repository>(context))),
      ],
      child: RaspScreen(repositoryContext: context),
    );
  }
}
