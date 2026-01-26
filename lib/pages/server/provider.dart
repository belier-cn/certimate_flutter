import "dart:async";

import "package:adaptive_dialog/adaptive_dialog.dart";
import "package:certimate/api/server_api.dart";
import "package:certimate/api/workflow_api.dart";
import "package:certimate/database/database.dart";
import "package:certimate/database/servers_dao.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/pages/home/provider.dart";
import "package:certimate/provider/local_certimate.dart";
import "package:certimate/widgets/refresh_body.dart";
import "package:copy_with_extension/copy_with_extension.dart";
import "package:drift/drift.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:version/version.dart";

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

  Future<void> setAutoStart(bool autoStart) async {
    state = AsyncValue.data(state.value?.copyWith(autoStart: autoStart));
    try {
      await ref
          .read(serversDaoProvider)
          .updateById(serverId, ServersCompanion(autoStart: Value(autoStart)));
    } catch (e) {
      SmartDialog.showNotify(msg: e.toString(), notifyType: NotifyType.error);
    }
  }

  void setLocalVersion(String version) {
    state = AsyncValue.data(state.value?.copyWith(version: version));
  }
}

@riverpod
class ServerStatisticsNotifier extends _$ServerStatisticsNotifier {
  @override
  Future<StatisticsResult> build(int serverId) async {
    final token = await ref.watch(
      serverProvider(serverId).selectAsync((item) => item?.token ?? ""),
    );
    if (token.isEmpty) {
      return const StatisticsResult();
    }
    return await ref.watch(serverApiProvider(serverId)).getStatistics();
  }
}

@riverpod
class ServerWorkflowRunNotifier extends _$ServerWorkflowRunNotifier {
  @override
  Future<List<WorkflowRunResult>> build(int serverId) async {
    final token = await ref.watch(
      serverProvider(serverId).selectAsync((item) => item?.token ?? ""),
    );
    if (token.isEmpty) {
      return const [];
    }
    return (await ref.watch(workflowApiProvider(serverId)).getRunRecords())
        .items;
  }
}

@CopyWith()
class ServerData extends RefreshData<WorkflowRunResult> {
  @override
  final List<WorkflowRunResult> list;

  @override
  int get topItemCount => 4;

  final StatisticsResult statistics;

  final ServerModel? server;

  final bool isRunning;

  const ServerData(this.isRunning, this.server, this.statistics, this.list);
}

@riverpod
class ServerDataNotifier extends _$ServerDataNotifier {
  @override
  Future<ServerData> build(int serverId) async {
    if (state.isRefreshing) {
      // 失效旧值
      ref.invalidate(serverStatisticsProvider(serverId));
      ref.invalidate(serverWorkflowRunProvider(serverId));
    }
    try {
      final server = await ref.read(serverProvider(serverId).future);
      if (server == null) {
        return const ServerData(false, null, StatisticsResult(), []);
      }
      if (server.localId.isNotEmpty) {
        final isRunning = ref.watch(
          localServerControlProvider(serverId).select((val) => val.isRunning),
        );
        if (!isRunning) {
          return ServerData(false, server, const StatisticsResult(), const [
            // 避免显示 EmptyWidget
            WorkflowRunResult(),
          ]);
        }
      }
      final (statistics, workflowRuns) = await wait2(
        ref.watch(serverStatisticsProvider(serverId).future),
        ref.watch(serverWorkflowRunProvider(serverId).future),
      );
      return ServerData(true, server, statistics, workflowRuns);
    } catch (e) {
      if (state.isRefreshing && state.hasValue) {
        if (state.requireValue.server?.localId.isNotEmpty == true &&
            !state.requireValue.isRunning) {
          rethrow;
        }
        // 有值的情况下，刷新失败只弹窗提示，保留之前的值
        SmartDialog.showNotify(msg: e.toString(), notifyType: NotifyType.error);
        return state.requireValue;
      }
      rethrow;
    }
  }

