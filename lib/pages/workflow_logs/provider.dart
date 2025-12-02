import "package:certimate/api/workflow_api.dart";
import "package:certimate/pages/server/provider.dart";
import "package:certimate/widgets/refresh_body.dart";
import "package:copy_with_extension/copy_with_extension.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "provider.g.dart";

@CopyWith()
class WorkflowLogsData extends RefreshData<WorkflowLogResult> {
  @override
  final List<WorkflowLogResult> list;

  final WorkflowRunDetailResult detail;

  @override
  int get topItemCount => 3;

  const WorkflowLogsData(this.detail, this.list);
}

@riverpod
class WorkflowLogsNotifier extends _$WorkflowLogsNotifier {
  @override
  Future<WorkflowLogsData> build(int serverId, String runId) async {
    try {
      final server = ref.watch(serverProvider(serverId)).value!;
      final detail = await ref
          .read(workflowApiProvider)
          .getRunDetail(server, runId);
      final logsRes = await ref
          .watch(workflowApiProvider)
          .getRunLogs(server, runId);
      return WorkflowLogsData(detail, logsRes.items);
    } catch (e) {
      if (state.isRefreshing && state.hasValue) {
        SmartDialog.showNotify(msg: e.toString(), notifyType: NotifyType.error);
        return state.requireValue;
      }
      rethrow;
    }
  }
}
