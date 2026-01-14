import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_platform_widgets/flutter_platform_widgets.dart";
import "package:pull_down_button/pull_down_button.dart";

class PullDownOption {
  final Key? key;
  final String? label;
  final bool? selected;
  final bool? enabled;
  final bool? isDestructive;
  final bool? withDivider;
  final Widget? iconWidget;
  final void Function(PullDownOption)? onTap;

  PullDownOption({
    this.key,
    this.label,
    this.selected,
    this.enabled,
    this.isDestructive,
    this.withDivider,
    this.iconWidget,
    this.onTap,
  });
}

class PlatformPullDownButton extends StatelessWidget {
  final List<PullDownOption> options;
  final Widget icon;

  const PlatformPullDownButton({
    required this.options,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      material: (context, _) => _materialPullDownButton(context),
      cupertino: (context, _) => _cupertinoPullDownButton(context),
    );
  }

  Widget _cupertinoPullDownButton(BuildContext context) {
    return PullDownButton(
      key: key,
      itemBuilder: (BuildContext context) {
        final items = <PullDownMenuEntry>[];
        for (final option in options) {
          if (option.selected != null) {
            items.add(
              PullDownMenuItem.selectable(
                key: option.key,
                selected: option.selected,
                title: option.label ?? "",
                onTap: () {
                  option.onTap?.call(option);
                },
                enabled: option.enabled ?? true,
                iconWidget: option.iconWidget,
                isDestructive: option.isDestructive ?? false,
              ),
            );
          } else {
            items.add(
              PullDownMenuItem(
                key: option.key,
                title: option.label ?? "",
                onTap: () {
                  option.onTap?.call(option);
                },
                enabled: option.enabled ?? true,
                iconWidget: option.iconWidget,
                isDestructive: option.isDestructive ?? false,
              ),
            );
          }
          if (option.withDivider ?? false) {
            items.add(
              const PullDownMenuDivider.large(
                color: Color.fromRGBO(0, 0, 0, 0.16),
              ),
            );
          }
        }
        return items;
      },
      buttonBuilder: (context, showMenu) =>
          CupertinoWell(onPressed: showMenu, child: icon),
    );
  }

  Widget _materialPullDownButton(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<PullDownOption>(
      onSelected: (option) {
        option.onTap?.call(option);
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<PullDownOption>>[];
        for (final option in options) {
          final selected = option.selected != null;
          final text = Text(
            option.label ?? "",
            style: option.isDestructive == true
                ? TextStyle(color: theme.colorScheme.error)
                : null,
          );
          final iconWidget = option.iconWidget != null
              ? IconTheme(
                  data: IconThemeData(
                    size: 16,
                    color: option.isDestructive == true
                        ? theme.colorScheme.error
                        : theme.iconTheme.color?.withValues(alpha: 0.75),
                  ),
                  child: option.iconWidget!,
                )
              : null;
          final child = iconWidget != null
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: selected
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.start,
                  children: selected
                      ? [
                          text,
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: iconWidget,
                          ),
                        ]
                      : [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: iconWidget,
                          ),
                          text,
                        ],
                )
              : text;
          items.add(
            selected
                ? CheckedPopupMenuItem<PullDownOption>(
                    key: option.key,
                    checked: option.selected ?? false,
                    value: option,
                    enabled: option.enabled ?? true,
                    child: child,
                  )
                : PopupMenuItem<PullDownOption>(
                    key: option.key,
                    value: option,
                    enabled: option.enabled ?? true,
                    child: child,
                  ),
          );
          if (option.withDivider ?? false) {
            items.add(const PopupMenuDivider());
          }
        }
        return items;
      },
      style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      child: icon,
    );
  }
}
