import "package:adaptive_dialog/adaptive_dialog.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/generated/intl/messages_all.dart";
import "package:certimate/generated/l10n.dart";
import "package:certimate/provider/language.dart";
import "package:certimate/provider/package.dart";
import "package:certimate/provider/platform.dart";
import "package:certimate/provider/security.dart";
import "package:certimate/provider/theme.dart";
import "package:certimate/router/route.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_platform_widgets/flutter_platform_widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:flutter_tabler_icons/flutter_tabler_icons.dart";
import "package:go_router/go_router.dart";
import "package:intl/intl.dart";
import "package:local_auth/local_auth.dart";
import "package:share_plus/share_plus.dart";

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.read(themeModeProvider);
    final themeScheme = ref.read(themeSchemeProvider);
    final language = ref.read(languageProvider);
    final packageInfo = ref.read(packageInfoProvider);
    final biometrics = ref.read(biometricsProvider);

    final privacyBlur = ref.watch(privacyBlurProvider);
    final biometric = ref.watch(biometricProvider);

    final theme = Theme.of(context);
    final s = context.s;

    return BasePage(
      exitInterceptor: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.settings.titleCase),
          leading: context.canPop() ? const AppBarLeading() : null,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              SettingsList(
                shrinkWrap: true,
                platform: context.isCupertinoStyle
                    ? DevicePlatform.iOS
                    : DevicePlatform.android,
                physics: const NeverScrollableScrollPhysics(),
                sections: [
                  SettingsSection(
                    title: Text(s.theme.capitalCase),
                    tiles: <SettingsTile>[
                      SettingsTile.navigation(
                        leading: const Icon(TablerIcons.language),
                        title: Text(s.language.capitalCase),
                        value: Text(
                          (language == null ? s.system : s.languageName)
                              .capitalCase,
                        ),
                        onPressed: (context) {
                          _showSwitchLanguageDialog(context, ref);
                        },
                      ),
                      SettingsTile.navigation(
                        leading: const Icon(TablerIcons.brightness_filled),
                        title: Text(s.brightness.capitalCase),
                        value: Text(
                          Intl.message(
                            themeMode.name,
                            name: themeMode.name,
                          ).capitalCase,
                        ),
                        onPressed: (context) {
                          _showSwitchThemeModelDialog(context, ref);
                        },
                      ),
                      SettingsTile.navigation(
                        leading: const Icon(TablerIcons.palette),
                        title: Text(s.theme.capitalCase),
                        value: Text(themeScheme.name.capitalCase),
                        onPressed: (context) {
                          const ThemeRoute().push(context);
                        },
                      ),
                      if (RunPlatform.isIOS || RunPlatform.isMacOS)
                        SettingsTile.switchTile(
                          leading: const Icon(TablerIcons.device_mobile),
                          title: const Text("Material"),
                          initialValue: context.isMaterialStyle,
                          onToggle: (bool value) {
                            ref
                                .read(targetPlatformProvider.notifier)
                                .update(
                                  value
                                      ? TargetPlatform.android
                                      : TargetPlatform.iOS,
                                );
                          },
                        ),
                      if (!(RunPlatform.isIOS || RunPlatform.isMacOS))
                        SettingsTile.switchTile(
                          leading: const Icon(TablerIcons.device_mobile),
                          title: const Text("Cupertino"),
                          initialValue: context.isCupertinoStyle,
                          onToggle: (bool value) {
                            ref
                                .read(targetPlatformProvider.notifier)
                                .update(
                                  value
                                      ? TargetPlatform.iOS
                                      : TargetPlatform.android,
                                );
                          },
                        ),
                    ],
                  ),
                  SettingsSection(
                    title: Text(s.security.capitalCase),
                    tiles: [
                      SettingsTile.switchTile(
                        leading: const Icon(TablerIcons.background),
                        title: Text(s.privacyBlur.capitalCase),
                        initialValue: privacyBlur,
                        onToggle: (bool value) {
                          ref.read(privacyBlurProvider.notifier).update(value);
                        },
                      ),
                      if (biometrics.isNotEmpty)
                        SettingsTile.switchTile(
                          leading: biometrics.contains(BiometricType.face)
                              ? const Icon(TablerIcons.face_id)
                              : const Icon(TablerIcons.fingerprint_scan),
                          title: Text(s.backgroundLock.capitalCase),
                          initialValue: biometric,
                          onToggle: (bool value) async {
                            final didAuthenticate = await localAuthenticate(
                              value
                                  ? s.enableBackgroundLockTip
                                  : s.disableBackgroundLockTip,
                            );
                            if (didAuthenticate) {
                              ref
                                  .read(biometricProvider.notifier)
                                  .update(value);
                            }
                          },
                        ),
                    ],
                  ),
                  SettingsSection(
                    title: Text(s.about.capitalCase),
                    tiles: [
                      SettingsTile.navigation(
                        leading: const Icon(TablerIcons.share_2),
                        title: Text(s.share.capitalCase),
                        onPressed: (_) async {
                          final url =
                              "https://github.com/belier-cn/certimate_flutter";
                          if (RunPlatform.useShareDevice) {
                            SharePlus.instance.share(
                              ShareParams(uri: Uri.parse(url)),
                            );
                          } else {
                            await Clipboard.setData(ClipboardData(text: url));
                            if (context.mounted) {
                              final _ = showOkAlertDialog(
                                context: context,
                                message: context.s.copied,
                              );
                            }
                          }
                        },
                      ),
                      SettingsTile.navigation(
                        leading: const Icon(TablerIcons.file_text),
                        title: Text(s.document.capitalCase),
                        onPressed: (_) => const WebViewRoute(
                          url: "https://docs.certimate.me",
                        ).push(context),
                      ),
                      SettingsTile.navigation(
                        leading: const Icon(TablerIcons.circle_dot),
                        title: Text(s.issues.capitalCase),
                        onPressed: (_) => const WebViewRoute(
                          url:
                              "https://github.com/belier-cn/certimate_flutter/issues",
                        ).push(context),
                      ),
                    ],
                  ),
                ],
              ),
              if (packageInfo != null)
                Padding(
                  padding: isMaterial(context)
                      ? const EdgeInsets.only(top: 10, bottom: 40)
                      : const EdgeInsets.only(bottom: 30),
                  child: Text(
                    "${s.version.capitalCase} ${packageInfo.version} (${packageInfo.buildNumber})",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSwitchThemeModelDialog(BuildContext context, WidgetRef ref) async {
    final s = context.s;
    final themeMode = ref.read(themeModeProvider);
    final value = await showModalActionSheet(
      context: context,
      cancelLabel: s.cancel.capitalCase,
      actions: [ThemeMode.system, ThemeMode.light, ThemeMode.dark].map((item) {
        final isDefault = themeMode == item;
        return SheetAction(
          key: item,
          isDefaultAction: themeMode == item,
          icon: Icons.check.none(!isDefault),
          label: Intl.message(item.name, name: item.name).capitalCase,
        );
      }).toList(),
    );
    if (value != null && value != themeMode) {
      ref.read(themeModeProvider.notifier).update(value);
    }
  }

  void _showSwitchLanguageDialog(BuildContext context, WidgetRef ref) async {
    for (final value in S.delegate.supportedLocales) {
      // 初始化全部语言，方便读取语言的名称
      await initializeMessages(value.toLanguageTag());
    }
    if (!context.mounted) {
      return;
    }
    final s = context.s;
    final languageTag = "${ref.read(languageProvider)?.toLanguageTag()}";
    final value = await showModalActionSheet(
      context: context,
      cancelLabel: s.cancel.capitalCase,
      actions:
          [
            const Locale.fromSubtags(languageCode: "null"),
            ...S.delegate.supportedLocales,
          ].map((item) {
            final isDefault = item.toLanguageTag() == languageTag;
            return SheetAction(
              key: item,
              isDefaultAction: isDefault,
              icon: Icons.check.none(!isDefault),
              label:
                  (item.languageCode == "null"
                          ? s.system
                          : Intl.message(
                              item.toLanguageTag(),
                              name: "languageName",
                              locale: item.toLanguageTag(),
                            ))
                      .capitalCase,
            );
          }).toList(),
    );
    if (value != null && value.toLanguageTag() != languageTag) {
      ref
          .read(languageProvider.notifier)
          .update(value.languageCode == "null" ? null : value);
    }
  }
}
