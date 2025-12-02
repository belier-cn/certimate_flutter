import "package:certimate/api/access_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/pages/accesses/provider.dart";
import "package:certimate/router/route.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/cupertino.dart";
import "package:flutter_svg/svg.dart";
import "package:intl/intl.dart";

class AccessWidget extends StatelessWidget {
  final int serverId;
  final String serverHost;
  final AccessResult data;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;
  final VoidCallback? onUpdate;

  const AccessWidget({
    super.key,
    required this.data,
    required this.serverId,
    required this.serverHost,
    this.onDelete,
    this.onCopy,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    final usage = AccessFilter.values.firstWhere(
      (item) => item.value == data.reserve,
      orElse: () => AccessFilter.dnsProvider,
    );

    return ModelCard(
      moreWidget: PlatformPullDownButton(
        options: [
          PullDownOption(
            label: s.viewDetails.capitalCase,
            iconWidget: Icon(context.appIcons.info),
            onTap: (_) {
              AccessDetailRoute(
                serverId: serverId,
                accessId: data.id ?? "",
              ).push(context);
            },
          ),
          PullDownOption(
            label: s.edit.capitalCase,
            iconWidget: Icon(context.appIcons.edit),
            onTap: (_) => onUpdate?.call(),
          ),
          PullDownOption(
            label: s.copy.capitalCase,
            withDivider: true,
            iconWidget: Icon(context.appIcons.copy),
            onTap: (_) => onCopy?.call(),
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
        ModelCardCell.string(label: s.id.capitalCase, value: data.id),
        ModelCardCell.string(label: s.name.capitalCase, value: data.name),
        ModelCardCell.string(
          label: s.type.capitalCase,
          value: Intl.message(usage.name, name: usage.name).capitalCase,
        ),
        ModelCardCell.string(
          center: true,
          label: s.provider.capitalCase,
          title: Row(
            children: [
              if (data.provider.isNotEmptyOrNull)
                SvgPicture.network(
                  data.provider!.providerSvg(serverHost),
                  width: 26,
                  height: 26,
                ),
              if (data.provider.isNotEmptyOrNull) const SizedBox(width: 10),
              Text(data.provider.showVal.capitalCase),
            ],
          ),
        ),
        ModelCardCell.string(
          label: s.createdAt.capitalCase,
          value: data.created.toDateTimeString(),
        ),
      ],
    );
  }
}
