import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer {
  static Widget getDrawer(BuildContext context) {
    return Drawer(
// Add a ListView to the drawer. This ensures the user can scroll
// through the options in the drawer if there isn't enough vertical
// space to fit everything.
      child: ListView(
// Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: <Widget>[
          new SizedBox(
            height: 120.0,
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
            title: Text('Windy'),
            onTap: () {
// Update the state of the app
// ...
// Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('SkySight'),
            onTap: () {
              _launchWebBrowser("https://skysight.io/");
            },
          ),
          ListTile(
            title: Text('Dr Jacks'),
            onTap: () {
              _launchWebBrowser("http://www.drjack.info/BLIP/univiewer.html");
            },
          ),
          ListTile(
            title: Text('Airport METAR/TAF'),
            onTap: () {
// Update the state of the app
// ...
// Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('NOAA'),
            onTap: () {
// Update the state of the app
// ...
// Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('GEOS NE'),
            onTap: () {
// Update the state of the app
// ...
// Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Airport List'),
            onTap: () {
// Update the state of the app
// ...
// Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Task List'),
            onTap: () {
// Update the state of the app
// ...
// Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Import Turnpoints'),
            onTap: () {
// Update the state of the app
// ...
// Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Settings'),
            onTap: () {
// Update the state of the app
// ...
// Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('About'),
            onTap: () {
// Update the state of the app
// ...
// Then close the drawer
              Navigator.pop(context);
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
