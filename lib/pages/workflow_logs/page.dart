import "dart:io";

import "package:certimate/api/workflow_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/hooks/easy_refresh.dart";
import "package:certimate/pages/workflow_logs/provider.dart";
import "package:certimate/pages/workflow_logs/widgets/workflow_log.dart";
import "package:certimate/pages/workflow_logs/widgets/workflow_node.dart";
import "package:certimate/pages/workflow_runs/widgets/workflow_run.dart";
import "package:certimate/widgets/index.dart";
import "package:collection/collection.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:flutter_tabler_icons/flutter_tabler_icons.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:intl/intl.dart";
import "package:path_provider/path_provider.dart";
import "package:share_plus/share_plus.dart";

class WorkflowLogsPage extends HookConsumerWidget {
  final int serverId;
  final String runId;

  const WorkflowLogsPage({
    super.key,
    required this.serverId,
    required this.runId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final refreshController = useRefreshController();
    final scrollController = useScrollController();
    final topVisible = useValueNotifier(false);
    final provider = workflowLogsProvider(serverId, runId);

    return BasePage(
      child: Scaffold(
        body: RefreshBody<WorkflowLogsData>(
          topVisible: topVisible,
          title: Text(s.workflowRunLogs.titleCase),
          itemSpacing: 0,
          provider: provider,
          itemBuilder: (context, data, index) {
            if (index == 0) {
              final milliseconds =
                  (data.detail.endedAt?.millisecondsSinceEpoch ?? 0) -
                  (data.detail.startedAt?.millisecondsSinceEpoch ?? 0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: WorkflowRunStatusWidget(
                  status: data.detail.status,
                  child: Text(
                    s.workflowRunDesc(
                      Intl.message(
                        data.detail.trigger ?? "",
                        name: data.detail.trigger ?? "",
                      ),
                      data.detail.startedAt.toDateTimeString(),
                      "${(milliseconds / 1000).toInt()}s",
                    ),
                  ),
                ),
              );
            }
            if (index == 1) {
              return Stack(
                children: [
                  TitleCard(
                    title: "流程",
                    child: WorkflowNodeWidget(
                      nodes: data.detail.graph?.nodes ?? [],
                    ),
                  ),
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: CupertinoWell(
                      onPressed: () {
                        SmartDialog.show(
                          builder: (_) => WorkflowNodeWidget(
                            nodes: data.detail.graph?.nodes ?? [],
                            fullscreen: true,
                          ),
                        );
                      },
                      child: const Icon(TablerIcons.maximize, size: 18),
                    ),
                  ),
                ],
              );
            }
            if (index == 2) {
              return TitleCard(title: s.logs.capitalCase, card: false);
            }
            final itemIndex = index - data.topItemCount;
            final item = data.list[itemIndex];
            final start = itemIndex == 0;
            return WorkflowLogWidget(
              key: ValueKey(item.id),
              data: item,
              start: start,
              status: start ? "succeeded" : null,
              onDownload: start ? () => _onDownload(data.list) : null,
              end: itemIndex == data.list.length - 1,
              node: start || item.nodeId != data.list[itemIndex - 1].nodeId,
            );
          },
          refreshController: refreshController,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _onDownload(List<WorkflowLogResult> logs) async {
    final newLine = "\n";
    final content = logs
        .groupListsBy((log) => log.nodeId)
        .entries
        .map((entry) {
          return "#${entry.key}${entry.value.first.nodeName}$newLine${entry.value.map((record) {
            final datetime = record.created.toDateTimeString();
            final level = record.level;
            final message = record.message;
            final data = record.data?.isNotEmpty == true ? record.data?.toJsonString() : "";
            return "[$datetime] [$level] ${_escape(message)} ${_escape(data)}";
          }).join(newLine)}";
        })
        .join(newLine + newLine);
    final fileName = "certimate_workflow_run_#${runId}_logs.txt";
    if (isPhoneDevice) {
      final temporaryDirectory = await getTemporaryDirectory();
      final filePath = "${temporaryDirectory.path}/$fileName";
      await File(filePath).writeAsString(content);
      SharePlus.instance.share(
        ShareParams(title: "Workflow logs", files: [XFile(filePath)]),
      );
    } else {
      String? initialDirectory;
      try {
        final directory = await getDownloadsDirectory();
        initialDirectory = directory?.path;
      } catch (e) {
        // no
      }
      final outputFile = await FilePicker.platform.saveFile(
        fileName: fileName,
        initialDirectory: initialDirectory,
      );
      if (outputFile != null) {
        await File(outputFile).writeAsString(content);
      }
    }
  }

  String _escape(String? str) {
    if (str == null) {
      return "";
    }
    return str.replaceAll("\r", "\\r").replaceAll("\n", "\\n");
  }
}
