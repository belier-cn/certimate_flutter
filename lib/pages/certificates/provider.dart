import "package:adaptive_dialog/adaptive_dialog.dart";
import "package:certimate/api/certificate_api.dart";
import "package:certimate/api/http.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/pages/server/provider.dart";
import "package:certimate/widgets/index.dart";
import "package:copy_with_extension/copy_with_extension.dart";
import "package:easy_refresh/easy_refresh.dart";
import "package:flutter/cupertino.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "provider.g.dart";

enum CertificateFilter implements FilterEnum {
  unexpired("validityNotAfter>'{time}'", 0),
  expired("validityNotAfter<='{time}'", 0),
  expiringSoon("validityNotAfter<'{time}' && validityNotAfter>@now", 20);

  final String value;

  final int days;

  @override
  String get filter => value.isEmpty
      ? ""
      : value.replaceFirst(
          "{time}",
          DateTime.now().add(Duration(days: -days)).toIso8601String(),
        );

  const CertificateFilter(this.value, this.days);
}

@CopyWith()
class CertificatesData extends RefreshData<CertificateResult> {
  @override
  final List<CertificateResult> list;

  const CertificatesData(this.list);
}

@riverpod
CertificateFilter? certificateFilter(Ref ref) => null;

@Riverpod(dependencies: [certificateFilter])
class CertificatesNotifier extends _$CertificatesNotifier
    with LoadMoreMixin, SearchMixin, FilterMixin {
  @override
  List<Enum> get filterItems => CertificateFilter.values;

  @override
  List<SortField> get sortItems => const [
    SortField(name: "createdAt", field: "created", firstSort: Sort.desc),
    SortField(name: "expiry", field: "validityNotAfter", firstSort: Sort.desc),
  ];

  @override
  Future<CertificatesData> build(int serverId) async {
    if (state.isLoading && state.value == null) {
      sortField = sortItems.first.field;
      sort = sortItems.first.firstSort;
      filter = ref.read(certificateFilterProvider);
    }
    try {
      return CertificatesData((await loadData()).items);
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

  Future<ApiPageResult<CertificateResult>> loadData({int loadPage = 1}) async {
    final server = ref.watch(serverProvider(serverId)).value!;
    final filters = [
      "deleted=null",
      searchKey.isEmpty
          ? ""
          : "(id='$searchKey' || serialNumber='$searchKey' || subjectAltNames~'$searchKey')",
      getFilter(),
    ];
    return await ref
        .watch(certificateApiProvider)
        .getRecords(
          server,
          page: loadPage,
          sort: getSort(),
          filter: filters.where((filter) => filter.isNotEmpty).join("&&"),
        )
        .then((res) {
          hasMore = res.totalPages > res.page;
          total = res.totalItems;
          page = loadPage;
          return res;
        });
  }

  Future<bool> revoke(BuildContext context, CertificateResult cert) async {
    final s = context.s;
    final res = await showOkCancelAlertDialog(
      context: context,
      title: '${s.revoke.capitalCase} "${cert.subjectAltNames}"',
      message: s.revokeCertificateTip,
      okLabel: s.revoke.capitalCase,
      defaultType: OkCancelAlertDefaultType.cancel,
      isDestructiveAction: true,
    );
    if (res == OkCancelResult.ok) {
      final server = ref.watch(serverProvider(serverId)).value!;
      await ref.watch(certificateApiProvider).revoke(server, cert.id ?? "");
      updateCertificateRevoked(cert.id ?? "");
      return true;
    }
    return false;
  }

  void updateCertificateRevoked(String id) {
    final list = state.value?.list;
    if (list != null) {
      final index = list.indexWhere((item) => item.id == id);
      if (index >= 0) {
        state = AsyncValue.data(
          state.requireValue.copyWith(
            list: [...list]
              ..setAll(index, [list[index].copyWith(isRevoked: true)]),
          ),
        );
      }
    }
  }

  Future<bool> delete(BuildContext context, CertificateResult cert) async {
    final s = context.s;
    final res = await showOkCancelAlertDialog(
      context: context,
      title: '${s.delete.capitalCase} "${cert.subjectAltNames}"',
      message: s.deleteCertificateTip,
      okLabel: s.delete.capitalCase,
      defaultType: OkCancelAlertDefaultType.cancel,
      isDestructiveAction: true,
    );
    if (res == OkCancelResult.ok) {
      final server = ref.watch(serverProvider(serverId)).value!;
      await ref.watch(certificateApiProvider).delete(server, cert.id ?? "");
      return true;
    }
    return false;
  }
}
