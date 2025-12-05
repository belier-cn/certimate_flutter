import "package:certimate/database/servers_dao.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/hooks/index.dart";
import "package:certimate/pages/server_edit/provider.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:keyboard_actions/keyboard_actions.dart";

class ServerEditPage extends HookConsumerWidget {
  final int? serverId;

  const ServerEditPage({super.key, this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final provider = serverEditProvider(serverId);
    final focusNodes = useFocusNodes(count: 4);
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
          child: RefreshBody<SubmitRefreshData<ServerModel?>>(
            title: Text((serverId == null ? s.add : s.edit).titleCase),
            provider: provider,
            scrollController: scrollController,
            itemBuilder: (context, data, index) {
              final item = data.value;
              final notifier = ref.read(provider.notifier);
              return FormBuilder(
                key: notifier.formKey,
                child: PlatformFormBuilderSection(
                  children: [
                    PlatformFormBuilderTextField(
                      title: Text(s.displayName.capitalCase),
                      name: "displayName",
                      focusNode: focusNodes[0],
                      initialValue: item?.displayName,
                      placeholder: s.pleaseEnter(s.displayName),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                      ]),
                    ),
                    PlatformFormBuilderTextField(
                      title: Text(s.host.capitalCase),
                      name: "host",
                      focusNode: focusNodes[1],
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
                      focusNode: focusNodes[2],
                      initialValue: item?.username,
                      placeholder: s.pleaseEnter(s.username),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                      ]),
                    ),
                    PlatformFormBuilderTextField(
                      title: Text(s.password.capitalCase),
                      name: "password",
                      focusNode: focusNodes[3],
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
      ),
    );
  }
}
