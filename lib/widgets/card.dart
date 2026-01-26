import "package:adaptive_dialog/adaptive_dialog.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_platform_widgets/flutter_platform_widgets.dart";
import "package:material_design/material_design.dart";
import "package:sp_util/sp_util.dart";
import "package:tolyui_collapse/tolyui_collapse.dart";

class TitleCard extends StatelessWidget {
  final String title;

  final Widget? child;

  final bool card;

  final bool horizontalPadding;

  final bool? expanded;

  final String expandedKey;

  const TitleCard({
    super.key,
    this.title = "",
    this.child,
    this.card = true,
    this.horizontalPadding = true,
    this.expanded,
    this.expandedKey = "",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final realExpanded = (expandedKey.isNotEmpty
        ? SpUtil.getBool(expandedKey, defValue: expanded)
        : expanded);
    final widget = Padding(
      padding: horizontalPadding
          ? const EdgeInsets.all(M3Spacings.space16)
          : const EdgeInsets.symmetric(vertical: M3Spacings.space16),
      child: realExpanded == null || child == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(title, style: theme.textTheme.headlineSmall),
                if (child != null) const SizedBox(height: M3Spacings.space16),
                if (child != null) child!,
              ],
            )
          : TolyCollapse(
              expanded: realExpanded,
              titlePadding: EdgeInsets.zero,
              controller: CollapseController(),
              contentPadding: const EdgeInsets.only(top: M3Spacings.space16),
              title: Text(title, style: theme.textTheme.headlineSmall),
              content: child!,
              duration: const Duration(milliseconds: 300),
              icon: Icon(
                context.appIcons.expandMore,
                size: context.isMaterialStyle ? 24 : 16,
              ),
              onOpen: () {
                if (expandedKey.isNotEmpty) {
                  SpUtil.putBool(expandedKey, true);
                }
              },
              onClose: () {
                if (expandedKey.isNotEmpty) {
                  SpUtil.putBool(expandedKey, false);
                }
              },
            ),
    );
    if (!card) {
      return widget;
    }
    return Card(margin: EdgeInsets.zero, child: widget);
  }
}

class ModelCard extends StatelessWidget {
  final List<Widget> children;

  final Widget? child;

  final Widget? moreWidget;

  final BoxDecoration? decoration;

  const ModelCard({
    super.key,
    this.children = const [],
    this.child,
    this.moreWidget,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final boxDecoration =
        decoration ?? const BoxDecoration(borderRadius: M3BorderRadius.small);
    final body =
        child ??
        Container(
          padding: moreWidget == null
              ? const EdgeInsets.symmetric(
                  horizontal: M3Spacings.space20,
                  vertical: M3Spacings.space20,
                )
              : const EdgeInsets.only(
                  top: M3Spacings.space28,
                  bottom: M3Spacings.space20,
                  left: M3Spacings.space20,
                  right: M3Spacings.space20,
                ),
          decoration: boxDecoration.borderRadius == null
              ? boxDecoration.copyWith(borderRadius: M3BorderRadius.small)
              : boxDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        );
    return Card(
      child: moreWidget == null
          ? body
          : Stack(
              children: [
                body,
                Positioned(
                  top: M3Spacings.space8,
                  right: isMaterial(context)
                      ? M3Spacings.space16
                      : M3Spacings.space20,
                  child: moreWidget!,
                ),
              ],
            ),
    );
  }
}

class ModelCardCell extends StatelessWidget {
  final Widget? leading;

  final Widget? title;

  final Widget? subtitle;

  final Widget? trailing;

  final bool center;

  final Axis direction;

  factory ModelCardCell.string({
    Key? key,
    String? label,
    String? value,
    String? desc,
    Widget? leading,
    Widget? title,
    Widget? subtitle,
    Widget? trailing,
    bool center = false,
    Axis direction = Axis.horizontal,
  }) {
    return ModelCardCell(
      key: key,
      leading: leading ?? (label != null ? Text("$label: ") : null),
      title: title ?? (value != null ? Text(value) : null),
      subtitle: subtitle ?? (desc != null ? Text(desc) : null),
      trailing: trailing,
      center: center,
      direction: direction,
    );
  }

