import 'dart:io';

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
import 'package:latlong2/latlong.dart';

import '../../app/web_launcher.dart';
import '../../email_sender/email_sender.dart' show EmailDetails;
import '../../local_forecast/data/local_forecast_favorite.dart';
import '../bloc/rasp_bloc.dart';

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
  late final Future<bool> _getSkySightVisibilitySetting =
      RepositoryProvider.of<Repository>(context)
          .getGenericBool(key: "DISPLAY_SKYSIGHT", defaultValue: true);
  late final Future<bool> _getDrJacksVisibilitySetting =
      RepositoryProvider.of<Repository>(context)
          .getGenericBool(key: "DISPLAY_DRJACKS", defaultValue: true);
  late final Future<LocalForecastFavorite?> _getLocalForecastFavorite =
      RepositoryProvider.of<Repository>(widget.context)
          .getLocateForecastFavorite();

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
          _getOptionalWidget(
              _getLocalForecastFavorite, _getLocalForecastFavoriteWidget),
          _getOptionalWidget(_getWindyVisibilitySetting, _getWindyMenuWidget),
          _getOptionalWidget(
              _getSkySightVisibilitySetting, _getSkySightMenuWidget),
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
            title: Text(DrawerLiterals.GOES_NE),
            onTap: () {
              Navigator.popAndPushNamed(context, GoesRouteBuilder.routeName);
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
            title: Text(DrawerLiterals.GLIDER_POLARS),
            onTap: () {
              Navigator.popAndPushNamed(
                  context, GliderPolarListBuilder.routeName);
            },
          ),
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
              await sendEmail();
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

  Future<void> sendEmail() async {

    EmailDetails emailDetails = EmailDetails(title: "Feedback"
        ,subject: Feedback.FEEDBACK_TITLE +
            ' - ' + Platform.operatingSystem
        , recipients: FEEDBACK_EMAIL_ADDRESS);
    await Navigator.pushNamed(context, SendEmailRouteBuilder.routeName,  arguments:emailDetails);

  }

  static Widget _getDivider() {
    return Divider(
      height: 4,
      thickness: 2,
    );
  }

  Widget _getLocalForecastFavoriteWidget(
      LocalForecastFavorite? localForecastFavorite) {
    if (localForecastFavorite != null) {
      return BlocBuilder<RaspDataBloc, RaspDataState>(
          builder: (context, state) {
        return ListTile(
            title: Text(
                "${localForecastFavorite.turnpointName} (${localForecastFavorite.turnpointCode}) Forecast"),
            onTap: () async {
              Navigator.pop(context);
              _sendEvent(DisplayLocalForecastEvent(
                  latLng: LatLng(
                      localForecastFavorite.lat, localForecastFavorite.lng),
                  turnpointName: localForecastFavorite.turnpointName,
                  turnpointCode: localForecastFavorite.turnpointCode,
                  forTask: false));
            });
      });
    }
    return SizedBox.shrink();
  }

  Widget _getWindyMenuWidget(bool? visible) {
    if (visible != null && visible) {
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
    return SizedBox.shrink();
  }

  Widget _getSkySightMenuWidget(bool? visible) {
    if (visible != null && visible) {
      return ListTile(
        title: Text(DrawerLiterals.SKYSIGHT),
        onTap: () async {
          await launchWebBrowser("skysight.io", "");
          Navigator.pop(context);
        },
      );
    }
    return SizedBox.shrink();
  }

  Widget _getDrJacksMenuWidget(bool? visible) {
    if (visible != null && visible) {
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
    return SizedBox.shrink();
  }

  FutureBuilder<dynamic> _getOptionalWidget(
    Future<dynamic> futureFunction,
    Function menuWidget,
  ) {
    return FutureBuilder<dynamic>(
      future: futureFunction, // a previously-obtained Future<String> or null
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        List<Widget> children = <Widget>[];
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasData) {
          return SizedBox.shrink();
        }
        if (snapshot.hasData) {
          children.add(menuWidget(snapshot.data));
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

  void _sendEvent(RaspDataEvent event) {
    BlocProvider.of<RaspDataBloc>(context).add(event);
  }
}
