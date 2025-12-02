import "dart:convert";
import "dart:io";

import "package:certimate/api/certificate_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/pages/server/provider.dart";
import "package:certimate/widgets/index.dart";
import "package:copy_with_extension/copy_with_extension.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:path_provider/path_provider.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:share_plus/share_plus.dart";

part "provider.g.dart";

@CopyWith()
class CertificateDetailData extends RefreshData<CertificateDetailResult> {
  @override
  final List<CertificateDetailResult> list;

  const CertificateDetailData(this.list);
}

@riverpod
class CertificateDetailNotifier extends _$CertificateDetailNotifier {
  @override
  Future<CertificateDetailData> build(int serverId, String certId) async {
    try {
      return CertificateDetailData([await loadData()]);
    } catch (e) {
      if (state.isRefreshing && state.hasValue) {
        SmartDialog.showNotify(msg: e.toString(), notifyType: NotifyType.error);
        return state.requireValue;
      }
      rethrow;
    }
  }

  Future<CertificateDetailResult> loadData() async {
    final server = ref.watch(serverProvider(serverId)).value!;
    return await ref.watch(certificateApiProvider).getDetail(server, certId);
  }

  Future<void> archive(String format) async {
    final server = ref.watch(serverProvider(serverId)).value!;
    final res = await ref
        .watch(certificateApiProvider)
        .archive(server, certId, format);
    final name =
        state.value?.list.first.subjectAltNames?.replaceFirst("*", "_") ?? "";
    final fileName =
        '$certId${name.isNotEmpty ? "-$name" : ""}.${res.data.fileFormat ?? "zip"}';
    if (isPhoneDevice) {
      final directory = await getTemporaryDirectory();
      final filePath = "${directory.path}/$fileName";
      await File(filePath).writeAsBytes(base64Decode(res.data.fileBytes ?? ""));
      SharePlus.instance.share(
        ShareParams(title: "Certificate", files: [XFile(filePath)]),
      );
    } else {
      String? initialDirectory;
      try {
        final directory = await getDownloadsDirectory();
        initialDirectory = directory?.path;
      } catch (e) {
        // no
      }
      final outputFile = await FilePicker.platform.saveFile(
        fileName: fileName,
        initialDirectory: initialDirectory,
      );
      if (outputFile != null) {
        await File(
          outputFile,
        ).writeAsBytes(base64Decode(res.data.fileBytes ?? ""));
      }
    }
  }
}
