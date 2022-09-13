import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/windy/bloc/windy_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/windy/bloc/windy_event.dart';
import 'package:flutter_soaring_forecast/soaring/windy/bloc/windy_state.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_altitude.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_layer.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_model.dart';

class WindyForecast extends StatefulWidget {
  WindyForecast({Key? key}) : super(key: key);

  @override
  WindyForecastState createState() => WindyForecastState();
}

class WindyForecastState extends State<WindyForecast>
    with AfterLayoutMixin<WindyForecast> {
  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  // Make sure first layout occurs prior to map ready otherwise crash occurs
  @override
  void afterFirstLayout(BuildContext context) {
    _sendEvent(WindyInitEvent());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: _getAppBar(),
        body: _getBody(),
      ),
    );
  }

  AppBar _getAppBar() {
    return AppBar(
      title: Text('Windy'),
      leading: BackButton(
        onPressed: () => Navigator.pop(context),
      ),
      actions: _getWindyMenu(),
    );
  }

  Widget _getBody() {
    return Column(children: [
      _getDropDownOptions(),
      _getWindyWebView(),
      _getWindyListener(),
    ]);
  }

  _getDropDownOptions() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _getWindyModelDropDown(),
          _getWindyLayerDropdown(),
          _getWindyAltitude(),
        ],
      ),
    );
  }

  List<Widget> _getWindyMenu() {
    return <Widget>[
      TextButton(
        child: const Text('SELECT TASK', style: TextStyle(color: Colors.white)),
        onPressed: () {
          _selectTask();
        },
      ),
      PopupMenuButton<String>(
        onSelected: handleClick,
        icon: Icon(Icons.more_vert),
        itemBuilder: (BuildContext context) {
          return {
            WindyMenu.TopoMap,
          }.map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
      ),
    ];
  }

  void handleClick(String value) async {
    switch (value) {
      case WindyMenu.clearTask:
        // TODO display TopoMap if checked
        break;
      case WindyMenu.TopoMap:
        // TODO display TopoMap if checked
        break;
    }
  }

  bool displayTopoMap(bool checked) {
    if (checked) {
      //TODO return to base windy map
      //  setCommand(JAVASCRIPT_START + "setBaseLayerToDefault()");
      return false;
    } else {
      //  setCommand(JAVASCRIPT_START + "setBaseLayerToArcGisMap()");
      return true;
    }
  }

  Widget _getWindyWebView() {
    return Expanded(
      child: InAppWebView(
        onWebViewCreated: (controller) {
          webViewController = controller;
          webViewController!.loadFile(assetFilePath: 'assets/html/windy.html');
        },
        navigationDelegate: (navigation) {
          final host = Uri.parse(navigation.url).host;
          if (!navigation.url.startsWith("file:") &&
              !host.contains('windy.com')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Blocking navigation to $host',
                ),
              ),
            );
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        javascriptMode: JavascriptMode.unrestricted,
        javascriptChannels: _createJavascriptChannels(context),
      ),
    );
  }

  Widget _getWindyListener() {
    return BlocListener<WindyBloc, WindyState>(listener: (context, state) {
      if (state is WindyHtmlState) {
        _loadCustomWindyHTML(state.html);
      }
    });
  }

  Widget _getWindyModelDropDown() {
    return Expanded(
      flex: 2,
      child: BlocBuilder<WindyBloc, WindyState>(buildWhen: (previous, current) {
        return current is WindyLoadingState || current is WindyModelListState;
      }, builder: (context, state) {
        //print('creating/updating forecastDatesDropDown');
        if (state is WindyModelListState) {
          final List<WindyModel> models = state.models;
          return DropdownButton<WindyModel>(
            style: CustomStyle.bold18(context),
            value: (models[0]),
            hint: Text('Select Model'),
            isExpanded: true,
            iconSize: 24,
            elevation: 16,
            onChanged: (WindyModel? newValue) {
              // print('Selected model onChanged: $newValue');
              _sendEvent(WindyModelEvent(newValue!));
            },
            items: models.map<DropdownMenuItem<WindyModel>>((WindyModel value) {
              return DropdownMenuItem<WindyModel>(
                value: value,
                child: Text(value.name),
              );
            }).toList(),
          );
        } else {
          return Text("Getting Models");
        }
      }),
    );
  }

  Widget _getWindyLayerDropdown() {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: EdgeInsets.only(left: 16.0),
        child:
            BlocBuilder<WindyBloc, WindyState>(buildWhen: (previous, current) {
          return current is WindyLoadingState || current is WindyLayerListState;
        }, builder: (context, state) {
          //print('creating/updating forecastDatesDropDown');
          if (state is WindyLayerListState) {
            final List<WindyLayer> layers = state.layers;
            return DropdownButton<WindyLayer>(
              style: CustomStyle.bold18(context),
              value: (layers[0]),
              hint: Text('Select Model'),
              isExpanded: true,
              iconSize: 24,
              elevation: 16,
              onChanged: (WindyLayer? newValue) {
                // print('Selected model onChanged: $newValue');
                _sendEvent(WindyLayerEvent(newValue!));
              },
              items:
                  layers.map<DropdownMenuItem<WindyLayer>>((WindyLayer value) {
                return DropdownMenuItem<WindyLayer>(
                  value: value,
                  child: Text(value.name),
                );
              }).toList(),
            );
          } else {
            return Text("Getting Layers");
          }
        }),
      ),
    );
  }

  Widget _getWindyAltitude() {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: EdgeInsets.only(left: 16.0),
        child:
            BlocBuilder<WindyBloc, WindyState>(buildWhen: (previous, current) {
          return current is WindyLoadingState ||
              current is WindyAltitudeListState;
        }, builder: (context, state) {
          //print('creating/updating forecastDatesDropDown');
          if (state is WindyAltitudeListState) {
            final List<WindyAltitude> altitudes = state.altitudes;
            return DropdownButton<WindyAltitude>(
              style: CustomStyle.bold18(context),
              value: (altitudes[0]),
              hint: Text('Select Altitude'),
              isExpanded: true,
              iconSize: 24,
              elevation: 16,
              onChanged: (WindyAltitude? newValue) {
                _sendEvent(WindyAltitudeEvent(newValue!));
              },
              items: altitudes
                  .map<DropdownMenuItem<WindyAltitude>>((WindyAltitude value) {
                return DropdownMenuItem<WindyAltitude>(
                  value: value,
                  child: Text(value.imperial.toUpperCase()),
                );
              }).toList(),
            );
          } else {
            return Text("Getting Alitudes");
          }
        }),
      ),
    );
  }

  Future<void> _returnJavaScriptResult(WebViewController controller) async {
    final userAgent =
        await controller.runJavascriptReturningResult('navigator.userAgent');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(userAgent),
    ));
  }

  Set<JavascriptChannel> _createJavascriptChannels(BuildContext context) {
    return {
      JavascriptChannel(
        name: 'Print',
        onMessageReceived: (message) {
          print(message.message);
          // ScaffoldMessenger.of(context)
          //     .showSnackBar(SnackBar(content: Text(message.message)));
        },
      ),
    };
  }

  void _selectTask() {}

  void _sendEvent(WindyEvent event) {
    BlocProvider.of<WindyBloc>(context).add(event);
  }

  void _loadCustomWindyHTML(String html) {
    (widget.webViewController as WebViewController)
        .loloadHtmlString(html, baseUrl: 'windy.com');
  }
}
