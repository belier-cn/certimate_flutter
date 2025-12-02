import "package:certimate/extension/index.dart";
import "package:certimate/hooks/easy_refresh.dart";
import "package:certimate/pages/certificates/provider.dart";
import "package:certimate/pages/certificates/widgets/certificate.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class CertificatesPage extends HookConsumerWidget {
  final int serverId;

  const CertificatesPage({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final provider = certificatesProvider(serverId);
    final searchController = useTextEditingController();
    final refreshController = useRefreshController();
    final scrollController = useScrollController();
    final topVisible = useValueNotifier(false);
    return BasePage(
      child: Scaffold(
        body: RefreshBody<CertificatesData>(
          topVisible: topVisible,
          title: Text(s.certificates.titleCase),
          refreshController: refreshController,
          scrollController: scrollController,
          searchController: searchController,
          searchPlaceholder: s.certificatesSearchPlaceholder.capitalCase,
          provider: provider,
          itemBuilder: (context, data, index) {
            final item = data.list[index];
            return CertificateWidget(
              key: ValueKey(item.id),
              serverId: serverId,
              data: item,
              onRevoke: () async {
                if (await ref.read(provider.notifier).revoke(context, item)) {
                  refreshController.callRefresh(
                    scrollController: scrollController,
                  );
                }
              },
              onDelete: () async {
                if (await ref.read(provider.notifier).delete(context, item)) {
                  refreshController.callRefresh(
                    scrollController: scrollController,
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
