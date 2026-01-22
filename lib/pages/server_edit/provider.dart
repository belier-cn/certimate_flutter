import "package:certimate/api/auth_api.dart";
import "package:certimate/database/database.dart";
import "package:certimate/database/servers_dao.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/provider/local_certimate.dart";
import "package:certimate/provider/security.dart";
import "package:certimate/widgets/refresh_body.dart";
import "package:drift/drift.dart";
import "package:flutter/cupertino.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_riverpod/experimental/mutation.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:go_router/go_router.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:uuid/v4.dart";

part "provider.g.dart";

@riverpod
class ServerEditNotifier extends _$ServerEditNotifier with SubmitMixin {
  static final submitLoading = Mutation<void>();

  @override
  final formKey = GlobalKey<FormBuilderState>();

  @override
  Mutation get submitMutation => submitLoading;

  @override
  FutureOr<SubmitRefreshData<ServerModel?>> build(int? serverId) async {
    if (serverId == null) {
      return const SubmitRefreshData([null]);
    }
    final server = await ref.watch(serversDaoProvider).getById(serverId);
    return SubmitRefreshData([server]);
  }

  Future<ServerModel?> _submit(Map<String, dynamic> data) async {
    final serversDao = ref.read(serversDaoProvider);
    final host = data["host"];
    final username = data["username"];
    final String password = data["password"];
    final displayName = data["displayName"];
    final savePassword = data["savePassword"] == true;
    final isLocal = data["isLocal"] == true;
    final server = state.value?.value;
    String userId = "";
    String tokenValue = "";
    String? localVersion;
    String? localPid;
    final passwordId = server?.passwordId.isNotEmpty == true
        ? server!.passwordId
        : const UuidV4().generate().replaceAll("-", "");
    final localId = server?.localId.isNotEmpty == true
        ? server!.passwordId
        : const UuidV4().generate().replaceAll("-", "");
    if (isLocal && serverId == null) {
      final result = await ref
          .read(localCertimateManagerProvider)
          .createLocalServer(
            host: host,
            displayName: displayName,
            username: username,
            password: password,
            localId: localId,
          );
      localVersion = result.version;
      localPid = result.pid;
    }
    if (serverId == null ||
        host != server?.host ||
        username != server?.username ||
        password != server?.passwordId) {
      final loginPassword = password == passwordId
          ? await secureStorage.read(key: password)
          : password;
      final loginRes = await ref
          .read(authApiProvider)
          .login(host, username, loginPassword ?? "");
      tokenValue = loginRes.token ?? "";
      userId = loginRes.record?.id ?? "";
      if (tokenValue.isEmpty) {
        final msg = "Failed to authenticate.";
        SmartDialog.showNotify(msg: msg, notifyType: NotifyType.error);
        return Future.error(msg);
      }
    }

    if (serverId == null) {
      if (savePassword) {
        // 保存密码
        await secureStorage.write(key: passwordId, value: password);
      }
      return await serversDao.insert(
        ServersCompanion.insert(
          displayName: displayName,
          host: host,
          userId: userId,
          username: username,
          passwordId: savePassword ? passwordId : "",
          token: tokenValue,
          createdAt: DateTime.now(),
          localId: Value.absentIfNull(localId),
          autoStart: Value.absentIfNull(isLocal ? true : null),
          version: Value.absentIfNull(localVersion),
          pid: Value.absentIfNull(localPid),
        ),
      );
    } else {
      if (savePassword) {
        if (password != passwordId) {
          // 保存新密码
          await secureStorage.write(key: passwordId, value: password);
        }
      } else {
        // 删除密码
        await secureStorage.delete(key: passwordId);
      }
      final companion = ServersCompanion(
        displayName: displayName != server?.displayName
            ? Value(displayName)
            : const Value.absent(),
        host: host != server?.host ? Value(host) : const Value.absent(),
        username: username != server?.username
            ? Value(username)
            : const Value.absent(),
        userId: userId.isNotEmpty && userId != server?.userId
            ? Value(userId)
            : const Value.absent(),
        passwordId: savePassword == true ? Value(passwordId) : const Value(""),
        token: tokenValue.isNotEmpty && tokenValue != server?.token
            ? Value(tokenValue)
            : const Value.absent(),
      );
      if (companion.toColumns(false).isEmpty) {
        return null;
      }
      return await serversDao.updateById(serverId!, companion);
    }
  }

  @override
  Future submit(context, data) {
    return _submit(data).then((newServer) {
      if (newServer != null && context.mounted) {
        context.pop(RunPlatform.isOhos ? () => newServer : newServer);
      }
      return newServer;
    });
  }
}
