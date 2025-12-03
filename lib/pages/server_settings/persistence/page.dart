import "package:certimate/api/setting_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/pages/server_settings/persistence/provider.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class ServerPersistencePage extends HookConsumerWidget {
  final int serverId;

  const ServerPersistencePage({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final provider = serverPersistenceProvider(serverId);
    final inputFormatters = [const IntegerInputFormatter()];
    final validator = FormBuilderValidators.compose([
      FormBuilderValidators.required(),
      FormBuilderValidators.numeric(),
      FormBuilderValidators.max(36500),
    ]);
    return BasePage(
      child: Scaffold(
        body: RefreshBody<SubmitRefreshData<PersistenceContent?>>(
          title: Text(s.persistence.titleCase),
          provider: provider,
          itemBuilder: (context, data, index) {
            final notifier = ref.read(provider.notifier);
            return FormBuilder(
              key: notifier.formKey,
              child: PlatformFormBuilderSection(
                insetGrouped: false,
                children: [
                  PlatformFormBuilderTextField(
                    title: Text(s.workflowRunsMaxDaysRetention.capitalCase),
                    name: "workflowRunsMaxDaysRetention",
                    initialValue:
                        "${data.value?.workflowRunsMaxDaysRetention ?? 0}",
                    inputFormatters: inputFormatters,
                    validator: validator,
                    valueTransformer: integerValueTransformer,
                  ),
                  PlatformFormBuilderTextField(
                    name: "expiredCertificatesMaxDaysRetention",
                    title: Text(
                      s.expiredCertificatesMaxDaysRetention.capitalCase,
                    ),
                    initialValue:
                        "${data.value?.expiredCertificatesMaxDaysRetention ?? 0}",
                    inputFormatters: inputFormatters,
                    validator: validator,
                    valueTransformer: integerValueTransformer,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
