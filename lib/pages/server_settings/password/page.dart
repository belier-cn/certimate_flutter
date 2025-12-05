import "package:certimate/extension/index.dart";
import "package:certimate/hooks/index.dart";
import "package:certimate/pages/server_settings/password/provider.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:keyboard_actions/keyboard_actions.dart";

class ServerPasswordPage extends HookConsumerWidget {
  final int serverId;

  const ServerPasswordPage({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final provider = serverPasswordProvider(serverId);
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
          child: RefreshBody<OnlySubmitRefreshData>(
            title: Text(s.password.titleCase),
            provider: provider,
            itemBuilder: (context, data, index) {
              final notifier = ref.read(
                serverPasswordProvider(serverId).notifier,
              );
              return FormBuilder(
                key: notifier.formKey,
                child: PlatformFormBuilderSection(
                  children: [
                    PlatformFormBuilderTextField(
                      title: Text(s.currentPassword.capitalCase),
                      name: "password",
                      focusNode: focusNodes[0],
                      placeholder: s.pleaseEnter(s.currentPassword),
                      obscureText: true,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                      ]),
                    ),
                    PlatformFormBuilderTextField(
                      title: Text(s.newPassword.capitalCase),
                      name: "newPassword",
                      focusNode: focusNodes[1],
                      placeholder: s.pleaseEnter(s.newPassword),
                      obscureText: true,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.password(),
                      ]),
                    ),
                    PlatformFormBuilderTextField(
                      title: Text(s.passwordConfirm.capitalCase),
                      name: "passwordConfirm",
                      focusNode: focusNodes[2],
                      placeholder: s.pleaseEnter(s.passwordConfirm),
                      obscureText: true,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.password(),
                        (val) {
                          final newPassword = notifier
                              .formKey
                              ?.currentState
                              ?.fields["newPassword"]
                              ?.value;
                          if (newPassword != val) {
                            return s.twicePasswordDifferent;
                          }
                          return null;
                        },
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
