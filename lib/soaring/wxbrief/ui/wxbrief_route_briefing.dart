import 'dart:io';

import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/material.dart' hide Feedback;

class WxBriefRouteBriefing extends StatefulWidget {
  WxBriefRouteBriefing({Key? key}) : super(key: key);

  @override
  _WxBriefRouteBriefingState createState() => _WxBriefRouteBriefingState();
}

class _WxBriefRouteBriefingState extends State<WxBriefRouteBriefing> {
  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return ConditionalWillPopScope(
        onWillPop: _onWillPop,
        shouldAddCallback: true,
        child: _buildSafeArea(context),
      );
    } else {
      //iOS
      return GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.direction >= 0) {
            _onWillPop();
          }
        },
        child: _buildSafeArea(context),
      );
    }
  }

  Widget _buildSafeArea(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: getAppBar(context),
        body: _getBody(),
      ),
    );
  }

  AppBar getAppBar(BuildContext context) {
    return AppBar(
      title: Text("Task RouteBriefing"),
      leading: BackButton(onPressed: () => Navigator.pop(context)),
      //  actions: _getAppBarMenu(),
    );
  }

  Widget _getBody() {
    return Text("Task NOTAMS");
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop();
    return true;
  }
}
