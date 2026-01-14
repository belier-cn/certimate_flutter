import "package:certimate/extension/index.dart";
import "package:certimate/pages/template/list.dart";
import "package:certimate/pages/template/provider.dart";
import "package:certimate/router/route.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_platform_widgets/flutter_platform_widgets.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:intl/intl.dart";

class ServerTemplatePage extends HookConsumerWidget {
  final int serverId;

  const ServerTemplatePage({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final tabs = ["notifyTemplate", "scriptTemplate"];
    final tabController = useTabController(initialLength: tabs.length);
    return BasePage(
      child: Scaffold(
        appBar: PlatformAppBar(
          title: Text(s.presetTemplate.titleCase),
          trailingActions: [
            ActionButton(
              onPressed: () async {
                final settingName = tabs[tabController.index];
                final res = await TemplateEditRoute(
                  serverId: serverId,
                  settingName: settingName,
                ).push(context);
                final realRes = res is Function ? res.call() : res;
                if (realRes != null) {
                  ref.invalidate(templateListProvider(serverId, settingName));
                }
              },
              child: AppBarIconButton(context.appIcons.add),
            ),
          ],
          bottom: TabBar(
            controller: tabController,
            dividerHeight: 0,
            tabs: tabs
                .map(
                  (tab) => Tab(text: Intl.message(tab, name: tab).capitalCase),
                )
                .toList(),
          ),
        ).getAppBar(context),
        body: TabBarView(
          controller: tabController,
          children: tabs
              .map((tab) => TemplateList(serverId: serverId, settingName: tab))
              .toList(),
        ),
      ),
    );
  }
}
