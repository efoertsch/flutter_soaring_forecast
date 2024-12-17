import 'package:flutter/material.dart';

class IncrDecrIconWidget {
  static Widget getIncIconWidget(String symbol) {
    return Text(
      symbol,
      style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 30, color: Colors.blueAccent),
    );
  }
}
