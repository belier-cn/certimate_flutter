import "package:certimate/api/setting_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/hooks/index.dart";
import "package:certimate/pages/template_edit/provider.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:intl/intl.dart";
import "package:keyboard_actions/keyboard_actions.dart";
import "package:re_editor/re_editor.dart";
import "package:re_highlight/languages/bash.dart";
import "package:re_highlight/languages/shell.dart";
import "package:re_highlight/styles/github-dark.dart";
import "package:re_highlight/styles/github.dart";

class TemplateEditPage extends HookConsumerWidget {
  final int serverId;
  final String settingName;
  final int? templateIndex;

  const TemplateEditPage({
    super.key,
    required this.serverId,
    required this.settingName,
    this.templateIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final theme = context.theme;
    final isNotifyTemplate = settingName == "notifyTemplate";
    final provider = templateEditProvider(serverId, settingName, templateIndex);
    final focusNodes = useFocusNodes(count: isNotifyTemplate ? 3 : 2);
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
          child: RefreshBody<SubmitRefreshData<Object?>>(
            title: Text(
              s.join2(
                (templateIndex == null ? s.add : s.edit).titleCase,
                Intl.message(settingName, name: settingName),
              ),
            ),
            provider: provider,
            scrollController: scrollController,
            itemBuilder: (context, data, index) {
              final item = data.value;
              final notifier = ref.read(provider.notifier);
              final notifyTemplate = item is NotifyTemplate ? item : null;
              final scriptTemplate = item is ScriptTemplate ? item : null;
              return FormBuilder(
                key: notifier.formKey,
                child: PlatformFormBuilderSection(
                  insetGrouped: false,
                  children: [
                    PlatformFormBuilderTextField(
                      title: Text(s.name.capitalCase),
                      name: "name",
                      focusNode: focusNodes[0],
                      initialValue:
                          notifyTemplate?.name ?? scriptTemplate?.name,
                      placeholder: s.pleaseEnter(s.name),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                      ]),
                    ),
                    if (isNotifyTemplate)
                      PlatformFormBuilderTextField(
                        title: Text(s.subject.capitalCase),
                        name: "subject",
                        focusNode: focusNodes[1],
                        initialValue: notifyTemplate?.subject,
                        placeholder: s.pleaseEnter(s.subject),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                        ]),
                      ),
                    isNotifyTemplate
                        ? PlatformFormBuilderTextField(
                            title: Text(s.content.capitalCase),
                            name: "message",
                            focusNode: focusNodes[2],
                            initialValue: notifyTemplate?.message,
                            placeholder: s.pleaseEnter(s.content),
                            maxLines: isNotifyTemplate ? 8 : 6,
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                            ]),
                          )
                        : PlatformFormBuilderCodeField(
                            name: "command",
                            title: Text(s.command.capitalCase),
                            focusNode: focusNodes[1],
                            initialValue: scriptTemplate?.command,
                            placeholder: s.pleaseEnter(s.command),
                            maxLines: 6,
                            style: CodeEditorStyle(
                              codeTheme: CodeHighlightTheme(
                                languages: {
                                  "bash": CodeHighlightThemeMode(
                                    mode: langBash,
                                  ),
                                  "shell": CodeHighlightThemeMode(
                                    mode: langShell,
                                  ),
                                },
                                theme: theme.brightness == Brightness.light
                                    ? githubTheme
                                    : githubDarkTheme,
                              ),
                            ),
                            indicatorBuilder: indicatorBuilder,
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

  Widget indicatorBuilder(
    BuildContext context,
    CodeLineEditingController editingController,
    CodeChunkController chunkController,
    CodeIndicatorValueNotifier notifier,
  ) {
    return Row(
      children: [
        DefaultCodeLineNumber(
          controller: editingController,
          notifier: notifier,
        ),
        DefaultCodeChunkIndicator(
          width: 20,
          controller: chunkController,
          notifier: notifier,
        ),
      ],
    );
  }
}
