import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// see https://medium.com/flutter/the-power-of-webviews-in-flutter-a56234b57df2
//     https://alligator.io/flutter/webview/
class WebviewExplorer extends StatefulWidget {
  final String baseUrl;
  final String webviewTitle;
  final bool javaScriptAllowed;

  WebviewExplorer(this.baseUrl, this.javaScriptAllowed, this.webviewTitle);

  @override
  _WebviewExplorerState createState() => _WebviewExplorerState();
}

class _WebviewExplorerState extends State<WebviewExplorer> {
  Completer<WebViewController> _controller = Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.webviewTitle),
      ),
      body: WebView(
        initialUrl: widget.baseUrl,
        javascriptMode: (widget.javaScriptAllowed
            ? JavascriptMode.unrestricted
            : JavascriptMode.disabled),
        onWebViewCreated: (WebViewController webViewController) {
          _controller.complete(webViewController);
        },
      ),
    );
  }
}
