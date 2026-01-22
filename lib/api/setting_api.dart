import "package:certimate/api/http.dart";
import "package:dio/dio.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "setting_api.freezed.dart";
part "setting_api.g.dart";

@Riverpod(keepAlive: true)
SettingApi settingApi(Ref ref, int serverId) {
  final dio = ref.read(dioProvider);
  return SettingApi(dio: dio, serverId: serverId);
}

class SettingApi {
  final Dio dio;

  final int serverId;

  SettingApi({required this.dio, required this.serverId});

  Future<SettingResult<T>> getSettings<T>(
    String settingName,
    T Function(Map<String, Object?> json) fromJsonT,
  ) async {
    final response = await dio.get(
      "/api/collections/settings/records",
      queryParameters: {
        "page": 1,
        "perPage": 1,
        "skipTotal": 1,
        "filter": "name='$settingName'",
      },
      options: Options(extra: {"serverId": serverId}),
    );
    final data = ApiPageResult.fromJson(
      response.data,
      (json) => SettingResult.fromJson(
        json as Map<String, Object?>,
        (json) => fromJsonT(json as Map<String, Object?>),
      ),
    );
    return data.items.firstOrNull ??
        SettingResult(name: settingName, content: fromJsonT({}));
  }

  Future<SettingResult<T>> updateSettings<T>(
    SettingResult<T> settings,
    T Function(Map<String, Object?> json) fromJsonT,
    Object? Function(T) toJsonT,
  ) async {
    Response response;
    if (settings.id?.isNotEmpty == true) {
      response = await dio.patch(
        "/api/collections/settings/records/${settings.id}",
        data: settings.toJson(toJsonT),
        options: Options(extra: {"serverId": serverId}),
      );
    } else {
      final Object? content = settings.content == null
          ? null
          : toJsonT(settings.content as T);
      response = await dio.post(
        "/api/collections/settings/records",
        data: {"name": settings.name, if (content != null) "content": content},
        options: Options(extra: {"serverId": serverId}),
      );
    }
    return SettingResult.fromJson(
      response.data,
      (json) => fromJsonT(json as Map<String, Object?>),
    );
  }
}

@Freezed(genericArgumentFactories: true)
@freezed
abstract class SettingResult<T> with _$SettingResult<T> {
  const factory SettingResult({
    String? id,
    String? name,
    String? collectionId,
    String? collectionName,
    T? content,
    @dateTimeConverter DateTime? created,
    @dateTimeConverter DateTime? updated,
  }) = _SettingResult;

  factory SettingResult.fromJson(
    Map<String, Object?> json,
    T Function(Object?) fromJsonT,
  ) => _$SettingResultFromJson(json, fromJsonT);
}

@freezed
abstract class PersistenceContent with _$PersistenceContent {
  const factory PersistenceContent({
    int? certificatesWarningDaysBeforeExpire,
    int? expiredCertificatesMaxDaysRetention,
    int? workflowRunsMaxDaysRetention,
  }) = _PersistenceContent;

  factory PersistenceContent.fromJson(Map<String, Object?> json) =>
      _$PersistenceContentFromJson(json);
}

@freezed
abstract class NotifyTemplateContent with _$NotifyTemplateContent {
  const factory NotifyTemplateContent({List<NotifyTemplate>? templates}) =
      _NotifyTemplateContent;

  factory NotifyTemplateContent.fromJson(Map<String, Object?> json) =>
      _$NotifyTemplateContentFromJson(json);
}

@freezed
abstract class NotifyTemplate with _$NotifyTemplate {
  const factory NotifyTemplate({
    String? message,
    String? name,
    String? subject,
  }) = _NotifyTemplate;

  factory NotifyTemplate.fromJson(Map<String, Object?> json) =>
      _$NotifyTemplateFromJson(json);
}

@freezed
abstract class ScriptTemplateContent with _$ScriptTemplateContent {
  const factory ScriptTemplateContent({List<ScriptTemplate>? templates}) =
      _ScriptTemplateContent;

  factory ScriptTemplateContent.fromJson(Map<String, Object?> json) =>
      _$ScriptTemplateContentFromJson(json);
}

@freezed
abstract class ScriptTemplate with _$ScriptTemplate {
  const factory ScriptTemplate({String? command, String? name}) =
      _ScriptTemplate;

  factory ScriptTemplate.fromJson(Map<String, Object?> json) =>
      _$ScriptTemplateFromJson(json);
}
