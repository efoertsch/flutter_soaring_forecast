import 'dart:async';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show WxBriefLiterals, WxBriefFormat;
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/bloc/wxbrief_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/bloc/wxbrief_event.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/bloc/wxbrief_state.dart';

class WxBriefNotams extends StatefulWidget {
  WxBriefNotams({Key? key}) : super(key: key);

  @override
  _WxBriefNotamsState createState() => _WxBriefNotamsState();
}

class _WxBriefNotamsState extends State<WxBriefNotams>
    with AfterLayoutMixin<WxBriefNotams> {
  var _formKey = GlobalKey<FormState>();
  WxBriefFormat _selectedWxBriefFormat = WxBriefFormat.PDF;
  List<WxBriefFormat> _dropDownWxBriefFormatList = WxBriefFormat.values;
  String _accountName = "";
  String _aircraftRegistration = "";

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {
    _sendEvent(WxBriefGetTaskDetailsEvent());
  }

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

  Widget _buildSafeArea(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: getAppBar(context),
        body: _getBody(),
      ),
    );
  }

  AppBar getAppBar(BuildContext context) {
    return AppBar(
      title: Text("NOTAMS Briefing"),
      leading: BackButton(onPressed: () => Navigator.pop(context)),
      //  actions: _getAppBarMenu(),
    );
  }

  Widget _getBody() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
      child: CustomScrollView(slivers: <Widget>[
        SliverList(
          delegate: SliverChildListDelegate([
            _getTaskTitleWidget(),
            _getNOTAMAbbrevBriefText(),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _getAircraftRegistrion(),
                  _getWxBriefAccountName(),
                ],
              ),
            ),
            _getBriefingFormat()
          ]),
        ),
        SliverFillRemaining(
            hasScrollBody: false, child: _getCancelContinueWidgets()),
      ]),
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop();
    return true;
  }

  Widget _getTaskTitleWidget() {
    return BlocConsumer<WxBriefBloc, WxBriefState>(
        listener: (context, state) {},
        buildWhen: (previous, current) {
          return current is WxBriefInitialState ||
              current is WxBriefTaskTitleState;
        },
        builder: (context, state) {
          if (state is WxBriefInitialState) {
            return CommonWidgets.buildLoading();
          }
          if (state is WxBriefTaskTitleState) {
            return _taskTitleWidget(state.taskName, state.turnpointIds);
          }
          return Text('Undefined state');
        });
  }

  Widget _taskTitleWidget(
      final String taskName, final List<String> turnpointIds) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              taskName,
              style: textStyleBoldBlackFontSize24,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              turnpointIds.join(" "),
              style: textStyleBlackFontSize16,
            ),
          ),
        )
      ],
    );
  }

  Widget _getNOTAMAbbrevBriefText() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Text(
            "NOTAMS Abbreviated Brief",
            style: textStyleBlackFontSize16,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: IconButton(
              icon: Icon(Icons.info),
              color: Colors.blue,
              onPressed: () {
                CommonWidgets.showInfoDialog(
                    context: context,
                    title: WxBriefLiterals.NOTAMS_BRIEFING,
                    msg: WxBriefLiterals.WXBRIEF_NOTAMS_ABBREV_BRIEF_INFO,
                    button1Text: WxBriefLiterals.CLOSE,
                    button1Function: _cancel);
              },
            ),
          )
        ],
      ),
    );
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  Widget _getAircraftRegistrion() {
    return BlocConsumer<WxBriefBloc, WxBriefState>(listener: (context, state) {
      if (state is WxBriefDefaultsState) {
        _accountName = state.wxBriefDefaults.wxBriefAccountName;
      }
    }, buildWhen: (previous, current) {
      return current is WxBriefInitialState || current is WxBriefDefaultsState;
    }, builder: (context, state) {
      if (state is WxBriefInitialState) {
        return CommonWidgets.buildLoading();
      }
      if (state is WxBriefDefaultsState) {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: TextFormField(
              initialValue: _accountName,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Aircraft Registration',
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value != null && value.length > 3) {
                  _aircraftRegistration = value;
                  return null;
                } else {
                  return "Invalid aircraft registration";
                }
              }),
        );
      }
      ;
      return Text('Undefined state');
    });
  }

  Widget _getWxBriefAccountName() {
    return BlocConsumer<WxBriefBloc, WxBriefState>(listener: (context, state) {
      if (state is WxBriefDefaultsState) {
        _aircraftRegistration = state.wxBriefDefaults.aircraftRegistration;
      }
    }, buildWhen: (previous, current) {
      return current is WxBriefInitialState || current is WxBriefDefaultsState;
    }, builder: (context, state) {
      if (state is WxBriefInitialState) {
        return CommonWidgets.buildLoading();
      }
      if (state is WxBriefDefaultsState) {
        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: TextFormField(
              initialValue: _aircraftRegistration,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '1800WxBrief Account Name',
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value != null &&
                    value.length > 3 &&
                    EmailValidator.validate(value)) {
                  _accountName = value;
                  return null;
                } else {
                  return "Invalid aircraft registration";
                }
              }),
        );
      }
      ;
      return Text('Undefined state');
    });
  }

  Widget _getBriefingFormat() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          children: [
            Text('BriefingFormat'),
            _getBriefingFormatDropDown(),
          ],
        ),
      ),
    );
  }

  Widget _getBriefingFormatDropDown() {
    return DropdownButton<WxBriefFormat>(
      value: _selectedWxBriefFormat,
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      style: const TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: (WxBriefFormat? value) {
        // This is called when the user selects an item.
        setState(() {
          _selectedWxBriefFormat = value!;
        });
      },
      items: _dropDownWxBriefFormatList
          .map<DropdownMenuItem<WxBriefFormat>>((WxBriefFormat value) {
        return DropdownMenuItem<WxBriefFormat>(
          value: value,
          child: Text(value.option),
        );
      }).toList(),
    );
  }

  Widget _getCancelContinueWidgets() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: TextButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity,
                    40), // double.infinity is the width and 30 is the height
                onPrimary: Colors.white,
                primary: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                _cancel();
              },
              child: const Text(WxBriefLiterals.CANCEL),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: TextButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity,
                      40), // double.infinity is the width and 30 is the height
                  onPrimary: Colors.white,
                  primary: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  _submit();
                },
                child: const Text(WxBriefLiterals.SUBMIT),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendEvent(WxBriefEvent event) {
    BlocProvider.of<WxBriefBloc>(context).add(event);
  }

  void _submit() {
    _sendEvent(WxBriefGetNotamsEvent(
        aircraftRegistration: _aircraftRegistration,
        accountName: _accountName,
        wxBriefFormat: _selectedWxBriefFormat));
  }
}
