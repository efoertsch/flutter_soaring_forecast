import 'dart:async';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/gliders.dart';

import '../bloc/glider_cubit.dart';
import '../bloc/glider_state.dart';
import '../glider_enums.dart';

class GliderPolarListScreen extends StatefulWidget {
  GliderPolarListScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<GliderPolarListScreen> createState() => _GliderPolarListScreenState();
}

class _GliderPolarListScreenState extends State<GliderPolarListScreen> {
  String? _selectedGlider = null;
  List<String> gliders = [];
  late Glider _defaultGliderLocalUnits;
  late Glider? _customGliderLocalUnits = null;
  late DisplayUnits _displayUnits = DisplayUnits.Imperial_kts;
  String _velocityUnits = "";
  String _sinkRateUnits = "";
  String _massUnits = "";
  String _distanceUnits = "";

  // Menu options
  static const String _DISPLAY_UNITS = "Display Units";
  static const String _DISPLAY_XCSOAR_VALUES = "Display XCSoar Values";
  static const String _HIDE_XCSOAR_VALUES = "Hide XCSoar Values";
  static const String _RESET_TO_DEFAULT = "Reset To Default";
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
  static const String _ENTER_BANK_ANGLE = "Favorite Thermaling Bank Angle";
  static const String _POLAR_HELP = "HELP";

  static const String _GLIDER_POLAR_HELP =
      "The values displayed on the glider polar screen are based on XCSOAR glider data."
      "\n\nHighlighted values under the 'Your Glider' column can be updated. Tap on the particular cell to update the value."
      "\n\nConsult your glider POH or other sources to enter min sink rate and speed values based on your all up glider mass."
      " Also enter your favorite thermaling bank angle."
      "\n\n\The glider mass, sink rate, and Vx/Wx polar values on this screen are "
      "used to determine your gliders estimated climb rate in a thermal and speed to fly. These values are in turn used to calculate an estimated task time for each leg of your task. \n"
      "\nOnly change Vx/Wx values if you have either measured them in your glider or feel you have a better source than XCSoar data."
      "Toggle between metric and American units or reset your glider values back to "
      "the XCSOAR values using the top right menu dropdown";
  static const String _GLIDER_MASS_INFO =
      "Update glider and pilot mass as appropriate, The updated values will be used to adjust the polar based on the Vx/Wx values below. "
      "The adjustments that can be made are:"
      "\n\n1) If you only change your glider, pilot or ballast mass, the glider polar is adjusted by the sq root(your mass/XCSoar reference mass). "
      "\n\n2) If you update your glider Vx/Wx values then it is assumed you measured your Vx/Wx values at your (glider + pilot) mass."
      "\nSo a polar adjustment is only made if you add ballast, i.e. the polar is adjusted by sq root((glider + pilot + ballast)/(glider + pilot)).";
  static const String _SINK_RATE_INFO =
      "\n\nEnter your own min sink values based from your glider POH and your glider + pilot weight entered above."
      "\nThe sink rate will be adjusted should you add ballast. "
      "(Note the adjustment will be made when used in the flight calculations. It isn't show on this screen)"
      "\n\n\Thermaling speed, sink rate, turn diameter, and time for 1 turn are calculated based on your min sink values. "
      "\n\nThe thermaling sink rate (based on your bank angle) is used to estimate your actual climb rate in the forecasted thermals.";

  static const String _GLIDER_POLAR_INFO = "If you modify the Vx/Wx values,"
      " your polar will be calculated based on your glider's glider + pilot mass. No change will be made to your min sink values.";

  static const String YOUR_GLIDER = "Your\nGlider";
  static const String XCSOAR_VALUES = 'XCSoar\nValues';
  static const String GLIDER_MASS = "Glider Mass";
  static const String SINK_RATE = "Sink Rate";
  static const String SPEED_VS_SINK_RATE = "Speed vs Sink Rate";
  static const String GLIDER_POLAR = "Glider Polar";
  static const String THERMALING = "Thermaling";
  static const String MIN_SINK_SPEED = "Min Sink Speed";
  static const String POLAR_VALUES = "Polar Values";
  static const String NOT_APPLICABLE = 'N/A';
  static const String HELP = "HELP";

  bool _displayXCSoarValues = false;
  bool _doNotShowPolarHelp = false;

  // @override
  // FutureOr<void> afterFirstLayout(BuildContext context) async {
  //   await _getGliderCubit().getListOfGliders();
  // }

