import "package:certimate/extension/index.dart";
import "package:certimate/pages/server_settings/account/provider.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class ServerAccountPage extends HookConsumerWidget {
  final int serverId;

  const ServerAccountPage({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final provider = serverAccountProvider(serverId);
    final notifier = ref.read(serverAccountProvider(serverId).notifier);
    return BasePage(
      child: Scaffold(
        body: RefreshBody<ServerAccountData>(
          title: Text(s.account.titleCase),
          provider: provider,
          itemBuilder: (context, data, index) {
            return FormBuilder(
              key: notifier.formKey,
              child: PlatformFormBuilderSection(
                children: [
                  PlatformFormBuilderTextField(
                    title: Text(s.email.capitalCase),
                    name: "email",
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
    );
  }
}
