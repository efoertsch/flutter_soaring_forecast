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
  Turnpoint modifiableTurnpoint = Turnpoint();

  TurnpointEditView({Key? key, required this.turnpoint}) : super(key: key) {
    modifiableTurnpoint = turnpoint.clone();
  }

  @override
  State<TurnpointEditView> createState() => _TurnpointEditViewState();
}

class _TurnpointEditViewState extends State<TurnpointEditView>
    with AfterLayoutMixin<TurnpointEditView> {
  final _formKey = GlobalKey<FormState>();

  bool _isReadOnly = true;
  bool _isDecimalDegreesFormat = true;
  List<Style> _cupStyles = [];
  bool _needToSaveUpdates = false;

  // String latitudeDisplay = "";
  // String longitudeDisplay = "";
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  // Make sure first layout occurs
  @override
  void afterFirstLayout(BuildContext context) {
    _latitudeController.text = _getLatitudeInDisplayFormat();
    _longitudeController.text = _getLongitudeInDisplayFormat();
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
          getDescriptionWidget(),
        ]),
      ),
    );
  }

  Padding getDescriptionWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        readOnly: _isReadOnly,
        initialValue: widget.modifiableTurnpoint.description,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: TurnpointEditText.description,
          labelText: TurnpointEditText.description,
        ),
        onChanged: (text) {
          widget.modifiableTurnpoint.description = text;
        },
      ),
    );
  }

  Widget _getAirportFrequencyWidget() {
    return Visibility(
      visible: TurnpointUtils.isAirport(widget.modifiableTurnpoint.style),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          readOnly: _isReadOnly,
          initialValue: widget.modifiableTurnpoint.frequency,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: TurnpointEditText.airportFrequency,
            labelText: TurnpointEditText.airportFrequency,
          ),
          onChanged: (text) {
            widget.modifiableTurnpoint.frequency = text;
          },
        ),
      ),
    );
  }

  Widget _getRunwayWidthWidget() {
    return Visibility(
      visible: TurnpointUtils.isLandable(widget.modifiableTurnpoint.style),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          readOnly: _isReadOnly,
          initialValue: widget.modifiableTurnpoint.runwayWidth,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: TurnpointEditText.runwayWidth,
            labelText: TurnpointEditText.runwayWidth,
          ),
          onChanged: (text) {
            widget.modifiableTurnpoint.runwayWidth = text;
          },
        ),
      ),
    );
  }

  Widget _getRunwayLengthWidget() {
    return Visibility(
      visible: TurnpointUtils.isLandable(widget.modifiableTurnpoint.style),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          readOnly: _isReadOnly,
          initialValue: widget.modifiableTurnpoint.length,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: TurnpointEditText.runwayLength,
            labelText: TurnpointEditText.runwayLength,
          ),
          onChanged: (text) {
            widget.modifiableTurnpoint.length = text;
          },
        ),
      ),
    );
  }

  Widget _getDirectionWidget() {
    return Visibility(
      visible: TurnpointUtils.isLandable(widget.modifiableTurnpoint.style),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          readOnly: _isReadOnly,
          initialValue: widget.modifiableTurnpoint.direction,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: TurnpointEditText.runwayDirection,
            labelText: TurnpointEditText.runwayDirection,
          ),
          onChanged: (text) {
            widget.modifiableTurnpoint.direction = text;
          },
        ),
      ),
    );
  }

  Widget _getElevationWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        readOnly: _isReadOnly,
        initialValue: widget.modifiableTurnpoint.elevation,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: TurnpointEditText.elevation,
          labelText: TurnpointEditText.elevation,
        ),
        onChanged: (text) {
          widget.modifiableTurnpoint.elevation = text;
        },
      ),
    );
  }

  Widget _getTurnpointIconWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconButton(
        icon: Icon(Icons.location_searching),
        color:
            TurnpointUtils.getColorForTurnpointIcon(widget.modifiableTurnpoint),
        onPressed: () => Navigator.pushNamed(
          context,
          TurnpointView.routeName,
          arguments: TurnpointOverHeadArgs(
              isReadOnly: _isReadOnly,
              isDecimalDegreesFormat: _isDecimalDegreesFormat,
              turnpoint: widget.modifiableTurnpoint),
        ),
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
            hintText: getLongitudeText(),
            labelText: getLongitudeText()),
        controller: _longitudeController,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return getLatitudeText();
          }
          if (TurnpointUtils.validateLongitude(
              value, _isDecimalDegreesFormat)) {
            final longitude = TurnpointUtils.parseLongitudeValue(
                value, _isDecimalDegreesFormat);
            if (longitude != widget.turnpoint.longitudeDeg) {
              _needToSaveUpdates = true;
              widget.modifiableTurnpoint.longitudeDeg = double.parse(value);
            }
          } else {
            return getLongitudeText();
          }
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
        // initialValue: _getLatitudeInDisplayFormat(),
        decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: getLatitudeText(),
            labelText: getLatitudeText()),
        controller: _latitudeController,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return getLatitudeText();
          }
          if (TurnpointUtils.validateLatitude(value, _isDecimalDegreesFormat)) {
            final latitude = TurnpointUtils.parseLatitudeValue(
                value, _isDecimalDegreesFormat);
            if (latitude != widget.turnpoint.latitudeDeg) {
              _needToSaveUpdates = true;
              widget.modifiableTurnpoint.latitudeDeg = double.parse(value);
            }
          } else {
            return getLatitudeText();
          }

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
          if (value == null || value.isEmpty) {
            return 'A turnpoint code is required';
          }
          return null;
        },
        onChanged: (text) {
          widget.modifiableTurnpoint.country = text;
        },
      ),
    );
  }

  Widget _getCodeWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        readOnly: _isReadOnly || widget.modifiableTurnpoint.code.isNotEmpty,
        initialValue: widget.modifiableTurnpoint.code,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: TurnpointEditText.waypointCode,
          labelText: TurnpointEditText.waypointCode,
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'A turnpoint code is required';
          }
          return null;
        },
        onChanged: (text) {
          if (text != widget.modifiableTurnpoint.code) {
            widget.modifiableTurnpoint.code = text;
          }
        },
      ),
    );
  }

  Widget _getTitleWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 8, right: 8),
      child: TextFormField(
        readOnly: _isReadOnly,
        initialValue: widget.modifiableTurnpoint.title,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: TurnpointEditText.waypointName,
          labelText: TurnpointEditText.waypointName,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter waypoint title';
          }
          return null;
        },
        onChanged: (text) {
          if (text != widget.modifiableTurnpoint.title) {
            widget.modifiableTurnpoint.title = text;
          }
        },
      ),
    );
  }

  String _getLongitudeInDisplayFormat() {
    return _isDecimalDegreesFormat
        ? widget.modifiableTurnpoint.longitudeDeg.toStringAsFixed(5)
        : TurnpointUtils.getLongitudeInCupFormat(widget.turnpoint.longitudeDeg);
  }

  String _getLatitudeInDisplayFormat() {
    return _isDecimalDegreesFormat
        ? widget.modifiableTurnpoint.latitudeDeg.toStringAsFixed(5)
        : TurnpointUtils.getLatitudeInCupFormat(widget.turnpoint.latitudeDeg);
  }

  String getLongitudeText() {
    return _isDecimalDegreesFormat
        ? TurnpointEditText.longitudeDecimalDegrees
        : TurnpointEditText.longitudeDecimalMinutes;
  }

  String getLatitudeText() {
    return _isDecimalDegreesFormat
        ? TurnpointEditText.latitudeDecimalDegrees
        : TurnpointEditText.latitudeDecimalMinutes;
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
                    state.cupStyles, widget.modifiableTurnpoint.style),
                hint: Text('Select turnpoint type'),
                isExpanded: true,
                iconSize: 24,
                elevation: 16,
                onChanged: (String? description) {
                  if (description != null) {
                    widget.modifiableTurnpoint.style =
                        TurnpointUtils.getStyleFromStyleDescription(
                            state.cupStyles, description);
                  } else {
                    widget.modifiableTurnpoint.style = '0';
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

  Function _isStyleEnabled(String? description){
    return _isReadOnly ?
  }

  List<Widget> _getMenu() {
    return <Widget>[
      _isReadOnly
          ? IconButton(
              icon: Icon(Icons.edit),
              color: Colors.white,
              onPressed: () => setState(() {
                _isReadOnly = !_isReadOnly;
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                    CommonWidgets.getSnackBarForMessage(_isReadOnly
                        ? "Turnpoint in readonly mode."
                        : "Turnpoint in edit mode."));
              }),
            )
          : TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  print('Save/update turnpoint');
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

  void handleClick(String value) {
    switch (value) {
      case TurnpointEditMenu.reset:
        setState(() {
          widget.modifiableTurnpoint = widget.turnpoint;
          _isDecimalDegreesFormat = true;
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
            "www.airnav.com", "/airport/" + widget.modifiableTurnpoint.code);
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
