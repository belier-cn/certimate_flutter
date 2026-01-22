import "package:certimate/database/servers_dao.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/hooks/easy_refresh.dart";
import "package:certimate/pages/home/provider.dart";
import "package:certimate/pages/server/provider.dart";
import "package:certimate/pages/server/widgets/controls.dart";
import "package:certimate/pages/server/widgets/shortcuts.dart";
import "package:certimate/pages/server/widgets/statistics.dart";
import "package:certimate/pages/workflow_runs/widgets/workflow_run.dart";
import "package:certimate/router/route.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class ServerPage extends HookConsumerWidget {
  final int serverId;

  const ServerPage({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final refreshController = useRefreshController();
    final scrollController = useScrollController();
    final topVisible = useValueNotifier(false);
    return BasePage(
      child: Scaffold(
        body: RefreshBody<ServerData>(
          topVisible: topVisible,
          title: Consumer(
            builder: (_, ref, _) {
              final displayName = ref.watch(
                serverProvider(
                  serverId,
                ).select((item) => item.value?.displayName),
              );
              return Text(displayName ?? "");
            },
          ),
          trailing: PlatformPullDownButton(
            options: [
              PullDownOption(
                label: s.certificates.capitalCase,
                iconWidget: Icon(context.appIcons.certificate),
                onTap: (_) =>
                    CertificatesRoute(serverId: serverId).push(context),
              ),
              PullDownOption(
                label: s.workflows.capitalCase,
                iconWidget: Icon(context.appIcons.workflow),
                onTap: (_) => WorkflowsRoute(serverId: serverId).push(context),
              ),
              PullDownOption(
                label: s.credentials.capitalCase,
                iconWidget: Icon(context.appIcons.credential),
                onTap: (_) => AccessesRoute(serverId: serverId).push(context),
              ),
              PullDownOption(
                label: s.presetTemplate.capitalCase,
                iconWidget: Icon(context.appIcons.template),
                onTap: (_) =>
                    ServerTemplatesRoute(serverId: serverId).push(context),
              ),
              PullDownOption(
                label: s.systemSettings.capitalCase,
                iconWidget: Icon(context.appIcons.settings),
                withDivider: true,
                onTap: (_) =>
                    ServerSettingsRoute(serverId: serverId).push(context),
              ),
              PullDownOption(
                label: s.edit.capitalCase,
                iconWidget: Icon(context.appIcons.edit),
                withDivider: true,
                onTap: (_) async {
                  final newServer = await ServerEditRoute(
                    serverId: serverId,
                  ).push(context);
                  final realServer = newServer is Function
                      ? newServer.call()
                      : newServer;
                  if (realServer is ServerModel? && realServer != null) {
                    ref
                        .read(serverProvider(serverId).notifier)
                        .updateServer(realServer);
                  }
                },
              ),
              PullDownOption(
                label: s.delete.capitalCase,
                iconWidget: Icon(context.appIcons.delete),
                isDestructive: true,
                onTap: (_) async {
                  final count = await ref
                      .read(serverDataProvider(serverId).notifier)
                      .delete(context);
                  if (count > 0) {
                    if (context.mounted) context.pop();
                    ref
                        .read(serverListProvider.notifier)
                        .deleteServer(serverId);
                  }
                },
              ),
            ],
            icon: ActionButton(
              well: false,
              child: AppBarIconButton(context.appIcons.ellipsis),
            ),
          ),
          provider: serverDataProvider(serverId),
          refreshController: refreshController,
          scrollController: scrollController,
          itemBuilder: (context, data, index) {
            final showControls =
                !kIsWeb &&
                RunPlatform.isDesktop &&
                data.server?.localId.isNotEmpty == true;
            if (index == 0) {
              return showControls
                  ? TitleCard(
                      title: s.localServerControls.capitalCase,
                      child: ControlsWidget(
                        serverId: serverId,
                        server: data.server,
                      ),
                    )
                  : null;
            }
            if (index > 0 && showControls && !data.isRunning) {
              return null;
            }
            if (index == 1) {
              return TitleCard(
                title: s.statistics.capitalCase,
                child: StatisticsWidget(
                  serverId: serverId,
                  data: data.statistics,
                ),
              );
            }
            if (index == 2) {
              return TitleCard(
                title: s.shortcuts.capitalCase,
                child: ShortcutsWidget(serverId: serverId),
              );
            }
            if (index == 3) {
              return TitleCard(
                title: s.latestWorkflowRuns.capitalCase,
                card: false,
              );
            }
            final item = data.list[index - data.topItemCount];
            return WorkflowRunWidget(
              key: ValueKey(item.id),
              data: item,
              serverId: serverId,
            );
          },
        ),
      ),
    );
  }
}
