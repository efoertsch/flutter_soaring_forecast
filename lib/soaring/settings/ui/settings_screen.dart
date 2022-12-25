import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show StandardLiterals;
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/repository/options/setttings.dart';
import 'package:flutter_soaring_forecast/soaring/settings/bloc/settings_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/settings/bloc/settings_event.dart';
import 'package:flutter_soaring_forecast/soaring/settings/bloc/settings_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AfterLayoutMixin<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: _getSettingWidgets(),
    );
  }

  @override
  void afterFirstLayout(BuildContext context) {
    BlocProvider.of<SettingsBloc>(context).add(GetInitialSettingsEvent());
  }

  Widget _getSettingWidgets() {
    return BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
      if (state is SettingsErrorState) {
        CommonWidgets.showErrorDialog(
            context, StandardLiterals.UH_OH, state.error);
      }
    }, buildWhen: (previous, current) {
      return current is SettingsInitialState || current is SettingOptionsState;
    }, builder: (context, state) {
      if (state is SettingOptionsState) {
        final settings = state.settings;
        if (settings != null) {
          final settingWidgets = <Widget>[];
          settings.forEach((group) {
            settingWidgets.add(Align(
              alignment: Alignment.topLeft,
              child: Text(
                group.title,
                style: textStyleBoldBlackFontSize16,
              ),
            ));
            settingWidgets.addAll(
              _getSettingTileWidgets(group.options!),
            );
          });
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: settingWidgets),
          );
        }
        return SizedBox.shrink();
      }
      return SizedBox.shrink();
    });
  }

  List<Widget> _getSettingTileWidgets(List<Option> options) {
    final settingsTiles = <Widget>[];
    options.forEach((option) {
      settingsTiles.add(_createSettingTileWidget(option));
    });
    return settingsTiles;
  }

  Widget _createSettingTileWidget(final Option option) {
    bool currentValue = option.savedValue!;
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return SwitchListTile(
          title: Text(option.title),
          value: currentValue,
          onChanged: (value) {
            setState(() {
              currentValue = value;
              _sendEvent(SettingsSetEvent(option.key, value));
            });
          },
          subtitle:
              option.description == null ? null : Text(option.description!));
    });
  }

  void _sendEvent(SettingsEvent event) {
    BlocProvider.of<SettingsBloc>(context).add(event);
  }
}