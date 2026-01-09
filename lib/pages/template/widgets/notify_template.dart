import "package:certimate/api/setting_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";

class NotifyTemplateWidget extends StatelessWidget {
  final NotifyTemplate data;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const NotifyTemplateWidget({
    super.key,
    required this.data,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ModelCard(
      moreWidget: PlatformPullDownButton(
        options: [
          PullDownOption(
            label: s.edit.capitalCase,
            withDivider: true,
            iconWidget: Icon(context.appIcons.edit),
            onTap: (_) => onEdit?.call(),
          ),
          PullDownOption(
            label: s.delete.capitalCase,
            isDestructive: true,
            iconWidget: Icon(context.appIcons.delete),
            onTap: (_) => onDelete?.call(),
          ),
        ],
        icon: AppBarIconButton(context.appIcons.ellipsis),
      ),
      children: [
        ModelCardCell.string(label: s.name.capitalCase, value: data.name),
        ModelCardCell.string(label: s.subject.capitalCase, value: data.subject),
        ModelCardCell.string(
          label: s.content.capitalCase,
          subtitle: Text(data.message.showVal),
          direction: Axis.vertical,
        ),
      ],
    );
  }
}
