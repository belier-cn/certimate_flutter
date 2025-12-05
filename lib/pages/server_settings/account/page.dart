import "package:certimate/extension/index.dart";
import "package:certimate/hooks/index.dart";
import "package:certimate/pages/server_settings/account/provider.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:keyboard_actions/keyboard_actions.dart";

class ServerAccountPage extends HookConsumerWidget {
  final int serverId;

  const ServerAccountPage({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final provider = serverAccountProvider(serverId);
    final focusNodes = useFocusNodes(count: 1);
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
          child: RefreshBody<ServerAccountData>(
            title: Text(s.account.titleCase),
            provider: provider,
            itemBuilder: (context, data, index) {
              final notifier = ref.read(
                serverAccountProvider(serverId).notifier,
              );
              return FormBuilder(
                key: notifier.formKey,
                child: PlatformFormBuilderSection(
                  children: [
                    PlatformFormBuilderTextField(
                      title: Text(s.email.capitalCase),
                      name: "email",
                      focusNode: focusNodes[0],
                      initialValue: data.list.first,
                      placeholder: s.pleaseEnter(s.currentPassword),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                      ]),
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
