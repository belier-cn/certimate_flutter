import "package:certimate/extension/index.dart";
import "package:certimate/router/route.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_platform_widgets/flutter_platform_widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:go_router/go_router.dart";

class ServerSettingsPage extends ConsumerWidget {
  final int serverId;

  const ServerSettingsPage({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    return BasePage(
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.systemSettings.titleCase),
          leading: context.canPop() ? const AppBarLeading() : null,
        ),
        body: SingleChildScrollView(
          child: SettingsList(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            sections: [
              SettingsSection(
                tiles: <SettingsTile>[
                  SettingsTile.navigation(
                    leading: Icon(context.appIcons.user),
                    title: Text(s.account.capitalCase),
                    onPressed: (context) {
                      ServerAccountRoute(serverId: serverId).push(context);
                    },
                  ),
                  SettingsTile.navigation(
                    leading: Icon(context.appIcons.password),
                    title: Text(s.password.capitalCase),
                    onPressed: (context) {
                      ServerPasswordRoute(serverId: serverId).push(context);
                    },
                  ),
                  SettingsTile.navigation(
                    leading: Icon(context.appIcons.persistence),
                    title: Text(s.persistence.capitalCase),
                    onPressed: (context) {
                      ServerPersistenceRoute(serverId: serverId).push(context);
                    },
                  ),
                  SettingsTile.navigation(
                    leading: Icon(context.appIcons.certificate),
                    title: Text(s.certificateAuthority.capitalCase),
                    onPressed: (context) {
                      "/#/settings/ssl-provider".toServerWebview(
                        context,
                        serverId,
                      );
                    },
                  ),
                  SettingsTile.navigation(
                    leading: isMaterial(context)
                        ? Icon(context.appIcons.diagnostic)
                        : RotatedBox(
                            quarterTurns: 1,
                            child: Icon(context.appIcons.diagnostic),
                          ),
                    title: Text(s.diagnostics.capitalCase),
                    onPressed: (context) {
                      "/#/settings/diagnostics".toServerWebview(
                        context,
                        serverId,
                      );
                    },
                  ),
                  SettingsTile.navigation(
                    leading: Icon(context.appIcons.info),
                    title: Text(s.about.capitalCase),
                    onPressed: (context) {
                      "/#/settings/about".toServerWebview(context, serverId);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
