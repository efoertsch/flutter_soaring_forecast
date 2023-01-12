import 'dart:io';

import 'package:email_launcher/email_launcher.dart';
import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show
        DrawerLiterals,
        FEEDBACK_EMAIL_ADDRESS,
        Feedback,
        WxBriefBriefingRequest;
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';

import 'web_launcher.dart';

class AppDrawerWidget extends StatefulWidget {
  final Function? refreshTaskDisplayFunction;
  final BuildContext context;

  AppDrawerWidget(
      {Key? key,
      required BuildContext this.context,
      Function? this.refreshTaskDisplayFunction})
      : super(key: key);

  @override
  _AppDrawerWidgetState createState() => _AppDrawerWidgetState();
}

class _AppDrawerWidgetState extends State<AppDrawerWidget> {
  // Hmm. Perhaps too clever by half. Keys must match those in the settings.json file
  late final Future<bool> _getWindyVisibilitySetting =
      RepositoryProvider.of<Repository>(widget.context)
          .getGenericBool(key: "DISPLAY_WINDY", defaultValue: true);
  late final Future<bool> _geSkySightVisibilitySetting =
      RepositoryProvider.of<Repository>(context)
          .getGenericBool(key: "DISPLAY_SKYSIGHT", defaultValue: true);
  late final Future<bool> _getDrJacksVisibilitySetting =
      RepositoryProvider.of<Repository>(context)
          .getGenericBool(key: "DISPLAY_DRJACKS", defaultValue: true);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
// Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: <Widget>[
          new SizedBox(
            height: 80.0,
            child: DrawerHeader(
              child: Container(
                alignment: Alignment.bottomLeft,
                child: Text(
                  DrawerLiterals.SOARING_FORECAST,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
          ),
          ListTile(
              title: Text(
            DrawerLiterals.OTHER_FORECASTS,
            style: TextStyle(
              color: Colors.black54,
            ),
          )),
          _getOptionalWidget(_getWindyVisibilitySetting, _getWindyMenuWidget),
          _getOptionalWidget(
              _geSkySightVisibilitySetting, _getSkySightMenuWidget),
          _getOptionalWidget(
              _getDrJacksVisibilitySetting, _getDrJacksMenuWidget),
          _getDivider(),
          ListTile(
              title: Text(
            DrawerLiterals.ONE_800_WX_BRIEF,
            style: TextStyle(
              color: Colors.black54,
            ),
          )),
          ListTile(
              title: Text(DrawerLiterals.AREA_BRIEF),
              onTap: () {
                Navigator.popAndPushNamed(
                    context, WxBriefRequestBuilder.routeName,
                    arguments: WxBriefBriefingRequest.AREA_REQUEST);
              }),
          ListTile(
              title: Text(DrawerLiterals.AIRPORT_METAR_TAF),
              onTap: () {
                Navigator.popAndPushNamed(
                    context, AirportMetarTafRouteBuilder.routeName);
              }),
          Divider(
            height: 4,
            thickness: 2,
          ),
          ListTile(
            title: Text(DrawerLiterals.GEOS_NE),
            onTap: () {
              Navigator.popAndPushNamed(context, GeosRouteBuilder.routeName);
            },
          ),
          _getDivider(),
          ListTile(
              title: Text(
            DrawerLiterals.CUSTOMIZATION,
            style: TextStyle(
              color: Colors.black54,
            ),
          )),
          ListTile(
            title: Text(DrawerLiterals.TASK_LIST),
            onTap: () {
              Navigator.popAndPushNamed(
                  context, TaskListRouteBuilder.routeName);
            },
          ),
          ListTile(
              title: Text(DrawerLiterals.TURNPOINTS),
              onTap: () {
                Navigator.popAndPushNamed(
                    context, TurnpointListRouteBuilder.routeName);
              }),
          ListTile(
            title: Text(DrawerLiterals.SETTINGS),
            onTap: () {
              Navigator.popAndPushNamed(
                  context, SettingsRouteBuilder.routeName);
            },
          ),
          _getDivider(),
          ListTile(
            title: Text(DrawerLiterals.FEEDBACK),
            onTap: () async {
              Email email = Email(
                //to: ['flightservice@soaringforecast.org'],
                to: [FEEDBACK_EMAIL_ADDRESS],
                subject:
                    Feedback.FEEDBACK_TITLE + " - " + Platform.operatingSystem,
              );
              await EmailLauncher.launch(email);
            },
          ),
          ListTile(
            title: Text(DrawerLiterals.ABOUT),
            onTap: () async {
              Navigator.popAndPushNamed(
                  context, AboutInfoRouteBuilder.routeName);
            },
          ),
        ],
      ),
    );
  }

  static Widget _getDivider() {
    return Divider(
      height: 4,
      thickness: 2,
    );
  }

  Widget _getWindyMenuWidget() {
    return ListTile(
      title: Text(DrawerLiterals.WINDY),
      onTap: () async {
        var possibleTaskChange = await Navigator.popAndPushNamed(
            context, WindyRouteBuilder.routeName);
        if (widget.refreshTaskDisplayFunction != null &&
            possibleTaskChange != null &&
            (possibleTaskChange is bool)) {
          widget.refreshTaskDisplayFunction!(possibleTaskChange);
        }
      },
    );
  }

  Widget _getSkySightMenuWidget() {
    return ListTile(
      title: Text(DrawerLiterals.SKYSIGHT),
      onTap: () async {
        await launchWebBrowser("skysight.io", "");
        Navigator.pop(context);
      },
    );
  }

  Widget _getDrJacksMenuWidget() {
    return ListTile(
      title: Text(DrawerLiterals.DR_JACKS),
      onTap: () async {
        Navigator.pop(context);
        launchWebBrowser("www.drjack.info", "BLIP/univiewer.html",
            useHttp: true);
        // _launchWebBrowser("http://www.drjack.info/BLIP/univiewer.html");
      },
    );
  }

  FutureBuilder<bool> _getOptionalWidget(
    Future<bool> futureFunction,
    Function menuWidget,
  ) {
    return FutureBuilder<bool>(
      future: futureFunction, // a previously-obtained Future<String> or null
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        List<Widget> children = <Widget>[];
        if (snapshot.hasData) {
          children.add(snapshot.data! ? menuWidget() : SizedBox.shrink());
        } else if (snapshot.hasError) {
          children = <Widget>[
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Error: ${snapshot.error}'),
            ),
          ];
        } else {
          children = const <Widget>[
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Awaiting result...'),
            ),
          ];
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        );
      },
    );
  }
}
