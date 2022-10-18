import 'dart:ui';

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

  static Widget backArrow(
      {required BuildContext context, Function? backFunction}) {
    return BackButton(
      onPressed: () {
        if (backFunction != null) {
          backFunction();
        } else {
          Navigator.pop(context);
        }
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

  static showInfoDialog(
      {required final BuildContext context,
      required final String title,
      required final String msg,
      required final String button1Text,
      required final Function button1Function,
      final String? button2Text,
      final Function? button2Function}) async {
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
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

    // show the dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(onWillPop: () async => false, child: alert);
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

  static Future<void> displayTextInputDialog({
    required BuildContext context,
    required String title,
    required String inputHintText,
    required TextEditingController textEditingController,
    required String button1Text,
    required Function button1Function,
    String? button2Text,
    Function? button2Function,
    bool barrierDismissible = false,
    int minLines = 2,
    int maxLines = 10,
    double widthFactor = .75,
    double heightFactor = .5,
  }) async {
    return showDialog(
        barrierDismissible: barrierDismissible,
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: FractionallySizedBox(
              widthFactor: widthFactor,
              heightFactor: heightFactor,
              child: TextFormField(
                controller: textEditingController,
                decoration: InputDecoration(hintText: inputHintText),
                minLines: minLines,
                maxLines: maxLines,
              ),
            ),
            actions: composeDialogButtons(
                button1Text: button1Text,
                button1Function: button1Function,
                button2Text: button2Text,
                button2Function: button2Function),
          );
        });
  }

  static PopupMenuItem<bool> getCheckBoxMenuItem({
    required BuildContext context,
    required bool isChecked,
    required String menuText,
    required Function setStateCallBack,
  }) {
    return PopupMenuItem(
      child: Row(children: <Widget>[
        Text(menuText),
        //https://stackoverflow.com/questions/67007911/check-box-in-drop-down-list-flutter
        StatefulBuilder(
          builder: (_context, _setState) {
            return Checkbox(
              value: isChecked,
              onChanged: (bool? value) {
                Navigator.pop(context);
                // note here we call stateSetter from the StatefulBuilder!
                _setState(() {
                  isChecked = value!;
                  // reverse the value
                  setStateCallBack(isChecked);
                });
              },
            );
          },
        ),
      ]),
    );
  }

  static Widget getProxyDecorator(
      Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final ColorScheme colorScheme = Theme.of(context).colorScheme;
        final Color draggableItemColor = colorScheme.secondary;
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double elevation = lerpDouble(0, 6, animValue)!;
        return Material(
          elevation: elevation,
          color: draggableItemColor,
          shadowColor: draggableItemColor,
          child: child,
        );
      },
      child: child,
    );
  }
}

class CheckboxItem {
  final String checkboxText;
  bool isChecked;

  CheckboxItem(this.checkboxText, this.isChecked);
}
