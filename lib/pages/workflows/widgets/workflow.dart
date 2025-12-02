import "package:certimate/api/workflow_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/router/route.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:load_switch/load_switch.dart";

typedef WorkflowEnableCallback =
    Future<bool> Function(BuildContext context, WorkflowResult data);

class WorkflowWidget extends StatelessWidget {
  final int serverId;
  final WorkflowResult data;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;
  final VoidCallback? onRun;
  final WorkflowEnableCallback onEnabled;

  const WorkflowWidget({
    super.key,
    required this.data,
    required this.serverId,
    required this.onEnabled,
    this.onCopy,
    this.onDelete,
    this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return ModelCard(
      moreWidget: PlatformPullDownButton(
        options: [
          PullDownOption(
            label: s.edit.capitalCase,
            iconWidget: Icon(context.appIcons.edit),
            onTap: (_) => "/#/workflows/${data.id}/design".toServerWebview(
              context,
              serverId,
            ),
          ),
          PullDownOption(
            label: s.copy.capitalCase,
            iconWidget: Icon(context.appIcons.copy),
            onTap: (_) => onCopy?.call(),
          ),
          PullDownOption(
            label: s.logs.capitalCase,
            iconWidget: Icon(context.appIcons.log),
            onTap: (_) {
              WorkflowRunsRoute(
                serverId: serverId,
                workflowId: data.id ?? "",
              ).push(context);
            },
          ),
          PullDownOption(
            label: s.run.capitalCase,
            withDivider: true,
            enabled: data.enabled == true,
            iconWidget: Icon(context.appIcons.run),
            onTap: (_) => onRun?.call(),
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
        ModelCardCell.string(
          label: s.trigger.capitalCase,
          value: data.trigger.showVal.capitalCase,
          desc: data.triggerCron.isNotEmptyOrNull ? data.triggerCron : null,
        ),
        ModelCardCell.string(
          label: s.activeTitle.capitalCase,
          title: LoadSwitch(
            style: SpinStyle.material,
            spinColor: (v) =>
                v ? theme.colorScheme.primary : theme.colorScheme.surfaceDim,
            future: () async => onEnabled.call(context, data),
            height: 24,
            width: 48,
            onChange: (v) {},
            onTap: (v) {},
            value: data.enabled ?? false,
            switchDecoration: (v, _) => BoxDecoration(
              color: v
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceDim,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        ModelCardCell.string(
          label: s.lastRunAt.capitalCase,
          value: data.lastRunTime.toDateTimeString().showVal,
        ),
        ModelCardCell.string(
          label: s.createdAt.capitalCase,
          value: data.created.toDateTimeString(),
        ),
      ],
    );
  }
}
