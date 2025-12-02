import "package:certimate/extension/index.dart";
import "package:flex_color_scheme/flex_color_scheme.dart";
import "package:flutter/material.dart";

class ThemeItemWidget extends StatelessWidget {
  final FlexScheme flexScheme;

  const ThemeItemWidget({super.key, required this.flexScheme});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final flexSchemeData = FlexColor.schemes[flexScheme]!;
    final bool isLight = theme.brightness == Brightness.light;
    final flexSchemeColor = isLight
        ? flexSchemeData.light
        : flexSchemeData.dark;
    final isCupertino =
        theme.platform == TargetPlatform.iOS ||
        theme.platform == TargetPlatform.macOS;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Row(
        spacing: 4,
        children: [
          if (!isCupertino)
            Column(
              spacing: 4,
              children: [
                _SchemeColorBox(color: flexSchemeColor.primary),
                _SchemeColorBox(color: flexSchemeColor.secondary),
              ],
            ),
          if (!isCupertino)
            Column(
              spacing: 4,
              children: [
                _SchemeColorBox(color: flexSchemeColor.primaryContainer),
                _SchemeColorBox(color: flexSchemeColor.tertiary),
              ],
            ),
          if (isCupertino)
            _SchemeColorBox(color: flexSchemeColor.primary, width: 32),
          const SizedBox(width: 4),
          Text(flexScheme.name.capitalCase),
          const Spacer(),
          Radio.adaptive(
            value: flexScheme,
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _SchemeColorBox extends StatelessWidget {
  final Color color;
  final double width;

  const _SchemeColorBox({required this.color, this.width = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: width,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
    );
  }
}
