import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/floor/airport/airport.dart';

Widget getAirportWidget(Airport airport) {
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                airport.ident,
                textAlign: TextAlign.left,
                style: textStyleBoldBlackFontSize16,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        airport.name,
                        textAlign: TextAlign.right,
                        style: textStyleBoldBlack87FontSize14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        airport.municipality + ' ' + airport.state,
                        textAlign: TextAlign.right,
                        style: textStyleBoldBlack87FontSize14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child: Divider(
          thickness: 2,
        ),
      ),
    ],
  );
}
