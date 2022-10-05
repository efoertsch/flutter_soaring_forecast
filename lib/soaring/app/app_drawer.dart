import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:url_launcher/url_launcher.dart';

import 'web_launcher.dart';

class AppDrawer {
  static Widget getDrawer(BuildContext context,
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
            height: 100.0,
            child: DrawerHeader(
              child: Text(
                'SoaringForecast',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
          ),
          ListTile(
              title: Text('Turnpoints'),
              onTap: () {
                Navigator.popAndPushNamed(
                    context, TurnpointListRouteBuilder.routeName);
              }),
          ListTile(
            title: Text('Task List'),
            onTap: () {
              Navigator.popAndPushNamed(context, TaskList.routeName);
            },
          ),
          ListTile(
            title: Text('Windy'),
            onTap: () async {
              var possibleTaskChange = await Navigator.popAndPushNamed(
                  context, WindyScreen.routeName);
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
//           ListTile(
//             title: Text('Airport METAR/TAF'),
//             onTap: () {
// // Update the state of the app
// // ...
// // Then close the drawer
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             title: Text('NOAA'),
//             onTap: () {
// // Update the state of the app
// // ...
// // Then close the drawer
//               Navigator.pop(context);
//             },
//           ),
          ListTile(
            title: Text('GEOS NE'),
            onTap: () {
              Navigator.popAndPushNamed(context, Geos.routeName);
            },
          ),
//           ListTile(
//             title: Text('Airport List'),
//             onTap: () {
// // Update the state of the app
// // ...
// // Then close the drawer
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             title: Text('Settings'),
//             onTap: () {
// // Update the state of the app
// // ...
// // Then close the drawer
//               Navigator.pop(context);
//             },
//        ),
          ListTile(
            title: Text('About'),
            onTap: () {
              Navigator.popAndPushNamed(context, AboutInfo.routeName);
            },
          ),
        ],
      ),
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
