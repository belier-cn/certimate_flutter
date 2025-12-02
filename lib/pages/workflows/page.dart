import "package:certimate/extension/index.dart";
import "package:certimate/hooks/easy_refresh.dart";
import "package:certimate/pages/workflows/provider.dart";
import "package:certimate/pages/workflows/widgets/workflow.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class WorkflowsPage extends HookConsumerWidget {
  final int serverId;

  const WorkflowsPage({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final provider = workflowsProvider(serverId);
    final searchController = useTextEditingController();
    final refreshController = useRefreshController();
    final scrollController = useScrollController();
    final topVisible = useValueNotifier(false);
    return BasePage(
      child: Scaffold(
        body: RefreshBody<WorkflowsData>(
          topVisible: topVisible,
          title: Text(s.workflows.titleCase),
          trailing: ActionButton(
            onPressed: () =>
                "/#/workflows/new".toServerWebview(context, serverId),
            child: AppBarIconButton(context.appIcons.add),
          ),
          refreshController: refreshController,
          scrollController: scrollController,
          searchController: searchController,
          searchPlaceholder: s.workflowsSearchPlaceholder.capitalCase,
          provider: provider,
          itemBuilder: (context, data, index) {
            final item = data.list[index];
            return WorkflowWidget(
              key: ValueKey(item.id),
              data: item,
              serverId: serverId,
              onRun: () {
                ref.read(provider.notifier).run(context, item);
              },
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
              onEnabled: ref.read(provider.notifier).enabled,
            );
          },
        ),
      ),
    );
  }
}
