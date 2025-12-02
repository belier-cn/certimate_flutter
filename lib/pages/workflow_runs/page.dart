import "package:certimate/extension/index.dart";
import "package:certimate/hooks/easy_refresh.dart";
import "package:certimate/pages/workflow_runs/provider.dart";
import "package:certimate/pages/workflow_runs/widgets/workflow_run.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class WorkflowRunsPage extends HookConsumerWidget {
  final int serverId;
  final String workflowId;

  const WorkflowRunsPage({
    super.key,
    required this.serverId,
    required this.workflowId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final refreshController = useRefreshController();
    final scrollController = useScrollController();
    final topVisible = useValueNotifier(false);
    final provider = workflowRunsProvider(serverId, workflowId);
    return BasePage(
      child: Scaffold(
        body: RefreshBody<WorkflowRunsData>(
          topVisible: topVisible,
          title: Text(s.workflowRuns.titleCase),
          provider: provider,
          itemBuilder: (context, data, index) {
            final item = data.list[index];
            return WorkflowRunWidget(
              key: ValueKey(item.id),
              data: item,
              serverId: serverId,
              workflowId: workflowId,
              onCancel: () {
                ref.read(provider.notifier).cancel(context, item);
              },
              onDelete: () async {
                if (await ref.read(provider.notifier).delete(context, item)) {
                  refreshController.callRefresh(
                    scrollController: scrollController,
                  );
                }
              },
            );
          },
          refreshController: refreshController,
          scrollController: scrollController,
        ),
      ),
    );
  }
}
