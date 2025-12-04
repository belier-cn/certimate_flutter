import "dart:io";

import "package:adaptive_dialog/adaptive_dialog.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/generated/l10n.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_platform_widgets/flutter_platform_widgets.dart";
import "package:flutter_tabler_icons/flutter_tabler_icons.dart";
import "package:go_router/go_router.dart";
import "package:window_manager/window_manager.dart";

class ScaffoldWithNavbar extends StatelessWidget {
  const ScaffoldWithNavbar(this.navigationShell, {super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (isDesktopDevice) {
      final navigationRail = NavigationRail(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onChange,
        labelType: NavigationRailLabelType.selected,
        leading: context.isCupertinoStyle
            ? const SizedBox(height: 28)
            : const SizedBox(height: 52),
        destinations: [
          NavigationRailDestination(
            icon: Icon(context.platformIcons.home),
            label: Text(s.home.titleCase),
          ),
          NavigationRailDestination(
            icon: Icon(context.platformIcons.settings),
            label: Text(s.settings.titleCase),
          ),
        ],
      );
      return Scaffold(
        body: Row(
          children: [
            Platform.isMacOS
                ? navigationRail
                : Stack(
                    children: [
                      navigationRail,
                      const Positioned(
                        top: 0,
                        left: 0,
                        child: _DesktopButtons(),
                      ),
                    ],
                  ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: PlatformNavBar(
        currentIndex: navigationShell.currentIndex,
        cupertino: (_, _) => CupertinoTabBarData(iconSize: 22),
        items: [
          BottomNavigationBarItem(
            icon: Icon(context.platformIcons.home),
            label: s.home.titleCase,
          ),
          BottomNavigationBarItem(
            icon: Icon(context.platformIcons.settings),
            label: s.settings.titleCase,
          ),
        ],
        itemChanged: _onChange,
      ),
    );
  }

  void _onChange(int index) {
    if (index == navigationShell.currentIndex) {
      return;
    }
    navigationShell.goBranch(index);
  }
}

class _DesktopButtons extends HookWidget {
  const _DesktopButtons();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final hoverColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceBright
        : const Color(0xFFE5E5E5);
    final s = S.of(context);
    final closeIconHover = useValueNotifier(false);
    final isFullScreen = useValueNotifier(false);
    return SizedBox(
      height: 28,
      width: 80,
      child: IconTheme(
        data: theme.iconTheme.copyWith(size: 16),
        child: Row(
          children: [
            Material(
              child: SizedBox(
                width: 26,
                height: 26,
                child: InkWell(
                  onTap: () async {
                    final res = await showOkCancelAlertDialog(
                      context: context,
                      title: s.tip.capitalCase,
                      message: s.desktopExitTip,
                      defaultType: OkCancelAlertDefaultType.cancel,
                      isDestructiveAction: true,
                    );
                    if (res == OkCancelResult.ok) {
                      windowManager.close();
                    }
                  },
                  hoverColor: const Color(0xFFE81122),
                  onHover: (hover) {
                    closeIconHover.value = hover;
                  },
                  child: theme.brightness == Brightness.light
                      ? ValueListenableBuilder(
                          valueListenable: closeIconHover,
                          builder: (_, hover, _) {
                            return Icon(
                              TablerIcons.x,
                              color: hover ? Colors.white : null,
                            );
                          },
                        )
                      : const Icon(TablerIcons.x),
                ),
              ),
            ),
            Material(
              child: SizedBox(
                width: 26,
                height: 26,
                child: InkWell(
                  onTap: () async {
                    await windowManager.setFullScreen(!isFullScreen.value);
                    isFullScreen.value = !isFullScreen.value;
                  },
                  hoverColor: hoverColor,
                  child: ValueListenableBuilder(
                    valueListenable: isFullScreen,
                    builder: (_, fullScreen, _) {
                      return fullScreen
                          ? const Icon(TablerIcons.layers_subtract)
                          : const Icon(TablerIcons.crop_1_1);
                    },
                  ),
                ),
              ),
            ),
            Material(
              child: SizedBox(
                width: 26,
                height: 26,
                child: InkWell(
                  onTap: () => windowManager.minimize(),
                  hoverColor: hoverColor,
                  child: const Icon(TablerIcons.minus),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
