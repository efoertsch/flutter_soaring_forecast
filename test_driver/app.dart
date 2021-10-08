import 'package:flutter_driver/driver_extension.dart';

import '../test_apps/rasp_image.dart' as app;

/// See  https://flutter.dev/docs/cookbook/testing/integration/introduction
///
/// 1. Create SerializableFinders to locate specific widgets
/// 2. Connect to the app before our tests run in the setUpAll() function
/// 3. Test the important scenarios
/// 4. Disconnect from the app in the teardownAll() function after the tests complete

void main() {
  // This line enables the extension.
  enableFlutterDriverExtension();

  // Call the `main()` function of the app, or call `runApp` with
  // any widget you are interested in testing.
  app.main();
}
