import "package:certimate/api/server_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/pages/certificates/provider.dart";
import "package:certimate/pages/workflows/provider.dart";
import "package:certimate/router/route.dart";
import "package:certimate/widgets/grid_row.dart";
import "package:flutter/material.dart";
import "package:flutter_tabler_icons/flutter_tabler_icons.dart";
import "package:material_design/material_design.dart";

class StatisticsWidget extends StatelessWidget {
  final int serverId;
  final StatisticsResult data;

  const StatisticsWidget({
    super.key,
    required this.data,
    required this.serverId,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final appThemeData = context.appThemeData;
    return LayoutBuilder(
      builder: (context, c) {
        return GridRow(
          crossAxisCount: c.maxWidth >= 600 ? 3 : 2,
          crossAxisSpacing: M3Spacings.space12,
          mainAxisSpacing: M3Spacings.space12,
          children: [
            GestureDetector(
              onTap: () => CertificatesRoute(serverId: serverId).push(context),
              child: StatisticsItemWidget(
                title: s.allCertificates.capitalCase,
                value: "${data.certificateTotal ?? 0}",
                icon: const Icon(TablerIcons.shield),
                colors: appThemeData.infoColors,
              ),
            ),
            GestureDetector(
              onTap: () => CertificatesRoute(
                serverId: serverId,
                filter: CertificateFilter.unexpired,
              ).push(context),
              child: StatisticsItemWidget(
                title: s.validCertificate.capitalCase,
                value:
                    "${(data.certificateTotal ?? 0) - (data.certificateExpired ?? 0)}",
                icon: const Icon(TablerIcons.shield_check),
                colors: appThemeData.successColors,
              ),
            ),
            GestureDetector(
              onTap: () => CertificatesRoute(
                serverId: serverId,
                filter: CertificateFilter.expiringSoon,
              ).push(context),
              child: StatisticsItemWidget(
                title: s.expiringSoonCertificates.capitalCase,
                value: "${data.certificateExpiringSoon ?? 0}",
                icon: const Icon(TablerIcons.shield_exclamation),
                colors: appThemeData.warningColors,
              ),
            ),
            GestureDetector(
              onTap: () => CertificatesRoute(
                serverId: serverId,
                filter: CertificateFilter.expired,
              ).push(context),
              child: StatisticsItemWidget(
                title: s.expiredCertificates.capitalCase,
                value: "${data.certificateExpired ?? 0}",
                icon: const Icon(TablerIcons.shield_x),
                colors: appThemeData.errorColors,
              ),
            ),
            GestureDetector(
              onTap: () => WorkflowsRoute(serverId: serverId).push(context),
              child: StatisticsItemWidget(
                title: s.allWorkflows.capitalCase,
                value: "${data.workflowTotal ?? 0}",
                icon: const Icon(TablerIcons.route),
                colors: appThemeData.infoColors,
              ),
            ),
            GestureDetector(
              onTap: () => WorkflowsRoute(
                serverId: serverId,
                filter: WorkflowFilter.active,
              ).push(context),
              child: StatisticsItemWidget(
                title: s.activeWorkflows.capitalCase,
                value: "${data.workflowEnabled ?? 0}",
                icon: const Icon(TablerIcons.activity),
                colors: appThemeData.successColors,
              ),
            ),
          ],
        );
      },
    );
  }
}

class StatisticsItemWidget extends StatelessWidget {
  final List<Color> colors;

  final Widget? icon;

  final String value;

  final String title;

  const StatisticsItemWidget({
    super.key,
    this.colors = const [
      Color.fromRGBO(52, 102, 167, 1),
      Color.fromRGBO(121, 171, 237, 1),
    ],
    required this.title,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Colors.white.withValues(alpha: 0.85);
    final iconBgColor = Colors.white.withValues(alpha: 0.25);
    const iconBgSize = 48.0;
    const iconSize = 24.0;
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: M3Spacings.space20),
      decoration: BoxDecoration(
        borderRadius: M3BorderRadius.small,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: M3Spacings.space8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: theme.textTheme.displayMedium?.copyWith(color: color),
              ),
              if (icon != null)
                Container(
                  height: iconBgSize,
                  width: iconBgSize,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(iconBgSize / 2),
                    ),
                    color: iconBgColor,
                  ),
                  child: SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: IconTheme(
                      data: IconThemeData(color: color, size: iconSize),
                      child: icon!,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
