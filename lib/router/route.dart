import "package:certimate/database/database.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/logger/logger.dart";
import "package:certimate/pages/access_edit/page.dart";
import "package:certimate/pages/accesses/page.dart";
import "package:certimate/pages/certificate_detail/page.dart";
import "package:certimate/pages/certificates/page.dart";
import "package:certimate/pages/certificates/provider.dart";
import "package:certimate/pages/debug/page.dart";
import "package:certimate/pages/home/page.dart";
import "package:certimate/pages/server/page.dart";
import "package:certimate/pages/server_edit/page.dart";
import "package:certimate/pages/server_settings/account/page.dart";
import "package:certimate/pages/server_settings/page.dart";
import "package:certimate/pages/server_settings/password/page.dart";
import "package:certimate/pages/server_settings/persistence/page.dart";
import "package:certimate/pages/server_webview/page.dart";
import "package:certimate/pages/settings/page.dart";
import "package:certimate/pages/theme/page.dart";
import "package:certimate/pages/webview/page.dart";
import "package:certimate/pages/workflow_logs/page.dart";
import "package:certimate/pages/workflow_runs/page.dart";
import "package:certimate/pages/workflows/page.dart";
import "package:certimate/pages/workflows/provider.dart";
import "package:drift_db_viewer/drift_db_viewer.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:talker_flutter/talker_flutter.dart";

part "route.g.dart";

RouteBase get $singleHomeRoute =>
    GoRouteData.$route(path: "/servers", factory: $HomeRoute._fromState);

@TypedGoRoute<HomeRoute>(
  path: "/servers",
  routes: [
    TypedGoRoute<ServerAddRoute>(path: "add"),
    TypedGoRoute<ServerEditRoute>(path: "edit"),
    TypedGoRoute<ServerWebViewRoute>(path: "webview"),
    TypedGoRoute<ServerSettingsRoute>(
      path: "settings",
      routes: [
        TypedGoRoute<ServerPasswordRoute>(path: "password"),
        TypedGoRoute<ServerAccountRoute>(path: "account"),
        TypedGoRoute<ServerPersistenceRoute>(path: "persistence"),
      ],
    ),
    TypedGoRoute<ServerRoute>(
      path: ":serverId",
      routes: [
        TypedGoRoute<CertificatesRoute>(
          path: "certificates",
          routes: [TypedGoRoute<CertificateDetailRoute>(path: ":certId")],
        ),
        TypedGoRoute<WorkflowsRoute>(
          path: "workflows",
          routes: [TypedGoRoute<WorkflowRunsRoute>(path: ":workflowId/runs")],
        ),
        TypedGoRoute<AccessesRoute>(
          path: "accesses",
          routes: [
            TypedGoRoute<AccessDetailRoute>(
              path: ":accessId",
              routes: [TypedGoRoute<AccessEditRoute>(path: "edit")],
            ),
          ],
        ),
        TypedGoRoute<WorkflowLogsRoute>(path: "workflow_logs/:runId"),
      ],
    ),
  ],
)
@immutable
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(state: state, child: const HomePage());
  }
}

@immutable
class ServerAddRoute extends GoRouteData with $ServerAddRoute {
  const ServerAddRoute();

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(state: state, child: const ServerEditPage());
  }
}

@immutable
class ServerEditRoute extends GoRouteData with $ServerEditRoute {
  final int serverId;

  const ServerEditRoute({required this.serverId});

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(
      child: ServerEditPage(serverId: serverId),
      state: state,
      sheet: true,
    );
  }
}

@immutable
class ServerRoute extends GoRouteData with $ServerRoute {
  final int serverId;

  const ServerRoute({required this.serverId});

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(
      state: state,
      child: ServerPage(serverId: serverId),
    );
  }
}

@immutable
class CertificatesRoute extends GoRouteData with $CertificatesRoute {
  final int serverId;

  final CertificateFilter? filter;

  const CertificatesRoute({required this.serverId, this.filter});

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    final page = CertificatesPage(serverId: serverId);
    return AppRoutePage(
      state: state,
      child: filter != null
          ? ProviderScope(
              overrides: [certificateFilterProvider.overrideWithValue(filter)],
              child: page,
            )
          : page,
    );
  }
}

@immutable
class CertificateDetailRoute extends GoRouteData with $CertificateDetailRoute {
  final int serverId;
  final String certId;

  const CertificateDetailRoute({required this.serverId, required this.certId});

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(
      state: state,
      child: CertificateDetailPage(serverId: serverId, certId: certId),
    );
  }
}

@immutable
class WorkflowsRoute extends GoRouteData with $WorkflowsRoute {
  final int serverId;
  final WorkflowFilter? filter;

  const WorkflowsRoute({required this.serverId, this.filter});

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    final page = WorkflowsPage(serverId: serverId);
    return AppRoutePage(
      state: state,
      child: filter != null
          ? ProviderScope(
              overrides: [workflowFilterProvider.overrideWithValue(filter)],
              child: page,
            )
          : page,
    );
  }
}

@immutable
class WorkflowRunsRoute extends GoRouteData with $WorkflowRunsRoute {
  final String workflowId;
  final int serverId;

  const WorkflowRunsRoute({required this.serverId, required this.workflowId});

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(
      state: state,
      child: WorkflowRunsPage(serverId: serverId, workflowId: workflowId),
    );
  }
}

@immutable
class WorkflowLogsRoute extends GoRouteData with $WorkflowLogsRoute {
  final String runId;
  final int serverId;

