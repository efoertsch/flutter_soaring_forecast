import 'dart:io';

import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show FEEDBACK_EMAIL_ADDRESS, Feedback;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/web_launcher.dart';

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
      title: Text("About"),
      leading: BackButton(onPressed: () => Navigator.pop(context)),
      //  actions: _getAppBarMenu(),
    );
  }

  Widget _getBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [_displayVersion(), _getAboutText()],
    );
  }

  Widget _displayVersion() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: _getVersionText(),
    );
  }

  FutureBuilder<PackageInfo> _getVersionText() {
    return FutureBuilder<PackageInfo>(
        future: _queryPackageInfo(),
        builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Text('Please wait, its loading...'));
          } else {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final PackageInfo? packageInfo = snapshot.data;
              if (packageInfo != null) {
                String version = packageInfo.version;
                String buildNumber = packageInfo.buildNumber;
                return Text("Version: ${version}  Build: ${buildNumber}",
                    style: Theme.of(context).textTheme.titleMedium);
              } else {
                return Center(child: Text('Error: could not get build info'));
              }
            }
          }
        });
  }

  Future<PackageInfo> _queryPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo;
  }

  FutureBuilder<String> _getAboutText() {
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
                onLinkTap: (url, _, __, )  async {
                  if (url!.isNotEmpty) {
                    if (url.contains("privacy-policy")) {
                      // yeah - hack just to use this launcher
                      launchWebBrowser("soaringforecast.org","privacy-policy");
                    } else if (url.startsWith("mailto")) {
                      String subject = Feedback.FEEDBACK_TITLE +
                          ' - ' +
                          Platform.operatingSystem;
                      final Uri emailLaunchUri = Uri(
                        scheme: 'mailto',
                        path: FEEDBACK_EMAIL_ADDRESS,
                        query:
                          'subject= ${subject}',
                      );

                      if (await canLaunchUrl(emailLaunchUri)) {
                        await launchUrl(emailLaunchUri);
                      } else {
                        print('Could not launch $emailLaunchUri');
                      }
                    }
                  };
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
}
