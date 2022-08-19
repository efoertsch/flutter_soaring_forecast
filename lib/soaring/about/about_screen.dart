import 'dart:io';

import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:email_launcher/email_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  TextEditingController textEditingController = TextEditingController();

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
    return SafeArea(
      child: Scaffold(
        appBar: getAppBar(),
        body: _getBody(),
      ),
    );
  }

  AppBar getAppBar() {
    return AppBar(
      title: Text("About"),
      leading: CommonWidgets.backArrowToHomeScreen(),
      //  actions: _getAppBarMenu(),
    );
  }

  Widget _getBody() {
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
                onLinkTap: (reference, _, __, ___) {
                  _sendFeedback();
                },
              ),
            ); // snapshot.data  :- get your object which is pass from your downloadData() function
        }
      },
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    textEditingController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop();
    return true;
  }

  Future<String> _loadAboutHtml() async {
    return rootBundle.loadString('assets/html/about.html');
  }

  void _sendFeedback() {
    CommonWidgets.displayTextInputDialog(
        context: context,
        title: "SoaringForecast Feedback",
        inputHintText: "Please enter your feedback",
        textEditingController: textEditingController,
        button1Text: "Cancel",
        button1Function: () {
          Navigator.pop(context);
        },
        button2Text: "Submit",
        button2Function: () => _sendEmail());
  }

  Future<void> _sendEmail() async {
    final feedback = textEditingController.text;
    if (feedback.isNotEmpty) {
      print("Send email");
      Email email = Email(
          //to: ['flightservice@soaringforecast.org'],
          to: ['ericfoertsch@gmail.com'],
          subject: 'SoaringForecast iOS version feedback',
          body: feedback);
      await EmailLauncher.launch(email);
    }
  }
}
