import "package:adaptive_dialog/adaptive_dialog.dart";
import "package:certimate/api/http.dart";
import "package:certimate/api/workflow_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/pages/server/provider.dart";
import "package:certimate/widgets/refresh_body.dart";
import "package:copy_with_extension/copy_with_extension.dart";
import "package:easy_refresh/easy_refresh.dart";
import "package:flutter/material.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "provider.g.dart";

@CopyWith()
class WorkflowRunsData extends RefreshData<WorkflowRunResult> {
  @override
  final List<WorkflowRunResult> list;

  const WorkflowRunsData(this.list);
}

@riverpod
class WorkflowRunsNotifier extends _$WorkflowRunsNotifier with LoadMoreMixin {
  @override
  Future<WorkflowRunsData> build(int serverId, String workflowId) async {
    try {
      return WorkflowRunsData((await loadData()).items);
    } catch (e) {
      if (state.isRefreshing && state.hasValue) {
        SmartDialog.showNotify(msg: e.toString(), notifyType: NotifyType.error);
        return state.requireValue;
      }
      rethrow;
    }
  }

  @override
  Future<IndicatorResult> loadMore() async {
    if (!hasMore) {
      return IndicatorResult.noMore;
    }
    try {
      final res = await loadData(loadPage: page + 1);
      hasMore = res.items.isNotEmpty && res.totalPages > page;
      state = AsyncValue.data(
        state.requireValue.copyWith(
          list: [...state.requireValue.list, ...res.items],
        ),
      );
      return hasMore ? IndicatorResult.noMore : IndicatorResult.success;
    } catch (e) {
      SmartDialog.showNotify(msg: e.toString(), notifyType: NotifyType.error);
      return IndicatorResult.fail;
    }
  }

  Future<ApiPageResult<WorkflowRunResult>> loadData({int loadPage = 1}) async {
    final server = ref.watch(serverProvider(serverId)).value!;
    return await ref
        .watch(workflowApiProvider)
        .getRunRecords(
          server,
          page: loadPage,
          filter: "workflowRef='$workflowId'",
        )
        .then((res) {
          hasMore = res.totalPages > res.page;
          page = loadPage;
          total = res.totalItems;
          return res;
        });
  }

  Future<bool> delete(
    BuildContext context,
    WorkflowRunResult workflowRun,
  ) async {
    final s = context.s;
    final res = await showOkCancelAlertDialog(
      context: context,
      title: '${s.delete.capitalCase} "${workflowRun.id}"',
      message: s.deleteWorkflowRunTip,
      okLabel: s.delete.capitalCase,
      defaultType: OkCancelAlertDefaultType.cancel,
      isDestructiveAction: true,
    );
    if (res == OkCancelResult.ok) {
      final server = ref.watch(serverProvider(serverId)).value!;
      await ref
          .watch(workflowApiProvider)
          .deleteRun(server, workflowRun.id ?? "");
      return true;
    }
    return false;
  }

  Future<void> cancel(
    BuildContext context,
    WorkflowRunResult workflowRun,
  ) async {
    final s = context.s;
    final res = await showOkCancelAlertDialog(
      context: context,
      title: s.cancelWorkflowRun,
      message: s.cancelWorkflowRunTip,
      okLabel: s.ok.capitalCase,
      defaultType: OkCancelAlertDefaultType.cancel,
    );
    if (res == OkCancelResult.ok) {
      final server = ref.watch(serverProvider(serverId)).value!;
      await ref
          .watch(workflowApiProvider)
          .cancel(
            server,
            workflowRun.expand?.workflowRef?.id ?? "",
            workflowRun.id ?? "",
          );
      updateWorkflowRunCancel(workflowRun.id ?? "");
    }
  }

  void updateWorkflowRunCancel(String id) {
    final list = state.value?.list;
    if (list != null) {
      final index = list.indexWhere((item) => item.id == id);
      if (index >= 0) {
        state = AsyncValue.data(
          state.requireValue.copyWith(
            list: [...list]
              ..setAll(index, [list[index].copyWith(status: "canceled")]),
          ),
        );
      }
    }
  }
}
