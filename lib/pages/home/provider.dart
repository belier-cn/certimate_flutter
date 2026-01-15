import "package:certimate/database/servers_dao.dart";
import "package:certimate/widgets/refresh_body.dart";
import "package:copy_with_extension/copy_with_extension.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "provider.g.dart";

enum ServerFilter { localServer }

@CopyWith()
class ServersData extends RefreshData<ServerModel> {
  @override
  final List<ServerModel> list;

  const ServersData(this.list);
}

@riverpod
class ServerListNotifier extends _$ServerListNotifier
    with SearchMixin, FilterMixin {
  @override
  List<Enum> get filterItems => ServerFilter.values;

  @override
  List<SortField> get sortItems => const [
    SortField(name: "createdAt", field: "createdAt", firstSort: Sort.desc),
    SortField(name: "displayName", field: "displayName", firstSort: Sort.asc),
  ];

  bool _isLocalServer(ServerModel server) {
    return server.localId.isNotEmpty;
  }

  List<ServerModel> _applyFilterAndSort(List<ServerModel> list) {
    Iterable<ServerModel> filtered = list;
    if (filter == ServerFilter.localServer) {
      filtered = filtered.where(_isLocalServer);
    }

    final result = filtered.toList();

    int compareCreatedAt(ServerModel a, ServerModel b) {
      final cmp = a.createdAt.compareTo(b.createdAt);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    }

    int compareDisplayName(ServerModel a, ServerModel b) {
      final aName = a.displayName.trim().toLowerCase();
      final bName = b.displayName.trim().toLowerCase();
      final cmp = aName.compareTo(bName);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    }

    int Function(ServerModel a, ServerModel b) comparator;
    switch (sortField) {
      case "displayName":
        comparator = compareDisplayName;
        break;
      case "createdAt":
      default:
        comparator = compareCreatedAt;
        break;
    }

    if (sort == Sort.desc) {
      result.sort((a, b) => comparator(b, a));
    } else {
      result.sort(comparator);
    }

    return result;
  }

  @override
  Future<ServersData> build() async {
    if (state.isLoading && state.value == null) {
      sortField = sortItems.first.field;
      sort = sortItems.first.firstSort;
    }
    try {
      final list = await ref
          .watch(serversDaoProvider)
          .getAll(displayName: searchKey);
      return ServersData(_applyFilterAndSort(list));
    } catch (e) {
      if (state.isRefreshing && state.hasValue) {
        SmartDialog.showNotify(msg: e.toString(), notifyType: NotifyType.error);
        return state.requireValue;
      }
      rethrow;
    }
  }

  void updateServer(ServerModel server) {
    final list = state.value?.list;
    if (list != null) {
      final index = list.indexWhere((item) => item.id == server.id);
      if (index >= 0) {
        final next = [...list]..setAll(index, [server]);
        state = AsyncValue.data(
          state.requireValue.copyWith(list: _applyFilterAndSort(next)),
        );
      }
    }
  }

  void addServer(ServerModel server) {
    final list = state.value?.list;
    if (list != null) {
      state = AsyncValue.data(
        state.requireValue.copyWith(
          list: _applyFilterAndSort([...list, server]),
        ),
      );
    }
  }

  void deleteServer(int serverId) {
    final list = state.value?.list;
    if (list != null) {
      final index = list.indexWhere((item) => item.id == serverId);
      if (index >= 0) {
        state = AsyncValue.data(
          state.requireValue.copyWith(list: [...list]..removeAt(index)),
        );
      }
    }
  }
}
