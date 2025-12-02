import "package:adaptive_dialog/adaptive_dialog.dart";
import "package:certimate/api/access_api.dart";
import "package:certimate/api/http.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/pages/server/provider.dart";
import "package:certimate/widgets/index.dart";
import "package:copy_with_extension/copy_with_extension.dart";
import "package:easy_refresh/easy_refresh.dart";
import "package:flutter/material.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "provider.g.dart";

enum AccessFilter implements FilterEnum {
  dnsProvider(""),
  certificateAuthority("ca"),
  notificationChannel("notif");

  final String value;

  @override
  String get filter => "reserve='$value'";

  const AccessFilter(this.value);
}

@CopyWith()
class AccessesData extends RefreshData<AccessResult> {
  @override
  final List<AccessResult> list;

  const AccessesData(this.list);
}

@riverpod
class AccessesNotifier extends _$AccessesNotifier
    with LoadMoreMixin, SearchMixin, FilterMixin {
  @override
  List<Enum> get filterItems => AccessFilter.values;

  @override
  List<SortField> get sortItems => [];

  @override
  Future<AccessesData> build(int serverId) async {
    try {
      return AccessesData((await loadData(1)).items);
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
      final res = await loadData(page + 1);
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

  Future<ApiPageResult<AccessResult>> loadData(int loadPage) async {
    final server = ref.watch(serverProvider(serverId)).value!;
    final filters = [
      "deleted=null",
      searchKey.isEmpty ? "" : "name='$searchKey'",
      getFilter(),
    ];
    return await ref
        .watch(accessApiProvider)
        .getRecords(
          server,
          page: loadPage,
          filter: filters.where((filter) => filter.isNotEmpty).join("&&"),
        )
        .then((res) {
          hasMore = res.totalPages > res.page;
          total = res.totalItems;
          page = loadPage;
          return res;
        });
  }

  Future<bool> copy(BuildContext context, AccessResult access) async {
    final s = context.s;
    final res = await showOkCancelAlertDialog(
      context: context,
      title: '${s.copy.capitalCase} "${access.name}"',
      message: s.copyAccessTip,
      okLabel: s.copy.capitalCase,
      defaultType: OkCancelAlertDefaultType.cancel,
    );
    if (res == OkCancelResult.ok) {
      final server = ref.watch(serverProvider(serverId)).value!;
      await ref.watch(accessApiProvider).copy(server, access.id ?? "");
      return true;
    }
    return false;
  }

  Future<bool> delete(BuildContext context, AccessResult access) async {
    final s = context.s;
    final res = await showOkCancelAlertDialog(
      context: context,
      title: '${s.delete.capitalCase} "${access.name}"',
      message: s.deleteAccessTip,
      okLabel: s.delete.capitalCase,
      defaultType: OkCancelAlertDefaultType.cancel,
      isDestructiveAction: true,
    );
    if (res == OkCancelResult.ok) {
      final server = ref.watch(serverProvider(serverId)).value!;
      await ref.watch(accessApiProvider).delete(server, access.id ?? "");
      return true;
    }
    return false;
  }

  void updateAccess(AccessDetailResult newData) {
    final list = state.value?.list;
    if (list != null) {
      final index = list.indexWhere(
        (item) => item.id == newData.id && item.name != newData.name,
      );
      if (index >= 0) {
        state = AsyncValue.data(
          state.requireValue.copyWith(
            list: [...list]
              ..setAll(index, [list[index].copyWith(name: newData.name)]),
          ),
        );
      }
    }
  }
}
