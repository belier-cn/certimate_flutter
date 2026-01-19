import "package:certimate/extension/index.dart";
import "package:certimate/pages/home/page.dart";
import "package:certimate/router/navbar.dart";
import "package:certimate/router/route.dart";
import "package:certimate/web/index.dart" as web;
import "package:flutter/cupertino.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:go_router/go_router.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "router.g.dart";

const baseHref = String.fromEnvironment("FLUTTER_BASE_HREF", defaultValue: "/");

String? lastRoutePath = "/servers";

final navBarRoutes = [
  const HomeRoute().location,
  const SettingsRoute().location,
];

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: lastRoutePath,
    routes: kIsWeb || RunPlatform.isDesktopUi
        ? [
            StatefulShellRoute.indexedStack(
              branches: [
                StatefulShellBranch(
                  routes: [
                    ShellRoute(
                      observers: [ServersRouteObserver()],
                      routes: [$homeRoute],
                      builder: (context, state, child) {
                        return HomePage(navigationShell: child, state: state);
                      },
                    ),
                  ],
                ),
                // old StatefulShellBranch(routes: $appRoutes.sublist(1)),
                // 之前的方案会导致先访问哪个页面，哪个页面就被缓存了，通过 navigationShell.goBranch 无法切换到设置页面
                ...$appRoutes
                    .sublist(1)
                    .map((route) => StatefulShellBranch(routes: [route])),
              ],
              builder: (context, state, navigationShell) {
                return ScaffoldWithNavbar(navigationShell);
              },
            ),
          ]
        : [
            StatefulShellRoute.indexedStack(
              branches: [
                StatefulShellBranch(routes: [$singleHomeRoute]),
                StatefulShellBranch(routes: [$settingsRoute]),
              ],
              builder: (context, state, navigationShell) {
                return ScaffoldWithNavbar(navigationShell);
              },
            ),
            $homeRoute,
            ...($appRoutes.sublist(2)),
          ],
    observers: [FlutterSmartDialog.observer],
    redirect: (context, state) {
      if (state.matchedLocation == "/") {
        return lastRoutePath;
      }
      return null;
    },
  );

  router.routerDelegate.addListener(() {
    final fullPath = router.state.matchedLocation;
    lastRoutePath = fullPath;
    final webFullPath =
        "${baseHref.endsWith("/") ? baseHref.substring(0, baseHref.length - 1) : baseHref}$fullPath";
    if (kIsWeb && web.getPathName() != webFullPath) {
      Future.delayed(const Duration(milliseconds: 50)).then((_) {
        web.replacePath(webFullPath);
      });
    }
  });

  ref.onDispose(router.dispose);

  return router;
}

final List<String> _serversRouteHistory = [];

class ServersRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    final settings = route.settings;
    final url = "${settings is AppRoutePage ? settings.state.uri : "unknown"}";
    _serversRouteHistory.add(url);
    ServersRouteListener().notify(
      RouteChangeType.push,
      url,
      previousRoute?.settings is AppRoutePage
          ? (previousRoute?.settings as AppRoutePage).state.uri.toString()
          : null,
    );
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    final settings = route.settings;
    final url = "${settings is AppRoutePage ? settings.state.uri : "unknown"}";
    if (_serversRouteHistory.isNotEmpty) {
      _serversRouteHistory.removeLast();
    }
    ServersRouteListener().notify(
      RouteChangeType.pop,
      url,
      previousRoute?.settings is AppRoutePage
          ? (previousRoute?.settings as AppRoutePage).state.uri.toString()
          : null,
    );
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      final settings = newRoute.settings;
      final url =
          "${settings is AppRoutePage ? settings.state.uri : "unknown"}";
      if (_serversRouteHistory.isNotEmpty) {
        _serversRouteHistory[_serversRouteHistory.length - 1] = url;
      } else {
        _serversRouteHistory.add(url);
      }
      ServersRouteListener().notify(
        RouteChangeType.replace,
        url,
        oldRoute?.settings is AppRoutePage
            ? (oldRoute?.settings as AppRoutePage).state.uri.toString()
            : null,
      );
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    final settings = route.settings;
    final url = "${settings is AppRoutePage ? settings.state.uri : "unknown"}";
    ServersRouteListener().notify(
      RouteChangeType.remove,
      url,
      previousRoute?.settings is AppRoutePage
          ? (previousRoute?.settings as AppRoutePage).state.uri.toString()
          : null,
    );
  }
}

String? getPreviousRoute() {
  if (_serversRouteHistory.length > 1) {
    return _serversRouteHistory[_serversRouteHistory.length - 2];
  }
  return null;
}

List<String> getServersRouteHistory() {
  return _serversRouteHistory;
}

typedef RouteChangeCallback =
    Function(RouteChangeType type, String? route, String? previousRoute);

enum RouteChangeType { pop, push, replace, remove }

class ServersRouteListener {
  static final ServersRouteListener _instance =
      ServersRouteListener._internal();

  factory ServersRouteListener() => _instance;

  ServersRouteListener._internal();

  final List<RouteChangeCallback> _listeners = [];

  void addListener(RouteChangeCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(RouteChangeCallback listener) {
    _listeners.remove(listener);
  }

  void removeAllListener() {
    _listeners.clear();
  }

  void notify(RouteChangeType type, String? route, String? previousRoute) {
    for (final listener in _listeners) {
      try {
        listener(type, route, previousRoute);
      } catch (err) {
        debugPrint("route change listener error: $err");
      }
    }
  }
}