  Future<int> delete(BuildContext context) async {
    final server = await ref.read(serverProvider(serverId).future);
    if (server == null || !context.mounted) {
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
      if (server.localId.isNotEmpty) {
        await ref.read(localCertimateManagerProvider).stopLocalServer(server);
      }
      return await ref.read(serversDaoProvider).deleteById(server.id);
    }
    return 0;
  }
}

@CopyWith()
class LocalServerControlState {
  final bool isRunning;
  final bool isBusy;

  const LocalServerControlState({required this.isRunning, this.isBusy = false});
}

@riverpod
class LocalServerControlNotifier extends _$LocalServerControlNotifier {
  @override
  LocalServerControlState build(int serverId) {
    unawaited(refresh());
    return const LocalServerControlState(isRunning: false);
  }

  Future<ServerModel?> _getServer() {
    return ref.read(serverProvider(serverId).future);
  }

  Future<void> refresh() async {
    final server = await _getServer();
    if (server == null || server.localId.isEmpty) {
      state = state.copyWith(isRunning: false);
      return;
    }
    final isRunning = await ref
        .read(localCertimateManagerProvider)
        .isLocalServerRunning(server);
    state = state.copyWith(isRunning: isRunning);
  }

  Future<void> start() async {
    final server = await _getServer();
    if (server == null || server.localId.isEmpty) {
      return;
    }
    state = state.copyWith(isBusy: true);
    try {
      await ref.read(localCertimateManagerProvider).startLocalServer(server);
    } catch (e) {
      SmartDialog.showNotify(msg: e.toString(), notifyType: NotifyType.error);
    }
    await refresh();
    state = state.copyWith(isBusy: false);
  }

  Future<void> stop() async {
    final server = await _getServer();
    if (server == null || server.localId.isEmpty) {
      return;
    }
    state = state.copyWith(isBusy: true);
    try {
      await ref.read(localCertimateManagerProvider).stopLocalServer(server);
    } catch (e) {
      SmartDialog.showNotify(msg: e.toString(), notifyType: NotifyType.error);
    }
    await refresh();
    state = state.copyWith(isBusy: false);
  }

  Future<void> restart() async {
    final server = await _getServer();
    if (server == null || server.localId.isEmpty) {
      return;
    }
    state = state.copyWith(isBusy: true);
    try {
      await ref.read(localCertimateManagerProvider).restartLocalServer(server);
    } catch (e) {
      SmartDialog.showNotify(msg: e.toString(), notifyType: NotifyType.error);
    }
    await refresh();
    state = state.copyWith(isBusy: false);
  }

  Future<void> upgrade(String newVersion) async {
    final server = await _getServer();
    if (server == null || server.localId.isEmpty) {
      return;
    }

    state = state.copyWith(isBusy: true);
    try {
      await ref
          .read(localCertimateManagerProvider)
          .upgradeLocalServer(server, newVersion);
      // 同步数据
      ref.read(serverProvider(serverId).notifier).setLocalVersion(newVersion);
    } catch (e) {
      SmartDialog.showNotify(msg: e.toString(), notifyType: NotifyType.error);
    }
    await refresh();
    state = state.copyWith(isBusy: false);
  }
}

@Riverpod(keepAlive: true)
class LocalServerUpdateNotifier extends _$LocalServerUpdateNotifier {
  @override
  Future<String?> build() async {
    if (kIsWeb || !RunPlatform.isDesktop) {
      return null;
    }

    final latest = await ref
        .read(localCertimateManagerProvider)
        .getLatestReleaseInfo(forceRefresh: true);
    return latest.version;
  }

  bool isUpdateAvailable({
    required String currentVersion,
    required String latestVersion,
  }) {
    final current = _normalizeTagVersion(currentVersion);
    final latest = _normalizeTagVersion(latestVersion);
    if (latest.isEmpty) {
      return false;
    }
    if (current.isEmpty) {
      return false;
    }
    try {
      return Version.parse(latest) > Version.parse(current);
    } catch (_) {
      return false;
    }
  }

  String _normalizeTagVersion(String input) {
    final trimmed = input.trim();
    return trimmed.replaceFirst(RegExp(r"^[vV]"), "");
  }
}
