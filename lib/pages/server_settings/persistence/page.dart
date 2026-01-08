import "package:certimate/api/setting_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/hooks/index.dart";
import "package:certimate/pages/server_settings/persistence/provider.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:keyboard_actions/keyboard_actions.dart";

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
    final focusNodes = useFocusNodes(count: 3);
    final scrollController = useScrollController();
    return BasePage(
      child: Scaffold(
        body: KeyboardActions(
          scrollController: scrollController,
          config: KeyboardActionsConfig(
            defaultDoneButtonText: s.done.capitalCase,
            keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
            actions: focusNodes
                .map((focusNode) => KeyboardActionsItem(focusNode: focusNode))
                .toList(),
          ),
          child: RefreshBody<SubmitRefreshData<SettingResult<PersistenceContent>>>(
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
                      title: Text(
                        s.certificatesWarningDaysBeforeExpire.capitalCase,
                      ),
                      name: "certificatesWarningDaysBeforeExpire",
                      focusNode: focusNodes[0],
                      initialValue:
                          "${data.value.content?.certificatesWarningDaysBeforeExpire ?? 21}",
                      inputFormatters: inputFormatters,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.numeric(),
                        FormBuilderValidators.min(1),
                        FormBuilderValidators.max(365),
                      ]),
                      valueTransformer: integerValueTransformer,
                    ),
                    PlatformFormBuilderTextField(
                      title: Text(s.workflowRunsMaxDaysRetention.capitalCase),
                      name: "workflowRunsMaxDaysRetention",
                      focusNode: focusNodes[1],
                      initialValue:
                          "${data.value.content?.workflowRunsMaxDaysRetention ?? 0}",
                      inputFormatters: inputFormatters,
                      validator: validator,
                      valueTransformer: integerValueTransformer,
                    ),
                    PlatformFormBuilderTextField(
                      title: Text(
                        s.expiredCertificatesMaxDaysRetention.capitalCase,
                      ),
                      name: "expiredCertificatesMaxDaysRetention",
                      focusNode: focusNodes[2],
                      initialValue:
                          "${data.value.content?.expiredCertificatesMaxDaysRetention ?? 0}",
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
      ),
    );
  }
}