  const ModelCardCell({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.center = false,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Flex(
        direction: direction,
        crossAxisAlignment: center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (leading != null) leading!,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (title != null)
                DefaultTextStyle(
                  style: theme.textTheme.bodyMedium!.copyWith(
                    overflow: TextOverflow.ellipsis,
                  ),
                  child: title!,
                ),
              if (subtitle != null) const SizedBox(height: 4),
              if (subtitle != null)
                DefaultTextStyle(
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.hintColor,
                    overflow: TextOverflow.ellipsis,
                  ),
                  child: subtitle!,
                ),
            ],
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ModelDetailCell extends StatelessWidget {
  final Widget? leading;

  final Widget? title;

  final Widget? subtitle;

  final EdgeInsetsGeometry? titlePadding;

  final bool copy;

  final String? copyValue;

  final bool? textFieldBorder;

  const ModelDetailCell({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.titlePadding,
    this.copy = false,
    this.copyValue,
    this.textFieldBorder,
  });

  factory ModelDetailCell.string({
    Key? key,
    String? label,
    String? value,
    String? desc,
    Widget? leading,
    Widget? title,
    Widget? subtitle,
    EdgeInsetsGeometry? titlePadding,
    bool? copy,
    String? copyValue,
    bool? textFieldBorder,
  }) {
    return ModelDetailCell(
      key: key,
      leading: leading ?? (label != null ? Text(label) : null),
      title: title ?? (value != null ? Text(value) : null),
      subtitle: subtitle ?? (desc != null ? Text(desc) : null),
      titlePadding: titlePadding,
      copy: copy ?? false,
      copyValue: copyValue ?? value,
      textFieldBorder: textFieldBorder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget? leadingWidget = leading != null
        ? DefaultTextStyle(
            style: theme.textTheme.titleMedium!.copyWith(
              overflow: TextOverflow.ellipsis,
            ),
            child: leading!,
          )
        : null;
    if (copy && leadingWidget != null && copyValue != null) {
      leadingWidget = Row(
        children: [
          Expanded(child: leadingWidget),
          const SizedBox(width: 8),
          CupertinoWell(
            onPressed: () async {
              try {
                await Clipboard.setData(ClipboardData(text: copyValue ?? ""));
                if (context.mounted) {
                  final _ = showOkAlertDialog(
                    context: context,
                    message: context.s.copied,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  final _ = showOkAlertDialog(
                    context: context,
                    message: "copy failed",
                  );
                }
              }
            },
            child: Icon(
              context.appIcons.copy,
              size: theme.textTheme.titleMedium!.fontSize,
              color: theme.textTheme.titleMedium!.color,
            ),
          ),
        ],
      );
    }
    final polygonBorder = textFieldBorder == true && isMaterial(context);
    final titleWidget = title != null
        ? Container(
            width: double.infinity,
            padding:
                titlePadding ??
                const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: polygonBorder
                ? null
                : BoxDecoration(
                    color:
                        theme.inputDecorationTheme.fillColor ??
                        theme.colorScheme.onPrimary,
                    border: polygonBorder
                        ? null
                        : Border.all(color: theme.dividerColor, width: 1),
                    borderRadius: polygonBorder
                        ? null
                        : const BorderRadius.all(Radius.circular(6)),
                  ),
            child: polygonBorder
                ? title!
                : ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                    child: title!,
                  ),
          )
        : null;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leadingWidget != null) leadingWidget,
          if (titleWidget != null) const SizedBox(height: 12),
          if (titleWidget != null)
            polygonBorder
                ? PolygonBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(
                      color: theme.colorScheme.onSurfaceVariant,
                      width: 2,
                    ),
                    child: titleWidget,
                  )
                : titleWidget,
          if (subtitle != null) const SizedBox(height: 8),
          if (subtitle != null)
            DefaultTextStyle(
              style: theme.textTheme.bodySmall!.copyWith(
                overflow: TextOverflow.ellipsis,
              ),
              child: subtitle!,
            ),
        ],
      ),
    );
  }
}
