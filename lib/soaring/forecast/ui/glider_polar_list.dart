import 'dart:async';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/cubit/glider_cubit.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/cubit/polar_state.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/polars.dart';

class GliderPolarListScreen extends StatefulWidget {
  GliderPolarListScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<GliderPolarListScreen> createState() => _GliderPolarListScreenState();
}

class _GliderPolarListScreenState extends State<GliderPolarListScreen>
    with AfterLayoutMixin<GliderPolarListScreen> {
  String? selectedGlider = null;
  Polar? polar = null;

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {
    // TODO: implement afterFirstLayout
    BlocProvider.of<GliderPolarCubit>(context).getListOfGliders();
  }

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<GliderPolarCubit>(context);
    if (Platform.isAndroid) {
      return _buildScaffold(context);
    } else {
      //iOS
      return GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onHorizontalDragUpdate: (details) {
          if (details.delta.direction >= 0) {
            Navigator.of(context).pop();
          }
        },
        child: _buildScaffold(context),
      );
    }
  }

  SafeArea _buildScaffold(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: _getAppBar(context),
        body: _getBody(),
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity,
                      40), // double.infinity is the width and 30 is the height
                  foregroundColor: Colors.white,
                  backgroundColor: Theme
                      .of(context)
                      .colorScheme
                      .primary,
                ), child:
            Text("Optimize Route"),
                 onPressed: () {
                   Navigator.pop(context, polar);
                 },),
          ),),
    ),);
  }

  AppBar _getAppBar(BuildContext context) {
    return AppBar(
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(PolarLiterals.POLAR),
        actions: _getMenu(context));
  }

  List<Widget> _getMenu(BuildContext context) {
    return <Widget>[];
  }

  Widget _getBody() {
    return Stack(
      children: [
        Column(children: [
          _getGliderList(),
          _displayGliderDetail(),
        ]),
        _getIsWorkingIndicator(),
        _getErrorMessagesWidget()
      ],
    );
  }

  Widget _getGliderList() {
    return BlocConsumer<GliderPolarCubit, PolarDataState>(
        listener: (context, state) {
          return;
        }, buildWhen: (previous, current) {
      return current is GliderListState;
    }, builder: (context, state) {
      if (state is GliderListState) {
        if (state.gliderList.length == 0) {
          // WidgetsBinding.instance?.addPostFrameCallback(
          //     (_) => _showNoTasksFoundDialog(context));
          return Center(child: Text("No Polars Found"));
        } else {
          return _getGliderListView(state.gliderList);
        }
      }
      return SizedBox.shrink();
    });
  }

  Widget _getGliderListView(List<String> gliders) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _formatedTextCell("Glider:"),
          ),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              style: textStyleBoldBlackFontSize18,
              value: selectedGlider,
              hint: _formatedTextCell("Select Glider"),
              icon: const Icon(Icons.arrow_downward),
              elevation: 16,
              underline: Container(
                height: 2,
                color: Colors.black,
              ),
              onChanged: (String? value) {
                // This is called when the user selects an item.
                setState(() {
                  selectedGlider = value!;
                  BlocProvider.of<GliderPolarCubit>(context)
                      .getGliderPolar(selectedGlider!);
                });
              },
              items: gliders.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: _formatedTextCell(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// gliderAndMaxPilotWgt,
  /// maxBallast,
  /// v1,
  /// w1,
  /// v2,
  /// w2,
  /// v3,
  /// w3,
  /// wingArea,
  /// ballastDumpTime,
  /// handicap,
  /// gliderEmptyMass}
  Widget _displayGliderDetail() {
    return BlocConsumer<GliderPolarCubit, PolarDataState>(
        listener: (context, state) {
          return;
        }, buildWhen: (previous, current) {
      return current is GliderPolarState;
    }, builder: (context, state) {
      if (state is GliderPolarState) {
        polar = state.polar;
        return (state.polar == null)
            ? SizedBox.shrink()
            : Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
            Text("Speed vs sink Rate",
                style: textStyleBoldBlackFontSize18,
                textAlign: TextAlign.center),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Table(
                border: TableBorder.all(),
                defaultVerticalAlignment:
                TableCellVerticalAlignment.middle,
                children: <TableRow>[
                  TableRow(
                    children: [
                      _formatedTextCell("",),
                      _formatedTextCell("1"),
                      _formatedTextCell("2"),
                      _formatedTextCell("3"),
                    ],
                  ),
                  TableRow(
                    children: [
                      _formatedTextCell("V (km/hr)"),
                      _formatedTextCell(polar!.v1.toStringAsFixed(1)),
                      _formatedTextCell(polar!.v2.toStringAsFixed(1)),
                      _formatedTextCell(polar!.v3.toStringAsFixed(1)),
                    ],
                  ),
                  TableRow(
                    children: [
                      _formatedTextCell("W (m/sec)"),
                      _formatedTextCell(polar!.w1.toStringAsFixed(1)),
                      _formatedTextCell(polar!.w2.toStringAsFixed(1)),
                      _formatedTextCell(polar!.w3.toStringAsFixed(1)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Table(
                border: TableBorder.all(),
                defaultVerticalAlignment:
                TableCellVerticalAlignment.middle,
                children: <TableRow>[
                  TableRow(
                    children: [
                      _formatedTextCell(
                        "Glider Mass (kg)",
                      ),
                      _formatedTextCell(
                          polar!.gliderEmptyMass.toStringAsFixed(0)),
                    ],
                  ),
                  TableRow(
                    children: [
                      _formatedTextCell(
                        "Max Pilot Wgt (kg)",
                      ),
                      _formatedTextCell((polar!.gliderAndMaxPilotWgt -
                          polar!.gliderEmptyMass)
                          .toStringAsFixed(0)),
                    ],
                  ),
                  TableRow(
                    children: [
                      _formatedTextCell(
                        "Ref Mass (kg)",
                      ),
                      _formatedTextCell(
                          polar!.gliderAndMaxPilotWgt.toStringAsFixed(0)),
                    ],
                  ),
                ],
              ),
            ),
          ]),
        );
      }
      return SizedBox.shrink();
    });
  }

  Widget _formatedTextCell(String text) {
    return Text(text,
        style: textStyleBoldBlackFontSize18, textAlign: TextAlign.center);
  }

  Widget _getIsWorkingIndicator() {
    return BlocConsumer<GliderPolarCubit, PolarDataState>(
        listener: (context, state) {
          if (state is GliderPolarIsWorkingState);
        }, buildWhen: (previous, current) {
      return current is GliderPolarIsWorkingState;
    }, builder: (context, state) {
      return (state is GliderPolarIsWorkingState && state.isWorking)
          ? CommonWidgets.buildLoading()
          : SizedBox.shrink();
    });
  }

  Widget _getErrorMessagesWidget() {
    return BlocListener<GliderPolarCubit, PolarDataState>(
      listener: (context, state) {
        if (state is GliderPolarErrorState) {
          CommonWidgets.showErrorDialog(context, 'Polar Error', state.errorMsg);
        }
      },
      child: SizedBox.shrink(),
    );
  }
}
