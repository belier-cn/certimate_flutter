import "package:certimate/api/workflow_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/router/route.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:material_design/material_design.dart";

class WorkflowRunWidget extends StatelessWidget {
  final WorkflowRunResult data;
  final int serverId;
  final String? workflowId;
  final VoidCallback? onDelete;
  final VoidCallback? onCancel;

  const WorkflowRunWidget({
    super.key,
    required this.data,
    required this.serverId,
    this.workflowId,
    this.onCancel,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final body = ModelCard(
      moreWidget: workflowId != null
          ? PlatformPullDownButton(
              options: [
                PullDownOption(
                  label: s.viewDetails.capitalCase,
                  iconWidget: Icon(context.appIcons.info),
                  onTap: (_) => WorkflowLogsRoute(
                    serverId: serverId,
                    runId: data.id ?? "",
                  ).push(context),
                ),
                PullDownOption(
                  label: s.cancel.capitalCase,
                  withDivider: true,
                  enabled:
                      data.status == "pending" || data.status == "processing",
                  iconWidget: Icon(context.appIcons.pause),
                  onTap: (_) => onCancel?.call(),
                ),
                PullDownOption(
                  label: s.delete.capitalCase,
                  isDestructive: true,
                  iconWidget: Icon(context.appIcons.delete),
                  onTap: (_) => onDelete?.call(),
                ),
              ],
              icon: AppBarIconButton(context.appIcons.ellipsis),
            )
          : null,
      children: [
        ModelCardCell.string(label: s.id, value: data.id),
        ModelCardCell.string(
          label: s.workflows.capitalCase,
          title: Text(
            data.expand?.workflowRef?.name ?? "",
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
        ModelCardCell.string(
          label: s.status.capitalCase,
          title: WorkflowRunStatusWidget(status: data.status),
        ),
        ModelCardCell.string(
          label: s.trigger.capitalCase,
          value: data.trigger.showVal.capitalCase,
        ),
        ModelCardCell.string(
          label: s.startedAt.capitalCase,
          value: data.startedAt.toDateTimeString(),
        ),
        ModelCardCell.string(
          label: s.endedAt.capitalCase,
          value: data.endedAt.toDateTimeString(),
        ),
      ],
    );
    if (workflowId == null) {
      return GestureDetector(
        onTap: () => WorkflowLogsRoute(
          serverId: serverId,
          runId: data.id ?? "",
        ).push(context),
        child: body,
      );
    }
    return body;
  }
}

class WorkflowRunStatusWidget extends StatelessWidget {
  final String? status;
  final Widget? child;

  const WorkflowRunStatusWidget({super.key, required this.status, this.child});

  @override
  Widget build(BuildContext context) {
    final appThemeData = context.appThemeData;
    final statusColorMap = {
      "failed": appThemeData.errorColor,
      "pending": appThemeData.infoColor,
      "processing": appThemeData.infoColor,
      "succeeded": appThemeData.successColor,
      "canceled": appThemeData.warningColor,
    };
    if (child != null) {
      final color = statusColorMap[status] ?? appThemeData.infoColor;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(M3Spacings.space12),
        margin: const EdgeInsets.only(bottom: M3Spacings.space12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.all(
            Radius.circular(M3Corners.medium),
          ),
          border: Border.all(color: color),
        ),
        child: child,
      );
    }
    final statusIconMap = {
      "failed": context.appIcons.workflowFailed,
      "pending": context.appIcons.workflowPending,
      "processing": context.appIcons.workflowProcessing,
      "succeeded": context.appIcons.workflowSucceeded,
      "canceled": context.appIcons.workflowCancel,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          statusIconMap[status] ?? context.appIcons.workflowCancel,
          size: 14,
          color: statusColorMap[status],
        ),
        const SizedBox(width: M3Spacings.space4),
        Text(
          status.showVal.capitalCase,
          style: TextStyle(color: statusColorMap[status]),
        ),
      ],
    );
  }
}
