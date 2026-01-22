import "package:certimate/database/servers_dao.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/pages/server/provider.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_design/material_design.dart";

class ControlsWidget extends ConsumerWidget {
  final int serverId;

  final ServerModel? server;

  const ControlsWidget({super.key, required this.serverId, this.server});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final control = ref.watch(localServerControlProvider(serverId));
    final autoStart = ref.watch(
      serverProvider(serverId).select((val) => val.value?.autoStart ?? false),
    );
    final theme = Theme.of(context);

    final statusText = control.isRunning
        ? s.localServerRunning
        : s.localServerNotRunning;
    final statusColor = control.isRunning
        ? theme.colorScheme.primary
        : theme.hintColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              control.isRunning
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              size: 18,
              color: statusColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                statusText,
                style: theme.textTheme.bodyMedium?.copyWith(color: statusColor),
              ),
            ),
            if (control.isBusy) ...[
              const SizedBox(width: 8),
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        const SizedBox(height: M3Spacings.space16),
        Wrap(
          direction: Axis.horizontal,
          spacing: M3Spacings.space12,
          runSpacing: M3Spacings.space4,
          children: [
            OutlinedButton.icon(
              onPressed: (control.isBusy || control.isRunning)
                  ? null
                  : () async => ref
                        .read(localServerControlProvider(serverId).notifier)
                        .start(),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(s.start.capitalCase),
            ),
            OutlinedButton.icon(
              onPressed: (control.isBusy || !control.isRunning)
                  ? null
                  : () async => ref
                        .read(localServerControlProvider(serverId).notifier)
                        .stop(),
              icon: const Icon(Icons.stop_rounded),
              label: Text(s.stop.capitalCase),
            ),
            OutlinedButton.icon(
              onPressed: control.isBusy
                  ? null
                  : () async => ref
                        .read(localServerControlProvider(serverId).notifier)
                        .restart(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(s.restart.capitalCase),
            ),
          ],
        ),
        const SizedBox(height: M3Spacings.space16),
        Row(
          children: [
            Expanded(
              child: Text(
                s.localServerAutoStart.capitalCase,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Switch.adaptive(
              value: autoStart,
              onChanged: (value) async => ref
                  .read(serverProvider(serverId).notifier)
                  .setAutoStart(value),
            ),
          ],
        ),
      ],
    );
  }
}
