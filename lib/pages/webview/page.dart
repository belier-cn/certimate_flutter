import "package:certimate/widgets/webview.dart";
import "package:flutter/material.dart" hide Route;

class WebViewPage extends StatelessWidget {
  final String url;

  const WebViewPage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return WebviewWidget(url: url);
  }
}
