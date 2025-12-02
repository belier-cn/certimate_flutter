import "package:certimate/extension/index.dart";
import "package:certimate/pages/certificate_detail/provider.dart";
import "package:certimate/pages/certificate_detail/widgets/certificate_detail.dart";
import "package:certimate/pages/server/provider.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class CertificateDetailPage extends HookConsumerWidget {
  final int serverId;

  final String certId;

  const CertificateDetailPage({
    super.key,
    required this.serverId,
    required this.certId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final notifier = ref.read(
      certificateDetailProvider(serverId, certId).notifier,
    );
    return BasePage(
      child: Scaffold(
        body: RefreshBody<CertificateDetailData>(
          title: Consumer(
            builder: (_, ref, _) {
              final data = ref.watch(
                certificateDetailProvider(serverId, certId),
              );
              if (data.hasValue && data.requireValue.list.isNotEmpty) {
                return Text(
                  data.requireValue.list.first.subjectAltNames ?? certId,
                );
              }
              return const SizedBox();
            },
          ),
          trailing: PlatformPullDownButton(
            options: [
              PullDownOption(
                label: "PEM",
                onTap: (_) => notifier.archive("PEM"),
              ),
              PullDownOption(
                label: "PFX",
                onTap: (_) => notifier.archive("PFX"),
              ),
              PullDownOption(
                label: "JKS",
                onTap: (_) => notifier.archive("JKS"),
              ),
            ],
            icon: ActionButton(well: false, child: Text(s.download)),
          ),
          searchPlaceholder: s.credentialsSearchPlaceholder.capitalCase,
          provider: certificateDetailProvider(serverId, certId),
          itemBuilder: (context, data, index) {
            final server = ref.read(serverProvider(serverId));
            final item = data.list[index];
            return CertificateDetailWidget(
              key: ValueKey(item.id),
              data: item,
              serverHost: server.value?.host ?? "",
            );
          },
        ),
      ),
    );
  }
}
