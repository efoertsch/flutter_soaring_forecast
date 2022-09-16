import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/app/web_mixin.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_event.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/bloc/turnpoint_state.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/cup/cup_styles.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/turnpoint_utils.dart';
import 'package:flutter_soaring_forecast/soaring/turnpoints/ui/turnpoint_overhead_view.dart';
import 'package:permission_handler/permission_handler.dart';

class TurnpointEditResult {
  final TurnpointEditReturn returnResult;
  final Turnpoint turnpoint;

  TurnpointEditResult(this.returnResult, this.turnpoint);
}

class TurnpointEditView extends StatefulWidget {
  late final int? turnpointId;

  TurnpointEditView({Key? key, int? this.turnpointId = null}) : super(key: key);

  @override
  State<TurnpointEditView> createState() => _TurnpointEditViewState();
}

class _TurnpointEditViewState extends State<TurnpointEditView>
    with AfterLayoutMixin<TurnpointEditView> {
  // not making formKey final as may assign new key in case of edit/reset scenario and
  var _formKey = GlobalKey<FormState>();
  Turnpoint? turnpoint = null;
  Turnpoint? modifiableTurnpoint = null;
  bool _isReadOnly = true;
  bool _isDecimalDegreesFormat = true;
  bool _turnpointInitialized = false;
  List<CupStyle> _cupStyles = [];
  bool _needToSaveUpdates = false;
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _elevationController = TextEditingController();
  TurnpointEditReturn turnpointEditReturn = TurnpointEditReturn.noChange;

  @override
  initState() {
    // if turnpointId is null then must be adding a new turnpoint so make immediately editable
    _isReadOnly = widget.turnpointId != null;
    super.initState();
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _elevationController.dispose();
    super.dispose();
  }

  // Make sure first layout occurs
  @override
  void afterFirstLayout(BuildContext context) {
    // issuing 2 events sequentially results in one state being dropped. Don't ask me why
    // so get styles, and when that received, issue view event (in styles state handler
    BlocProvider.of<TurnpointBloc>(context).add(CupStylesEvent());
    // BlocProvider.of<TurnpointBloc>(context)
    //     .add(TurnpointViewEvent(widget.turnpointId));
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return ConditionalWillPopScope(
        onWillPop: _onWillPop,
        shouldAddCallback: true,
        child: _buildSafeArea(),
      );
    } else {
      //iOS
      return GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.direction >= 0) {
            _onWillPop();
          }
        },
        child: _buildSafeArea(),
      );
    }
  }

  Widget _buildSafeArea() {
    return SafeArea(
      child: Scaffold(
        appBar: _getAppBar(),
        body: _getBodyWidget(),
        bottomNavigationBar: null,
      ),
    );
  }

  AppBar _getAppBar() {
    return AppBar(
      title: Text(TurnpointEditText.screenTitle),
      leading: BackButton(
        onPressed: _onWillPop,
      ),
      actions: _getMenu(),
    );
  }

  Widget _getBodyWidget() {
    return BlocConsumer<TurnpointBloc, TurnpointState>(
        listener: (context, state) {
      if (state is TurnpointShortMessageState) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(state.shortMsg),
          ),
        );
      }
      if (state is TurnpointErrorState) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(state.errorMsg),
          ),
        );
      }
    }, builder: (context, state) {
      if (state is TurnpointsInitialState) {
        return CommonWidgets.buildLoading();
      }
      if (state is EditTurnpoint) {
        if (!_turnpointInitialized) {
          turnpoint = state.turnpoint;
          modifiableTurnpoint = turnpoint!.clone();
          _updateLatLongDisplayText();
          print("Processed EditTurnpoint State");
          _turnpointInitialized = true;
        }
      }
      if (state is UpdatedTurnpoint) {
        _needToSaveUpdates = false;
        turnpoint = state.turnpoint;
        modifiableTurnpoint = turnpoint!.clone();
        turnpointEditReturn = TurnpointEditReturn.tpAddedUpdated;
      }
      if (state is TurnpointDeletedState) {
        _displayTurnpointDeletedDialog();
      }
      if (state is TurnpointCupStyles) {
        print("adding cup styles");
        _cupStyles.clear();
        _cupStyles.addAll(state.cupStyles);
        // got styles now ask for turnpoint info
        BlocProvider.of<TurnpointBloc>(context)
            .add(TurnpointViewEvent(widget.turnpointId));
        return CommonWidgets.buildLoading();
      }
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
    });
  }

  Widget _getTitleWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 8, right: 8),
      child: TextFormField(
        readOnly: _isReadOnly,
        initialValue: modifiableTurnpoint?.title,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          // hintText: TurnpointEditText.waypointName,
          labelText: TurnpointEditText.waypointName,
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (value != turnpoint?.title) {
            _needToSaveUpdates = true;
          }
          if (value?.isEmpty ?? true) {
            return TurnpointEditText.enterWaypointTitle;
          }
          modifiableTurnpoint?.title = value!;
          return null;
        },
      ),
    );
  }

  Widget _getCodeWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        readOnly:
            _isReadOnly || (modifiableTurnpoint?.code.isNotEmpty ?? false),
        initialValue: modifiableTurnpoint?.code,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: TurnpointEditText.waypointCode,
          labelText: TurnpointEditText.waypointCode,
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return TurnpointEditText.turnpointCodeRequired;
          }
          modifiableTurnpoint?.code = value!;
          if (modifiableTurnpoint?.code != turnpoint?.code) {
            _needToSaveUpdates = true;
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
        initialValue: ((modifiableTurnpoint?.country ?? "").isEmpty
            ? TurnpointEditText.countryCodeDefault
            : modifiableTurnpoint?.country),
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: TurnpointEditText.countryCode,
          labelText: TurnpointEditText.countryCode,
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return TurnpointEditText.countryCodeRequired;
          }
          modifiableTurnpoint?.country = value!;
          if (modifiableTurnpoint?.country != turnpoint!.country) {
            _needToSaveUpdates = true;
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
        //initialValue: _getLatitudeInDisplayFormat(),
        decoration: InputDecoration(
            border: OutlineInputBorder(),
            //hintText: getLatitudeText(),
            labelText: _getLatitudeText()),
        controller: _latitudeController,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (_isReadOnly) {
            // just toggling lat/long format
            return null;
          }
          if (value?.isEmpty ?? true) {
            return TurnpointEditText.latitudeRequired;
          }
          if (TurnpointUtils.validateLatitude(
              value!, _isDecimalDegreesFormat)) {
            final latitude = TurnpointUtils.parseLatitudeValue(
                value, _isDecimalDegreesFormat);
            if (latitude != turnpoint?.latitudeDeg) {
              _needToSaveUpdates = true;
              modifiableTurnpoint?.latitudeDeg = latitude;
            }
          } else {
            return TurnpointEditText.latitudeInvalid;
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
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (_isReadOnly) {
            // just toggling lat/long format
            return null;
          }
          if (value?.isEmpty ?? true) {
            return TurnpointEditText.longitudeRequired;
          }
          if (TurnpointUtils.validateLongitude(
              value!, _isDecimalDegreesFormat)) {
            final longitude = TurnpointUtils.parseLongitudeValue(
                value, _isDecimalDegreesFormat);
            if (longitude != turnpoint?.longitudeDeg) {
              _needToSaveUpdates = true;
              modifiableTurnpoint?.longitudeDeg = longitude;
              if (modifiableTurnpoint?.longitudeDeg !=
                  turnpoint!.longitudeDeg) {
                _needToSaveUpdates = true;
              }
            }
          } else {
            return TurnpointEditText.longitudeInvalid;
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
        color: TurnpointUtils.getColorForTurnpointIcon(
            modifiableTurnpoint?.style ?? "0"),
        onPressed: () => _gotoOverheadView(),
      ),
    );
  }

  Future<void> _gotoOverheadView() async {
    var updatedTurnpoint = await Navigator.pushNamed(
      context,
      TurnpointView.routeName,
      arguments: TurnpointOverHeadArgs(
          isReadOnly: _isReadOnly,
          isDecimalDegreesFormat: _isDecimalDegreesFormat,
          turnpoint: modifiableTurnpoint ?? Turnpoint()),
    );
    if (!_isReadOnly && updatedTurnpoint is Turnpoint) {
      modifiableTurnpoint!.latitudeDeg = updatedTurnpoint.latitudeDeg;
      modifiableTurnpoint!.longitudeDeg = updatedTurnpoint.longitudeDeg;
      modifiableTurnpoint!.elevation = updatedTurnpoint.elevation;
      _updateLatLongDisplayText();
      // this.setState(() {
      //   // force redraw
      // });
    }
  }

  Widget _getElevationWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        readOnly: _isReadOnly,
        controller: _elevationController,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: TurnpointEditText.elevation,
          labelText: TurnpointEditText.elevation,
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return TurnpointEditText.elevationRequired;
          }
          if (!TurnpointUtils.elevationValid(value!)) {
            return TurnpointEditText.elevationInvalid;
          }
          modifiableTurnpoint?.elevation = value;
          if (modifiableTurnpoint?.elevation != turnpoint!.elevation) {
            _needToSaveUpdates = true;
          }
          return null;
        },
      ),
    );
  }

  Widget _getCupStyleListWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 8, right: 8),
      child: InputDecorator(
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          labelText: TurnpointEditText.turnpointType,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            style: CustomStyle.bold18(context),
            value: TurnpointUtils.getStyleDescriptionFromStyle(
                _cupStyles, modifiableTurnpoint?.style ?? "0"),
            hint: Text(TurnpointEditText.selectTurnpointType),
            isExpanded: true,
            iconSize: 24,
            elevation: 16,
            onChanged: _isReadOnly
                ? null
                : (String? description) {
                    if (description != null) {
                      modifiableTurnpoint?.style =
                          TurnpointUtils.getStyleFromStyleDescription(
                              _cupStyles, description);
                    } else {
                      modifiableTurnpoint?.style = '0';
                    }
                    if (modifiableTurnpoint?.style != turnpoint!.style) {
                      _needToSaveUpdates = true;
                    }
                    setState(() {});
                    // _sendEvent(context, );
                  },
            items: _cupStyles
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
  }

  Widget _getDirectionWidget() {
    return Visibility(
      visible: TurnpointUtils.isLandable(modifiableTurnpoint?.style ?? "0"),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          readOnly: _isReadOnly,
          initialValue: modifiableTurnpoint?.direction,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: TurnpointEditText.runwayDirection,
            labelText: TurnpointEditText.runwayDirection,
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            if (TurnpointUtils.isLandable(modifiableTurnpoint?.style ?? "0") &&
                (value == null || value.isEmpty)) {
              return TurnpointEditText.runwayDirectionRequired;
            }
            if (!TurnpointUtils.runwayDirectionValid(value!)) {
              return TurnpointEditText.invalidRunwayDirection;
            }
            modifiableTurnpoint?.direction = value;
            if (modifiableTurnpoint?.direction != turnpoint!.direction) {
              _needToSaveUpdates = true;
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _getRunwayLengthWidget() {
    return Visibility(
      visible: TurnpointUtils.isLandable(modifiableTurnpoint?.style ?? "0"),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          readOnly: _isReadOnly,
          initialValue: modifiableTurnpoint?.length,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: TurnpointEditText.runwayLength,
            labelText: TurnpointEditText.runwayLength,
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            if (TurnpointUtils.isLandable(modifiableTurnpoint?.style ?? "0") &&
                (value == null || value.isEmpty)) {
              return TurnpointEditText.runwayLengthRequired;
            }
            if (!TurnpointUtils.runwayLengthValid(value!)) {
              return TurnpointEditText.invalidRunwayLength;
            }
            modifiableTurnpoint?.length = value;
            if (modifiableTurnpoint?.length != turnpoint!.length) {
              _needToSaveUpdates = true;
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _getRunwayWidthWidget() {
    return Visibility(
      visible: TurnpointUtils.isLandable(modifiableTurnpoint?.style ?? "0"),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          readOnly: _isReadOnly,
          initialValue: modifiableTurnpoint?.runwayWidth,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: TurnpointEditText.runwayWidthHint,
            labelText: TurnpointEditText.runwayWidth,
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            final isLandable =
                TurnpointUtils.isLandable(modifiableTurnpoint?.style ?? "0");
            if ((!isLandable && (value == null || value.isEmpty)) ||
                (isLandable && TurnpointUtils.runwayWidthValid(value ?? ""))) {
              modifiableTurnpoint?.runwayWidth = value ?? "";
              if (modifiableTurnpoint?.runwayWidth != turnpoint!.runwayWidth) {
                _needToSaveUpdates = true;
              }
              return null;
            }
            return TurnpointEditText.invalidRunwayWidth;
          },
        ),
      ),
    );
  }

  Widget _getAirportFrequencyWidget() {
    return Visibility(
      visible: TurnpointUtils.isAirport(modifiableTurnpoint?.style),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          readOnly: _isReadOnly,
          initialValue: modifiableTurnpoint?.frequency,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            //hintText: TurnpointEditText.airportFrequency,
            labelText: TurnpointEditText.airportFrequency,
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            final isAirport =
                TurnpointUtils.isAirport(modifiableTurnpoint?.style);
            if ((!isAirport || (value?.isEmpty ?? true))) {
              modifiableTurnpoint?.frequency = "";
              return null;
            }
            if (isAirport &&
                TurnpointUtils.airportFrequencyValid(value ?? "")) {
              modifiableTurnpoint?.frequency = value!;
              return null;
            }
            if (modifiableTurnpoint?.frequency != turnpoint!.frequency) {
              _needToSaveUpdates = true;
            }
            return TurnpointEditText.invalidAirportFrequency;
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
        initialValue: modifiableTurnpoint?.description,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: TurnpointEditText.description,
          labelText: TurnpointEditText.description,
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: (text) {
          modifiableTurnpoint?.description = text;
          if (modifiableTurnpoint?.description != turnpoint!.description) {
            _needToSaveUpdates = true;
          }
        },
      ),
    );
  }

  String _getLatitudeText() {
    return _isDecimalDegreesFormat
        ? TurnpointEditText.latitudeDecimalDegrees
        : TurnpointEditText.latitudeDecimalMinutes;
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
                  _saveTurnpointEdit();
                } else {
                  _displayEditWarning();
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
          return _getMenuOptions().map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
      ),
    ];
  }

  Set<String> _getMenuOptions() {
    Set<String> menuOptions = {};
    if (!_isReadOnly) menuOptions.add(TurnpointEditMenu.reset);
    menuOptions.add(TurnpointEditMenu.toggleLatLongFormat);
    if (modifiableTurnpoint != null && modifiableTurnpoint!.code.isNotEmpty)
      menuOptions.add(TurnpointEditMenu.airNav);
    if (_isReadOnly || (!_needToSaveUpdates))
      menuOptions.add(TurnpointEditMenu.exportTurnpoint);
    if (!_isReadOnly && modifiableTurnpoint!.id != null)
      menuOptions.add(TurnpointEditMenu.deleteTurnpoint);

    return menuOptions;
  }

  void _displayEditWarning() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
        CommonWidgets.getSnackBarForMessage(
            TurnpointEditText.correctDataErrors));
    setState(() {});
  }

  void _displayEditStatus() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
        CommonWidgets.getSnackBarForMessage(_isReadOnly
            ? TurnpointEditText.turnpointInReadOnlyMode
            : TurnpointEditText.turnpointInEditMode));
    setState(() {});
  }

  void handleClick(String value) {
    switch (value) {
      case TurnpointEditMenu.reset:
        setState(() {
          _isReadOnly = true;
          modifiableTurnpoint = turnpoint!.clone();
          _isDecimalDegreesFormat = true;
          _updateLatLongDisplayText();
          _displayEditStatus();
          _formKey = GlobalKey<FormState>();
        });
        break;
      case TurnpointEditMenu.toggleLatLongFormat:
        // don't need to use setState() when using textcontrollers
        _isDecimalDegreesFormat = !_isDecimalDegreesFormat;
        _updateLatLongDisplayText();
        break;
      case TurnpointEditMenu.airNav:
        if (modifiableTurnpoint != null) {
          launchWebBrowser(
              "www.airnav.com", "/airport/" + modifiableTurnpoint!.code);
        }
        break;
      case TurnpointEditMenu.deleteTurnpoint:
        _displayConfirmDeleteDialog();
        break;
      case TurnpointEditMenu.exportTurnpoint:
        _exportTurnpoint();
        break;
    }
  }

  void _updateLatLongDisplayText() {
    _latitudeController.text = TurnpointUtils.getLatitudeInDisplayFormat(
        _isDecimalDegreesFormat, modifiableTurnpoint!.latitudeDeg);
    _longitudeController.text = TurnpointUtils.getLongitudeInDisplayFormat(
        _isDecimalDegreesFormat, modifiableTurnpoint!.longitudeDeg);
    _elevationController.text = modifiableTurnpoint!.elevation;
  }

  Future<bool> _onWillPop() async {
    // TODO check for changes
    if (_needToSaveUpdates) {
      CommonWidgets.showInfoDialog(
          context: context,
          title: "Unsaved Updates!",
          msg: "Updates will be lost. Continue?",
          button1Text: "No",
          button1Function: _dismissDialogFunction,
          button2Text: "Yes",
          button2Function: _cancelUpdateFunction);
    } else {
      Navigator.pop(
          context,
          TurnpointEditResult(
              turnpointEditReturn, modifiableTurnpoint ?? Turnpoint()));
    }
    return true;
  }

  void _dismissDialogFunction() {
    Navigator.pop(context);
  }

  void _cancelUpdateFunction() {
    Navigator.pop(context); // remove dialog
    Navigator.pop(
        context,
        TurnpointEditResult(
            turnpointEditReturn, modifiableTurnpoint ?? Turnpoint()));
  }

  void _saveTurnpointEdit() {
    print('Save/update turnpoint');
    _sendEvent(SaveTurnpointEvent(modifiableTurnpoint!));
  }

  _sendEvent(TurnpointEvent event) {
    BlocProvider.of<TurnpointBloc>(context).add(event);
  }

  void _displayConfirmDeleteDialog() {
    CommonWidgets.showInfoDialog(
        context: context,
        title: "Deleting Turnpoint!",
        msg: "Are you sure you want to do this?",
        button1Text: "No",
        button1Function: _dismissDialogFunction,
        button2Text: "Yes",
        button2Function: _deleteTurnpoint);
  }

  _deleteTurnpoint() {
    Navigator.pop(context); // remove dialog
    BlocProvider.of<TurnpointBloc>(context)
        .add(DeleteTurnpoint(modifiableTurnpoint!.id!));
  }

  void _displayTurnpointDeletedDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CommonWidgets.showInfoDialog(
          context: context,
          title: "Turnpoint Deleted",
          msg: "Turnpoint Deleted Successfully!",
          button1Text: "OK",
          button1Function: _exitAndRefreshListFunction);
    });
  }

  _exitAndRefreshListFunction() {
    _dismissDialogFunction();
    Navigator.pop(
        context,
        TurnpointEditResult(TurnpointEditReturn.tpDeleted,
            modifiableTurnpoint!)); // remove dialog
  }

  void _exportTurnpoint() async {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      // We didn't ask for permission yet or the permission has been denied before but not permanently.
      if (await Permission.storage.request().isGranted) {
        // Fire event to export turnpoints
        _sendEvent(DownloadTurnpointToFile(modifiableTurnpoint!));
      }
    }
    if (status.isPermanentlyDenied) {
      // display msg to user they need to go to settings to re-enable
      openAppSettings();
    }
    if (status.isGranted) {
      _sendEvent(DownloadTurnpointToFile(modifiableTurnpoint!));
      ;
    }
  }
}
