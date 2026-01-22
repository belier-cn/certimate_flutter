import "dart:async";

import "package:certimate/api/setting_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_riverpod/experimental/mutation.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:go_router/go_router.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "provider.g.dart";

@riverpod
class TemplateEditNotifier extends _$TemplateEditNotifier with SubmitMixin {
  static final submitLoading = Mutation<void>();

  @override
  final formKey = GlobalKey<FormBuilderState>();

  @override
  Mutation get submitMutation =>
      submitLoading("$serverId:$settingName:${templateIndex ?? "add"}");

  late SettingResult<dynamic> _settings;

  @override
  FutureOr<SubmitRefreshData<Object?>> build(
    int serverId,
    String settingName,
    int? templateIndex,
  ) async {
    final adapter = _TemplateEditAdapter.fromSettingName(settingName);
    final settings = await adapter.getSettings(ref, serverId, settingName);
    _settings = settings;
    final list = adapter.getTemplates(settings);
    final item =
        templateIndex != null &&
            templateIndex >= 0 &&
            templateIndex < list.length
        ? list[templateIndex]
        : adapter.emptyTemplate;
    return SubmitRefreshData([item]);
  }

  Future<Object?> _submit(Map<String, dynamic> data) async {
    final adapter = _TemplateEditAdapter.fromSettingName(settingName);
    final list = [...adapter.getTemplates(_settings)];
    final newTemplate = adapter.fromForm(data);
    final newName = adapter.getName(newTemplate) ?? "";
    _validateUniqueName(
      adapter: adapter,
      templates: list,
      name: newName,
      excludeIndex: templateIndex,
    );
    final nextList = _upsertByIndex(list, templateIndex, newTemplate);
    final next = await adapter.updateSettings(
      ref,
      serverId,
      settingName,
      _settings,
      nextList,
    );
    _settings = next;
    return newTemplate;
  }

  void _validateUniqueName({
    required _TemplateEditAdapter adapter,
    required List<Object> templates,
    required String name,
    required int? excludeIndex,
  }) {
    final normalized = name.trim();
    final duplicated = templates.indexed.any((entry) {
      final index = entry.$1;
      final templateName = (adapter.getName(entry.$2) ?? "").trim();
      if (excludeIndex != null && index == excludeIndex) return false;
      return templateName == normalized;
    });
    if (duplicated) {
      final msg = "模板名称已存在，请换一个。";
      throw Future.error(msg);
    }
  }

  List<T> _upsertByIndex<T>(List<T> list, int? index, T value) {
    if (index == null || index < 0 || index >= list.length) {
      return [...list, value];
    }
    return [...list]..setAll(index, [value]);
  }

  @override
  Future submit(BuildContext context, Map<String, dynamic> data) async {
    final res = await _submit(data);
    if (context.mounted) {
      SmartDialog.showToast(context.s.saveSuccess.capitalCase);
      context.pop(RunPlatform.isOhos ? () => res : res);
    }
  }
}

abstract class _TemplateEditAdapter {
  const _TemplateEditAdapter();

  factory _TemplateEditAdapter.fromSettingName(String settingName) {
    switch (settingName) {
      case "notifyTemplate":
        return const _NotifyTemplateAdapter();
      case "scriptTemplate":
        return const _ScriptTemplateAdapter();
      default:
        throw ArgumentError.value(settingName, "settingName");
    }
  }

  Object get emptyTemplate;

  String? getName(Object template);

  Object fromForm(Map<String, dynamic> data);

  Future<SettingResult<dynamic>> getSettings(
    Ref ref,
    int serverId,
    String settingName,
  );

  List<Object> getTemplates(SettingResult<dynamic> settings);

  Future<SettingResult<dynamic>> updateSettings(
    Ref ref,
    int serverId,
    String settingName,
    SettingResult<dynamic> settings,
    List<Object> templates,
  );
}

class _NotifyTemplateAdapter extends _TemplateEditAdapter {
  const _NotifyTemplateAdapter();

  @override
  Object get emptyTemplate => const NotifyTemplate();

  @override
  String? getName(Object template) => (template as NotifyTemplate).name;

  @override
  Object fromForm(Map<String, dynamic> data) {
    return NotifyTemplate(
      name: data["name"] as String?,
      subject: data["subject"] as String?,
      message: data["message"] as String?,
    );
  }

  @override
  Future<SettingResult<dynamic>> getSettings(
    Ref ref,
    int serverId,
    String settingName,
  ) {
    return ref
        .read(settingApiProvider(serverId))
        .getSettings<NotifyTemplateContent>(
          settingName,
          NotifyTemplateContent.fromJson,
        );
  }

  @override
  List<Object> getTemplates(SettingResult<dynamic> settings) {
    final realSettings = settings as SettingResult<NotifyTemplateContent>;
    return (realSettings.content?.templates ?? const <NotifyTemplate>[])
        .cast<Object>();
  }

  @override
  Future<SettingResult<dynamic>> updateSettings(
    Ref ref,
    int serverId,
    String settingName,
    SettingResult<dynamic> settings,
    List<Object> templates,
  ) {
    final realSettings = settings as SettingResult<NotifyTemplateContent>;
    return ref
        .read(settingApiProvider(serverId))
        .updateSettings<NotifyTemplateContent>(
          realSettings.copyWith(
            content: NotifyTemplateContent(
              templates: templates.cast<NotifyTemplate>(),
            ),
          ),
          NotifyTemplateContent.fromJson,
          (item) => item.toJson(),
        );
  }
}

class _ScriptTemplateAdapter extends _TemplateEditAdapter {
  const _ScriptTemplateAdapter();

  @override
  Object get emptyTemplate => const ScriptTemplate();

  @override
  String? getName(Object template) => (template as ScriptTemplate).name;

  @override
  Object fromForm(Map<String, dynamic> data) {
    return ScriptTemplate(
      name: data["name"] as String?,
      command: data["command"] as String?,
    );
  }

  @override
  Future<SettingResult<dynamic>> getSettings(
    Ref ref,
    int serverId,
    String settingName,
  ) {
    return ref
        .read(settingApiProvider(serverId))
        .getSettings<ScriptTemplateContent>(
          settingName,
          ScriptTemplateContent.fromJson,
        );
  }

  @override
  List<Object> getTemplates(SettingResult<dynamic> settings) {
    final realSettings = settings as SettingResult<ScriptTemplateContent>;
    return (realSettings.content?.templates ?? const <ScriptTemplate>[])
        .cast<Object>();
  }

  @override
  Future<SettingResult<dynamic>> updateSettings(
    Ref ref,
    int serverId,
    String settingName,
    SettingResult<dynamic> settings,
    List<Object> templates,
  ) {
    final realSettings = settings as SettingResult<ScriptTemplateContent>;
    return ref
        .read(settingApiProvider(serverId))
        .updateSettings<ScriptTemplateContent>(
          realSettings.copyWith(
            content: ScriptTemplateContent(
              templates: templates.cast<ScriptTemplate>(),
            ),
          ),
          ScriptTemplateContent.fromJson,
          (item) => item.toJson(),
        );
  }
}
