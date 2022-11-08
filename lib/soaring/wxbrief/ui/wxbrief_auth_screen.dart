import 'dart:io';

import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:email_launcher/email_launcher.dart';
import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show FEEDBACK_EMAIL_ADDRESS, Feedback;

class WxBriefAuthScreen extends StatefulWidget {
  WxBriefAuthScreen({Key? key}) : super(key: key);

  @override
  _WxBriefAuthScreenState createState() => _WxBriefAuthScreenState();
}

class _WxBriefAuthScreenState extends State<WxBriefAuthScreen> {
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
      title: Text("Briefing Authorization"),
      leading: BackButton(onPressed: () => Navigator.pop(context)),
      //  actions: _getAppBarMenu(),
    );
  }

  Widget _getBody() {
    return Stack(children: [
      _getWxBriefAuth(),
      Positioned(
        bottom: 0,
        left: 8,
        right: 8,
        child: Row(
          children: [_getCancelButton(), _getContinueButton()],
        ),
      ),
    ]);
  }

  FutureBuilder<String> _getWxBriefAuth() {
    return FutureBuilder<String>(
      future: _loadAboutHtml(),
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
                  Email email = Email(
                    //to: ['flightservice@soaringforecast.org'],
                    to: [FEEDBACK_EMAIL_ADDRESS],
                    subject: Feedback.FEEDBACK_TITLE +
                        " - " +
                        Platform.operatingSystem,
                  );
                  await EmailLauncher.launch(email);
                },
              ),
            ); // snapshot.data  :- get your object which is pass from your downloadData() function
        }
      },
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop();
    return true;
  }

  Future<String> _loadAboutHtml() async {
    return rootBundle.loadString('assets/html/wx_brief_disclaimer.html');
  }

  Widget _getCancelButton() {
    return TextButton(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.pop(context, "Cancel");
        });
  }

  Widget _getContinueButton() {
    return TextButton(
        child: Text("Continue"),
        onPressed: () {
          Navigator.pop(context, "Continue");
        });
  }
}
