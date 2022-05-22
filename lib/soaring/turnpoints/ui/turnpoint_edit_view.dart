import 'dart:io';

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

class TurnpointEditView extends StatefulWidget {
  final Turnpoint turnpoint;
  late final Turnpoint modifiableTurnpoint;

  TurnpointEditView({Key? key, required this.turnpoint}) : super(key: key) {
    modifiableTurnpoint = turnpoint.clone();
  }

  @override
  State<TurnpointEditView> createState() => _TurnpointEditViewState();
}

class _TurnpointEditViewState extends State<TurnpointEditView> {
  final _formKey = GlobalKey<FormState>();

  bool isReadOnly = true;
  bool isDecimalDegreesFormat = true;
  List<Style> cupStyles = [];

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
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 8, right: 8),
            child: TextFormField(
              readOnly: isReadOnly,
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
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              readOnly:
                  isReadOnly || widget.modifiableTurnpoint.code.isNotEmpty,
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
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              readOnly: isReadOnly,
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
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    readOnly: isReadOnly,
                    initialValue: isDecimalDegreesFormat
                        ? widget.modifiableTurnpoint.latitudeDeg
                            .toStringAsFixed(5)
                        : TurnpointUtils.getLatitudeInCupFormat(
                            widget.turnpoint.latitudeDeg),
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: isDecimalDegreesFormat
                            ? TurnpointEditText.latitudeDecimalDegrees
                            : TurnpointEditText.latitudeDecimalMinutes,
                        labelText: isDecimalDegreesFormat
                            ? TurnpointEditText.latitudeDecimalDegrees
                            : TurnpointEditText.latitudeDecimalMinutes),
                    onChanged: (text) {
                      widget.modifiableTurnpoint.latitudeDeg =
                          double.parse(text);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    readOnly: isReadOnly,
                    initialValue: isDecimalDegreesFormat
                        ? widget.modifiableTurnpoint.longitudeDeg
                            .toStringAsFixed(5)
                        : TurnpointUtils.getLongitudeInCupFormat(
                            widget.turnpoint.longitudeDeg),
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: isDecimalDegreesFormat
                            ? TurnpointEditText.longitudeDecimalDegrees
                            : TurnpointEditText.longitudeDecimalMinutes,
                        labelText: isDecimalDegreesFormat
                            ? TurnpointEditText.longitudeDecimalDegrees
                            : TurnpointEditText.longitudeDecimalMinutes),
                    onChanged: (text) {
                      widget.modifiableTurnpoint.latitudeDeg =
                          double.parse(text);
                    },
                  ),
                ),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: Icon(Icons.location_searching),
                  color:
                      TurnpointUtils.getColorForTurnpointIcon(widget.turnpoint),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    TurnpointView.routeName,
                    arguments: widget.modifiableTurnpoint,
                  ),
                ),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              readOnly: isReadOnly,
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
          ),
          getCupStyleList(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              readOnly: isReadOnly,
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              readOnly: isReadOnly,
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              readOnly: isReadOnly,
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              readOnly: isReadOnly,
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              readOnly: isReadOnly,
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
          ),
        ]),
      ),
    );
  }

  Widget getCupStyleList() {
    return BlocBuilder<TurnpointBloc, TurnpointState>(
        buildWhen: (previous, current) {
      return current is TurnpointCupStyles;
    }, builder: (context, state) {
      if (state is TurnpointCupStyles) {
        cupStyles.clear();
        cupStyles.addAll(state.cupStyles);
        return DropdownButton<String>(
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
        );
      } else {
        return Container();
      }
    });
  }

  List<Widget> _getMenu() {
    return <Widget>[
      isReadOnly
          ? IconButton(
              icon: Icon(Icons.edit),
              color: Colors.white,
              onPressed: () => setState(() {
                isReadOnly = !isReadOnly;
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                    CommonWidgets.getSnackBarForMessage(isReadOnly
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
      case TurnpointEditMenu.toggleLatLongFormat:
        setState(() {
          isDecimalDegreesFormat = !isDecimalDegreesFormat;
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
