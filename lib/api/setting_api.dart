import "package:certimate/api/http.dart";
import "package:certimate/database/servers_dao.dart";
import "package:dio/dio.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "setting_api.freezed.dart";
part "setting_api.g.dart";

@Riverpod(keepAlive: true)
SettingApi settingApi(Ref ref) {
  final dio = ref.read(dioProvider);
  return SettingApi(dio: dio);
}

class SettingApi {
  final Dio dio;

  SettingApi({required this.dio});

  Future<PersistenceContent?> getPersistence(ServerModel server) async {
    final response = await dio.get(
      "${server.host}/api/collections/settings/records",
      queryParameters: {
        "page": 1,
        "perPage": 1,
        "skipTotal": 1,
        "filter": "name='persistence'",
      },
      options: server.getOptions(),
    );
    final data = ApiPageResult.fromJson(
      response.data,
      (json) => SettingResult.fromJson(
        json as Map<String, Object?>,
        (json) => PersistenceContent.fromJson(json as Map<String, Object?>),
      ),
    );
    return data.items.firstOrNull?.content;
  }

  Future<void> updatePersistence(
    ServerModel server, {
    required int workflowRunsMaxDaysRetention,
    required int expiredCertificatesMaxDaysRetention,
  }) async {
    await dio.patch(
      "${server.host}/api/collections/settings/records",
      data: {
        "content": {
          "workflowRunsMaxDaysRetention": workflowRunsMaxDaysRetention,
          "expiredCertificatesMaxDaysRetention":
              expiredCertificatesMaxDaysRetention,
        },
        "name": "persistence",
      },
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
    int? expiredCertificatesMaxDaysRetention,
    int? workflowRunsMaxDaysRetention,
  }) = _PersistenceContent;

  factory PersistenceContent.fromJson(Map<String, Object?> json) =>
      _$PersistenceContentFromJson(json);
}
