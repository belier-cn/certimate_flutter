import "package:certimate/database/servers_dao.dart";
import "package:certimate/widgets/refresh_body.dart";
import "package:copy_with_extension/copy_with_extension.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "provider.g.dart";

@CopyWith()
class ServersData extends RefreshData<ServerModel> {
  @override
  final List<ServerModel> list;

  const ServersData(this.list);
}

@riverpod
class ServerListNotifier extends _$ServerListNotifier with SearchMixin {
  @override
  Future<ServersData> build() async {
    try {
      return ServersData(
        await ref.watch(serversDaoProvider).getAll(displayName: searchKey),
      );
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
        state = AsyncValue.data(
          state.requireValue.copyWith(list: [...list]..setAll(index, [server])),
        );
      }
    }
  }

  void addServer(ServerModel server) {
    final list = state.value?.list;
    if (list != null) {
      state = AsyncValue.data(
        state.requireValue.copyWith(list: [...list, server]),
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
