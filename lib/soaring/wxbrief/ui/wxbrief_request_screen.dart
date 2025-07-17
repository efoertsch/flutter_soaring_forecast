import 'dart:async';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/main.dart';
import 'package:flutter_soaring_forecast/soaring/airport/ui/airport_search.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show
        StandardLiterals,
        WxBriefBriefingRequest,
        WxBriefFormat,
        WxBriefLiterals,
        WxBriefMenu,
        WxBriefTypeOfBrief;
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/app/upper_case_text_formatter.dart';
import 'package:flutter_soaring_forecast/soaring/fileutils/file_utils.dart';
import 'package:flutter_soaring_forecast/soaring/floor/airport/airport.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/bloc/wxbrief_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/bloc/wxbrief_event.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/bloc/wxbrief_state.dart';
import 'package:flutter_soaring_forecast/soaring/wxbrief/data/briefing_option.dart';
import 'package:permission_handler/permission_handler.dart';

///  The following is used to determine which widgets to display
///  Area Brief
///               Departure Date      Reporting Options   Product Options
///  Standard     Don't Display       Display             Don't Display
///  Abbreviated  Don't Display       Display             Display
///  NOTAMS       Display             Don't Display       Don't Display
///  Outlook      Display             Don't Display       Don't Display
///
///  Route Brief
///               Departure Date      Reporting Options   Product Options
///  Standard     Don't Display       Display             Don't Display
///  Abbreviated  Don't Display       Display             Display
///  NOTAMS       Display             Don't Display       Don't Display
///  Outlook      Display             Don't Display       Don't Display

class WxBriefRequestScreen extends StatefulWidget {
  late final WxBriefBriefingRequest request;

  WxBriefRequestScreen({Key? key, required this.request}) : super(key: key);

  @override
  _WxBriefRequestScreenState createState() => _WxBriefRequestScreenState();
}

