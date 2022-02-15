import 'package:flutter/material.dart';

class CommonWidgets {
  static Widget backArrowToHomeScreen() {
    return Builder(
      builder: (BuildContext context) {
        return IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.popUntil(
                context, ModalRoute.withName(Navigator.defaultRouteName));
          },
        );
      },
    );
  }

  static Widget buildLoading() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  static Future<void> showErrorDialog(
      BuildContext context, String title, String errorMsg) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[Text(errorMsg)],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> showInfoDialog(
      {required final BuildContext context,
      required final String title,
      required final String msg,
      required final String button1Text,
      required final Function button1Function,
      final String? button2Text,
      final Function? button2Function}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[Text(msg)],
            ),
          ),
          actions: composeDialogButtons(
              button1Text: button1Text,
              button1Function: button1Function,
              button2Text: button2Text,
              button2Function: button2Function),
        );
      },
    );
  }

  static List<Widget> composeDialogButtons(
      {required final String button1Text,
      required final Function button1Function,
      final String? button2Text,
      final Function? button2Function}) {
    final buttonWidgets = <Widget>[];
    buttonWidgets.add(TextButton(
        child: Text(button1Text),
        onPressed: () {
          button1Function;
        }));
    if (button2Text != null) {
      buttonWidgets.add(TextButton(
          child: Text(button2Text),
          onPressed: () {
            button2Function;
          }));
    }
    return buttonWidgets;
  }

  static SnackBar getSnackBarForMessage(String msg){
    return SnackBar(content: Text(msg));
  }
}