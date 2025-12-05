import "package:certimate/database/servers_dao.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/hooks/easy_refresh.dart";
import "package:certimate/pages/home/provider.dart";
import "package:certimate/pages/home/widgets/server_item.dart";
import "package:certimate/router/route.dart";
import "package:certimate/router/router.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class HomePage extends HookConsumerWidget {
  final Widget? navigationShell;
  final GoRouterState? state;

  const HomePage({super.key, this.navigationShell, this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (navigationShell == null && isDesktopDevice) {
      return const Scaffold();
    }
    final s = context.s;
    final searchController = useTextEditingController();
    final refreshController = useRefreshController();
    final scrollController = useScrollController();
    final topVisible = useValueNotifier(false);
    final activeServerId = useValueNotifier<int?>(null);

    useEffect(() {
      if (isDesktopDevice) {
        void listener(_, route, _) {
          final routeHistory = getServersRouteHistory();
          var find = false;
          for (var i = routeHistory.length - 1; i >= 0; i--) {
            final route = routeHistory[i];
            final reg = RegExp(r"/servers/(\d+)");
            final match = reg.firstMatch(route);
            if (match != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                activeServerId.value = int.tryParse(match.group(1)!);
              });
              find = true;
              break;
            }
          }
          if (!find) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              activeServerId.value = null;
            });
          }
        }

        ServersRouteListener().addListener(listener);

        return () {
          ServersRouteListener().removeListener(listener);
        };
      } else {
        return null;
      }
    }, []);

    final page = BasePage(
      exitInterceptor: true,
      child: Scaffold(
        body: RefreshBody<ServersData>(
          topVisible: topVisible,
          title: Text(
            navigationShell != null ? s.servers.titleCase : s.home.titleCase,
          ),
          automaticallyImplyLeading: navigationShell == null,
          trailing: ActionButton(
            onPressed: () async {
              final route = const ServerAddRoute();
              if (state?.fullPath != route.location) {
                final newServer = await route.push<ServerModel?>(context);
                if (newServer != null) {
                  ref.read(serverListProvider.notifier).addServer(newServer);
                  if (isDesktopDevice && context.mounted) {
                    ServerRoute(serverId: newServer.id).push(context);
                  }
                }
              }
            },
            child: AppBarIconButton(context.appIcons.add),
          ),
          refreshController: refreshController,
          scrollController: scrollController,
          searchController: searchController,
          searchPlaceholder: s.serverSearchPlaceholder.capitalCase,
          provider: serverListProvider,
          itemBuilder: (context, data, index) {
            final item = data.list[index];
            return GestureDetector(
              onTap: () {
                final route = ServerRoute(serverId: item.id);
                if (GoRouter.of(context).state.matchedLocation !=
                    route.location) {
                  route.push(context);
                }
              },
              child: ValueListenableBuilder(
                valueListenable: activeServerId,
                builder: (context, serverId, child) {
                  return ServerItemWidget(
                    key: Key("${item.id}"),
                    data: item,
                    selected: serverId == item.id,
                  );
                },
              ),
            );
          },
        ),
      ),
    );

    if (navigationShell != null) {
      if (isDesktopDevice) {
        return Row(
          children: [
            SizedBox(width: 300, child: page),
            Expanded(child: navigationShell!),
          ],
        );
      } else {
        return navigationShell!;
      }
    }

    return page;
  }
}
