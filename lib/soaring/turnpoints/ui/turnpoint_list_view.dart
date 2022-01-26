import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/app/main.dart';
import 'package:flutter_soaring_forecast/soaring/floor/turnpoint/turnpoint.dart';

import '../turnpoint_utils.dart';

class TurnpointListView {
  BuildContext context;
  final List<Turnpoint> turnpoints;

  TurnpointListView({required this.context, required this.turnpoints});

  Widget getTurnpoinListView() {
    return ListView.separated(
      itemCount: turnpoints.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
          visualDensity: VisualDensity(horizontal: 0, vertical: -4),
          leading: IconButton(
            icon: Icon(Icons.location_searching),
            color: TurnpointUtils.getColorForTurnpointIcon(turnpoints[index]),
            onPressed: () => Navigator.pushNamed(
              context,
              TurnpointView.routeName,
              arguments: turnpoints[index],
            ),
          ),
          title: TextButton(
            onPressed: () => print('clicked text'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    turnpoints[index].code + '   ' + turnpoints[index].title,
                    textAlign: TextAlign.left,
                    style: textStyleBoldBlackFontSize20,
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    TurnpointUtils.getStyleName(turnpoints[index].style),
                    textAlign: TextAlign.left,
                    style: textStyleBoldBlack87FontSize15,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context, index) {
        return Divider();
      },
    );
  }
}
