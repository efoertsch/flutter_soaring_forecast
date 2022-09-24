import 'dart:async';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/app/measure_size_render_object.dart';
import 'package:flutter_soaring_forecast/soaring/app/web_launcher.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/ui/task_list.dart';
import 'package:flutter_soaring_forecast/soaring/windy/bloc/windy_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/windy/bloc/windy_event.dart';
import 'package:flutter_soaring_forecast/soaring/windy/bloc/windy_state.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_altitude.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_layer.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_model.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WindyForecast extends StatefulWidget {
  WindyForecast({Key? key}) : super(key: key);

  @override
  WindyForecastState createState() => WindyForecastState();
}

class WindyForecastState extends State<WindyForecast>
    with AfterLayoutMixin<WindyForecast> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  WebViewController? _webViewController;

  int _modelIndex = 0;
  int _layerIndex = 0;
  int _altitudeIndex = 0;
  int _windyWidgetHeight = 1;
  bool topoMapChecked = false;

  bool _enabledPopUpMenu = false;

  bool _windyHtmlLoaded = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _sendEvent(WindyInitEvent());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: _getAppBar(context),
        body: _getBody(),
      ),
    );
  }

  AppBar _getAppBar(BuildContext context) {
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
      _getWindyScriptJavaScriptWidget()
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
      PopupMenuButton<bool>(
          enabled: _enabledPopUpMenu,
          itemBuilder: (context) => [
                PopupMenuItem(
                  child: InkWell(
                      child: Text("Clear Task"),
                      onTap: () {
                        _clearTask();
                        Navigator.pop(context);
                      }),
                ),
                // Can't switch maps - not sure if can't do it with new windy API
                // or a problem on my end.
                // CommonWidgets.getCheckBoxMenuItem(
                //     context: context,
                //     isChecked: topoMapChecked,
                //     menuText: "TopoMap",
                //     setStateCallBack: _toggleBaseMap),
              ]),
    ];
  }

  void _toggleBaseMap(bool isChecked) {
    topoMapChecked = isChecked;
    debugPrint("ToggleBaseMap: " + isChecked.toString());
    _sendEvent(DisplayTopoMapTypeEvent(isChecked));
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

  Widget _getWindyModelDropDown() {
    return BlocBuilder<WindyBloc, WindyState>(buildWhen: (previous, current) {
      return current is WindyLoadingState || current is WindyModelListState;
    }, builder: (context, state) {
      //debugPrint('creating/updating forecastDatesDropDown');
      if (state is WindyModelListState) {
        final List<WindyModel> models = state.models;
        return Expanded(
          flex: 2,
          child: DropdownButton<WindyModel>(
            style: CustomStyle.bold18(context),
            value: (models[_modelIndex]),
            hint: Text('Select Model'),
            isExpanded: true,
            iconSize: 24,
            elevation: 16,
            onChanged: (WindyModel? newValue) {
              setState(() {
                _modelIndex = newValue!.id;
                _sendEvent(WindyModelEvent(_modelIndex));
              });
            },
            items: models.map<DropdownMenuItem<WindyModel>>((WindyModel value) {
              return DropdownMenuItem<WindyModel>(
                value: value,
                child: Text(value.name),
              );
            }).toList(),
          ),
        );
      } else {
        return Text("Getting Models");
      }
    });
  }

  Widget _getWindyLayerDropdown() {
    return BlocBuilder<WindyBloc, WindyState>(buildWhen: (previous, current) {
      return current is WindyLoadingState || current is WindyLayerListState;
    }, builder: (context, state) {
      //debugPrint('creating/updating forecastDatesDropDown');
      if (state is WindyLayerListState) {
        final List<WindyLayer> layers = state.layers;
        return Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: DropdownButton<WindyLayer>(
              style: CustomStyle.bold18(context),
              value: (layers[_layerIndex]),
              hint: Text('Select Model'),
              isExpanded: true,
              iconSize: 24,
              elevation: 16,
              onChanged: (WindyLayer? newValue) {
                // debugPrint('Selected model onChanged: $newValue');
                setState(() {
                  _layerIndex = newValue!.id;
                  _sendEvent(WindyLayerEvent(_layerIndex));
                });
              },
              items:
                  layers.map<DropdownMenuItem<WindyLayer>>((WindyLayer value) {
                return DropdownMenuItem<WindyLayer>(
                  value: value,
                  child: Text(value.name),
                );
              }).toList(),
            ),
          ),
        );
      } else {
        return Text("Getting Layers");
      }
    });
  }

  Widget _getWindyAltitude() {
    return BlocBuilder<WindyBloc, WindyState>(buildWhen: (previous, current) {
      return current is WindyLoadingState || current is WindyAltitudeListState;
    }, builder: (context, state) {
      //debugPrint('creating/updating forecastDatesDropDown');
      if (state is WindyAltitudeListState) {
        final List<WindyAltitude> altitudes = state.altitudes;
        return Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: DropdownButton<WindyAltitude>(
              style: CustomStyle.bold18(context),
              value: (altitudes[_altitudeIndex]),
              hint: Text('Select Altitude'),
              isExpanded: true,
              iconSize: 24,
              elevation: 16,
              onChanged: (WindyAltitude? newValue) {
                setState(() {
                  _altitudeIndex = newValue!.id;
                  _sendEvent(WindyAltitudeEvent(_altitudeIndex));
                });
              },
              items: altitudes
                  .map<DropdownMenuItem<WindyAltitude>>((WindyAltitude value) {
                return DropdownMenuItem<WindyAltitude>(
                  value: value,
                  child: Text(value.imperial.toUpperCase()),
                );
              }).toList(),
            ),
          ),
        );
      } else {
        return Text("Getting Altitudes");
      }
    });
  }

  Widget _getWindyListener() {
    return BlocListener<WindyBloc, WindyState>(
      listener: (context, state) {
        if (state is WindyHtmlState && !_windyHtmlLoaded) {
          loadWindyHtml(state.html);
          debugPrint("Loading WindyHTML");
        }
        if (state is TaskDrawnState) {
          setState(() {
            _enabledPopUpMenu = state.taskDrawn;
          });
        }
      },
      child: SizedBox.shrink(),
    );
  }

  // Don't execute until webview created and webcontroller ready
  void loadWindyHtml(String html) async {
    if (!_windyHtmlLoaded) {
      await _webViewController!.loadHtmlString(html, baseUrl: "www.windy.com");
      _windyHtmlLoaded = true;
    }
  }

  Widget _getWindyWebView() {
    return BlocConsumer<WindyBloc, WindyState>(
        listener: (context, state) {},
        buildWhen: (context, state) {
          return state is WindyInitComplete;
        },
        builder: (context, state) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: MeasureSize(
                onChange: (Size size) {
                  setState(() {
                    // Need to reduce size so windy legend visible at bottom
                    _windyWidgetHeight = size.height.toInt() - 16;
                    _sendWindyWidgetHeight(
                        _webViewController, _windyWidgetHeight);
                    debugPrint(
                        "windyWidgetHeight: " + _windyWidgetHeight.toString());
                  });
                },
                child: Container(
                  height: _windyWidgetHeight.toDouble(),
                  child: WebView(
                    javascriptChannels: _getJavascriptChannels(),
                    debuggingEnabled: !kReleaseMode,
                    javascriptMode: JavascriptMode.unrestricted,
                    onWebViewCreated: (WebViewController webViewController) {
                      //_controller.complete(webViewController);
                      _webViewController = webViewController;
                      _sendWindyWidgetHeight(
                          webViewController, _windyWidgetHeight);
                    },
                    navigationDelegate: (NavigationRequest request) {
                      var url = request.url!.toString();
                      if (url.startsWith("https://www.windy.com")) {
                        launchWebBrowser("www.windy.com", "");
                        return NavigationDecision.prevent;
                      }
                      if (url.startsWith("file:") ||
                          url.contains("windy.com")) {
                        return NavigationDecision.navigate;
                      }
                      return NavigationDecision.prevent;
                    },
                  ),
                ),
              ),
            ),
          );
        });
  }

  Future<void> _sendWindyWidgetHeight(
      WebViewController? webViewController, int height) async {
    if (webViewController != null && height > 0) {
      _sendEvent(LoadWindyHTMLEvent(height));
    }
  }

  Widget _getWindyScriptJavaScriptWidget() {
    return BlocListener<WindyBloc, WindyState>(
      listenWhen: (previousState, state) {
        return (state is WindyJavaScriptState);
      },
      listener: (context, state) {
        if (state is WindyJavaScriptState) {
          runJavaScript(state.javaScript);
        }
      },
      child: SizedBox.shrink(),
    );
  }

  Future<void> runJavaScript(String javaScript) async {
    await _webViewController!.runJavascript(javaScript);
  }

  void _selectTask() async {
    final result = await Navigator.pushNamed(context, TaskList.routeName,
        arguments: TaskListScreen.SELECT_TASK_OPTION);
    if (result != null && result is int && result > -1) {
      //debugPrint('Draw task for ' + result.toString());
      _sendEvent(SelectTaskEvent(result));
    }
  }

  void _clearTask() {
    _sendEvent(ClearTaskEvent());
    setState(() {
      _enabledPopUpMenu = false;
    });
  }

  void _sendEvent(WindyEvent event) {
    BlocProvider.of<WindyBloc>(context).add(event);
  }

  Set<JavascriptChannel> _getJavascriptChannels() {
    return Set.from([
      JavascriptChannel(
          name: "print",
          onMessageReceived: (JavascriptMessage message) {
            debugPrint("debug from webview:" + message.message);
          }),
      JavascriptChannel(
          name: "htmlLoaded",
          onMessageReceived: (JavascriptMessage message) {
            debugPrint("htmlLoaded callback:" + message.message);
            _sendEvent(AssignWindyStartupParms());
          }),
      JavascriptChannel(
          name: "redrawCompleted",
          onMessageReceived: (JavascriptMessage message) {
            debugPrint("redrawCompleted");
          }),
      JavascriptChannel(
          name: "getTaskTurnpointsForMap",
          onMessageReceived: (JavascriptMessage message) {
            _sendEvent(DisplayTaskIfAnyEvent());
          }),
    ]);
  }
}
