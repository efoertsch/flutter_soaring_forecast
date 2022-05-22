import 'package:url_launcher/url_launcher.dart';

void launchWebBrowser(String base, String path) async {
  final uri = Uri.https(base, path);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    throw 'Could not launch $uri';
  }
}
