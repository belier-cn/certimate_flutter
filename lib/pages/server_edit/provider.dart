import "package:certimate/api/auth_api.dart";
import "package:certimate/database/database.dart";
import "package:certimate/database/servers_dao.dart";
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
    final savePassword = data["savePassword"];
    final server = state.value?.value;
    String userId = "";
    String tokenValue = "";
    final passwordId = server?.passwordId ?? const UuidV4().generate();
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
      if (savePassword == true) {
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
        ),
      );
    } else {
      if (savePassword == true) {
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
        passwordId: savePassword ? Value(passwordId) : const Value(""),
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
      if (newServer != null && context.mounted) context.pop(newServer);
      return newServer;
    });
  }
}
