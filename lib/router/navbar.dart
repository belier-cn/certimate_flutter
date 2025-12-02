import "package:certimate/extension/index.dart";
import "package:flutter/material.dart";
import "package:flutter_platform_widgets/flutter_platform_widgets.dart";
import "package:go_router/go_router.dart";

class ScaffoldWithNavbar extends StatelessWidget {
  const ScaffoldWithNavbar(this.navigationShell, {super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (isDesktopDevice) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onChange,
              labelType: NavigationRailLabelType.selected,
              leading: const SizedBox(height: 28),
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
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
