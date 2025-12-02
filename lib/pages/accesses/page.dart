import "package:certimate/api/access_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/hooks/easy_refresh.dart";
import "package:certimate/pages/accesses/provider.dart";
import "package:certimate/pages/accesses/widgets/access.dart";
import "package:certimate/pages/server/provider.dart";
import "package:certimate/router/route.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class AccessesPage extends HookConsumerWidget {
  final int serverId;

  const AccessesPage({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final provider = accessesProvider(serverId);
    final searchController = useTextEditingController();
    final refreshController = useRefreshController();
    final scrollController = useScrollController();
    final topVisible = useValueNotifier(false);

    void toAddPage(BuildContext context, String type) async {
      final res = await "/#/accesses/new?usage=$type".toServerWebview<int>(
        context,
        serverId,
      );
      if (res != null && res > 0) {
        // 添加成功，刷新页面
        refreshController.callRefresh(scrollController: scrollController);
      }
    }

    return BasePage(
      child: Scaffold(
        body: RefreshBody<AccessesData>(
          topVisible: topVisible,
          title: Text(s.credentials.titleCase),
          trailing: PlatformPullDownButton(
            options: [
              PullDownOption(
                label: s.dnsProvider.capitalCase,
                iconWidget: Icon(context.appIcons.world),
                onTap: (_) => toAddPage(context, "dns-hosting"),
              ),
              PullDownOption(
                label: s.certificateAuthority.capitalCase,
                iconWidget: Icon(context.appIcons.certificate),
                onTap: (_) => toAddPage(context, "ca"),
              ),
              PullDownOption(
                label: s.notificationChannel.capitalCase,
                iconWidget: Icon(context.appIcons.bell),
                onTap: (_) => toAddPage(context, "notification"),
              ),
            ],
            icon: ActionButton(well: false, child: AppBarIconButton(context.appIcons.add)),
          ),
          refreshController: refreshController,
          scrollController: scrollController,
          searchController: searchController,
          searchPlaceholder: s.credentialsSearchPlaceholder.capitalCase,
          provider: provider,
          itemBuilder: (context, data, index) {
            final server = ref.read(serverProvider(serverId));
            final item = data.list[index];
            return AccessWidget(
              key: ValueKey(item.id),
              data: item,
              serverId: serverId,
              serverHost: server.value?.host ?? "",
              onDelete: () async {
                if (await ref.read(provider.notifier).delete(context, item)) {
                  refreshController.callRefresh(
                    scrollController: scrollController,
                  );
                }
              },
              onCopy: () async {
                if (await ref.read(provider.notifier).copy(context, item)) {
                  refreshController.callRefresh(
                    scrollController: scrollController,
                  );
                }
              },
              onUpdate: () async {
                final newData = await AccessEditRoute(
                  serverId: serverId,
                  accessId: item.id ?? "",
                ).push<AccessDetailResult?>(context);
                if (newData != null) {
                  ref.read(provider.notifier).updateAccess(newData);
                }
              },
            );
          },
        ),
      ),
    );
  }
}
