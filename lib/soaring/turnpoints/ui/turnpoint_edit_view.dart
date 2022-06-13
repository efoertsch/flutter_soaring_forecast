import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/app/main.dart';
import 'package:flutter_soaring_forecast/soaring/app/web_mixin.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/cup/cup_styles.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoint_utils.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_overhead_view.dart';

class TurnpointEditView extends StatefulWidget {
  final Turnpoint turnpoint;

  TurnpointEditView({Key? key, required this.turnpoint}) : super(key: key) {}

  @override
  State<TurnpointEditView> createState() => _TurnpointEditViewState();
}

class _TurnpointEditViewState extends State<TurnpointEditView>
    with AfterLayoutMixin<TurnpointEditView> {
  // not making formKey final as may assign new key in case of edit/reset scenario and
  // need to redraw screen
  var _formKey = GlobalKey<FormState>();
  Turnpoint modifiableTurnpoint = Turnpoint();

  bool _isReadOnly = true;
  bool _isDecimalDegreesFormat = true;
  List<Style> _cupStyles = [];
  bool _needToSaveUpdates = false;
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  void initState() {
    modifiableTurnpoint = widget.turnpoint.clone();
    _latitudeController.text = _getLatitudeInDisplayFormat();
    _longitudeController.text = _getLongitudeInDisplayFormat();
    super.initState();
  }

  // Make sure first layout occurs
  @override
  void afterFirstLayout(BuildContext context) {
    BlocProvider.of<TurnpointBloc>(context).add(CupStylesEvent());
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return ConditionalWillPopScope(
        onWillPop: _onWillPop,
        shouldAddCallback: true,
        child: _buildScaffold(context),
      );
    } else {
      //iOS
      return GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.direction >= 0) {
            _onWillPop();
          }
        },
        child: _buildScaffold(context),
      );
    }
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Turnpoint'),
        leading: CommonWidgets.backArrowToHomeScreen(),
        actions: _getMenu(),
      ),
      body: _getBodyWidget(),
      bottomNavigationBar: null,
    );
  }

  Widget _getBodyWidget() {
    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(children: [
          _getTitleWidget(),
          _getCodeWidget(),
          _getCountryWidget(),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _getLatitudeWidget(),
                _getLongitudeWidget(),
              ]),
            ),
            Expanded(
              child: _getTurnpointIconWidget(),
            ),
          ]),
          _getElevationWidget(),
          _getCupStyleListWidget(),
          _getDirectionWidget(),
          _getRunwayLengthWidget(),
          _getRunwayWidthWidget(),
          _getAirportFrequencyWidget(),
          _getDescriptionWidget(),
        ]),
      ),
    );
  }

  Widget _getTitleWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 8, right: 8),
      child: TextFormField(
        readOnly: _isReadOnly,
        initialValue: modifiableTurnpoint.title,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          // hintText: TurnpointEditText.waypointName,
          labelText: TurnpointEditText.waypointName,
        ),
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return 'Please enter waypoint title';
          }
          modifiableTurnpoint.title = value!;
          return null;
        },
      ),
    );
  }

  Widget _getCodeWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        readOnly: _isReadOnly || modifiableTurnpoint.code.isNotEmpty,
        initialValue: modifiableTurnpoint.code,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: TurnpointEditText.waypointCode,
          labelText: TurnpointEditText.waypointCode,
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return 'A turnpoint code is required';
          }
          modifiableTurnpoint.code = value!;
          return null;
        },
      ),
    );
  }

  Widget _getCountryWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        readOnly: _isReadOnly,
        initialValue: (widget.turnpoint.country),
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: TurnpointEditText.countryCode,
          labelText: TurnpointEditText.countryCode,
        ),
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return 'Country(probably \'US\') is required';
          }
          modifiableTurnpoint.country = value!;
          return null;
        },
      ),
    );
  }

  Widget _getLatitudeWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        readOnly: _isReadOnly,
        //initialValue: _getLatitudeInDisplayFormat(),
        decoration: InputDecoration(
            border: OutlineInputBorder(),
            //hintText: getLatitudeText(),
            labelText: _getLatitudeText()),
        controller: _latitudeController,

        validator: (value) {
          if (value?.isEmpty ?? true) {
            return "Latitude is required";
          }
          if (TurnpointUtils.validateLatitude(
              value!, _isDecimalDegreesFormat)) {
            final latitude = TurnpointUtils.parseLatitudeValue(
                value, _isDecimalDegreesFormat);
            if (latitude != widget.turnpoint.latitudeDeg) {
              _needToSaveUpdates = true;
              modifiableTurnpoint.latitudeDeg = double.parse(value);
            }
          } else {
            return "Invalid Latitude format";
          }
          return null;
        },
      ),
    );
  }

  Widget _getLongitudeWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        readOnly: _isReadOnly,
        // initialValue: _getLongitudeInDisplayFormat(),
        decoration: InputDecoration(
            border: OutlineInputBorder(),
            //hintText: getLongitudeText(),
            labelText: _getLongitudeText()),
        controller: _longitudeController,
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return "Longitude is required";
            ;
          }
          if (TurnpointUtils.validateLongitude(
              value!, _isDecimalDegreesFormat)) {
            final longitude = TurnpointUtils.parseLongitudeValue(
                value, _isDecimalDegreesFormat);
            if (longitude != widget.turnpoint.longitudeDeg) {
              _needToSaveUpdates = true;
              modifiableTurnpoint.longitudeDeg = double.parse(value);
            }
          } else {
            return "Invalid Longitude value";
          }
          return null;
        },
      ),
    );
  }

  Widget _getTurnpointIconWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconButton(
        icon: Icon(Icons.location_searching),
        color: TurnpointUtils.getColorForTurnpointIcon(modifiableTurnpoint),
        onPressed: () => Navigator.pushNamed(
          context,
          TurnpointView.routeName,
          arguments: TurnpointOverHeadArgs(
              isReadOnly: _isReadOnly,
              isDecimalDegreesFormat: _isDecimalDegreesFormat,
              turnpoint: modifiableTurnpoint),
        ),
      ),
    );
  }

  Widget _getElevationWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        readOnly: _isReadOnly,
        initialValue: modifiableTurnpoint.elevation,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: TurnpointEditText.elevation,
          labelText: TurnpointEditText.elevation,
        ),
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return "Elevation is required";
          }
          if (TurnpointUtils.elevationValid(value!)) {
            modifiableTurnpoint.elevation = value;
          } else {
            return "Invalid elevation";
          }
        },
      ),
    );
  }

  Widget _getCupStyleListWidget() {
    return BlocBuilder<TurnpointBloc, TurnpointState>(
        buildWhen: (previous, current) {
      return current is TurnpointCupStyles;
    }, builder: (context, state) {
      if (state is TurnpointCupStyles) {
        _cupStyles.clear();
        _cupStyles.addAll(state.cupStyles);
        return Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 8, right: 8),
          child: InputDecorator(
            decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              labelText: TurnpointEditText.turnpointType,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                style: CustomStyle.bold18(context),
                value: TurnpointUtils.getStyleDescriptionFromStyle(
                    state.cupStyles, modifiableTurnpoint.style),
                hint: Text('Select turnpoint type'),
                isExpanded: true,
                iconSize: 24,
                elevation: 16,
                onChanged: _isReadOnly
                    ? null
                    : (String? description) {
                        if (description != null) {
                          modifiableTurnpoint.style =
                              TurnpointUtils.getStyleFromStyleDescription(
                                  state.cupStyles, description);
                        } else {
                          modifiableTurnpoint.style = '0';
                        }
                        setState(() {});
                        // _sendEvent(context, );
                      },
                items: state.cupStyles
                    .map((style) {
                      return style.description;
                    })
                    .toList()
                    .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value.toUpperCase()),
                      );
                    })
                    .toList(),
              ),
            ),
          ),
        );
      } else {
        return Container();
      }
    });
  }

  Widget _getDirectionWidget() {
    return Visibility(
      visible: TurnpointUtils.isLandable(modifiableTurnpoint.style),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          readOnly: _isReadOnly,
          initialValue: modifiableTurnpoint.direction,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: TurnpointEditText.runwayDirection,
            labelText: TurnpointEditText.runwayDirection,
          ),
          validator: (value) {
            if (TurnpointUtils.isLandable(modifiableTurnpoint.style) &&
                (value == null || value.isEmpty)) {
              return "Enter runway direction";
            }
            if (!TurnpointUtils.runwayDirectionValid(value!)) {
              return "Invalid runway direction value";
            }
            modifiableTurnpoint.direction = value;
            return null;
          },
        ),
      ),
    );
  }

  Widget _getRunwayLengthWidget() {
    return Visibility(
      visible: TurnpointUtils.isLandable(modifiableTurnpoint.style),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          readOnly: _isReadOnly,
          initialValue: modifiableTurnpoint.length,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: TurnpointEditText.runwayLength,
            labelText: TurnpointEditText.runwayLength,
          ),
          validator: (value) {
            if (TurnpointUtils.isLandable(modifiableTurnpoint.style) &&
                (value == null || value.isEmpty)) {
              return "Enter runway/landable area length";
            }
            if (!TurnpointUtils.runwayLengthValid(value!)) {
              return "Invalid runway/landable area value";
            }
            modifiableTurnpoint.length = value;
            return null;
          },
        ),
      ),
    );
  }

  Widget _getRunwayWidthWidget() {
    return Visibility(
      visible: TurnpointUtils.isLandable(modifiableTurnpoint.style),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          readOnly: _isReadOnly,
          initialValue: modifiableTurnpoint.runwayWidth,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: TurnpointEditText.runwayWidth,
            labelText: TurnpointEditText.runwayWidth,
          ),
          validator: (value) {
            final isLandable =
                TurnpointUtils.isLandable(modifiableTurnpoint.style);
            if ((!isLandable && (value == null || value.isEmpty)) ||
                (isLandable && TurnpointUtils.runwayWidthValid(value ?? ""))) {
              modifiableTurnpoint.runwayWidth = value ?? "";
              return null;
            }
            return "Invalid runway/landable area width";
          },
        ),
      ),
    );
  }

  Widget _getAirportFrequencyWidget() {
    return Visibility(
      visible: TurnpointUtils.isAirport(modifiableTurnpoint.style),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          readOnly: _isReadOnly,
          initialValue: modifiableTurnpoint.frequency,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            //hintText: TurnpointEditText.airportFrequency,
            labelText: TurnpointEditText.airportFrequency,
          ),
          validator: (value) {
            final isAirport =
                TurnpointUtils.isAirport(modifiableTurnpoint.style);
            if ((!isAirport || (value?.isEmpty ?? true))) {
              modifiableTurnpoint.frequency = "";
              return null;
            }
            if (isAirport &&
                TurnpointUtils.airportFrequencyValid(value ?? "")) {
              modifiableTurnpoint.frequency = value!;
              return null;
            }
            return "Invalid airport frequency";
          },
        ),
      ),
    );
  }

  Widget _getDescriptionWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        readOnly: _isReadOnly,
        initialValue: modifiableTurnpoint.description,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: TurnpointEditText.description,
          labelText: TurnpointEditText.description,
        ),
        onChanged: (text) {
          modifiableTurnpoint.description = text;
        },
      ),
    );
  }

  String _getLatitudeInDisplayFormat() {
    return _isDecimalDegreesFormat
        ? modifiableTurnpoint.latitudeDeg.toStringAsFixed(5)
        : TurnpointUtils.getLatitudeInCupFormat(widget.turnpoint.latitudeDeg);
  }

  String _getLatitudeText() {
    return _isDecimalDegreesFormat
        ? TurnpointEditText.latitudeDecimalDegrees
        : TurnpointEditText.latitudeDecimalMinutes;
  }

  String _getLongitudeInDisplayFormat() {
    return _isDecimalDegreesFormat
        ? modifiableTurnpoint.longitudeDeg.toStringAsFixed(5)
        : TurnpointUtils.getLongitudeInCupFormat(widget.turnpoint.longitudeDeg);
  }

  String _getLongitudeText() {
    return _isDecimalDegreesFormat
        ? TurnpointEditText.longitudeDecimalDegrees
        : TurnpointEditText.longitudeDecimalMinutes;
  }

  List<Widget> _getMenu() {
    return <Widget>[
      _isReadOnly
          ? IconButton(
              icon: Icon(Icons.edit),
              color: Colors.white,
              onPressed: () => setState(() {
                _isReadOnly = false;
                _displayEditStatus();
              }),
            )
          : TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  print('Save/update turnpoint');
                } else {
                  _displayEditWaring();
                }
              },
              child: Text(
                TurnpointEditMenu.save,
                style: TextStyle(color: Colors.white),
              ),
            ),
      PopupMenuButton<String>(
        onSelected: handleClick,
        icon: Icon(Icons.more_vert),
        itemBuilder: (BuildContext context) {
          return {
            TurnpointEditMenu.reset,
            TurnpointEditMenu.toggleLatLongFormat,
            TurnpointEditMenu.airNav,
          }.map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
      ),
    ];
  }

  void _displayEditWaring() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
        CommonWidgets.getSnackBarForMessage(
            "Correct data errors in turnpoint ."));
    setState(() {});
  }

  void _displayEditStatus() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
        CommonWidgets.getSnackBarForMessage(_isReadOnly
            ? "Turnpoint in read only mode."
            : "Turnpoint in edit mode."));
    setState(() {});
  }

  void handleClick(String value) {
    switch (value) {
      case TurnpointEditMenu.reset:
        setState(() {
          _isReadOnly = true;
          modifiableTurnpoint = widget.turnpoint.clone();
          _isDecimalDegreesFormat = true;
          _latitudeController.text = _getLatitudeInDisplayFormat();
          _longitudeController.text = _getLongitudeInDisplayFormat();
          _displayEditStatus();
          _formKey = GlobalKey<FormState>();
        });
        break;
      case TurnpointEditMenu.toggleLatLongFormat:
        setState(() {
          _isDecimalDegreesFormat = !_isDecimalDegreesFormat;
          _latitudeController.text = _getLatitudeInDisplayFormat();
          _longitudeController.text = _getLongitudeInDisplayFormat();
        });
        break;
      case TurnpointEditMenu.airNav:
        launchWebBrowser(
            "www.airnav.com", "/airport/" + modifiableTurnpoint.code);
        break;
    }
  }

  Future<bool> _onWillPop() async {
    // TODO check for changes
    Navigator.of(context).pop();
    return true;
  }

  _sendEvent(TurnpointEvent event) {
    BlocProvider.of<TurnpointBloc>(context).add(event);
  }
}
