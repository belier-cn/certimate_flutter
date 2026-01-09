import "package:certimate/api/setting_api.dart";
import "package:certimate/pages/server/provider.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "provider.g.dart";

class TemplateListData extends RefreshData<Object> {
  @override
  final List<Object> list;

  const TemplateListData(this.list);
}

@riverpod
class TemplateListNotifier extends _$TemplateListNotifier {
  @override
  Future<TemplateListData> build(int serverId, String settingName) async {
    try {
      switch (settingName) {
        case "notifyTemplate":
          return TemplateListData(
            (await _loadTemplateList<NotifyTemplateContent, NotifyTemplate>(
              fromJson: NotifyTemplateContent.fromJson,
              getTemplates: (content) => content?.templates,
            )).cast<Object>(),
          );
        case "scriptTemplate":
          return TemplateListData(
            (await _loadTemplateList<ScriptTemplateContent, ScriptTemplate>(
              fromJson: ScriptTemplateContent.fromJson,
              getTemplates: (content) => content?.templates,
            )).cast<Object>(),
          );
        default:
          return const TemplateListData([]);
      }
    } catch (e) {
      if (state.isRefreshing && state.hasValue) {
        SmartDialog.showNotify(msg: e.toString(), notifyType: NotifyType.error);
        return state.requireValue;
      }
      rethrow;
    }
  }

  Future<List<ItemT>> _loadTemplateList<ContentT, ItemT>({
    required ContentT Function(Map<String, Object?> json) fromJson,
    required List<ItemT>? Function(ContentT? content) getTemplates,
  }) async {
    final server = ref.watch(serverProvider(serverId)).value!;
    final res = await ref
        .watch(settingApiProvider)
        .getSettings<ContentT>(server, settingName, fromJson);
    return getTemplates(res.content) ?? List<ItemT>.empty(growable: false);
  }
}
