import 'dart:async';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/cubit/glider_cubit.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/cubit/polar_state.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/gliders.dart';

class GliderPolarListScreen extends StatefulWidget {
  GliderPolarListScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<GliderPolarListScreen> createState() => _GliderPolarListScreenState();
}

class _GliderPolarListScreenState extends State<GliderPolarListScreen>
    with AfterLayoutMixin<GliderPolarListScreen> {
  String? _selectedGlider = null;
  List<String> gliders = [];
  Glider? _defaultGlider;
  Glider? _customGlider;
  String _velocityUnits = "";
  String _sinkRateUnits = "";
  String _massUnits = "";
  DisplayUnits? _displayUnits;

  // Menu options
  static const String UNITS = "Units";
  static const String RESET_TO_DEFAULT = "Reset To Default";
  static const String REGEX_TO_999 = "^([0-9]{0,3})\$";
  static const String REGEX_TO_999_9 = "^([0-9]{0,3})((\.[0-9])?)\$";
  static const String REGEX_TO_999_99 = "^([0-9]{0,3})((\.[0-9]{1,2})?)\$";
  static const String REGEX_TO_9999_9 = "^([0-9]{0,4})((\.[0-9])?)\$";
  static const String REGEX_0_TO_60 = "^(([1-5][0-9])|(60))\$";
  static const String NUMBER_TO_999_9 = "Number between 0 and 999.9";
  static const String NUMBER_TO_9999_9 = "Number between 0 and 9999.9";
  static const String ENTER_VELOCITY = "Enter velocity";
  static const String REGEX_MINUS_999_99_TO_0 =
      "^(-[0-9]{0,3})((\.[0-9]{0,2})?)\$";
  static const String SINKRATE_TO_MINUS_999_99 =
      "Negative number between 999.99 and 0.00";
  static const String ENTER_SINKRATE = "Sink rate (always negative number)";
  static const String NUMBER_TO_999 = "Positive number 0 to 999.";

  static const String BANK_ANGLE_10_TO_60 = "Bank Angle - 10 to 60 degrees";
  static const String ENTER_BANK_ANGLE = "Favorite Thermalling Bank Angle";

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {
    _getGliderCubit().getListOfGliders();
  }

  @override
  Widget build(BuildContext context) {
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
        bottomNavigationBar: SafeArea(
          child: BottomAppBar(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity,
                          40), // double.infinity is the width and 30 is the height
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(StandardLiterals.OK),
                    onPressed: () {
                      _getGliderCubit().calcOptimalTaskTime();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity,
                          40), // double.infinity is the width and 30 is the height
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(StandardLiterals.CANCEL),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _getAppBar(BuildContext context) {
    return AppBar(
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(PolarLiterals.POLAR),
        actions: _getMenu());
  }

  List<Widget> _getMenu() {
    return <Widget>[
      PopupMenuButton<String>(
          onSelected: _handleClick,
          icon: Icon(Icons.more_vert),
          itemBuilder: (BuildContext context) {
            return {
              UNITS,
              RESET_TO_DEFAULT,
            }.map((String choice) {
              if (choice == UNITS) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: _getUnitsPopUpMenu(),
                );
              }
              ;
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          }),
    ];
  }

  Widget _getUnitsPopUpMenu() {
    return PopupMenuButton<DisplayUnits>(
        initialValue: _displayUnits,
        offset: Offset(-30, 25),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              UNITS,
            ),
            Spacer(),
            Icon(Icons.arrow_right, size: 20.0, color: Colors.black),
          ],
        ),
        onSelected: _handleDisplayUnitsClick,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<DisplayUnits>>[
              PopupMenuItem<DisplayUnits>(
                  value: DisplayUnits.Metric,
                  child: Text(DisplayUnits.Metric.name)),
              PopupMenuItem<DisplayUnits>(
                  value: DisplayUnits.American,
                  child: Text(DisplayUnits.American.name)),
            ]);
  }

  void _handleClick(String value) async {
    switch (value) {
      case RESET_TO_DEFAULT:
        resetGliderToDefaultValues();
    }
  }

  void _handleDisplayUnitsClick(DisplayUnits? displayUnits) {
    if (displayUnits is DisplayUnits) {
      if (this._displayUnits != displayUnits) {
        _getGliderCubit().saveDisplayUnits(displayUnits, _customGlider!);
      }
    }
    Navigator.pop(context);
  }

  Widget _getBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _getGliderList(),
          _displayGliderDetail(),
          _getIsWorkingIndicator(),
          _getErrorMessagesWidget()
        ],
      ),
    );
  }

  Widget _getGliderList() {
    return BlocConsumer<GliderCubit, GliderState>(listener: (context, state) {
      if (state is GliderListState) {
        _selectedGlider =
            state.selectedGlider.isNotEmpty ? state.selectedGlider : null;
      }
    }, buildWhen: (previous, current) {
      return current is GliderListState;
    }, builder: (context, state) {
      if (state is GliderListState) {
        if (state.gliderList.length == 0) {
          // WidgetsBinding.instance?.addPostFrameCallback(
          //     (_) => _showNoTasksFoundDialog(context));
          return Container(
            child: Center(
              child: Text(
                "No Polars Found",
                style: textStyleBoldBlackFontSize24,
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else {
          return _getGliderListView(state);
        }
      }
      return SizedBox.shrink();
    });
  }

  Widget _getGliderListView(GliderListState state) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _formattedTextCell("Glider:"),
          ),
          _getGliderDropdownButton(state),
        ],
      ),
    );
  }

  Widget _getGliderDropdownButton(GliderListState state) {
    return Expanded(
      child: DropdownButton<String>(
        isExpanded: true,
        style: textStyleBoldBlackFontSize18,
        value: _selectedGlider,
        hint: _formattedTextCell("Select Glider"),
        icon: const Icon(Icons.arrow_drop_down),
        elevation: 16,
        underline: Container(
          height: 2,
          color: Colors.black,
        ),
        onChanged: (String? value) {
          // This is called when the user selects an item.
          setState(
            () {
              _selectedGlider = value!;
              _getGliderCubit().getGliderPolar(_selectedGlider!);
            },
          );
        },
        items: state.gliderList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: _formattedTextCell(value),
          );
        }).toList(),
      ),
    );
  }

  GliderCubit _getGliderCubit() => BlocProvider.of<GliderCubit>(context);

  Widget _displayGliderDetail() {
    return BlocConsumer<GliderCubit, GliderState>(listener: (context, state) {
      if (state is GliderPolarState) {
        _defaultGlider = state.defaultPolar;
        _customGlider = state.customPolar;
        _displayUnits = state.displayUnits;
        _velocityUnits = "(" + state.velocityUnits + ")";
        _sinkRateUnits = " (" + state.sinkRateUnits + ")";
        _massUnits = " (" + state.massUnits + ")";
      }
    }, buildWhen: (previous, current) {
      return current is GliderPolarState;
    }, builder: (context, state) {
      if (state is GliderPolarState) {
        return (_customGlider == null)
            ? SizedBox.shrink()
            : _getGliderDetailsWidget(); //_getHorizontalPolarDisplay();
      }
      ;
      return SizedBox.shrink();
    });
  }

  Widget _getGliderDetailsWidget() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          Text(_customGlider!.glider + " Glider Sink Rate",
              style: textStyleBoldBlackFontSize18, textAlign: TextAlign.center),
          _getThermallingValues(),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text("Glider Mass (1)",
                style: textStyleBoldBlackFontSize18,
                textAlign: TextAlign.center),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _getGliderWeightDisplay(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(_customGlider!.glider + " Speed vs Sink Rate (2))",
                style: textStyleBoldBlackFontSize18,
                textAlign: TextAlign.center),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _getPolarTable(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
                "*NOTES:\n(1) If you just adjust your glider weight, the optimal task calculation will use adjusted polar speeds with respect to XCSoar values. " +
                    "\n(2) If your polar V/W values are modified, the task calculation will assume those values were measured at youyr current glider + pilot (ballast ignored) values ",
                softWrap: true,
                style: textStyleBoldBlackFontSize18,
                textAlign: TextAlign.left),
          ),
        ]),
      ),
    );
  }

  Widget _getThermallingValues() {
    return Table(
        border: TableBorder.all(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: <TableRow>[
          TableRow(
            children: [
              _formattedTextCell("Thermalling"),
              Text(""),
              Text(""),
            ],
          ),
          TableRow(children: [
            _formattedTextCell("Min Sink Rate " + _sinkRateUnits),
            InkWell(
              child: _formattedTextCell(
                  _customGlider!.minSinkRate.toStringAsFixed(2)),
              onTap: (() {
                _updateGliderValueDialog(
                    label: "Min Sink Rate " + _sinkRateUnits,
                    regexValidation: REGEX_MINUS_999_99_TO_0,
                    value: _customGlider!.minSinkRate.toStringAsFixed(2),
                    updateFunction: ((String value) {
                      double doubleValue = _convertToDouble(value);
                      if (doubleValue != _customGlider?.minSinkRate) {
                        setState(() {
                          _customGlider?.minSinkRate = doubleValue;
                          _customGlider?.calcThermallingSinkRate();
                        });
                      }
                    }),
                    validationErrorMsg: SINKRATE_TO_MINUS_999_99,
                    hintText: ENTER_SINKRATE);
              }),
            ),
            _formattedTextCell(_defaultGlider!.minSinkRate.toStringAsFixed(2)),
          ]),
          TableRow(children: [
            _formattedTextCell("Min Sink Speed " + _velocityUnits),
            InkWell(
              child: _formattedTextCell(
                  _customGlider!.minSinkSpeed.toStringAsFixed(0)),
              onTap: (() {
                _updateGliderValueDialog(
                    label: "Min Sink Speed " + _velocityUnits,
                    regexValidation: REGEX_TO_999,
                    value: _customGlider!.minSinkSpeed.toStringAsFixed(0),
                    updateFunction: ((String value) {
                      double doubleValue = _convertToDouble(value);
                      if (doubleValue != _customGlider?.minSinkRate) {
                        setState(() {
                          _customGlider?.minSinkSpeed = doubleValue;
                          _customGlider?.calcThermallingSinkRate();
                        });
                      }
                    }),
                    validationErrorMsg: NUMBER_TO_999,
                    hintText: ENTER_VELOCITY);
              }),
            ),
            _formattedTextCell(_defaultGlider!.minSinkSpeed.toStringAsFixed(0)),
          ]),
          TableRow(
            children: [
              _formattedTextCell("Thermal Bank Angle"),
              InkWell(
                child: _formattedTextCell(
                    _customGlider!.bankAngle.toStringAsFixed(0)),
                onTap: (() {
                  _updateGliderValueDialog(
                      label: "Thermal Bank Angle ",
                      regexValidation: REGEX_0_TO_60,
                      value: _customGlider!.bankAngle.toStringAsFixed(0),
                      updateFunction: ((String value) {
                        int intValue = _convertToInt(value);
                        if (intValue != _customGlider?.bankAngle) {
                          setState(() {
                            _customGlider?.bankAngle = intValue;
                            _customGlider?.calcThermallingSinkRate();
                          });
                        }
                      }),
                      validationErrorMsg: BANK_ANGLE_10_TO_60,
                      hintText: ENTER_BANK_ANGLE);
                }),
              ),
              _formattedTextCell(_defaultGlider!.bankAngle.toStringAsFixed(0)),
            ],
          ),
          TableRow(
            children: [
              _formattedTextCell("Thermalling Sink Rate" + _sinkRateUnits),
              _formattedTextCell(
                  _customGlider!.thermallingSinkRate.toStringAsFixed(1)),
              _formattedTextCell(""),
            ],
          ),
        ]);
  }

  Widget _getPolarTable() {
    return Table(
      border: TableBorder.all(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: <TableRow>[
        TableRow(
          children: [
            _formattedTextCell("Polar Values"),
            Text(""),
            Text(""),
          ],
        ),
        TableRow(
          children: [
            _formattedTextCell("V1 " + _velocityUnits),
            InkWell(
              child: _formattedTextCell(_customGlider!.v1.toStringAsFixed(1)),
              onTap: (() {
                _updateGliderValueDialog(
                    label: "V1 " + _velocityUnits,
                    regexValidation: REGEX_TO_999_9,
                    value: _customGlider!.v1.toStringAsFixed(1),
                    updateFunction: ((String value) {
                      double doubleValue = _convertToDouble(value);
                      if (doubleValue != _customGlider?.v1) {
                        setState(() {
                          _customGlider?.updatedVW = true;
                          _customGlider?.v1 = doubleValue;
                        });
                      }
                    }),
                    validationErrorMsg: NUMBER_TO_999_9,
                    hintText: ENTER_VELOCITY);
              }),
            ),
            _formattedTextCell(_defaultGlider!.v1.toStringAsFixed(1)),
          ],
        ),
        TableRow(children: [
          _formattedTextCell("W1 " + _sinkRateUnits),
          InkWell(
            child: _formattedTextCell(_customGlider!.w1.toStringAsFixed(2)),
            onTap: (() {
              _updateGliderValueDialog(
                  label: "W1 " + _sinkRateUnits,
                  regexValidation: REGEX_MINUS_999_99_TO_0,
                  value: _customGlider!.w1.toStringAsFixed(2),
                  updateFunction: ((String value) {
                    double doubleValue = _convertToDouble(value);
                    if (doubleValue != _customGlider?.w1) {
                      setState(() {
                        _customGlider?.updatedVW = true;
                        _customGlider?.w1 = doubleValue;
                      });
                    }
                  }),
                  validationErrorMsg: SINKRATE_TO_MINUS_999_99,
                  hintText: ENTER_SINKRATE);
            }),
          ),
          _formattedTextCell(_defaultGlider!.w1.toStringAsFixed(2)),
        ]),
        TableRow(
          children: [
            _formattedTextCell("V2 " + _velocityUnits),
            InkWell(
              child: _formattedTextCell(_customGlider!.v2.toStringAsFixed(1)),
              onTap: (() {
                _updateGliderValueDialog(
                    label: "V2 " + _velocityUnits,
                    regexValidation: REGEX_TO_999_9,
                    value: _customGlider!.v2.toStringAsFixed(1),
                    updateFunction: ((String value) {
                      double doubleValue = _convertToDouble(value);
                      if (doubleValue != _customGlider?.v2) {
                        setState(() {
                          _customGlider?.updatedVW = true;
                          _customGlider?.v2 = doubleValue;
                        });
                      }
                    }),
                    validationErrorMsg: NUMBER_TO_999_9,
                    hintText: ENTER_VELOCITY);
              }),
            ),
            _formattedTextCell(_defaultGlider!.v2.toStringAsFixed(1)),
          ],
        ),
        TableRow(
          children: [
            _formattedTextCell("W2 " + _sinkRateUnits),
            InkWell(
              child: _formattedTextCell(_customGlider!.w2.toStringAsFixed(2)),
              onTap: (() {
                _updateGliderValueDialog(
                    label: "W2 " + _sinkRateUnits,
                    regexValidation: REGEX_MINUS_999_99_TO_0,
                    value: _customGlider!.w2.toStringAsFixed(2),
                    updateFunction: ((String value) {
                      double doubleValue = _convertToDouble(value);
                      if (doubleValue != _customGlider?.w2) {
                        setState(() {
                          _customGlider?.updatedVW = true;
                          _customGlider?.w2 = doubleValue;
                        });
                      }
                    }),
                    validationErrorMsg: SINKRATE_TO_MINUS_999_99,
                    hintText: ENTER_SINKRATE);
              }),
            ),
            _formattedTextCell(_defaultGlider!.w2.toStringAsFixed(2)),
          ],
        ),
        TableRow(
          children: [
            _formattedTextCell("V3 " + _velocityUnits),
            InkWell(
              child: _formattedTextCell(_customGlider!.v3.toStringAsFixed(1)),
              onTap: (() {
                _updateGliderValueDialog(
                    label: "V3 " + _velocityUnits,
                    regexValidation: REGEX_TO_999_9,
                    value: _customGlider!.v3.toStringAsFixed(1),
                    updateFunction: ((String value) {
                      double doubleValue = _convertToDouble(value);
                      if (doubleValue != _customGlider?.v3) {
                        setState(() {
                          _customGlider?.updatedVW = true;
                          _customGlider?.v3 = doubleValue;
                        });
                      }
                    }),
                    validationErrorMsg: NUMBER_TO_999_9,
                    hintText: ENTER_VELOCITY);
              }),
            ),
            _formattedTextCell(_defaultGlider!.v3.toStringAsFixed(1)),
          ],
        ),
        TableRow(
          children: [
            _formattedTextCell("W3 " + _sinkRateUnits),
            InkWell(
              child: _formattedTextCell(_customGlider!.w3.toStringAsFixed(2)),
              onTap: (() {
                _updateGliderValueDialog(
                    label: "W3 " + _sinkRateUnits,
                    regexValidation: REGEX_MINUS_999_99_TO_0,
                    value: _customGlider!.w3.toStringAsFixed(2),
                    updateFunction: ((String value) {
                      double doubleValue = _convertToDouble(value);
                      if (doubleValue != _customGlider?.w3) {
                        setState(() {
                          _customGlider?.updatedVW = true;
                          _customGlider?.w3 = doubleValue;
                        });
                      }
                    }),
                    validationErrorMsg: SINKRATE_TO_MINUS_999_99,
                    hintText: ENTER_SINKRATE);
              }),
            ),
            _formattedTextCell(_defaultGlider!.w3.toStringAsFixed(2)),
          ],
        ),
      ],
    );
  }

  Table _getGliderWeightDisplay() {
    String massLabel = "(" + _massUnits + ")";
    return Table(
      border: TableBorder.all(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: <TableRow>[
        TableRow(children: [
          _formattedTextCell(""),
          _formattedTextCell('Your\nGlider'),
          _formattedTextCell('XCSoar\nValues'),
        ]),
        TableRow(
          children: [
            _formattedTextCell("Glider Mass " + massLabel),
            InkWell(
              child: _formattedTextCell(
                  _customGlider!.gliderEmptyMass.toStringAsFixed(1)),
              onTap: (() {
                _updateGliderValueDialog(
                    label: "Glider Mass " + massLabel,
                    regexValidation: REGEX_TO_9999_9,
                    value: _customGlider!.gliderEmptyMass.toStringAsFixed(1),
                    updateFunction: ((String value) {
                      double doubleValue = _convertToDouble(value);
                      if (doubleValue != _customGlider!.gliderEmptyMass) {
                        setState(() {
                          _customGlider!.gliderEmptyMass = doubleValue;
                        });
                      }
                    }),
                    validationErrorMsg: NUMBER_TO_9999_9,
                    hintText: "Enter glider empty mass.");
              }),
            ),
            _formattedTextCell(
                _defaultGlider!.gliderEmptyMass.toStringAsFixed(1)),
          ],
        ),
        TableRow(
          children: [
            _formattedTextCell("Pilot Mass " + massLabel),
            InkWell(
              child: _formattedTextCell(
                  _customGlider!.pilotMass.toStringAsFixed(1)),
              onTap: (() {
                _updateGliderValueDialog(
                    label: "Pilot Mass " + massLabel,
                    regexValidation: REGEX_TO_999_9,
                    value: _customGlider!.pilotMass.toStringAsFixed(1),
                    updateFunction: ((String value) {
                      double doubleValue = _convertToDouble(value);
                      if (doubleValue != _customGlider!.pilotMass) {
                        setState(() {
                          _customGlider!.pilotMass = doubleValue;
                        });
                      }
                    }),
                    validationErrorMsg: NUMBER_TO_999_9,
                    hintText: "Enter pilot mass.");
              }),
            ),
            _formattedTextCell(_defaultGlider!.pilotMass.toStringAsFixed(1)),
          ],
        ),
        TableRow(
          children: [
            _formattedTextCell(" Max Ballast " + massLabel),
            _formattedTextCell(_customGlider!.maxBallast.toStringAsFixed(1)),
            _formattedTextCell(_defaultGlider!.maxBallast.toStringAsFixed(1)),
          ],
        ),
        TableRow(
          children: [
            _formattedTextCell("On Board Ballast" + massLabel),
            InkWell(
              child: _formattedTextCell(
                  _customGlider!.loadedBallast.toStringAsFixed(1)),
              onTap: (() {
                _updateGliderValueDialog(
                    label: "On Board Ballast " + massLabel,
                    regexValidation: REGEX_TO_999_9,
                    value: _customGlider!.loadedBallast.toStringAsFixed(1),
                    updateFunction: ((String value) {
                      double doubleValue = _convertToDouble(value);
                      if (doubleValue != _customGlider!.loadedBallast) {
                        setState(() {
                          _customGlider!.loadedBallast = doubleValue;
                        });
                      }
                    }),
                    validationErrorMsg: NUMBER_TO_999_9,
                    hintText: "Enter loaded ballast.");
              }),
            ),
            _formattedTextCell(_defaultGlider!.loadedBallast.toStringAsFixed(1)),
          ],
        ),
        TableRow(
          children: [
            _formattedTextCell("Glider + \nPilot + \nBallast" + massLabel),
            _formattedTextCell((_customGlider!.gliderEmptyMass +
                    _customGlider!.pilotMass +
                    _customGlider!.loadedBallast)
                .toStringAsFixed(1)),
            _formattedTextCell((_defaultGlider!.gliderAndMaxPilotWgt +
                    _defaultGlider!.loadedBallast)
                .toStringAsFixed(1)),
          ],
        ),
      ],
    );
  }

  Widget _formattedTextCell(String? text) {
    return Text(text ?? "",
        style: textStyleBoldBlackFontSize18, textAlign: TextAlign.center);
  }

  Widget _getIsWorkingIndicator() {
    return BlocConsumer<GliderCubit, GliderState>(listener: (context, state) {
      if (state is GliderPolarIsWorkingState) ;
    }, buildWhen: (previous, current) {
      return current is GliderPolarIsWorkingState;
    }, builder: (context, state) {
      return (state is GliderPolarIsWorkingState && state.isWorking)
          ? CommonWidgets.buildLoading()
          : SizedBox.shrink();
    });
  }

  Widget _getErrorMessagesWidget() {
    return BlocListener<GliderCubit, GliderState>(
      listener: (context, state) {
        if (state is GliderPolarErrorState) {
          CommonWidgets.showErrorDialog(context, 'Polar Error', state.errorMsg);
        }
      },
      child: SizedBox.shrink(),
    );
  }

  void _updateGliderValueDialog(
      {required String label,
      required String regexValidation,
      required String value,
      required Function updateFunction,
      required String validationErrorMsg,
      required String hintText}) {
    var formKey = GlobalKey<FormFieldState>();
    RegExp validationRegex = RegExp(regexValidation);
    String? validValue;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(label),
          content: TextFormField(
            key: formKey,
            initialValue: value,
            enabled: true,
            decoration: InputDecoration(
                hintText: hintText,
                hintMaxLines: 2,
                errorText: validationErrorMsg),
            // style: textStyleBoldBlackFontSize18,
            keyboardType: TextInputType.number,
            validator: (inputValue) {
              if (inputValue == null ||
                  inputValue.isEmpty ||
                  !validationRegex.hasMatch(inputValue)) {
                return validationErrorMsg;
              }
              validValue = inputValue;
              return null;
            },
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () {
                try {
                  if (formKey.currentState!.validate()) {
                    updateFunction(validValue!);
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  print(e.toString());
                  debugPrint(e.toString());
                }
              },
            ),
          ],
        );
      },
    );
  }

  void resetGliderToDefaultValues() {
    _customGlider = _defaultGlider!;
  }

  // Value must be proper numeric
  // Dart throws error if you try to convert an integer text string to double
  // so need to see if value contains a '.', else value is an int
  double _convertToDouble(String value) {
    try {
      return value.contains(".")
          ? double.parse(value)
          : int.parse(value).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  // Value must be proper text numeric value
  int _convertToInt(String value) {
    try {
      return value.contains(".")
          ? double.parse(value).toInt()
          : int.parse(value);
    } catch (e) {
      return 0;
    }
  }
}
