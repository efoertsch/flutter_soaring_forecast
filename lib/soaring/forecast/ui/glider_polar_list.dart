import 'dart:async';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/cubit/glider_cubit.dart';
import 'package:flutter_soaring_forecast/soaring/forecast/cubit/glider_state.dart';
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
  static const String _UNITS = "Units";
  static const String _RESET_TO_DEFAULT = "Reset To Default";
  static const String _DISPLAY_EXPERIMENTAL_TEXT = "Experimental Disclaimer";
  static const String _REGEX_TO_999 = "^([0-9]{0,3})\$";
  static const String _REGEX_TO_999_9 = "^([0-9]{0,3})((\.[0-9])?)\$";
  static const String _REGEX_TO_999_99 = "^([0-9]{0,3})((\.[0-9]{1,2})?)\$";
  static const String _REGEX_TO_9999_9 = "^([0-9]{0,4})((\.[0-9])?)\$";
  static const String _REGEX_0_TO_60 = "^(([1-5][0-9])|(60))\$";
  static const String _NUMBER_TO_999_9 = "Number between 0 and 999.9";
  static const String _NUMBER_TO_9999_9 = "Number between 0 and 9999.9";
  static const String _ENTER_VELOCITY = "Enter velocity";
  static const String _REGEX_MINUS_999_99_TO_0 =
      "^(-[0-9]{0,3})((\.[0-9]{0,2})?)\$";
  static const String _SINKRATE_TO_MINUS_999_99 =
      "Negative number between 999.99 and 0.00";
  static const String _ENTER_SINKRATE = "Sink rate (always negative number)";
  static const String _ENTER_MIN_SINKRATE = "Sink rate (as positive number)";
  static const String _NUMBER_TO_999 = "Positive number 0 to 999.";
  static const String _NUMBER_TO_999_99 = "Positive number 0 to 999.99";

  static const String _BANK_ANGLE_10_TO_60 = "Bank Angle - 10 to 60 degrees";
  static const String _ENTER_BANK_ANGLE = "Favorite Thermalling Bank Angle";
  static const String _POLAR_HELP = "HELP";
  static const String _EXPERIMENTAL_ESTIMATED_FLIGHT_TEXT =
      " This is a feature based on Dr. Jack logic uses a glider's min sink and polar, and along"
      " with the forecast, will show for the given task estimated flight time "
      " and associated flight information."
      "\nThe specific forecast values used in the calculations are:"
      "\n1. Thermal Updraft Velocity (W*)"
      "\n2. Wind speed (Boundary Layer average)"
      "\n3. Wind direction (Boundary Layer average)"
      "\nThe values displayed on the underlying screen are based or calculated from XCSOAR glider data."
      "\nNote that the min sink rate is calculated based on Vx/Wx values which is not the best method to determine "
      "your glider min sink. Consult your glider POH or other sources to enter a more appropriate number."
      "\nMost values under the 'Your Glider' column can be updated. Tap on the particular cell to update."
      "\n\nFeedback is most welcome. ";
  static const String _GLIDER_POLAR_DATA =
      "The sink rate, glider mass and polar values (Vx/Wx) on this screen are "
      "used to determine your gliders estimated climb rate in a thermal and wind adjusted speed to fly. \n"
      "These values are in turn used to calculate an estimated task time for each leg of your task. \n"
      "The default values are set based on XCSOAR values. \n"
      "However your gliders min sink rate, calculated from the polar Vx/Wx values (per Reichmann) "
      " is probably not a good value and should be updated from other sources (such as your glider's POH).\n"
      "You can modify most values under the 'Your Glider' column to provide a better calculated task time.\n"
      "Toggle between metric and American units or reset you glider values back to "
      "the XCSOAR values using the top right menu dropdown";
  static const String _SINK_RATE_INFO =
      "The min. sink rate and speed are initially derived "
      "from the XCSOAR polar Vx/Wx values below but likely they will not give the best estimates."
      " Perhaps better values can be obtained from you glider POH and entered here. "
      "Enter values for your glider + pilot weight. The sink rate will be adjusted should you add ballast. "
      "(Note the adjustment will be made when used in the flight calculations. It isn't show on this screen)"
      " Updating the values should lead to a better estimate of your gliders thermalling sink rate.\n"
      "The thermalling sink rate (based on your bank angle) is used to estimate your actual climb rate in the forcasted thermals. ";
  static const String _GLIDER_MASS_INFO =
      "Glider mass may be used to adjust the polar based on your Vx/Wx values below. "
      "The adjustments that can be made are: \n"
      "1) If you only change your glider, pilot or ballast mass, the glider polar is adjusted by the sq root(your mass/XCSoar reference mass)\n "
      "2) If you update your glider Vx/Wx values then it is assumed you measured your Vx/Wx values at your (glider + pilot) mass."
      " So a polar adjustment is only made if you add ballast, i.e. the polar is adjusted by sq root((glider + pilot + ballast)/(glider + pilot)).";
  static const String _GLIDER_POLAR_INFO =
      "If your Vx/Wx values are modified,"
      " your polar will be calculated based on your glider's glider + pilot mass. No change will be made to your min sink values.";

  bool _showExperimentalDialog = false;

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
              mainAxisSize: MainAxisSize.max,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 40),
                        // double.infinity is the width and 30 is the height
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(StandardLiterals.OK),
                      onPressed: () {
                        _getGliderCubit().calcEstimatedTaskTime(_customGlider!);
                        //Navigator.pop(context, polar);
                      },
                    ),
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 40),
                        // double.infinity is the width and 30 is the height
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(StandardLiterals.CANCEL),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
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
      TextButton(
        child: const Text(_POLAR_HELP, style: TextStyle(color: Colors.white)),
        onPressed: () {
          CommonWidgets.showInfoDialog(
              context: context,
              title: "Glider Polar",
              msg: _GLIDER_POLAR_DATA,
              button1Text: StandardLiterals.OK,
              button1Function: (() => Navigator.of(context).pop()));
        },
      ),
      PopupMenuButton<String>(
          onSelected: _handleClick,
          icon: Icon(Icons.more_vert),
          itemBuilder: (BuildContext context) {
            return {
              _UNITS,
              _RESET_TO_DEFAULT,
              _DISPLAY_EXPERIMENTAL_TEXT,
            }.map((String choice) {
              if (choice == _UNITS) {
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
              _UNITS,
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
      case _RESET_TO_DEFAULT:
        resetGliderToDefaultValues();
        break;
      case _DISPLAY_EXPERIMENTAL_TEXT:
        resetDisplayExperimentalText();
        break;
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
          _getErrorMessagesWidget(),
          _getMiscStatesHandlerWidget(),
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
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_customGlider!.glider + " Glider Sink Rate",
                    style: textStyleBoldBlackFontSize18,
                    textAlign: TextAlign.center),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    icon: Icon(
                      Icons.info,
                      color: Colors.blueAccent,
                    ),
                    onPressed: () {
                      CommonWidgets.showInfoDialog(
                        context: context,
                        title: "Sink Rate",
                        msg: _SINK_RATE_INFO,
                        button1Text: StandardLiterals.OK,
                        button1Function: (() => Navigator.of(context).pop()),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
          _getThermallingValues(),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Glider Mass",
                      style: textStyleBoldBlackFontSize18,
                      textAlign: TextAlign.center),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.info,
                        color: Colors.blueAccent,
                      ),
                      onPressed: () {
                        CommonWidgets.showInfoDialog(
                          context: context,
                          title: "Glider Mass",
                          msg: _GLIDER_MASS_INFO,
                          button1Text: StandardLiterals.OK,
                          button1Function: (() => Navigator.of(context).pop()),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
          _getGliderWeightDisplay(),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Speed vs Sink Rate",
                      style: textStyleBoldBlackFontSize18,
                      textAlign: TextAlign.center),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.info,
                        color: Colors.blueAccent,
                      ),
                      onPressed: () {
                        CommonWidgets.showInfoDialog(
                          context: context,
                          title: "Glider Polar",
                          msg: _GLIDER_POLAR_INFO,
                          button1Text: StandardLiterals.OK,
                          button1Function: (() => Navigator.of(context).pop()),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _getPolarTable(),
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
              _formattedTextCell('Your\nGlider'),
              _formattedTextCell('XCSoar\nValues'),
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
                    regexValidation: _REGEX_TO_999_99,
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
                    validationErrorMsg: _NUMBER_TO_999_99,
                    hintText: _ENTER_MIN_SINKRATE);
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
                    regexValidation: _REGEX_TO_999,
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
                    validationErrorMsg: _NUMBER_TO_999,
                    hintText: _ENTER_VELOCITY);
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
                      regexValidation: _REGEX_0_TO_60,
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
                      validationErrorMsg: _BANK_ANGLE_10_TO_60,
                      hintText: _ENTER_BANK_ANGLE);
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
              _formattedTextCell(
                  _defaultGlider!.thermallingSinkRate.toStringAsFixed(1)),
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
            _formattedTextCell('Your\nGlider'),
            _formattedTextCell('XCSoar\nValues'),
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
                    regexValidation: _REGEX_TO_999_9,
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
                    validationErrorMsg: _NUMBER_TO_999_9,
                    hintText: _ENTER_VELOCITY);
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
                  regexValidation: _REGEX_MINUS_999_99_TO_0,
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
                  validationErrorMsg: _SINKRATE_TO_MINUS_999_99,
                  hintText: _ENTER_SINKRATE);
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
                    regexValidation: _REGEX_TO_999_9,
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
                    validationErrorMsg: _NUMBER_TO_999_9,
                    hintText: _ENTER_VELOCITY);
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
                    regexValidation: _REGEX_MINUS_999_99_TO_0,
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
                    validationErrorMsg: _SINKRATE_TO_MINUS_999_99,
                    hintText: _ENTER_SINKRATE);
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
                    regexValidation: _REGEX_TO_999_9,
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
                    validationErrorMsg: _NUMBER_TO_999_9,
                    hintText: _ENTER_VELOCITY);
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
                    regexValidation: _REGEX_MINUS_999_99_TO_0,
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
                    validationErrorMsg: _SINKRATE_TO_MINUS_999_99,
                    hintText: _ENTER_SINKRATE);
              }),
            ),
            _formattedTextCell(_defaultGlider!.w3.toStringAsFixed(2)),
          ],
        ),
      ],
    );
  }

  Table _getGliderWeightDisplay() {
    String massLabel =   _massUnits ;
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
                    regexValidation: _REGEX_TO_9999_9,
                    value: _customGlider!.gliderEmptyMass.toStringAsFixed(1),
                    updateFunction: ((String value) {
                      double doubleValue = _convertToDouble(value);
                      if (doubleValue != _customGlider!.gliderEmptyMass) {
                        setState(() {
                          _customGlider!.gliderEmptyMass = doubleValue;
                        });
                      }
                    }),
                    validationErrorMsg: _NUMBER_TO_9999_9,
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
                    regexValidation: _REGEX_TO_999_9,
                    value: _customGlider!.pilotMass.toStringAsFixed(1),
                    updateFunction: ((String value) {
                      double doubleValue = _convertToDouble(value);
                      if (doubleValue != _customGlider!.pilotMass) {
                        setState(() {
                          _customGlider!.pilotMass = doubleValue;
                        });
                      }
                    }),
                    validationErrorMsg: _NUMBER_TO_999_9,
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
                    regexValidation: _REGEX_TO_999_9,
                    value: _customGlider!.loadedBallast.toStringAsFixed(1),
                    updateFunction: ((String value) {
                      double doubleValue = _convertToDouble(value);
                      if (doubleValue != _customGlider!.loadedBallast) {
                        setState(() {
                          _customGlider!.loadedBallast = doubleValue;
                          _customGlider!.calcThermallingSinkRate();
                        });
                      }
                    }),
                    validationErrorMsg: _NUMBER_TO_999_9,
                    hintText: "Enter loaded ballast.");
              }),
            ),
            _formattedTextCell(
                _defaultGlider!.loadedBallast.toStringAsFixed(1)),
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

  Widget _getMiscStatesHandlerWidget() {
    return BlocListener<GliderCubit, GliderState>(
      listener: (context, state) {
        if (state is CalcEstimatedFlightState) {
          Navigator.pop(context, state.glider);
        }
        if (state is DisplayEstimatedFlightText) {
          _displayEstimatedFlightText();
        }
      },
      child: SizedBox.shrink(),
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
      barrierDismissible: false,
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
    setState(() {
      _customGlider = _defaultGlider!.copyWith();
    });
  }

  void resetDisplayExperimentalText() async {
    _getGliderCubit().resetExperimentalTextDisplay();
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

  void _displayEstimatedFlightText() async {
    _showExperimentalDialog = true;
    CommonWidgets.showTextAndCheckboxDialogBuilder(
      context: context,
      title: "TASK FLIGHT ESTIMATES\n(EXPERIMENTAL)",
      child: _getExperimentalFlightTextWidget(),
      button1Text: StandardLiterals.OK,
      button1Function: (() => Navigator.pop(context)),
    );
  }

  Widget _getExperimentalFlightTextWidget() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top:4.0, bottom:8.0),
            child: Text(_EXPERIMENTAL_ESTIMATED_FLIGHT_TEXT),
          ),
          StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
            return CheckboxListTile(
              title: Text("Do not show this again"),
              controlAffinity: ListTileControlAffinity.leading,
              value: !_showExperimentalDialog,
              onChanged: (newValue) async {
                _showExperimentalDialog = newValue != null ? !newValue : true;
                await _getGliderCubit()
                    .displayExperimentalText(_showExperimentalDialog);
                setState(() {
                  // if checked then DO NOT display experimental text, hence save as false
                });
              },
            );
          })
        ],
      ),
    );
  }
}
