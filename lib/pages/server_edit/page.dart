import "package:certimate/database/servers_dao.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/pages/server_edit/provider.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class ServerEditPage extends HookConsumerWidget {
  final int? serverId;

  const ServerEditPage({super.key, this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final provider = serverEditProvider(serverId);
    final notifier = ref.read(provider.notifier);
    return BasePage(
      child: Scaffold(
        body: RefreshBody<SubmitRefreshData<ServerModel?>>(
          title: Text((serverId == null ? s.add : s.edit).titleCase),
          provider: provider,
          itemBuilder: (context, data, index) {
            final item = data.value;
            return FormBuilder(
              key: notifier.formKey,
              child: PlatformFormBuilderSection(
                children: [
                  PlatformFormBuilderTextField(
                    title: Text(s.displayName.capitalCase),
                    name: "displayName",
                    initialValue: item?.displayName,
                    placeholder: s.pleaseEnter(s.displayName),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                    ]),
                  ),
                  PlatformFormBuilderTextField(
                    title: Text(s.host.capitalCase),
                    name: "host",
                    initialValue: item?.host,
                    placeholder: s.pleaseEnter(s.url),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.url(),
                      FormBuilderValidators.matchNot(
                        RegExp(r"^(.*[^/])$"),
                        errorText: s.hostEndsErrorMsg,
                      ),
                    ]),
                  ),
                  PlatformFormBuilderTextField(
                    title: Text(s.user.capitalCase),
                    name: "username",
                    initialValue: item?.username,
                    placeholder: s.pleaseEnter(s.username),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                    ]),
                  ),
                  PlatformFormBuilderTextField(
                    title: Text(s.password.capitalCase),
                    name: "password",
                    initialValue: item?.passwordId,
                    placeholder: s.pleaseEnter(s.password),
                    obscureText: true,
                    validator: serverId == null
                        ? FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                          ])
                        : null,
                  ),
                  PlatformFormBuilderSwitch(
                    name: "savePassword",
                    initialValue: item?.passwordId.isNotEmptyOrNull ?? false,
                    title: Text(s.savePassword.capitalCase),
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
