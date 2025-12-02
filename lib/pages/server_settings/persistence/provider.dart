import "package:certimate/api/setting_api.dart";
import "package:certimate/pages/server/provider.dart";
import "package:certimate/widgets/refresh_body.dart";
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_riverpod/experimental/mutation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "provider.g.dart";

@riverpod
class ServerPersistenceNotifier extends _$ServerPersistenceNotifier
    with SubmitMixin {
  static final submitLoading = Mutation<void>();

  @override
  final formKey = GlobalKey<FormBuilderState>();

  @override
  Mutation get submitMutation => submitLoading(serverId);

  @override
  FutureOr<SubmitRefreshData<PersistenceContent?>> build(int serverId) async {
    final server = ref.watch(serverProvider(serverId)).value!;
    final data = await ref.watch(settingApiProvider).getPersistence(server);
    return SubmitRefreshData([data]);
  }

  @override
  Future submit(context, data) async {
    final server = ref.watch(serverProvider(serverId)).value!;
    await ref
        .watch(settingApiProvider)
        .updatePersistence(
          server,
          workflowRunsMaxDaysRetention: data["workflowRunsMaxDaysRetention"],
          expiredCertificatesMaxDaysRetention:
              data["expiredCertificatesMaxDaysRetention"],
        );
  }
}
