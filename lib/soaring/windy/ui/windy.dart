import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/tasks/ui/task_list.dart';
import 'package:flutter_soaring_forecast/soaring/windy/bloc/windy_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/windy/bloc/windy_event.dart';
import 'package:flutter_soaring_forecast/soaring/windy/bloc/windy_state.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_altitude.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_layer.dart';
import 'package:flutter_soaring_forecast/soaring/windy/data/windy_model.dart';
import 'package:latlong2/latlong.dart';

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
        javaScriptEnabled: true,
        disableHorizontalScroll: true,
        disableVerticalScroll: true,
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: false,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));
  late final String key;
  late final LatLng latLng;
  final int zoom = 7;
  var windyWidgetSize = Size.zero;
  double height = 1;

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
        // TODO clear task if checked
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
              _sendEvent(WindyModelEvent(newValue!.id));
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
                _sendEvent(WindyLayerEvent(newValue!.id));
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
                _sendEvent(WindyAltitudeEvent(newValue!.id));
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
            return Text("Getting Altitudes");
          }
        }),
      ),
    );
  }

  Widget _getWindyWebView() {
    return BlocConsumer<WindyBloc, WindyState>(listener: (context, state) {
      if (state is WindyKeyState) {
        key = state.key;
      }
      if (state is WindyLatLngState) {
        latLng = state.latLng;
      }
      if (state is WindyHtmlState) {
        webViewController!.loadData(data: state.html);
      }
    }, buildWhen: (context, state) {
      return (state is WindyHtmlState || state is WindyKeyState);
    }, builder: (context, state) {
      return Expanded(
        child: InAppWebView(
          onWebViewCreated: (controller) {
            webViewController = controller;
            _addJavaScriptHandlers();
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            var url = navigationAction.request.url!.toString();
            if (url.startsWith("file:") || url.contains('windy.com')) {
              return NavigationActionPolicy.ALLOW;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Blocking navigation to $url',
                ),
              ),
            );
            return NavigationActionPolicy.CANCEL;
          },
        ),
      );
    });
  }

  void _selectTask() async {
    final result = await Navigator.pushNamed(context, TaskList.routeName,
        arguments: TaskListScreen.SELECT_TASK_OPTION);
    if (result != null && result is int && result > -1) {
      //print('Draw task for ' + result.toString());
      _sendEvent(SelectTaskEvent(result));
    }
  }

  void _clearTask() {
    _sendEvent(ClearTaskEvent());
  }

  void _sendEvent(WindyEvent event) {
    BlocProvider.of<WindyBloc>(context).add(event);
  }

  void _addJavaScriptHandlers() {
    webViewController!.addJavaScriptHandler(
        handlerName: "Print",
        callback: (args) {
          print("Print called with arg:" + args.toString());
        });
    webViewController!.addJavaScriptHandler(
        handlerName: "getWindyKey",
        callback: (args) {
          return key;
        });
    webViewController!.addJavaScriptHandler(
        handlerName: "getLat",
        callback: (args) {
          print("getLat called");
          return latLng.latitude.toString();
        });
    webViewController!.addJavaScriptHandler(
        handlerName: "getLong",
        callback: (args) {
          print("getLong called");
          return latLng.longitude.toString();
        });
    webViewController!.addJavaScriptHandler(
        handlerName: "getZoom",
        callback: (args) {
          print("getZoom called");
          return zoom;
        });
    webViewController!.addJavaScriptHandler(
        handlerName: "redrawCompleted",
        callback: (args) {
          print("redrawCompleted");
          return zoom;
        });
    webViewController!.addJavaScriptHandler(
        handlerName: "newHeight",
        callback: (List<dynamic> arguments) async {
          int? height = arguments.isNotEmpty
              ? arguments[0]
              : await webViewController!.getContentHeight();
          if (mounted) setState(() => this.height = height!.toDouble());
        });
  }
}
