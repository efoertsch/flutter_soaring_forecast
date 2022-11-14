import 'dart:io';

import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/region/bloc/region_bloc.dart';

class RegionListScreen extends StatefulWidget {
  late final String selectedRegionName;

  RegionListScreen({Key? key, required String this.selectedRegionName})
      : super(key: key);

  @override
  State<RegionListScreen> createState() =>
      _RegionListScreenState(selectedRegionName);
}

class _RegionListScreenState extends State<RegionListScreen> {
  late String _selectedRegionName;
  _RegionListScreenState(String this._selectedRegionName) {}

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
    BlocProvider.of<RegionDataBloc>(context).add(ListRegionsEvent());
    return SafeArea(
      child: Scaffold(
        appBar: _getAppBar(),
        body: _getBody(),
      ),
    );
  }

  AppBar _getAppBar() {
    return AppBar(
      leading: BackButton(
        onPressed: _onWillPop,
      ),
      title: Text('Region List'),
    );
  }

  Padding _getBody() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: BlocConsumer<RegionDataBloc, RegionDataState>(
        listener: (context, state) {
          if (state is RegionErrorState) {
            CommonWidgets.showErrorDialog(context, 'Region Error', state.error);
          }
        },
        buildWhen: (previous, current) {
          return current is RegionInitialState ||
              current is RegionsLoadedState ||
              current is RegionErrorState;
        },
        builder: (context, state) {
          if (state is RegionInitialState) {
            return CommonWidgets.buildLoading();
          }
          if (state is RegionsLoadedState) {
            if (state.regions.length == 0) {
              // WidgetsBinding.instance?.addPostFrameCallback(
              //     (_) => _showNoTasksFoundDialog(context));
              return Center(child: Text("No Regions Found"));
            } else {
              return Column(
                children: _getRegionListView(regions: state.regions),
              );
            }
          }
          if (state is RegionErrorState) {
            WidgetsBinding.instance.addPostFrameCallback((_) =>
                CommonWidgets.showErrorDialog(
                    context, 'Regions Error', state.error));
            return Center(
                child:
                    Text('Oops. Error occurred getting the list of Regions.'));
          }
          return Center(child: Text("Unhandled State"));
        },
      ),
    );
  }

  List<Widget> _getRegionListView({required List<String> regions}) {
    final radioListTiles = <RadioListTile>[];
    regions.forEach((region) {
      radioListTiles.add(RadioListTile(
        title: Text(
          region,
          style: textStyleBlackFontSize20,
        ),
        value: region,
        groupValue: _selectedRegionName,
        onChanged: (value) {
          setState(() {
            _selectedRegionName = value;
            _fireEvent(context, RegionNameSelectedEvent(value));
          });
        },
      ));
    });
    return radioListTiles;
  }

  void _fireEvent(BuildContext context, RegionDataEvent event) {
    BlocProvider.of<RegionDataBloc>(context).add(event);
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context, _selectedRegionName);
    return true;
  }
}
