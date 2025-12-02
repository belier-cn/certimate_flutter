import "package:certimate/api/certificate_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/router/route.dart";
import "package:certimate/theme/theme.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";

class CertificateWidget extends StatelessWidget {
  final int serverId;
  final CertificateResult data;
  final VoidCallback? onRevoke;
  final VoidCallback? onDelete;

  const CertificateWidget({
    super.key,
    required this.serverId,
    required this.data,
    this.onRevoke,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final nowTime = DateTime.now();
    final appThemeData = Theme.of(context).extension<AppThemeData>()!;
    var totalDays = 0;
    final validDays =
        ((data.validityNotAfter?.difference(nowTime).inHours ?? 0) / 24).ceil();
    if (validDays > 0 && data.validityNotBefore != null) {
      final hours = data.validityNotAfter
          ?.difference(data.validityNotBefore!)
          .inHours;
      totalDays = ((hours ?? 0) / 24).ceil();
    }
    return ModelCard(
      moreWidget: PlatformPullDownButton(
        options: [
          PullDownOption(
            label: s.viewDetails.capitalCase,
            withDivider: true,
            iconWidget: Icon(context.appIcons.info),
            onTap: (_) => CertificateDetailRoute(
              serverId: serverId,
              certId: data.id ?? "",
            ).push(context),
          ),
          PullDownOption(
            label: s.revoke.capitalCase,
            withDivider: true,
            isDestructive: true,
            iconWidget: Icon(context.appIcons.revoke),
            onTap: (_) => onRevoke?.call(),
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
        ModelCardCell.string(
          label: s.name.capitalCase,
          value: data.subjectAltNames,
        ),
        ModelCardCell.string(
          label: s.expiry.capitalCase,
          title: Row(
            children: [
              Icon(
                Icons.circle,
                color: validDays > 0
                    ? appThemeData.successColor
                    : appThemeData.errorColor,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                data.isRevoked == true
                    ? s.revoked
                    : (validDays > 0
                          ? s.certificateExpiry(validDays, totalDays)
                          : s.expired),
                style: TextStyle(
                  color: validDays > 0 && data.isRevoked != true
                      ? appThemeData.successColor
                      : appThemeData.errorColor,
                ),
              ),
            ],
          ),
          desc: data.validityNotAfter?.toDateString(),
        ),
        ModelCardCell.string(
          label: s.brand.capitalCase,
          value: data.issuerOrg,
          desc: data.keyAlgorithm,
        ),
        ModelCardCell.string(
          label: s.source.capitalCase,
          value: data.source?.capitalCase,
          desc: data.expand?.workflowRef?.name,
        ),
        ModelCardCell.string(
          label: s.createdAt.capitalCase,
          value: data.created.toDateTimeString(),
        ),
      ],
    );
  }
}