class _WxBriefRequestScreenState extends State<WxBriefRequestScreen>
    with AfterLayoutMixin<WxBriefRequestScreen> {
  var _formKey = GlobalKey<FormState>();

  String _accountName = "";
  String _aircraftRegistration = "";
  RegExp aircraftIdRegex =
      RegExp('^([A-Z]-[A-Z]{4}|[A-Z]{2}[A-Z]{3}|N[0-9]{1,5}[A-Z]{0,2})\$');

  /// Online(PDF) or EMAIL
  WxBriefFormat? _selectedWxBriefFormat;
  String _selectedDepartureDate = "";

  WxBriefTypeOfBrief? _selectedBriefType;
  List<BriefingOption> _fullReportOptionList = <BriefingOption>[];

  List<BriefingOption> _fullProductOptionList = <BriefingOption>[];

  List<String> _departureDates = <String>[];

  Airport? _airport = Airport(ident: "");

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {
    _sendEvent(WxBriefInitEvent(widget.request));
  }

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
        title: Text(WxBriefLiterals.ONE800WXBRIEF),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        actions: _getWxBriefMenu()
        //  actions: _getAppBarMenu(),
        );
  }

  Widget _getBody() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
      child: Stack(children: [
        CustomScrollView(slivers: <Widget>[
          SliverList(
            delegate: SliverChildListDelegate(
              _getRequestWidgets(),
            ),
          ),
          SliverFillRemaining(
              hasScrollBody: false, child: _getCancelContinueWidgets()),
        ]),
        _getProgressIndicator(),
        _widgetForMessages(),
      ]),
    );
  }

  // There are 3 different screen formats displayed depending on the request
  // 1. NOTAMS_REQUEST - uses RouteBrief but only asks for NOTAMS
  // 2. ROUTE_REQUEST - displays widgets so use can select Standard, Abbreviated, Outlook or NOTAMS briefing
  // 3. AREA_REQUEST - Requests Area Briefing and user can also select Standard, Abbreviated, Outlook or NOTAMS briefing
  List<Widget> _getRequestWidgets() {
    final widgetList = <Widget>[];
    widgetList.add(_getBriefingHeader());
    if (widget.request == WxBriefBriefingRequest.NOTAMS_REQUEST ||
        widget.request == WxBriefBriefingRequest.ROUTE_REQUEST) {
      widgetList.add(_getTaskTitleWidget());
    }
    if (widget.request == WxBriefBriefingRequest.NOTAMS_REQUEST) {
      widgetList.add(_getNOTAMAbbrevBriefText());
    }
    if (widget.request == WxBriefBriefingRequest.AREA_REQUEST) {
      widgetList.add(_getAreaBriefWidget());
    }
    widgetList.add(_getRegistrationAndAccountNameForm());
    if (widget.request == WxBriefBriefingRequest.NOTAMS_REQUEST) {
      widgetList.add(Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Align(
            alignment: Alignment.centerLeft, child: _getBriefingFormatWidget()),
      ));
    } else {
      widgetList.add(_getBriefTypeAndFormat());
      widgetList.add(_getDepartureDatesWidget());
      widgetList.add(_getReportAndProductOptions());
    }
    return widgetList;
  }

  Widget _getBriefingHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Center(
        child: Text(
          widget.request == WxBriefBriefingRequest.NOTAMS_REQUEST
              ? WxBriefLiterals.NOTAMS_BRIEFING
              : (widget.request == WxBriefBriefingRequest.AREA_REQUEST)
                  ? WxBriefLiterals.ONE800WX_AREA_BRIEF
                  : WxBriefLiterals.ONE800WX_ROUTE_BRIEF,
          style: textStyleBoldBlackFontSize24,
        ),
      ),
    );
  }

  Form _getRegistrationAndAccountNameForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _getAircraftRegistrion(),
          _getWxBriefAccountName(),
        ],
      ),
    );
  }

  Widget _getProgressIndicator() {
    return BlocConsumer<WxBriefBloc, WxBriefState>(
        listener: (context, state) {},
        buildWhen: (previous, current) {
          return current is WxBriefWorkingState;
        },
        builder: (context, state) {
          if (state is WxBriefWorkingState) {
            if (state.working) {
              return Container(
                child: AbsorbPointer(
                    absorbing: true, child: CircularProgressIndicator()),
                alignment: Alignment.center,
                color: Colors.transparent,
              );
            }
          }
          return SizedBox.shrink();
        });
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop();
    return true;
  }

  Widget _getTaskTitleWidget() {
    return BlocConsumer<WxBriefBloc, WxBriefState>(
        listener: (context, state) {},
        buildWhen: (previous, current) {
          return current is WxBriefInitialState ||
              current is WxBriefTaskTitleState;
        },
        builder: (context, state) {
          if (state is WxBriefInitialState) {
            return CommonWidgets.buildLoading();
          }
          if (state is WxBriefTaskTitleState) {
            return _taskTitleWidget(state.taskName, state.turnpointIds);
          }
          return Text('Undefined state');
        });
  }

  Widget _taskTitleWidget(
      final String taskName, final List<String> turnpointIds) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              taskName,
              style: textStyleBoldBlackFontSize24,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              turnpointIds.join(" "),
              style: textStyleBlackFontSize16,
            ),
          ),
        )
      ],
    );
  }

  Widget _getAreaBriefWidget() {
    return BlocConsumer<WxBriefBloc, WxBriefState>(
      listener: (context, state) {
        if (state is WxBriefAirportState) {
          _airport = state.airport;
        }
      },
      buildWhen: (previous, current) {
        return current is WxBriefInitialState || current is WxBriefAirportState;
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                    key: Key(_airport!.ident),
                    initialValue: _airport!.ident,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: WxBriefLiterals.AIRPORT_ID,
                    ),
                    inputFormatters: [UpperCaseTextFormatter()],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value != null && value.length >= 3) {
                        _sendEvent(WxAirportIdEvent(value));
                        return null;
                      } else {
                        return WxBriefLiterals.INVALID_AIRPORT_ID;
                      }
                    }),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: IconButton(
                        icon: Icon(Icons.search),
                        color: Colors.blue,
                        onPressed: () {
                          _searchForAirport();
                        })),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    _airport!.name,
                    style: textStyleBlackFontSize16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getNOTAMAbbrevBriefText() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Text(
            WxBriefLiterals.NOTAMS_ABBREV_BRIEF,
            style: textStyleBlackFontSize16,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: IconButton(
              icon: Icon(Icons.info),
              color: Colors.blue,
              onPressed: () {
                CommonWidgets.showInfoDialog(
                    context: context,
                    title: WxBriefLiterals.NOTAMS_BRIEFING,
                    msg: WxBriefLiterals.WXBRIEF_NOTAMS_ABBREV_BRIEF_INFO,
                    button1Text: WxBriefLiterals.CLOSE,
                    button1Function: _cancel);
              },
            ),
          )
        ],
      ),
    );
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  Widget _getAircraftRegistrion() {
    return BlocConsumer<WxBriefBloc, WxBriefState>(listener: (context, state) {
      if (state is WxBriefDefaultsState) {
        _aircraftRegistration = state.wxBriefDefaults.aircraftRegistration;
      }
    }, buildWhen: (previous, current) {
      return current is WxBriefInitialState || current is WxBriefDefaultsState;
    }, builder: (context, state) {
      if (state is WxBriefInitialState) {
        return CommonWidgets.buildLoading();
      }
      if (state is WxBriefDefaultsState) {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: TextFormField(
              initialValue: _aircraftRegistration,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: WxBriefLiterals.AIRCRAFT_REGISTRATION_LABEL,
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              inputFormatters: [UpperCaseTextFormatter()],
              validator: (value) {
                if (value != null &&
                    value.length > 3 &&
                    aircraftIdRegex.hasMatch(value)) {
                  _aircraftRegistration = value;
                  _sendEvent(WxBriefUpdateAircraftRegistrationEvent(value));
                  return null;
                } else {
                  return WxBriefLiterals.INVALID_AIRCRAFT_REGISTRATION_ID;
                }
              }),
        );
      }
      ;
      return Text('Undefined state');
    });
  }

  Widget _getWxBriefAccountName() {
    return BlocConsumer<WxBriefBloc, WxBriefState>(listener: (context, state) {
      if (state is WxBriefDefaultsState) {
        _accountName = state.wxBriefDefaults.wxBriefAccountName;
      }
    }, buildWhen: (previous, current) {
      return current is WxBriefInitialState || current is WxBriefDefaultsState;
    }, builder: (context, state) {
      if (state is WxBriefInitialState) {
        return CommonWidgets.buildLoading();
      }
      if (state is WxBriefDefaultsState) {
        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: TextFormField(
              initialValue: _accountName,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: WxBriefLiterals.WXBRIEF_ACCOUNT_NAME,
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value != null &&
                    value.length > 3 &&
                    EmailValidator.validate(value)) {
                  _accountName = value;
                  _sendEvent(WxBriefUpdateAccountNameEvent(value));
                  return null;
                } else {
                  return WxBriefLiterals.INVALID_WXBRIEF_USER_NAME;
                }
              }),
        );
      }
      ;
      return Text('Undefined state');
    });
  }

  Widget _getBriefTypeAndFormat() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: _getTypeOfBriefWidget())),
          Expanded(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: _getBriefingFormatWidget())),
        ],
      ),
    );
  }

  Widget _getBriefingFormatWidget() {
    return BlocConsumer<WxBriefBloc, WxBriefState>(
        listener: (context, state) {},
        buildWhen: (previous, current) {
          return current is WxBriefBriefFormatsState;
        },
        builder: (context, state) {
          if (state is WxBriefBriefFormatsState) {
            return _getBriefingFormat(state.wxBriefFormats);
          }
          return SizedBox.shrink();
        });
  }

  Widget _getBriefingFormat(List<WxBriefFormat> wxBriefFormats) {
    if (_selectedWxBriefFormat == null) {
      _selectedWxBriefFormat = wxBriefFormats[0];
    }
    return Column(
      children: [
        Text(WxBriefLiterals.BRIEFING_FORMAT),
        DropdownButton<WxBriefFormat>(
          value: _selectedWxBriefFormat,
          icon: const Icon(Icons.arrow_downward),
          elevation: 16,
          style: const TextStyle(color: Colors.deepPurple),
          underline: Container(
            height: 2,
            color: Colors.deepPurpleAccent,
          ),
          onChanged: (WxBriefFormat? value) {
            // This is called when the user selects an item.
            setState(() {
              _selectedWxBriefFormat = value!;
              _sendEvent(WxBriefSetBriefFormatEvent(
                  wxBriefFormat: _selectedWxBriefFormat!));
            });
          },
          items: wxBriefFormats
              .map<DropdownMenuItem<WxBriefFormat>>((WxBriefFormat value) {
            return DropdownMenuItem<WxBriefFormat>(
              value: value,
              child: Text(value.option),
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _getDepartureDatesWidget() {
    return BlocConsumer<WxBriefBloc, WxBriefState>(listener: (context, state) {
      if (state is WxBriefDepartureDatesState) {
        _departureDates = state.departureDates;
        if (_selectedDepartureDate.isEmpty) {
          _selectedDepartureDate = state.departureDates[0];
        }
      }
    }, buildWhen: (previous, current) {
      return current is WxBriefDepartureDatesState;
    }, builder: (context, state) {
      return _getDepartureDates(_departureDates);
    });
  }

  Widget _getDepartureDates(List<String> departureDates) {
    return Visibility(
      visible: (_selectedBriefType == WxBriefTypeOfBrief.NOTAMS ||
          _selectedBriefType == WxBriefTypeOfBrief.OUTLOOK),
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            children: [
              Text(WxBriefLiterals.DEPARTURE_DATE),
              DropdownButton<String>(
                value: _selectedDepartureDate,
                icon: const Icon(Icons.arrow_downward),
                elevation: 16,
                style: const TextStyle(color: Colors.deepPurple),
                underline: Container(
                  height: 2,
                  color: Colors.deepPurpleAccent,
                ),
                onChanged: (String? value) {
                  // This is called when the user selects an item.
                  setState(() {
                    _selectedDepartureDate = value!;
                    _sendEvent(WxBriefUpdateDepartureDateEvent(
                        _selectedDepartureDate));
                  });
                },
                items: departureDates
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _getTypeOfBriefWidget() {
    return BlocConsumer<WxBriefBloc, WxBriefState>(listener: (context, state) {
      if (state is WxBriefBriefingTypesState) {
        if (_selectedBriefType == null) {
          _selectedBriefType = state.briefingTypes[0];
        }
      }
    }, buildWhen: (previous, current) {
      return current is WxBriefBriefingTypesState;
    }, builder: (context, state) {
      if (state is WxBriefBriefingTypesState) {
        return _getTypesOfBriefs(state.briefingTypes);
      }
      return SizedBox.shrink();
    });
  }

  Widget _getTypesOfBriefs(List<WxBriefTypeOfBrief> briefingTypes) {
    return Column(
      children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Text(WxBriefLiterals.TYPE_OF_BRIEF)),
        Align(
          alignment: Alignment.centerLeft,
          child: DropdownButton<WxBriefTypeOfBrief>(
            value: _selectedBriefType,
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            style: const TextStyle(color: Colors.deepPurple),
            underline: Container(
              height: 2,
              color: Colors.deepPurpleAccent,
            ),
            onChanged: (WxBriefTypeOfBrief? value) {
              // This is called when the user selects an item.
              setState(() {
                _selectedBriefType = value!;
                if (_selectedBriefType == WxBriefTypeOfBrief.OUTLOOK) {
                  // set to tomorrow
                  (_selectedDepartureDate = _departureDates[1]);
                } else {
                  // set to today
                  _selectedDepartureDate = _departureDates[0];
                }
                _sendEvent(
                    WxBriefUpdateDepartureDateEvent(_selectedDepartureDate));
                _sendEvent(WxBriefSetTypeOfBriefEvent(
                    wxBriefTypeOfBriefing: _selectedBriefType!));
              });
            },
            items: briefingTypes.map<DropdownMenuItem<WxBriefTypeOfBrief>>(
                (WxBriefTypeOfBrief value) {
              return DropdownMenuItem<WxBriefTypeOfBrief>(
                value: value,
                child: Text(value.name),
              );
            }).toList(),
          ),
        )
      ],
    );
  }

  Widget _getReportAndProductOptions() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        children: [
          Expanded(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: _getReportingOptionsWidget())),
          Expanded(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: _getProductOptionsWidget()))
        ],
      ),
    );
  }

  Widget _getReportingOptionsWidget() {
    return BlocConsumer<WxBriefBloc, WxBriefState>(listener: (context, state) {
      if (state is WxBriefReportingOptionsState) {
        debugPrint("Listener for WxBriefReportingOptionsState fired");
        _fullReportOptionList.clear();
        _fullReportOptionList.addAll(state.reportingOptions);
        debugPrint(
            "_fullReportOptionList.length : ${_fullReportOptionList.length}");
      }
    }, buildWhen: (previous, current) {
      return current is WxBriefReportingOptionsState;
    }, builder: (context, state) {
      if (state is WxBriefReportingOptionsState &&
          (_selectedBriefType == WxBriefTypeOfBrief.STANDARD ||
              _selectedBriefType == WxBriefTypeOfBrief.ABBREVIATED)) {
        debugPrint(
            "Drawings ReportingOptions Widget - _fullReportOptionList.length : ${_fullReportOptionList.length}");
        return _getReportingOptions(_fullReportOptionList);
      }
      return SizedBox.shrink();
    });
  }

  _getReportingOptions(List<BriefingOption> reportingOptions) {
    return Column(
      children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Text(WxBriefLiterals.REPORT_OPTIONS)),
        InkWell(
          child: Row(
            children: [
              Text(WxBriefLiterals.SELECT),
              Icon(Icons.arrow_downward_outlined),
            ],
          ),
          onTap: (() => _displayReportingOptionsDropDown()),
        ),
      ],
    );
  }

  void _displayReportingOptionsDropDown() {
    List<CheckboxItem> currentReportingOptions = [];
    currentReportingOptions.addAll(_fullReportOptionList
        .where((option) => option.displayThisOption)
        .map((displayableOption) => CheckboxItem(
              displayableOption.displayDescription,
              displayableOption.selectForBrief,
            )));

    CommonWidgets.showCheckBoxsInfoDialog(
      context: context,
      msg: "",
      title: WxBriefLiterals.REPORT_OPTIONS,
      button1Text: "OK",
      button1Function: (() => Navigator.pop(context, currentReportingOptions)),
      checkboxItems: currentReportingOptions,
    ).then((newReportingOptions) =>
        _processReportingOptions(newReportingOptions!));
  }

  void _processReportingOptions(List<CheckboxItem> reportingOptions) {
    reportingOptions.forEach((displayOption) {
      BriefingOption briefingOption = _fullReportOptionList.firstWhere(
          (option) => option.displayDescription == displayOption.checkboxText);
      briefingOption.selectForBrief = displayOption.isChecked;
    });
    _sendEvent(WxBriefUpdateReportingOptionsEvent(
        briefingOptions: _fullReportOptionList));
  }

  Widget _getProductOptionsWidget() {
    return BlocConsumer<WxBriefBloc, WxBriefState>(listener: (context, state) {
      if (state is WxBriefProductOptionsState) {
        debugPrint("Listener for WxBriefProductOptionsState fired");
        _fullProductOptionList.clear();
        _fullProductOptionList.addAll(state.productOptions);
        debugPrint(
            " _fullProductOptionList.length : ${_fullProductOptionList.length}");
      }
    }, buildWhen: (previous, current) {
      return current is WxBriefProductOptionsState;
    }, builder: (context, state) {
      if (state is WxBriefProductOptionsState &&
          _selectedBriefType == WxBriefTypeOfBrief.ABBREVIATED) {
        debugPrint(
            "Drawing ProductOptions Widget - _fullReportOptionList.length : ${_fullReportOptionList.length}");
        return _getProductOptions(_fullProductOptionList);
      }
      return SizedBox.shrink();
    });
  }

  _getProductOptions(List<BriefingOption> productOptions) {
    return Column(
      children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Text(WxBriefLiterals.PRODUCT_OPTIONS)),
        InkWell(
          child: Row(
            children: [
              Text(WxBriefLiterals.SELECT),
              Icon(Icons.arrow_downward_outlined),
            ],
          ),
          onTap: (() => _displayProductOptionsDropDown()),
        ),
      ],
    );
  }

  void _displayProductOptionsDropDown() {
    List<CheckboxItem> currentProductOptions = [];
    currentProductOptions.addAll(_fullProductOptionList
        .where((option) => option.displayThisOption)
        .map((displayableOption) => CheckboxItem(
              displayableOption.displayDescription,
              displayableOption.selectForBrief,
            )));

    CommonWidgets.showCheckBoxsInfoDialog(
      context: context,
      msg: "",
      title: WxBriefLiterals.PRODUCT_OPTIONS,
      button1Text: "OK",
      button1Function: (() => Navigator.pop(context, currentProductOptions)),
      checkboxItems: currentProductOptions,
    ).then((newProductOptions) => _processProductOptions(newProductOptions!));
  }

  void _processProductOptions(List<CheckboxItem> productOptions) {
    productOptions.forEach((displayOption) {
      BriefingOption briefingOption = _fullProductOptionList.firstWhere(
          (option) => option.displayDescription == displayOption.checkboxText);
      briefingOption.selectForBrief = displayOption.isChecked;
    });
    _sendEvent(WxBriefUpdateProductOptionsEvent(
        briefingOptions: _fullProductOptionList));
  }

  Widget _getCancelContinueWidgets() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: TextButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity,
                    40), // double.infinity is the width and 30 is the height
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                _cancel();
              },
              child: const Text(WxBriefLiterals.CANCEL),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: TextButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity,
                      40), // double.infinity is the width and 30 is the height
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  _checkStoragePermission();
                  ;
                },
                child: const Text(WxBriefLiterals.SUBMIT),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _widgetForMessages() {
    return BlocListener<WxBriefBloc, WxBriefState>(
      listener: (context, state) async {
        if (state is WxBriefMessageState) {
          CommonWidgets.showInfoDialog(
              context: context,
              title: WxBriefLiterals.ONE800WXBRIEF,
              msg: state.msg,
              button1Text: WxBriefLiterals.CLOSE,
              button1Function: _cancel);
        }
        if (state is WxBriefPdfDocState) {
          await Navigator.pushNamed(context, PdfViewRouteBuilder.routeName,
              arguments: state.fileName);
        }
        if (state is WxBriefErrorState) {
          CommonWidgets.showErrorDialog(context, "Error", state.error);
        }
        if (state is WxBriefShowAuthScreenState) {
          if (state.showAuthScreen) {
            var result = await Navigator.pushNamed(
                context, WxBriefAuthBuilder.routeName);
            if (result == StandardLiterals.CANCEL) {
              Navigator.pop(context);
            }
          }
        }
      },
      child: SizedBox.shrink(),
    );
  }

  void _searchForAirport() async {
    final result = await Navigator.pushNamed(
      context,
      AirportsSearchRouteBuilder.routeName,
      arguments: AirportsSearch.PICK_ONE,
    );
    if (result != null && result is String) {
      BlocProvider.of<WxBriefBloc>(context).add(WxAirportIdEvent(result));
    } else {
      _airport = null;
    }
    setState(() {});
  }

  void _sendEvent(WxBriefEvent event) {
    BlocProvider.of<WxBriefBloc>(context).add(event);
  }

  void _checkStoragePermission() async {
    checkFileAccess(
        permissionGrantedFunction: _submit,
        requestPermissionFunction: _openAppSettingsFunction,
        permissionDeniedFunction: _openAppSettingsFunction);
  }

  Future<void> _openAppSettingsFunction() async {
    await openAppSettings();
  }

  void _submit()  {
    _sendEvent(WxBriefSubmitEvent());
  }

  List<Widget> _getWxBriefMenu() {
    return <Widget>[
      PopupMenuButton<String>(
        onSelected: handleClick,
        icon: Icon(Icons.more_vert),
        itemBuilder: (BuildContext context) {
          return {
            WxBriefMenu.HELP,
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
      case WxBriefMenu.HELP:
        _displayWxBriefAuthorizationHelp();
        break;
    }
  }

  void _displayWxBriefAuthorizationHelp() {
    _sendEvent(WxBriefDisplayAuthScreenEvent());
  }
}
