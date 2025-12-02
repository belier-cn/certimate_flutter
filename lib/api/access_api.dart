import "package:certimate/api/http.dart";
import "package:certimate/database/servers_dao.dart";
import "package:dio/dio.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "access_api.freezed.dart";
part "access_api.g.dart";

@Riverpod(keepAlive: true)
AccessApi accessApi(Ref ref) {
  final dio = ref.read(dioProvider);
  return AccessApi(dio: dio);
}

class AccessApi {
  final Dio dio;

  AccessApi({required this.dio});

  Future<ApiPageResult<AccessResult>> getRecords(
    ServerModel server, {
    int page = 1,
    int perPage = 15,
    String sort = "-created",
    String filter = "",
  }) async {
    final response = await dio.get(
      "${server.host}/api/collections/access/records",
      queryParameters: {
        "page": page,
        "perPage": perPage,
        "sort": sort,
        "fields": "id,name,provider,reserve,created",
        "filter": filter,
      },
      options: server.getOptions(),
    );
    return ApiPageResult.fromJson(
      response.data,
      (json) => AccessResult.fromJson(json as Map<String, Object?>),
    );
  }

  Future<AccessDetailResult> getDetail(ServerModel server, String id) async {
    final response = await dio.get(
      "${server.host}/api/collections/access/records/$id",
      options: server.getOptions(),
    );
    return AccessDetailResult.fromJson(response.data);
  }

  Future<ApiResult> update(
    ServerModel server,
    String id,
    String name,
    dynamic config,
  ) async {
    final response = await dio.patch(
      "${server.host}/api/collections/access/records/$id",
      data: {"name": name, "config": config},
      options: server.getOptions(),
    );
    return ApiResult.fromJson(response.data, (json) => json);
  }

  Future<void> copy(ServerModel server, String accessId) async {
    final accessRes = await getDetail(server, accessId);
    await dio.post<Map<String, dynamic>>(
      "${server.host}/api/collections/access/records",
      data: {
        "name": "${accessRes.name}-copy",
        "provider": accessRes.provider,
        "config": accessRes.config,
      },
      options: server.getOptions(),
    );
  }

  Future<void> delete(ServerModel server, String id) async {
    await dio.delete(
      "${server.host}/api/collections/access/records/$id",
      options: server.getOptions(),
    );
  }
}

@freezed
abstract class AccessResult with _$AccessResult {
  const factory AccessResult({
    String? id,
    String? name,
    String? provider,
    String? reserve,
    @dateTimeConverter DateTime? created,
  }) = _AccessResult;

  factory AccessResult.fromJson(Map<String, Object?> json) =>
      _$AccessResultFromJson(json);
}

@freezed
abstract class AccessDetailResult with _$AccessDetailResult {
  const factory AccessDetailResult({
    String? id,
    String? name,
    Map<String, dynamic>? config,
    String? usage,
    String? reserve,
    String? provider,
    @dateTimeConverter DateTime? created,
  }) = _AccessDetailResult;

  factory AccessDetailResult.fromJson(Map<String, Object?> json) =>
      _$AccessDetailResultFromJson(json);
}
