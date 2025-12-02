import "package:certimate/extension/index.dart";
import "package:certimate/pages/access_edit/provider.dart";
import "package:certimate/pages/accesses/provider.dart";
import "package:certimate/pages/server/provider.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_json_view/flutter_json_view.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:intl/intl.dart";

class AccessEditPage extends HookConsumerWidget {
  final int serverId;

  final String accessId;

  final bool readonly;

  const AccessEditPage({
    super.key,
    required this.serverId,
    required this.accessId,
    required this.readonly,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final theme = Theme.of(context);
    final jsonViewTheme = JsonViewTheme(
      backgroundColor:
          theme.inputDecorationTheme.fillColor ?? theme.colorScheme.onPrimary,
      openIcon: Icon(
        Icons.arrow_drop_down,
        size: 18,
        color: theme.colorScheme.onPrimaryContainer,
      ),
      closeIcon: Icon(
        Icons.arrow_drop_up,
        size: 18,
        color: theme.colorScheme.onPrimaryContainer,
      ),
      defaultTextStyle: theme.textTheme.bodyMedium!.copyWith(
        fontWeight: FontWeight.w500,
      ),
    );
    return BasePage(
      child: Scaffold(
        body: RefreshBody<AccessDetailData>(
          title: readonly
              ? Consumer(
                  builder: (_, ref, _) {
                    final data = ref.watch(
                      accessDetailProvider(serverId, accessId),
                    );
                    if (data.hasValue && data.requireValue.list.isNotEmpty) {
                      return Text(
                        data.requireValue.list.first.name ?? accessId,
                      );
                    }
                    return const SizedBox();
                  },
                )
              : Text(s.edit.titleCase),
          trailing: readonly ? const SizedBox() : null,
          searchPlaceholder: s.credentialsSearchPlaceholder.capitalCase,
          provider: accessDetailProvider(serverId, accessId),
          itemBuilder: (context, data, index) {
            final server = ref.read(serverProvider(serverId));
            final item = data.list[index];
            final notifier = ref.read(
              accessDetailProvider(serverId, accessId).notifier,
            );
            final usage = AccessFilter.values.firstWhere(
              (filter) => filter.value == item.reserve,
              orElse: () => AccessFilter.dnsProvider,
            );
            return FormBuilder(
              key: notifier.formKey,
              child: PlatformFormBuilderSection(
                insetGrouped: false,
                children: [
                  PlatformFormBuilderTextField(
                    title: Text(s.name.capitalCase),
                    name: "name",
                    initialValue: item.name,
                    readOnly: readonly,
                    placeholder: s.pleaseEnter(s.name),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                    ]),
                  ),
                  PlatformFormBuilderTextField(
                    title: Text(s.type.capitalCase),
                    name: "type",
                    initialValue: Intl.message(
                      usage.name,
                      name: usage.name,
                    ).capitalCase,
                    readOnly: true,
                    enabled: readonly,
                  ),
                  PlatformFormBuilderTextField(
                    title: Text(s.provider.capitalCase),
                    name: "provider",
                    initialValue: item.provider?.capitalCase,
                    readOnly: true,
                    enabled: readonly,
                    prefix: item.provider != null
                        ? Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: SvgPicture.network(
                              item.provider!.providerSvg(
                                server.value?.host ?? "",
                              ),
                            ),
                          )
                        : null,
                    prefixIconConstraints: const BoxConstraints(
                      maxWidth: 32,
                      maxHeight: 26,
                    ),
                  ),
                  if (readonly)
                    PlatformFormBuilderTextField(
                      title: Text(s.createdAt.capitalCase),
                      name: "created",
                      initialValue: item.created.toDateTimeString(),
                      readOnly: true,
                    ),
                  readonly
                      ? ModelDetailCell.string(
                          label: s.accessConfig.capitalCase,
                          title: JsonView.map(
                            item.config ?? {},
                            theme: jsonViewTheme,
                          ),
                          titlePadding: EdgeInsets.zero,
                          textFieldBorder: readonly,
                        )
                      : PlatformFormBuilderTextField(
                          title: Text(s.accessConfig.capitalCase),
                          name: "config",
                          maxLines: 10,
                          initialValue: item.config.toJsonString(),
                          placeholder: s.pleaseEnter(s.accessConfig),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.json(),
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
