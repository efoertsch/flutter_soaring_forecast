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
          print("button1 pressed");
          button1Function();
        }));
    if (button2Text != null) {
      buttonWidgets.add(TextButton(
          child: Text(button2Text),
          onPressed: () {
            print("button2 pressed");
            button2Function!();
          }));
    }
    return buttonWidgets;
  }

  static showTwoButtonAlertDialog(BuildContext context, String alertMsg,
      {String title = "AlertDialog",
      String cancelButtonText = "Cancel",
      String continueButtonText = "OK",
      final Function? cancelButtonFunction,
      final Function? continueButtonFunction}) {
    // set up the buttons
    Widget cancelButton = TextButton(
        child: Text(cancelButtonText),
        onPressed: () {
          if (cancelButtonFunction != null) {
            cancelButtonFunction();
          }
        });
    Widget continueButton = TextButton(
        child: Text(continueButtonText),
        onPressed: () {
          if (continueButtonFunction != null) {
            continueButtonFunction();
          }
        });

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(alertMsg),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(onWillPop: () async => false, child: alert);
      },
    );
  }

  static SnackBar getSnackBarForMessage(String msg) {
    return SnackBar(content: Text(msg));
  }

  static Future<List<CheckboxItem>?> showCheckBoxsInfoDialog(
      {required final BuildContext context,
      required final String title,
      required final String msg,
      required final String button1Text,
      required final Function button1Function,
      final String? button2Text,
      final Function? button2Function,
      required final List<CheckboxItem> checkboxItems}) async {
    return showDialog<List<CheckboxItem>?>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: Container(
              width: double.minPositive,
              child: getCheckboxListTiles(context, checkboxItems, setState),
            ),
            actions: composeDialogButtons(
                button1Text: button1Text,
                button1Function: button1Function,
                button2Text: button2Text,
                button2Function: button2Function),
          );
        });
      },
    );
  }

  static Widget getCheckboxListTiles(BuildContext context,
      List<CheckboxItem> checkboxItems, StateSetter setState) {
    return ListView.separated(
        shrinkWrap: true,
        itemCount: checkboxItems.length,
        itemBuilder: (BuildContext context, int index) {
          return CheckboxListTile(
            title: Text(checkboxItems[index].checkboxText),
            value: checkboxItems[index].isChecked,
            onChanged: (bool? value) {
              setState(() {
                checkboxItems[index].isChecked = value!;
              });
            },
          );
        },
        separatorBuilder: (context, index) {
          return Divider();
        });
  }
}

class CheckboxItem {
  final String checkboxText;
  bool isChecked;

  CheckboxItem(this.checkboxText, this.isChecked);
}
