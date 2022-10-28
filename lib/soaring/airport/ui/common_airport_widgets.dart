import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/app/custom_styles.dart';
import 'package:flutter_soaring_forecast/soaring/floor/airport/airport.dart';

Widget getAirportWidget(Airport airport) {
  return Padding(
    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 3,
          child: Text(
            airport.ident,
            textAlign: TextAlign.left,
            style: textStyleBoldBlackFontSize20,
          ),
        ),
        Flexible(
          flex: 7,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  airport.name,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  softWrap: true,
                  style: textStyleBoldBlackFontSize20,
                ),
                Text(
                  airport.municipality + ' ' + airport.state,
                  textAlign: TextAlign.right,
                  style: textStyleBoldBlack87FontSize14,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
