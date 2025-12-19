import "dart:convert";

import "package:certimate/api/access_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/pages/server/provider.dart";
import "package:certimate/widgets/index.dart";
import "package:copy_with_extension/copy_with_extension.dart";
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_riverpod/experimental/mutation.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:go_router/go_router.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "provider.g.dart";

@CopyWith()
class AccessDetailData extends RefreshData<AccessDetailResult> {
  @override
  final List<AccessDetailResult> list;

  const AccessDetailData(this.list);
}

@riverpod
class AccessDetailNotifier extends _$AccessDetailNotifier with SubmitMixin {
  static final submitLoading = Mutation<void>();

  @override
  final formKey = GlobalKey<FormBuilderState>();

  @override
  Mutation get submitMutation => submitLoading;

  @override
  Future<AccessDetailData> build(int serverId, String accessId) async {
    try {
      return AccessDetailData([await loadData()]);
    } catch (e) {
      if (state.isRefreshing && state.hasValue) {
        SmartDialog.showNotify(msg: e.toString(), notifyType: NotifyType.error);
        return state.requireValue;
      }
      rethrow;
    }
  }

  Future<AccessDetailResult> loadData() async {
    final server = ref.watch(serverProvider(serverId)).value!;
    return await ref.watch(accessApiProvider).getDetail(server, accessId);
  }

  Future<AccessDetailResult> _submit(Map<String, dynamic> data) async {
    final server = ref.watch(serverProvider(serverId)).value!;
    await ref
        .read(accessApiProvider)
        .update(server, accessId, data["name"], jsonDecode(data["config"]));
    return state.requireValue.list.first.copyWith(name: data["name"]);
  }

  @override
  Future submit(context, data) async {
    await _submit(data).then((newData) {
      if (context.mounted) {
        context.pop(RunPlatform.isOhos ? () => newData : newData);
      }
    });
  }
}
