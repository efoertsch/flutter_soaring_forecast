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
}
