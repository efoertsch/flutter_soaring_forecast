import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:flutter_soaring_forecast/soaring/repository/rasp/forecast_types.dart';

class CommonForecastWidgets {
  static void showForecastDescriptionBottomSheet(
      BuildContext context, Forecast forecast) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        builder: (context) => SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                getForecastDisplayNameAndIcon(forecast),
                Padding(
                  padding: const EdgeInsets.only(
                      top: 16, left: 8.0, right: 8.0, bottom: 8.0),
                  child: Text(forecast.forecastDescription,
                      style: textStyleBlackFontSize18),
                ),
                ElevatedButton(
                  child: Text('Close'),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ));
  }

  static Row getForecastDisplayNameAndIcon(Forecast forecast,
      {Function? onTapIcon = null, Function? onTapText = null}) {
    return Row(
      children: [
        InkWell(
          onTap: () => (onTapIcon != null ? onTapIcon() : null),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: getForecastIcon(forecast.forecastCategory.toString()),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () => (onTapText != null ? onTapText() : null),
            child: Text(
              forecast.forecastNameDisplay,
              textAlign: TextAlign.left,
              softWrap: true,
              style: textStyleBlackFontSize20,
            ),
          ),
        ),
      ],
    );
  }
}
