import "package:certimate/extension/index.dart";
import "package:certimate/router/route.dart";
import "package:certimate/theme/theme.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_tabler_icons/flutter_tabler_icons.dart";
import "package:material_design/material_design.dart";

class ShortcutsWidget extends ConsumerWidget {
  final int serverId;

  const ShortcutsWidget({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeData>()!;
    return Wrap(
      direction: Axis.horizontal,
      spacing: M3Spacings.space12,
      runSpacing: M3Spacings.space4,
      children: [
        ShortcutsItemWidget(
          title: s.createNewWorkflow.capitalCase,
          icon: Icon(TablerIcons.circle_plus, color: theme.colorScheme.primary),
          onPressed: () {
            "/#/workflows/new".toServerWebview(context, serverId);
          },
        ),
        ShortcutsItemWidget(
          title: s.changeUsername.capitalCase,
          icon: Icon(TablerIcons.user_shield, color: appTheme.successColor),
          onPressed: () {
            ServerAccountRoute(serverId: serverId).push(context);
          },
        ),
        ShortcutsItemWidget(
          title: s.changePassword.capitalCase,
          icon: Icon(TablerIcons.lock, color: appTheme.warningColor),
          onPressed: () {
            ServerPasswordRoute(serverId: serverId).push(context);
          },
        ),
        ShortcutsItemWidget(
          title: s.configureCertificateAuthorities.capitalCase,
          icon: Icon(TablerIcons.plug_connected, color: appTheme.infoColor),
          onPressed: () {
            "/#/settings/ssl-provider".toServerWebview(context, serverId);
          },
        ),
      ],
    );
  }
}

class ShortcutsItemWidget extends StatelessWidget {
  final String title;
  final Widget? icon;
  final VoidCallback? onPressed;

  const ShortcutsItemWidget({
    super.key,
    required this.title,
    this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed ?? () {},
      label: Text(title, style: theme.textTheme.bodyMedium),
      icon: icon!,
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: M3Spacings.space12),
        ),
      ),
    );
  }
}
