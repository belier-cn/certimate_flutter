import "package:certimate/api/certificate_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/widgets/card.dart";
import "package:flutter/material.dart";

class CertificateDetailWidget extends StatelessWidget {
  final String serverHost;
  final CertificateDetailResult data;

  const CertificateDetailWidget({
    super.key,
    required this.data,
    required this.serverHost,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModelDetailCell.string(
          label: s.name.capitalCase,
          value: data.subjectAltNames,
        ),
        ModelDetailCell.string(
          label: s.issuer.capitalCase,
          value: data.issuerOrg,
        ),
        ModelDetailCell.string(
          label: s.keyAlgorithm.capitalCase,
          value: data.keyAlgorithm,
        ),
        ModelDetailCell.string(
          label: s.expiry.capitalCase,
          value:
              "${data.validityNotBefore.toDateTimeString()} - ${data.validityNotAfter.toDateTimeString()}",
        ),
        ModelDetailCell.string(
          label: s.serialNumber.capitalCase,
          value: data.serialNumber,
        ),
        ModelDetailCell.string(
          label: s.certificateChain.capitalCase,
          value: data.certificate,
          copy: true,
        ),
        ModelDetailCell.string(
          label: s.privateKey.capitalCase,
          value: data.privateKey,
          copy: true,
        ),
        ModelDetailCell.string(
          label: s.createdAt.capitalCase,
          value: data.created.toDateTimeString(),
        ),
      ],
    );
  }
}
