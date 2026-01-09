import "package:certimate/api/setting_api.dart";
import "package:certimate/hooks/easy_refresh.dart";
import "package:certimate/pages/template/provider.dart";
import "package:certimate/pages/template/widgets/notify_template.dart";
import "package:certimate/pages/template/widgets/script_template.dart";
import "package:certimate/router/route.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class TemplateList extends HookConsumerWidget {
  final int serverId;
  final String settingName;

  const TemplateList({
    super.key,
    required this.serverId,
    required this.settingName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();
    final provider = templateListProvider(serverId, settingName);
    final refreshController = useRefreshController();
    final scrollController = useScrollController();
    final topVisible = useValueNotifier(false);
    return BasePage(
      child: Scaffold(
        body: RefreshBody<TemplateListData>(
          topVisible: topVisible,
          refreshController: refreshController,
          scrollController: scrollController,
          provider: provider,
          itemBuilder: (context, data, index) {
            final item = data.list[index];
            if (item is NotifyTemplate) {
              return NotifyTemplateWidget(
                key: ValueKey(index),
                data: item,
                onEdit: () async {
                  final res = await TemplateEditRoute(
                    serverId: serverId,
                    settingName: settingName,
                    templateIndex: index,
                  ).push(context);
                  final realRes = res is Function ? res.call() : res;
                  if (realRes != null) {
                    refreshController.callRefresh(
                      scrollController: scrollController,
                    );
                  }
                },
              );
            } else if (item is ScriptTemplate) {
              return ScriptTemplateWidget(
                key: ValueKey(index),
                data: item,
                onEdit: () async {
                  final res = await TemplateEditRoute(
                    serverId: serverId,
                    settingName: settingName,
                    templateIndex: index,
                  ).push(context);
                  final realRes = res is Function ? res.call() : res;
                  if (realRes != null) {
                    refreshController.callRefresh(
                      scrollController: scrollController,
                    );
                  }
                },
              );
            }
            return Container(
              key: ValueKey(index),
              child: Text(item.toString()),
            );
          },
        ),
      ),
    );
  }
}