  GliderCubit _getGliderCubit() => BlocProvider.of<GliderCubit>(context);

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return ConditionalWillPopScope(
        onWillPop: _onWillPop,
        shouldAddCallback: true,
        child: _buildSafeArea(context),
      );
    } else {
      //iOS
      return GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.direction >= 0) {
            _onWillPop();
          }
        },
        child: _buildSafeArea(context),
      );
    }
  }

  SafeArea _buildSafeArea(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: _getAppBar(context),
        body: _getBody(),
        bottomNavigationBar: SafeArea(
          child: _getBottomAppBar(context),
        ),
      ),
    );
  }

  BottomAppBar _getBottomAppBar(BuildContext context) {
    return BottomAppBar(
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
                onPressed: (_selectedGlider == null)
                    ? null
                    : () async {
                        await _getGliderCubit().saveCustomGliderDetails();
                        Navigator.pop(
                            context,
                            _customGliderLocalUnits != null
                                ? _customGliderLocalUnits!.glider
                                : "");
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
                  Navigator.pop(context, "");
                },
              ),
            ),
          ),
        ],
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
          child: const Text(HELP, style: TextStyle(color: Colors.white)),
          onPressed: () {
            _getGliderCubit().showPolarHelp();
          }),
      PopupMenuButton<String>(
          onSelected: _handleClick,
          icon: Icon(Icons.more_vert),
          itemBuilder: (BuildContext context) {
            return {
              _DISPLAY_UNITS,
              _displayXCSoarValues
                  ? _HIDE_XCSOAR_VALUES
                  : _DISPLAY_XCSOAR_VALUES,
              _RESET_TO_DEFAULT,
            }.map((String choice) {
              if (choice == _DISPLAY_UNITS) {
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
              _DISPLAY_UNITS,
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
                  value: DisplayUnits.Imperial_kts,
                  child: Text(DisplayUnits.Imperial_kts.name)),
              PopupMenuItem<DisplayUnits>(
                  value: DisplayUnits.Imperial_mph,
                  child: Text(DisplayUnits.Imperial_mph.name)),
            ]);
  }

  void _handleClick(String value) async {
    switch (value) {
      case _DISPLAY_XCSOAR_VALUES:
        _showXCSoarValues(true);
        break;
      case _HIDE_XCSOAR_VALUES:
        _showXCSoarValues(false);
        break;
      case _RESET_TO_DEFAULT:
        resetGliderToDefaultValues();
        break;
    }
  }

  void _handleDisplayUnitsClick(DisplayUnits? displayUnits) {
    if (displayUnits is DisplayUnits) {
      if (this._displayUnits != displayUnits) {
        _getGliderCubit().saveDisplayUnits(displayUnits);
      }
    }
    Navigator.pop(context);
  }

  void _displayPolarHelp() async {
    CommonWidgets.showTextAndCheckboxDialogBuilder(
        context: context,
        title: GLIDER_POLAR,
        child: _getPolarHelpTextWidget(),
        button1Text: StandardLiterals.OK,
        button1Function: (() {
          Navigator.pop(context);
        }));
  }

  Widget _getPolarHelpTextWidget() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
            child: Text(_GLIDER_POLAR_HELP),
          ),
          StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return CheckboxListTile(
              title: Text("Do not display again. (Can display via HELP)"),
              controlAffinity: ListTileControlAffinity.leading,
              value: _doNotShowPolarHelp,
              onChanged: (newValue) async {
                _doNotShowPolarHelp = newValue != null ? newValue : false;
                await _getGliderCubit().displayPolarHelp(_doNotShowPolarHelp);
                setState(() {
                  // Seems like flutter wants async task out of setstate
                  // if checked then DO NOT display experimental text, hence save as false
                });
              },
            );
          })
        ],
      ),
    );
  }

  Widget _getBody() {
    return Stack(children: [
      SingleChildScrollView(
        child: Column(
          children: [
            _getGliderList(),
            _displayGliderDetail(),
            _getErrorMessagesWidget(),
            _getGliderStatesHandler(),
          ],
        ),
      ),
      _getIsWorkingIndicator(),
    ]);
  }

  Widget _getGliderList() {
    return BlocConsumer<GliderCubit, GliderCubitState>(
        listener: (context, state) {
      if (state is GliderListState) {
        _selectedGlider = state.selectedGliderName.isNotEmpty
            ? state.selectedGliderName
            : null;
      }
    }, buildWhen: (previous, current) {
      return current is GliderListState;
    }, builder: (context, state) {
      if (state is GliderListState) {
        if (state.gliderNameList.length == 0) {
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
        items:
            state.gliderNameList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: _formattedTextCell(value),
          );
        }).toList(),
      ),
    );
  }

  Widget _displayGliderDetail() {
    return BlocConsumer<GliderCubit, GliderCubitState>(
        listener: (context, state) {
      if (state is GliderPolarState) {
        _defaultGliderLocalUnits = state.defaultPolar;
        _customGliderLocalUnits = state.customPolar;
        _displayUnits = state.displayUnits;
        _velocityUnits = state.velocityUnits;
        _sinkRateUnits = state.sinkRateUnits;
        _massUnits = state.massUnits;
        _distanceUnits = state.distanceUnits;
        _displayXCSoarValues = state.displayXCSoarValues;
      }
    }, buildWhen: (previous, current) {
      return current is GliderPolarState;
    }, builder: (context, state) {
      if (state is GliderPolarState) {
        return _getGliderDetailsWidget(); //_getHorizontalPolarDisplay();
      }
      return SizedBox.shrink();
    });
  }

  Widget _getGliderDetailsWidget() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
        child: Column(children: [
          _getTableHeader(
              tableTitle: GLIDER_MASS,
              infoTitle: GLIDER_MASS,
              tableInfo: _GLIDER_MASS_INFO),
          _getGliderWeightDisplay(
              customGlider: _customGliderLocalUnits!,
              defaultGlider: _defaultGliderLocalUnits,
              displayXCSoarValues: _displayXCSoarValues,
              massUnits: _massUnits),
          _getTableHeader(
              tableTitle: THERMALING + " " + SINK_RATE,
              infoTitle: SINK_RATE,
              tableInfo: _SINK_RATE_INFO),
          _getThermalingValues(
              customGlider: _customGliderLocalUnits!,
              defaultGlider: _defaultGliderLocalUnits,
              displayUnits: _displayUnits,
              velocityUnits: _velocityUnits,
              sinkRateUnits: _sinkRateUnits,
              distanceUnits: _distanceUnits,
              displayXCSoarValues: _displayXCSoarValues),
          _getTableHeader(
              tableTitle: SPEED_VS_SINK_RATE,
              infoTitle: GLIDER_POLAR,
              tableInfo: _GLIDER_POLAR_INFO),
          _getPolarTable(
              customGlider: _customGliderLocalUnits!,
              defaultGlider: _defaultGliderLocalUnits,
              displayUnits: _displayUnits,
              sinkRateUnits: _sinkRateUnits,
              velocityUnits: _velocityUnits,
              displayXCSoarValues: _displayXCSoarValues),
        ]),
      ),
    );
  }

  Table _getGliderWeightDisplay(
      {required Glider customGlider,
      required Glider defaultGlider,
      required bool displayXCSoarValues,
      required String massUnits}) {
    String massLabel = " (" + massUnits + ")";
    return Table(
      border: TableBorder.all(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: <TableRow>[
        TableRow(
            children: _buildTableColumnLabels(
                dataLabel: "",
                customLabel: 'Your\nGlider',
                defaultLabel: 'XCSoar\nValues',
                displayDefaultValues: displayXCSoarValues)),
        TableRow(
          children: _getGliderMass(
              customGlider: customGlider,
              defaultGlider: defaultGlider,
              massLabel: massLabel,
              displayXCSoarValues: displayXCSoarValues),
        ),
        TableRow(
          children: _getPilotMass(
              customGlider: customGlider,
              defaultGlider: defaultGlider,
              massLabel: massLabel,
              displayXCSoarValues: displayXCSoarValues),
        ),
        TableRow(
          children: _getMaxBallast(
              customGlider: customGlider,
              defaultGlider: defaultGlider,
              massLabel: massLabel,
              displayXCSoarValues: displayXCSoarValues),
        ),
        TableRow(
          children: _getOnBoardBallast(
              customGlider: customGlider,
              defaultGlider: defaultGlider,
              massLabel: massLabel,
              displayXCSoarValues: displayXCSoarValues),
        ),
        TableRow(
          children: _getTotalGliderMass(
              customGlider: customGlider,
              defaultGlider: defaultGlider,
              massLabel: massLabel,
              displayXCSoarValues: displayXCSoarValues),
        ),
      ],
    );
  }

  Widget _getThermalingValues(
      {required Glider customGlider,
      required Glider defaultGlider,
      required DisplayUnits displayUnits,
      required String velocityUnits,
      required String sinkRateUnits,
      required String distanceUnits,
      required bool displayXCSoarValues}) {
    String velocityLabel = " (" + velocityUnits + ")";
    String sinkRateLabel = " (" + sinkRateUnits + ")";
    String distanceLabel = " (" + distanceUnits + ")";
    return Table(
        border: TableBorder.all(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: <TableRow>[
          TableRow(
            children: _buildTableColumnLabels(
                dataLabel: " ",
                customLabel: YOUR_GLIDER,
                defaultLabel: XCSOAR_VALUES,
                displayDefaultValues: _displayXCSoarValues),
          ),
          TableRow(
              children: _getMinSinkSpeed(
                  customGlider: customGlider,
                  defaultGlider: defaultGlider,
                  displayUnits: displayUnits,
                  velocityLabel: velocityLabel,
                  displayXCSoarValues: displayXCSoarValues)),
          TableRow(
              children: _getMinSinkRate(
                  customGlider: customGlider,
                  defaultGlider: defaultGlider,
                  displayUnits: displayUnits,
                  sinkRateUnits: sinkRateUnits,
                  sinkRateLabel: sinkRateLabel,
                  displayXCSoarValues: displayXCSoarValues)),
          TableRow(
            children: _getThermalBankAngle(
                customGlider: customGlider,
                defaultGlider: defaultGlider,
                displayXCSoarValues: displayXCSoarValues),
          ),
          TableRow(
            children: _getThermalingSpeed(
                customGlider: customGlider,
                defaultGlider: defaultGlider,
                displayUnits: displayUnits,
                velocityLabel: velocityLabel,
                displayXCSoarValues: displayXCSoarValues),
          ),
          TableRow(
            children: _getThermalingSinkRate(
                customGlider: customGlider,
                defaultGlider: defaultGlider,
                displayUnits: displayUnits,
                sinkRateUnits: sinkRateUnits,
                sinkRateLabel: sinkRateLabel,
                displayXCSoarValues: displayXCSoarValues),
          ),
          TableRow(
            children: _getTurnDiameter(
              customGlider: customGlider,
              defaultGlider: defaultGlider,
              displayUnits: displayUnits,
              sinkRateUnits: sinkRateUnits,
              distanceLabel: distanceLabel,
              displayXCSoarValues: displayXCSoarValues,
            ),
          ),
          TableRow(
            children: _getTimeForTurn(
                customGlider: customGlider,
                defaultGlider: defaultGlider,
                displayXCSoarValues: displayXCSoarValues),
          ),
        ]);
  }

  List<Widget> _getMinSinkSpeed(
      {required Glider customGlider,
      required Glider defaultGlider,
      required String velocityLabel,
      required bool displayXCSoarValues,
      required DisplayUnits displayUnits}) {
    List<Widget> widgets = [];
    widgets.add(_formattedTextCell(MIN_SINK_SPEED + velocityLabel));
    widgets.add(InkWell(
      child: _formattedTextCell(customGlider.minSinkSpeed.toStringAsFixed(0),
          modifiable: true),
      onTap: (() {
        _updateGliderValueDialog(
            label: MIN_SINK_SPEED + " " + velocityLabel,
            regexValidation: _REGEX_TO_999,
            value: customGlider.minSinkSpeed.toStringAsFixed(0),
            updateFunction: ((String value) {
              double doubleValue = _convertToDouble(value);
              if (doubleValue != customGlider.minSinkSpeed) {
                _getGliderCubit()
                    .updateVelocity(VELOCITY_PARM.MIN_SINK_SPEED, doubleValue);
              }
            }),
            validationErrorMsg: _NUMBER_TO_999,
            hintText: _ENTER_VELOCITY);
      }),
    ));
    if (displayXCSoarValues) {
      widgets.add(_formattedTextCell(NOT_APPLICABLE));
    }
    return widgets;
  }

  List<Widget> _getMinSinkRate(
      {required Glider customGlider,
      required Glider defaultGlider,
      required DisplayUnits displayUnits,
      required String sinkRateLabel,
      required bool displayXCSoarValues,
      required String sinkRateUnits}) {
    List<Widget> widgets = [];
    widgets.add(_formattedTextCell("Min Sink Rate " + sinkRateLabel));
    widgets.add(InkWell(
      child: _formatSinkRateValue(displayUnits, customGlider.minSinkRate,
          modifiable: true),
      onTap: (() {
        _updateGliderValueDialog(
            label: "Min Sink Rate " + sinkRateLabel,
            regexValidation: _REGEX_TO_999_99,
            value: customGlider.minSinkRate.toStringAsFixed(2),
            updateFunction: ((String value) {
              double doubleValue = _convertToDouble(value);
              if (doubleValue != customGlider.minSinkRate) {
                _getGliderCubit()
                    .updateSinkRate(SINK_RATE_PARM.MIN_SINK, doubleValue);
              }
            }),
            validationErrorMsg: _NUMBER_TO_999_99,
            hintText: _ENTER_MIN_SINKRATE);
      }),
    ));
    if (displayXCSoarValues) {
      widgets.add(_formattedTextCell(NOT_APPLICABLE));
    }
    return widgets;
  }

  List<Widget> _getThermalBankAngle({
    required Glider customGlider,
    required Glider defaultGlider,
    required bool displayXCSoarValues,
  }) {
    List<Widget> widgets = [];
    widgets.add(_formattedTextCell("Thermal Bank Angle"));
    widgets.add(InkWell(
      child: _formattedTextCell(customGlider.bankAngle.toStringAsFixed(0),
          modifiable: true),
      onTap: (() {
        _updateGliderValueDialog(
            label: "Thermal Bank Angle ",
            regexValidation: _REGEX_0_TO_60,
            value: customGlider.bankAngle.toStringAsFixed(0),
            updateFunction: ((String value) {
              int intValue = _convertToInt(value);
              if (intValue != customGlider.bankAngle) {
                _getGliderCubit().updateThermalingBankAngle(intValue);
              }
            }),
            validationErrorMsg: _BANK_ANGLE_10_TO_60,
            hintText: _ENTER_BANK_ANGLE);
      }),
    ));
    if (displayXCSoarValues) {
      widgets.add(_formattedTextCell(NOT_APPLICABLE));
    }
    return widgets;
  }

  List<Widget> _getThermalingSpeed(
      {required Glider customGlider,
      required Glider defaultGlider,
      required DisplayUnits displayUnits,
      required String velocityLabel,
      required bool displayXCSoarValues}) {
    List<Widget> widgets = [];
    widgets.add(_formattedTextCell("Thermaling Speed" + velocityLabel));
    widgets.add(_formattedTextCell(
        customGlider.minSinkSpeedAtBankAngle.round().toString()));
    if (displayXCSoarValues) {
      widgets.add(_formattedTextCell(NOT_APPLICABLE));
    }
    return widgets;
  }

  List<Widget> _getThermalingSinkRate({
    required Glider customGlider,
    required Glider defaultGlider,
    required DisplayUnits displayUnits,
    required String sinkRateUnits,
    required String sinkRateLabel,
    required bool displayXCSoarValues,
  }) {
    List<Widget> widgets = [];
    widgets.add(_formattedTextCell("Thermaling Sink Rate\n" + sinkRateLabel));
    widgets.add(_formatSinkRateValue(
        displayUnits, customGlider.ballastAdjThermalingSinkRate));
    if (displayXCSoarValues) {
      widgets.add(_formattedTextCell(NOT_APPLICABLE));
    }
    return widgets;
  }

  Widget _formatSinkRateValue(DisplayUnits displayUnits, double sinkRate,
      {bool modifiable = false}) {
    return _formattedTextCell(
        sinkRate.toStringAsFixed(displayUnits == DisplayUnits.Metric ? 2 : 0),
        modifiable: modifiable);
  }

  List<Widget> _getTurnDiameter(
      {required Glider customGlider,
      required Glider defaultGlider,
      required String sinkRateUnits,
      required String distanceLabel,
      required bool displayXCSoarValues,
      required DisplayUnits displayUnits}) {
    List<Widget> widgets = [];
    widgets.add(_formattedTextCell("Turn Diameter" + distanceLabel));
    widgets
        .add(_formattedTextCell(customGlider.turnDiameter.round().toString()));
    if (displayXCSoarValues) {
      widgets.add(_formattedTextCell(NOT_APPLICABLE));
    }
    return widgets;
  }

  List<Widget> _getTimeForTurn(
      {required Glider customGlider,
      required Glider defaultGlider,
      required bool displayXCSoarValues}) {
    List<Widget> widgets = [];
    widgets.add(_formattedTextCell("Time for turn (sec)"));
    widgets.add(
        _formattedTextCell(customGlider.secondsForTurn.round().toString()));
    if (displayXCSoarValues) {
      widgets.add(_formattedTextCell(NOT_APPLICABLE));
    }
    return widgets;
  }

  Widget _getPolarTable(
      {required Glider customGlider,
      required Glider defaultGlider,
      required DisplayUnits displayUnits,
      required String sinkRateUnits,
      required String velocityUnits,
      required bool displayXCSoarValues}) {
    String velocityLabel = "(" + velocityUnits + ")";
    String sinkRateLabel = "(" + sinkRateUnits + ")";
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Table(
        border: TableBorder.all(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: <TableRow>[
          TableRow(
            children: _buildTableColumnLabels(
                dataLabel: POLAR_VALUES,
                customLabel: YOUR_GLIDER,
                defaultLabel: XCSOAR_VALUES,
                displayDefaultValues: displayXCSoarValues),
          ),
          TableRow(
            children: _getPolarVelocityRow(
                customGlider: customGlider,
                defaultGlider: defaultGlider,
                displayUnits: displayUnits,
                polarVelocityParm: VELOCITY_PARM.V1,
                displayXCSoarValues: displayXCSoarValues,
                velocityLabel: velocityLabel),
          ),
          TableRow(
              children: _getPolarSinkRateRow(
                  customGlider: customGlider,
                  defaultGlider: defaultGlider,
                  displayUnits: displayUnits,
                  sinkRateParm: SINK_RATE_PARM.W1,
                  displayXCSoarValues: displayXCSoarValues,
                  sinkRateLabel: sinkRateLabel)),
          TableRow(
            children: _getPolarVelocityRow(
                customGlider: customGlider,
                defaultGlider: defaultGlider,
                displayUnits: displayUnits,
                polarVelocityParm: VELOCITY_PARM.V2,
                displayXCSoarValues: displayXCSoarValues,
                velocityLabel: velocityLabel),
          ),
          TableRow(
              children: _getPolarSinkRateRow(
                  customGlider: customGlider,
                  defaultGlider: defaultGlider,
                  displayUnits: displayUnits,
                  sinkRateParm: SINK_RATE_PARM.W2,
                  displayXCSoarValues: displayXCSoarValues,
                  sinkRateLabel: sinkRateLabel)),
          TableRow(
            children: _getPolarVelocityRow(
                customGlider: customGlider,
                defaultGlider: defaultGlider,
                displayUnits: displayUnits,
                polarVelocityParm: VELOCITY_PARM.V3,
                displayXCSoarValues: displayXCSoarValues,
                velocityLabel: velocityLabel),
          ),
          TableRow(
              children: _getPolarSinkRateRow(
                  customGlider: customGlider,
                  defaultGlider: defaultGlider,
                  displayUnits: displayUnits,
                  sinkRateParm: SINK_RATE_PARM.W3,
                  displayXCSoarValues: displayXCSoarValues,
                  sinkRateLabel: sinkRateLabel)),
        ],
      ),
    );
  }

  List<Widget> _getPolarVelocityRow(
      {required Glider customGlider,
      required Glider defaultGlider,
      required DisplayUnits displayUnits,
      required VELOCITY_PARM polarVelocityParm, //V1, V2, or V3
      required String velocityLabel,
      required bool displayXCSoarValues}) {
    List<Widget> widgets = [];
    widgets
        .add(_formattedTextCell(polarVelocityParm.name + " " + velocityLabel));
    widgets.add(InkWell(
      child: _getFormattedPolarVelocity(
          glider: customGlider,
          displayUnits: displayUnits,
          velocityParm: polarVelocityParm,
          modifiable: true),
      onTap: (() {
        double polarVelocity = _getVelocity(customGlider, polarVelocityParm);
        _updateGliderValueDialog(
            label: polarVelocityParm.toString() + " " + _velocityUnits,
            regexValidation: _REGEX_TO_999_9,
            value: polarVelocity.toStringAsFixed(1),
            updateFunction: ((String value) {
              double newValue = _convertToDouble(value);
              if (newValue != polarVelocity) {
                setState(() {
                  _getGliderCubit().updateVelocity(polarVelocityParm, newValue);
                });
              }
            }),
            validationErrorMsg: _NUMBER_TO_999_9,
            hintText: _ENTER_VELOCITY);
      }),
    ));
    if (displayXCSoarValues) {
      widgets.add(_getFormattedPolarVelocity(
          glider: defaultGlider,
          displayUnits: displayUnits,
          velocityParm: polarVelocityParm));
    }
    return widgets;
  }

  double _getVelocity(Glider glider, VELOCITY_PARM velocityParm) {
    switch (velocityParm) {
      case VELOCITY_PARM.MIN_SINK_SPEED:
        return glider.minSinkSpeed;
      case VELOCITY_PARM.MIN_SINK_SPEED_AT_BANK_ANGLE:
        return glider.minSinkSpeedAtBankAngle;
      case VELOCITY_PARM.V1:
        return glider.v1;
      case VELOCITY_PARM.V2:
        return glider.v2;
      case VELOCITY_PARM.V3:
        return glider.v3;
      default:
        return 0;
    }
  }

  Widget _getFormattedPolarVelocity(
      {required Glider glider,
      required DisplayUnits displayUnits,
      required VELOCITY_PARM velocityParm,
      modifiable = false}) {
    return _formattedTextCell(
        (_getVelocity(glider, velocityParm))
            .toStringAsFixed(displayUnits == DisplayUnits.Metric ? 0 : 0),
        modifiable: modifiable);
  }

  List<Widget> _getPolarSinkRateRow(
      {required Glider customGlider,
      required Glider defaultGlider,
      required DisplayUnits displayUnits,
      required SINK_RATE_PARM sinkRateParm, //W1, W2, or W3
      required String sinkRateLabel,
      required bool displayXCSoarValues}) {
    List<Widget> widgets = [];
    widgets.add(_formattedTextCell(sinkRateParm.name + " " + sinkRateLabel));
    widgets.add(InkWell(
      child: _getFormattedPolarSinkRate(
          glider: customGlider,
          displayUnits: displayUnits,
          sinkRateParm: sinkRateParm,
          modifiable: true),
      onTap: (() {
        double polarSinkRate = _getSinkRate(customGlider, sinkRateParm);
        _updateGliderValueDialog(
            label: sinkRateParm.toString() + " " + _sinkRateUnits,
            regexValidation: _REGEX_MINUS_999_99_TO_0,
            value: polarSinkRate.toStringAsFixed(2),
            updateFunction: ((String value) {
              double newValue = _convertToDouble(value);
              if (newValue != polarSinkRate) {
                setState(() {
                  _getGliderCubit().updateSinkRate(sinkRateParm, newValue);
                });
              }
            }),
            validationErrorMsg: _SINKRATE_TO_MINUS_999_99,
            hintText: _ENTER_SINKRATE);
      }),
    ));
    if (displayXCSoarValues) {
      widgets.add(_getFormattedPolarSinkRate(
          glider: defaultGlider,
          displayUnits: displayUnits,
          sinkRateParm: sinkRateParm));
    }
    ;
    return widgets;
  }

  double _getSinkRate(Glider glider, SINK_RATE_PARM sinkRateParm) {
    switch (sinkRateParm) {
      case SINK_RATE_PARM.MIN_SINK:
        return glider.minSinkRate;
      case SINK_RATE_PARM.W1:
        return glider.w1;
      case SINK_RATE_PARM.W2:
        return glider.w2;
      case SINK_RATE_PARM.W3:
        return glider.w3;
      default:
        return 0;
    }
  }

  Widget _getFormattedPolarSinkRate(
      {required Glider glider,
      required DisplayUnits displayUnits,
      required SINK_RATE_PARM sinkRateParm,
      modifiable = false}) {
    return _formatSinkRateValue(
        displayUnits, _getSinkRate(glider, sinkRateParm),
        modifiable: modifiable);
  }

  List<Widget> _buildTableColumnLabels(
      {required String dataLabel,
      required String customLabel,
      required String defaultLabel,
      required bool displayDefaultValues}) {
    List<Widget> widgets = [];
    widgets.add(_formattedTextCell(dataLabel));
    widgets.add(_formattedTextCell(customLabel));
    if (displayDefaultValues) {
      widgets.add(_formattedTextCell(defaultLabel));
    }
    return widgets;
  }

  List<Widget> _getGliderMass(
      {required Glider customGlider,
      required Glider defaultGlider,
      required String massLabel,
      required bool displayXCSoarValues}) {
    List<Widget> widgets = [];
    widgets.add(_formattedTextCell(GLIDER_MASS + massLabel));
    widgets.add(InkWell(
      child: _formattedTextCell(customGlider.gliderEmptyMass.toStringAsFixed(1),
          modifiable: true),
      onTap: (() {
        _updateGliderValueDialog(
            label: GLIDER_MASS + massLabel,
            regexValidation: _REGEX_TO_9999_9,
            value: customGlider.gliderEmptyMass.toStringAsFixed(1),
            updateFunction: ((String value) {
              double doubleValue = _convertToDouble(value);
              if (doubleValue != customGlider.gliderEmptyMass) {
                _getGliderCubit().updateMass(MASS_PARM.GLIDER, doubleValue);
              }
            }),
            validationErrorMsg: _NUMBER_TO_9999_9,
            hintText: "Enter glider empty mass.");
      }),
    ));
    if (displayXCSoarValues) {
      widgets.add(
          _formattedTextCell(defaultGlider.gliderEmptyMass.toStringAsFixed(1)));
    }
    return widgets;
  }

  List<Widget> _getPilotMass(
      {required Glider customGlider,
      required Glider defaultGlider,
      required String massLabel,
      required bool displayXCSoarValues}) {
    List<Widget> widgets = [];
    widgets.add(_formattedTextCell("Pilot Mass " + massLabel));
    widgets.add(InkWell(
      child: _formattedTextCell(customGlider.pilotMass.toStringAsFixed(1),
          modifiable: true),
      onTap: (() {
        _updateGliderValueDialog(
            label: "Pilot Mass " + massLabel,
            regexValidation: _REGEX_TO_999_9,
            value: customGlider.pilotMass.toStringAsFixed(1),
            updateFunction: ((String value) {
              double doubleValue = _convertToDouble(value);
              if (doubleValue != customGlider.pilotMass) {
                _getGliderCubit().updateMass(MASS_PARM.PILOT, doubleValue);
              }
            }),
            validationErrorMsg: _NUMBER_TO_999_9,
            hintText: "Enter pilot mass.");
      }),
    ));

    if (displayXCSoarValues) {
      widgets
          .add(_formattedTextCell(defaultGlider.pilotMass.toStringAsFixed(1)));
    }
    return widgets;
  }

  List<Widget> _getMaxBallast(
      {required Glider customGlider,
      required Glider defaultGlider,
      required String massLabel,
      required bool displayXCSoarValues}) {
    List<Widget> widgets = [];
    widgets.add(_formattedTextCell(" Max Ballast " + massLabel));

    widgets.add(InkWell(
      child: _formattedTextCell(customGlider.maxBallast.toStringAsFixed(1),
          modifiable: true),
      onTap: (() {
        _updateGliderValueDialog(
            label: "Max Ballast " + massLabel,
            regexValidation: _REGEX_TO_999_9,
            value: customGlider.maxBallast.toStringAsFixed(1),
            updateFunction: ((String value) {
              double doubleValue = _convertToDouble(value);
              if (doubleValue != customGlider.maxBallast) {
                _getGliderCubit()
                    .updateMass(MASS_PARM.MAX_BALLAST, doubleValue);
              }
            }),
            validationErrorMsg: _NUMBER_TO_999_9,
            hintText: "Enter max ballast.");
      }),
    ));

    if (displayXCSoarValues) {
      widgets
          .add(_formattedTextCell(defaultGlider.maxBallast.toStringAsFixed(1)));
    }
    return widgets;
  }

  List<Widget> _getOnBoardBallast(
      {required Glider customGlider,
      required Glider defaultGlider,
      required String massLabel,
      required bool displayXCSoarValues}) {
    List<Widget> widgets = [];
    widgets.add(_formattedTextCell("On Board Ballast" + massLabel));
    widgets.add(InkWell(
      child: _formattedTextCell(customGlider.loadedBallast.toStringAsFixed(1),
          modifiable: true),
      onTap: (() {
        _updateGliderValueDialog(
            label: "On Board Ballast " + massLabel,
            regexValidation: _REGEX_TO_999_9,
            value: customGlider.loadedBallast.toStringAsFixed(1),
            updateFunction: ((String value) {
              double doubleValue = _convertToDouble(value);
              if (doubleValue != customGlider.loadedBallast) {
                setState(() {
                  customGlider.loadedBallast = doubleValue;
                  _getGliderCubit().updateMass(MASS_PARM.BALLAST, doubleValue);
                });
              }
            }),
            validationErrorMsg: _NUMBER_TO_999_9,
            hintText: "Enter loaded ballast.");
      }),
    ));
    if (displayXCSoarValues) {
      widgets.add(
          _formattedTextCell(defaultGlider.loadedBallast.toStringAsFixed(1)));
    }
    return widgets;
  }

  List<Widget> _getTotalGliderMass(
      {required Glider customGlider,
      required Glider defaultGlider,
      required String massLabel,
      required bool displayXCSoarValues}) {
    List<Widget> widgets = [];
    widgets.add(_formattedTextCell("Glider + \nPilot + \nBallast" + massLabel));
    widgets.add(_formattedTextCell((customGlider.gliderEmptyMass +
            customGlider.pilotMass +
            customGlider.loadedBallast)
        .toStringAsFixed(1)));
    if (displayXCSoarValues) {
      widgets.add(_formattedTextCell(
          (defaultGlider.gliderAndMaxPilotWgt + defaultGlider.loadedBallast)
              .toStringAsFixed(1)));
    }
    return widgets;
  }

  Widget _getTableHeader(
      {required String tableTitle,
      required String infoTitle,
      required String tableInfo}) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(tableTitle,
              style: textStyleBoldBlackFontSize18, textAlign: TextAlign.center),
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
                  title: infoTitle,
                  msg: tableInfo,
                  button1Text: StandardLiterals.OK,
                  button1Function: (() => Navigator.of(context).pop()),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _getGliderStatesHandler() {
    return BlocListener<GliderCubit, GliderCubitState>(
      listener: (context, state) {
        if (state is CalcEstimatedFlightState) {
          Navigator.pop(context, state.glider);
        }
        if (state is ShowPolarHelpState) {
          _displayPolarHelp();
        }
        if (state is PolarUnitsState) {
          _displayUnits = state.displayUnits;
        }
      },
      child: SizedBox.shrink(),
    );
  }

  Widget _formattedTextCell(String? text, {bool modifiable = false}) {
    if (modifiable) {
      return Ink(
        height: 50,
        color: Colors.green[50],
        child: Container(
          alignment: Alignment.center,
          child: Text(text ?? "",
              style: textStyleBoldBlackFontSize18, textAlign: TextAlign.center),
        ),
      );
    }
    return Text(text ?? "",
        style: textStyleBoldBlackFontSize18, textAlign: TextAlign.center);
  }

  Widget _getIsWorkingIndicator() {
    return BlocConsumer<GliderCubit, GliderCubitState>(
        listener: (context, state) {
      if (state is GliderCubitWorkingState) ;
    }, buildWhen: (previous, current) {
      return current is GliderCubitWorkingState;
    }, builder: (context, state) {
      return (state is GliderCubitWorkingState && state.working)
          ? CommonWidgets.buildLoading()
          : SizedBox.shrink();
    });
  }

  Widget _getErrorMessagesWidget() {
    return BlocListener<GliderCubit, GliderCubitState>(
      listener: (context, state) {
        if (state is GliderCubitErrorState) {
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
            autofocus: true,
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

  Future<bool> _onWillPop() async {
    Navigator.pop(context);
    return true;
  }

  void _showXCSoarValues(bool displayXCSoarValues) {
    _getGliderCubit().saveDisplayXCSoarValues(displayXCSoarValues);
    setState(() {
      _displayXCSoarValues = displayXCSoarValues;
    });
  }

  void resetGliderToDefaultValues() {
    setState(() {
      _customGliderLocalUnits = _defaultGliderLocalUnits.copyWith();
    });
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
