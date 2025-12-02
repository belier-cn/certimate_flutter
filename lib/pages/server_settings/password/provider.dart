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

@riverpod
class ServerPasswordNotifier extends _$ServerPasswordNotifier with SubmitMixin {
  @override
  final formKey = GlobalKey<FormBuilderState>();

  static final submitLoading = Mutation<void>();

  @override
  Mutation get submitMutation => submitLoading(serverId);

  @override
  FutureOr<OnlySubmitRefreshData> build(int serverId) async {
    return const OnlySubmitRefreshData();
  }

  @override
  Future submit(context, data) async {
    final server = ref.watch(serverProvider(serverId)).value!;
    // 先判断旧密码是否正确
    final oldPassword = data["password"];
    final loginRes = await ref
        .read(authApiProvider)
        .login(server.host, server.username, oldPassword);
    // 调用修改密码的接口
    final password = data["newPassword"];
    final passwordConfirm = data["passwordConfirm"];
    await ref
        .read(authApiProvider)
        .updatePassword(
          server.copyWith(token: loginRes.token ?? ""),
          userId: server.userId,
          password: password,
          passwordConfirm: passwordConfirm,
        );
    var newToken = "";
    try {
      // 重新登录
      final loginRes = await ref
          .read(authApiProvider)
          .login(server.host, server.username, password);
      newToken = loginRes.token ?? "";
    } catch (e) {
      // no throw
    }
    if (server.passwordId.isNotEmpty) {
      // 保存密码
      secureStorage.write(key: server.passwordId, value: password);
    }
    // 同步数据
    ref
        .read(serverProvider(serverId).notifier)
        .updateServer(server.copyWith(token: newToken), syncDatabase: true);
    if (context.mounted) {
      // 成功提示
      SmartDialog.showNotify(
        msg: context.s.passwordUpdateSuccess,
        notifyType: NotifyType.success,
      );
      // 返回上一页
      newToken.isNotEmpty ? context.pop() : context.go("/");
    }
  }
}
