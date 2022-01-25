import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/ui/rasp_screen.dart';

class AppNavigator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Navigator(
        pages: [
          MaterialPage(child: RaspScreen(repositoryContext: context)),
        ],
        onPopPage: (route, result) {
          return true;
        });
  }
}
