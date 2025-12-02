import "package:certimate/extension/index.dart";
import "package:certimate/pages/server_settings/password/provider.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class ServerPasswordPage extends HookConsumerWidget {
  final int serverId;

  const ServerPasswordPage({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final provider = serverPasswordProvider(serverId);
    final notifier = ref.read(serverPasswordProvider(serverId).notifier);
    return BasePage(
      child: Scaffold(
        body: RefreshBody<OnlySubmitRefreshData>(
          title: Text(s.password.titleCase),
          provider: provider,
          itemBuilder: (context, data, index) {
            return FormBuilder(
              key: notifier.formKey,
              child: PlatformFormBuilderSection(
                children: [
                  PlatformFormBuilderTextField(
                    title: Text(s.currentPassword.capitalCase),
                    name: "password",
                    placeholder: s.pleaseEnter(s.currentPassword),
                    obscureText: true,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                    ]),
                  ),
                  PlatformFormBuilderTextField(
                    title: Text(s.newPassword.capitalCase),
                    name: "newPassword",
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
    );
  }
}
