import "package:adaptive_dialog/adaptive_dialog.dart";
import "package:certimate/api/server_api.dart";
import "package:certimate/api/workflow_api.dart";
import "package:certimate/database/servers_dao.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/pages/home/provider.dart";
import "package:certimate/widgets/refresh_body.dart";
import "package:copy_with_extension/copy_with_extension.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "provider.g.dart";

@Riverpod(keepAlive: true)
class ServerNotifier extends _$ServerNotifier {
  @override
  Future<ServerModel?> build(int serverId) async {
    return await ref.watch(serversDaoProvider).getById(serverId);
  }

  Future<ServerModel?> updateServer(
    ServerModel newServer, {
    bool syncDatabase = false,
  }) {
    state = AsyncValue.data(newServer);
    ref.read(serverListProvider.notifier).updateServer(newServer);
    if (syncDatabase) {
      return ref
          .read(serversDaoProvider)
          .updateById(newServer.id, newServer.toUpdateCompanion());
    }
    return Future.value(newServer);
  }
}

@riverpod
class ServerStatisticsNotifier extends _$ServerStatisticsNotifier {
  @override
  Future<StatisticsResult> build(int serverId) async {
    // token 改变了，才重构
    ref.watch(
      serverProvider(serverId).select((item) => item.value?.token ?? ""),
    );
    final server = await ref.read(serverProvider(serverId).future);
    if (server == null) {
      return const StatisticsResult();
    }
    return await ref.watch(serverApiProvider).getStatistics(server);
  }
}

@riverpod
class ServerWorkflowRunNotifier extends _$ServerWorkflowRunNotifier {
  @override
  Future<List<WorkflowRunResult>> build(int serverId) async {
    // token 改变了，才重构
    ref.watch(
      serverProvider(serverId).select((item) => item.value?.token ?? ""),
    );
    final server = await ref.read(serverProvider(serverId).future);
    if (server == null) {
      return const [];
    }
    return (await ref.watch(workflowApiProvider).getRunRecords(server)).items;
  }
}

@CopyWith()
class ServerData extends RefreshData<WorkflowRunResult> {
  @override
  final List<WorkflowRunResult> list;

  @override
  int get topItemCount => 3;

  final StatisticsResult statistics;

  const ServerData(this.statistics, this.list);
}

@riverpod
class ServerDataNotifier extends _$ServerDataNotifier {
  @override
  Future<ServerData> build(int serverId) async {
    if (state.isRefreshing) {
      // 刷新依赖
      final _ = ref.refresh(serverStatisticsProvider(serverId).future);
      final _ = ref.refresh(serverWorkflowRunProvider(serverId).future);
    }
    try {
      final resList = await Future.wait([
        ref.watch(serverStatisticsProvider(serverId).future),
        ref.watch(serverWorkflowRunProvider(serverId).future),
      ]);
      return ServerData(
        resList[0] as StatisticsResult,
        resList[1] as List<WorkflowRunResult>,
      );
    } catch (e) {
      if (state.isRefreshing && state.hasValue) {
        // 有值的情况下，刷新失败只弹窗提示，保留之前的值
        SmartDialog.showNotify(msg: e.toString(), notifyType: NotifyType.error);
        return state.requireValue;
      }
      rethrow;
    }
  }

  Future<int> delete(BuildContext context) async {
    final server = ref.read(serverProvider(serverId)).value;
    if (server == null) {
      return 0;
    }
    final s = context.s;
    final res = await showOkCancelAlertDialog(
      context: context,
      title: '${s.delete.capitalCase} "${server.displayName}"',
      message: s.deleteAccessTip,
      okLabel: s.delete.capitalCase,
      defaultType: OkCancelAlertDefaultType.cancel,
      isDestructiveAction: true,
    );
    if (res == OkCancelResult.ok) {
      return await ref.read(serversDaoProvider).deleteById(server.id);
    }
    return 0;
  }
}
