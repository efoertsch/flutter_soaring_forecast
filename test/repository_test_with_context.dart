import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_soaring_forecast/soaring/drift/app_database.dart';
import 'package:flutter_soaring_forecast/soaring/repository/repository.dart';
import "package:flutter_test/flutter_test.dart";

void main() {
  late AppDatabase appDatabase;
  setUp(() {
    // Create a fresh in-memory database before each test
    appDatabase = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() async {
    // Close the database after each test
    await appDatabase.close();
  });
  testWidgets('Get forecast types', (WidgetTester tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          var actual = Repository(context,appDatabase)
              .getDisplayableForecastList()
              .then(expectAsync1((forecasts) => expect(forecasts.length, 43)));

          // The builder function must return a widget.
          return Container();
        },
      ),
    );
  });
}
