import "package:certimate/api/setting_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/widgets/refresh_body.dart";
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_riverpod/experimental/mutation.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
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
  FutureOr<SubmitRefreshData<SettingResult<PersistenceContent>>> build(
    int serverId,
  ) async {
    final data = await ref
        .watch(settingApiProvider(serverId))
        .getSettings<PersistenceContent>(
          "persistence",
          PersistenceContent.fromJson,
        );
    return SubmitRefreshData([data]);
  }

  @override
  Future submit(context, data) async {
    final newData = await ref
        .watch(settingApiProvider(serverId))
        .updateSettings<PersistenceContent>(
          state.requireValue.value.copyWith(
            content: PersistenceContent(
              workflowRunsMaxDaysRetention:
                  data["workflowRunsMaxDaysRetention"],
              certificatesWarningDaysBeforeExpire:
                  data["certificatesWarningDaysBeforeExpire"],
              expiredCertificatesMaxDaysRetention:
                  data["expiredCertificatesMaxDaysRetention"],
            ),
          ),
          PersistenceContent.fromJson,
          (item) => item.toJson(),
        );

    state = AsyncValue.data(SubmitRefreshData([newData]));
    if (context.mounted) {
      SmartDialog.showToast(context.s.saveSuccess.capitalCase);
    }
  }
}
