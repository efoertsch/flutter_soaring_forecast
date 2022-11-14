import 'dart:io';

import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show StandardLiterals, WxBriefLiterals;
import 'package:flutter_soaring_forecast/soaring/app/web_launcher.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/bloc/wxbrief_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/bloc/wxbrief_event.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/bloc/wxbrief_state.dart';

class WxBriefAuthScreen extends StatefulWidget {
  WxBriefAuthScreen({Key? key}) : super(key: key);

  @override
  _WxBriefAuthScreenState createState() => _WxBriefAuthScreenState();
}

class _WxBriefAuthScreenState extends State<WxBriefAuthScreen> {
  bool _doNotShowAgain = false;

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
      title: Text(WxBriefLiterals.WXBRIEF_AUTHORIZATION),
      leading: BackButton(onPressed: () => Navigator.pop(context)),
      //  actions: _getAppBarMenu(),
    );
  }

  Widget _getBody() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
      child: Stack(children: [
        CustomScrollView(slivers: <Widget>[
          SliverList(
            delegate: SliverChildListDelegate(
              [_getWxBriefAuth(), _getDoNotShowAgainCheckbox()],
            ),
          ),
          SliverFillRemaining(
              hasScrollBody: false, child: _getContinueButton()),
        ])
      ]),
    );
  }

  FutureBuilder<String> _getWxBriefAuth() {
    return FutureBuilder<String>(
      future: _loadWxBriefAuthHtml(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Text('Please wait, its loading...'));
        } else {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          else
            return SingleChildScrollView(
              child: Html(
                data: snapshot.data,
                onLinkTap: (reference, _, __, ___) async {
                  launchWebBrowser(reference!, "", launchAsExternal: true);
                },
              ),
            );
        }
      },
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop();
    return true;
  }

  Future<String> _loadWxBriefAuthHtml() async {
    return rootBundle
        .loadString('assets/html/wx_brief_authorization_help.html');
  }

  Widget _getCancelButton() {
    return TextButton(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.pop(context, "Cancel");
        });
  }

  _getCancelContinue(String result) {
    Navigator.pop(context, result);
  }

  Widget _getContinueButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: TextButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity,
              40), // double.infinity is the width and 30 is the height
          foregroundColor: Colors.white,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        onPressed: () {
          Navigator.pop(context, StandardLiterals.CONTINUE);
        },
        child: Text(StandardLiterals.CONTINUE),
      ),
    );
  }

  Widget _getDoNotShowAgainCheckbox() {
    return BlocConsumer<WxBriefBloc, WxBriefState>(listener: (context, state) {
      if (state is WxBriefShowAuthScreenState) {
        _doNotShowAgain = !state.showAuthScreen;
      }
    }, builder: (context, state) {
      return Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(WxBriefLiterals.DO_NOT_SHOW_THIS_AGAIN),
          value: _doNotShowAgain,
          onChanged: (newValue) {
            setState(() {
              _doNotShowAgain = newValue!;
              _sendEvent(SetWxBriefDisplayAuthScreenEvent(!newValue!));
            });
          },
        ),
      );
    });
  }

  void _sendEvent(WxBriefEvent event) {
    BlocProvider.of<WxBriefBloc>(context).add(event);
  }
}
