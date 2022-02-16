import 'package:flutter/material.dart';

class CustomStyle {
  static TextStyle bold18(BuildContext context) {
    return Theme.of(context)
        .textTheme
        .bodyText1!
        .copyWith(fontSize: 18.0, fontWeight: FontWeight.bold);
  }
}
