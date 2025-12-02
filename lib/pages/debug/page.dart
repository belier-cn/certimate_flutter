import "package:certimate/router/route.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:flutter_tabler_icons/flutter_tabler_icons.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class DebugPage extends HookConsumerWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BasePage(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Debug"),
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
                    leading: const Icon(TablerIcons.database),
                    title: const Text("Tables"),
                    onPressed: (context) {
                      const DbViewerRoute().push(context);
                    },
                  ),
                  SettingsTile.navigation(
                    leading: const Icon(TablerIcons.clock_hour_3),
                    title: const Text("Logger"),
                    onPressed: (context) {
                      const LoggerRoute().push(context);
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
