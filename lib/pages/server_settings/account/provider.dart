import "package:certimate/api/auth_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/pages/server/provider.dart";
import "package:certimate/provider/security.dart";
import "package:certimate/widgets/refresh_body.dart";
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_riverpod/experimental/mutation.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:go_router/go_router.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "provider.g.dart";

class ServerAccountData extends RefreshData<String?> {
  @override
  final List<String?> list;

  const ServerAccountData(this.list);
}

@riverpod
class ServerAccountNotifier extends _$ServerAccountNotifier with SubmitMixin {
  @override
  final formKey = GlobalKey<FormBuilderState>();

  static final submitLoading = Mutation<void>();

  @override
  Mutation get submitMutation => submitLoading(serverId);

  @override
  FutureOr<ServerAccountData> build(int serverId) {
    final server = ref.read(serverProvider(serverId));
    return ServerAccountData([server.value?.username]);
  }

  @override
  Future submit(context, data) async {
    final server = ref.watch(serverProvider(serverId)).value!;
    final email = data["email"];
    // 调用接口
    await ref
        .read(authApiProvider)
        .updateEmail(server, userId: server.userId, email: email);
    var newToken = "";
    if (server.passwordId.isNotEmpty) {
      final password = await secureStorage.read(key: server.passwordId);
      if (password.isNotEmptyOrNull) {
        try {
          // 重新登录
          final loginRes = await ref
              .read(authApiProvider)
              .login(server.host, email, password!);
          newToken = loginRes.token ?? "";
        } catch (e) {
          // no throw
        }
      }
    }
    // 同步数据
    await ref
        .read(serverProvider(serverId).notifier)
        .updateServer(
          server.copyWith(username: email, token: newToken),
          syncDatabase: true,
        );
    if (context.mounted) {
      // 成功提示
      SmartDialog.showNotify(
        msg: context.s.passwordUpdateSuccess,
        notifyType: NotifyType.success,
      );
      // 重新登录成功，就返回上一页，否则返回首页
      newToken.isNotEmpty ? context.pop() : context.go("/");
    }
  }
}
