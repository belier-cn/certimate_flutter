import "package:flutter_web_plugins/flutter_web_plugins.dart" as web_plugin;
import "package:web/web.dart" as web;

String getPathName() => web.window.location.pathname;

void replacePath(String path) =>
    web.window.history.replaceState(null, "", path);

void usePathUrlStrategy() => web_plugin.usePathUrlStrategy();
