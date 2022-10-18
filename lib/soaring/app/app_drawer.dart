import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/mixin/app_feedback.dart';
import 'package:url_launcher/url_launcher.dart';

import 'web_launcher.dart';

class AppDrawer with AppFeedback {
  Widget getDrawer(BuildContext context,
      {Function? refreshTaskDisplayFunction}) {
    return Drawer(
// Add a ListView to the drawer. This ensures the user can scroll
// through the options in the drawer if there isn't enough vertical
// space to fit everything.
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
                  'SoaringForecast',
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
            'Other Forecasts',
            style: TextStyle(
              color: Colors.black54,
            ),
          )),
          ListTile(
            title: Text('Windy'),
            onTap: () async {
              var possibleTaskChange = await Navigator.popAndPushNamed(
                  context, WindyRouteBuilder.routeName);
              if (refreshTaskDisplayFunction != null &&
                  possibleTaskChange != null &&
                  (possibleTaskChange is bool)) {
                refreshTaskDisplayFunction(possibleTaskChange);
              }
            },
          ),
          ListTile(
            title: Text('SkySight'),
            onTap: () async {
              await launchWebBrowser("skysight.io", "");
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Dr Jacks'),
            onTap: () async {
              Navigator.pop(context);
              launchWebBrowser("www.drjack.info", "BLIP/univiewer.html",
                  useHttp: true);
              // _launchWebBrowser("http://www.drjack.info/BLIP/univiewer.html");
            },
          ),
          _getDivider(),
          ListTile(
              title: Text('Airport METAR/TAF'),
              onTap: () {
                Navigator.popAndPushNamed(
                    context, AirportMetarTafRouteBuilder.routeName);
              }),
          Divider(
            height: 4,
            thickness: 2,
          ),
          ListTile(
            title: Text('GEOS NE'),
            onTap: () {
              Navigator.popAndPushNamed(context, GeosRouteBuilder.routeName);
            },
          ),
          _getDivider(),
          ListTile(
              title: Text(
            'Customization',
            style: TextStyle(
              color: Colors.black54,
            ),
          )),
          ListTile(
            title: Text('Task List'),
            onTap: () {
              Navigator.popAndPushNamed(
                  context, TaskListRouteBuilder.routeName);
            },
          ),
          ListTile(
              title: Text('Turnpoints'),
              onTap: () {
                Navigator.popAndPushNamed(
                    context, TurnpointListRouteBuilder.routeName);
              }),
          ListTile(
            title: Text('Airport List'),
            onTap: () {
              Navigator.popAndPushNamed(
                  context, SelectedAirportsRouteBuilder.routeName);
            },
          ),
          _getDivider(),
          ListTile(
            title: Text('Feedback'),
            onTap: () {
              sendFeedback(context: context);
            },
          ),
          ListTile(
            title: Text('About'),
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

  static void _launchWebBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
