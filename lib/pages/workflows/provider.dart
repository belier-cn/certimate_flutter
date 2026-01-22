import "package:adaptive_dialog/adaptive_dialog.dart";
import "package:certimate/api/http.dart";
import "package:certimate/api/workflow_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/widgets/refresh_body.dart";
import "package:copy_with_extension/copy_with_extension.dart";
import "package:easy_refresh/easy_refresh.dart";
import "package:flutter/material.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "provider.g.dart";

enum WorkflowFilter implements FilterEnum {
  active("true"),
  inactive("false");

  final String value;

  @override
  String get filter => value.isEmpty ? "" : "enabled=$value";

  const WorkflowFilter(this.value);
}

@CopyWith()
class WorkflowsData extends RefreshData<WorkflowResult> {
  @override
  final List<WorkflowResult> list;

  const WorkflowsData(this.list);
}

@riverpod
WorkflowFilter? workflowFilter(Ref ref) => null;

@Riverpod(dependencies: [workflowFilter])
class WorkflowsNotifier extends _$WorkflowsNotifier
    with LoadMoreMixin, SearchMixin, FilterMixin {
  @override
  List<Enum> get filterItems => WorkflowFilter.values;

  @override
  List<SortField> get sortItems => const [
    SortField(name: "createdAt", field: "created", firstSort: Sort.desc),
    SortField(name: "lastRunAt", field: "lastRunTime", firstSort: Sort.desc),
  ];

  @override
  Future<WorkflowsData> build(int serverId) async {
    if (state.isLoading && state.value == null) {
      sortField = sortItems.first.field;
      sort = sortItems.first.firstSort;
      filter = ref.read(workflowFilterProvider);
    }
    try {
      return WorkflowsData((await loadData()).items);
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

  Future<ApiPageResult<WorkflowResult>> loadData({int loadPage = 1}) async {
    final filters = [
      searchKey.isEmpty ? "" : "(id='$searchKey' || name~'$searchKey')",
      getFilter(),
    ];
    return await ref
        .watch(workflowApiProvider(serverId))
        .getRecords(
          page: loadPage,
          sort: getSort(),
          filter: filters.where((filter) => filter.isNotEmpty).join("&&"),
        )
        .then((res) {
          hasMore = res.totalPages > res.page;
          page = loadPage;
          total = res.totalItems;
          return res;
        });
  }

  Future<bool> delete(BuildContext context, WorkflowResult workflow) async {
    final s = context.s;
    final res = await showOkCancelAlertDialog(
      context: context,
      title: '${s.delete.capitalCase} "${workflow.name}"',
      message: s.deleteWorkflowTip,
      okLabel: s.delete.capitalCase,
      defaultType: OkCancelAlertDefaultType.cancel,
      isDestructiveAction: true,
    );
    if (res == OkCancelResult.ok) {
      await ref.watch(workflowApiProvider(serverId)).delete(workflow.id ?? "");
      return true;
    }
    return false;
  }

  Future<bool> copy(BuildContext context, WorkflowResult workflow) async {
    final s = context.s;
    final res = await showOkCancelAlertDialog(
      context: context,
      title: '${s.copy.capitalCase} "${workflow.name}"',
      message: s.copyWorkflowTip,
      okLabel: s.copy.capitalCase,
      defaultType: OkCancelAlertDefaultType.cancel,
    );
    if (res == OkCancelResult.ok) {
      await ref.watch(workflowApiProvider(serverId)).copy(workflow.id ?? "");
      return true;
    }
    return false;
  }

  Future<void> run(BuildContext context, WorkflowResult workflow) async {
    final s = context.s;
    final res = await showOkCancelAlertDialog(
      context: context,
      title: '${s.run.capitalCase} "${workflow.name}"',
      message: s.runWorkflowTip,
      okLabel: s.run.capitalCase,
      defaultType: OkCancelAlertDefaultType.cancel,
    );
    if (res == OkCancelResult.ok) {
      await ref.watch(workflowApiProvider(serverId)).run(workflow.id ?? "");
      if (context.mounted) {
        showOkAlertDialog(context: context, message: s.executeWorkflowSuccess);
      }
    }
  }

  Future<bool> enabled(BuildContext context, WorkflowResult workflow) async {
    final enabled = workflow.enabled ?? false;
    if (workflow.enabled != true && workflow.hasContent != true) {
      showOkAlertDialog(context: context, message: context.s.unpublishedTip);
      return enabled;
    }
    await ref
        .watch(workflowApiProvider(serverId))
        .enabled(workflow.id ?? "", !enabled);
    return !enabled;
  }
}
