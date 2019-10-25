import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';
import 'package:flutter_soaring_forecast/soaring/values/strings.dart';
import 'package:provider/provider.dart';

import 'main_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return Provider(
        builder: (_) => Repository(context),
        dispose: (context, value) => value.dispose(),
        child: MaterialApp(
            title: Strings.appTitle,
            theme: ThemeData(
              // brightness: Brightness.dark,
              primarySwatch: Colors.blue,
              primaryColor: Colors.blue,
            ),
            home: MainScreen()));
  }
}