  const WorkflowLogsRoute({required this.serverId, required this.runId});

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(
      state: state,
      child: WorkflowLogsPage(serverId: serverId, runId: runId),
    );
  }
}

@immutable
class AccessesRoute extends GoRouteData with $AccessesRoute {
  final int serverId;

  const AccessesRoute({required this.serverId});

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(
      state: state,
      child: AccessesPage(serverId: serverId),
    );
  }
}

@immutable
class AccessDetailRoute extends GoRouteData with $AccessDetailRoute {
  final int serverId;
  final String accessId;

  const AccessDetailRoute({required this.serverId, required this.accessId});

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(
      state: state,
      child: AccessEditPage(
        serverId: serverId,
        accessId: accessId,
        readonly: true,
      ),
    );
  }
}

@immutable
class AccessEditRoute extends GoRouteData with $AccessEditRoute {
  final int serverId;
  final String accessId;

  const AccessEditRoute({required this.serverId, required this.accessId});

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(
      state: state,
      child: AccessEditPage(
        serverId: serverId,
        accessId: accessId,
        readonly: false,
      ),
    );
  }
}

@immutable
class ServerSettingsRoute extends GoRouteData with $ServerSettingsRoute {
  final int serverId;

  const ServerSettingsRoute({required this.serverId});

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(
      state: state,
      child: ServerSettingsPage(serverId: serverId),
    );
  }
}

@immutable
class ServerPasswordRoute extends GoRouteData with $ServerPasswordRoute {
  final int serverId;

  const ServerPasswordRoute({required this.serverId});

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(
      child: ServerPasswordPage(serverId: serverId),
      state: state,
      sheet: true,
    );
  }
}

@immutable
class ServerAccountRoute extends GoRouteData with $ServerAccountRoute {
  final int serverId;

  const ServerAccountRoute({required this.serverId});

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(
      child: ServerAccountPage(serverId: serverId),
      state: state,
      sheet: true,
    );
  }
}

@immutable
class ServerPersistenceRoute extends GoRouteData with $ServerPersistenceRoute {
  final int serverId;

  const ServerPersistenceRoute({required this.serverId});

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(
      child: ServerPersistencePage(serverId: serverId),
      state: state,
      sheet: true,
    );
  }
}

@immutable
class ServerWebViewRoute extends GoRouteData with $ServerWebViewRoute {
  final String url;

  final int serverId;

  const ServerWebViewRoute({required this.url, required this.serverId});

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(
      state: state,
      child: ServerWebViewPage(
        url: Uri.decodeComponent(url),
        serverId: serverId,
      ),
    );
  }
}

@TypedGoRoute<SettingsRoute>(path: "/settings")
@immutable
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(state: state, child: const SettingsPage());
  }
}

@TypedGoRoute<WebViewRoute>(path: "/webview")
@immutable
class WebViewRoute extends GoRouteData with $WebViewRoute {
  final String url;

  const WebViewRoute({required this.url});

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(
      state: state,
      child: WebViewPage(url: Uri.decodeComponent(url)),
    );
  }
}

@TypedGoRoute<DebugRoute>(path: "/debug")
@immutable
class DebugRoute extends GoRouteData with $DebugRoute {
  const DebugRoute();

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(state: state, child: const DebugPage());
  }
}

@TypedGoRoute<DbViewerRoute>(path: "/db_viewer")
@immutable
class DbViewerRoute extends GoRouteData with $DbViewerRoute {
  const DbViewerRoute();

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(
      state: state,
      child: kDebugMode
          ? Consumer(
              builder: (_, ref, _) {
                final db = ref.read(databaseProvider);
                return DriftDbViewer(db);
              },
            )
          : Scaffold(appBar: AppBar()),
    );
  }
}

@TypedGoRoute<LoggerRoute>(path: "/logger")
@immutable
class LoggerRoute extends GoRouteData with $LoggerRoute {
  const LoggerRoute();

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(
      state: state,
      child: kDebugMode
          ? TalkerScreen(
              talker: Logger.getLogger(),
              appBarTitle: "Logger",
              theme: TalkerScreenTheme.fromTheme(Theme.of(context)),
            )
          : Scaffold(appBar: AppBar()),
    );
  }
}

@TypedGoRoute<ThemeRoute>(path: "/theme")
@immutable
class ThemeRoute extends GoRouteData with $ThemeRoute {
  const ThemeRoute();

  @override
  Page<Function> buildPage(BuildContext context, GoRouterState state) {
    return AppRoutePage(state: state, child: const ThemePage());
  }
}

class AppRoutePage<T> extends Page<T> {
  final Widget child;
  final bool sheet;
  final GoRouterState state;

  const AppRoutePage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    super.canPop,
    super.onPopInvoked,
    this.sheet = false,
    required this.state,
    required this.child,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    if (context.isCupertinoStyle) {
      if (isDesktopDevice) {
        return _NoSwipeCupertinoPageRoute<T>(
          settings: this,
          builder: (context) => child,
        );
      }
      if (sheet) {
        return CupertinoSheetRoute<T>(
          settings: this,
          builder: (context) => child,
        );
      }
    }

    return MaterialPageRoute(
      settings: this,
      fullscreenDialog: sheet,
      builder: (context) => child,
    );
  }
}

class _NoSwipeCupertinoPageRoute<T> extends CupertinoPageRoute<T> {
  _NoSwipeCupertinoPageRoute({required super.builder, super.settings});

  @override
  bool get popGestureEnabled => false;
}
