import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_soaring_forecast/soaring/respository/repository.dart';
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets('Get forecast types', (WidgetTester tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          var actual = Repository(context).getForecastTypes().then(expectAsync1(
              (forecastTypes) => expect(forecastTypes.forecasts.length, 43)));

          // The builder function must return a widget.
          return Container();
        },
      ),
    );
  });
}
