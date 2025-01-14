import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_event.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/bloc/rasp_data_state.dart';



class IncrDecrIconWidget {
  static Widget getIncIconWidget(String symbol) {
    return Text(
      symbol,
      style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 30, color: Colors.blueAccent),
    );
  }
}
