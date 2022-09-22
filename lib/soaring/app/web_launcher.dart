import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

FutureOr<void> launchWebBrowser(String base, String path,
    {bool useHttp = false, bool launchAsExternal = false}) async {
  late final uri;
  late final LaunchMode launchMode;
  launchMode = launchAsExternal
      ? LaunchMode.externalApplication
      : LaunchMode.platformDefault;
  if (useHttp) {
    uri = Uri.http(base, path);
  } else {
    uri = Uri.https(base, path);
  }
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: launchMode);
  } else {
    throw 'Could not launch $uri';
  }
}
