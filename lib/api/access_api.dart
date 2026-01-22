import "package:certimate/api/http.dart";
import "package:dio/dio.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "access_api.freezed.dart";
part "access_api.g.dart";

@Riverpod(keepAlive: true)
AccessApi accessApi(Ref ref, int serverId) {
  final dio = ref.read(dioProvider);
  return AccessApi(dio: dio, serverId: serverId);
}

class AccessApi {
  final Dio dio;

  final int serverId;

  AccessApi({required this.dio, required this.serverId});

  Future<ApiPageResult<AccessResult>> getRecords({
    int page = 1,
    int perPage = 15,
    String sort = "-created",
    String filter = "",
  }) async {
    final response = await dio.get(
      "/api/collections/access/records",
      queryParameters: {
        "page": page,
        "perPage": perPage,
        "sort": sort,
        "fields": "id,name,provider,reserve,created",
        "filter": filter,
      },
      options: Options(extra: {"serverId": serverId}),
    );
    return ApiPageResult.fromJson(
      response.data,
      (json) => AccessResult.fromJson(json as Map<String, Object?>),
    );
  }

  Future<AccessDetailResult> getDetail(String id) async {
    final response = await dio.get(
      "/api/collections/access/records/$id",
      options: Options(extra: {"serverId": serverId}),
    );
    return AccessDetailResult.fromJson(response.data);
  }

  Future<ApiResult> update(String id, String name, dynamic config) async {
    final response = await dio.patch(
      "/api/collections/access/records/$id",
      data: {"name": name, "config": config},
      options: Options(extra: {"serverId": serverId}),
    );
    return ApiResult.fromJson(response.data, (json) => json);
  }

  Future<void> copy(String accessId) async {
    final accessRes = await getDetail(accessId);
    await dio.post<Map<String, dynamic>>(
      "/api/collections/access/records",
      data: {
        "name": "${accessRes.name}-copy",
        "provider": accessRes.provider,
        "config": accessRes.config,
      },
      options: Options(extra: {"serverId": serverId}),
    );
  }

  Future<void> delete(String id) async {
    await dio.delete(
      "/api/collections/access/records/$id",
      options: Options(extra: {"serverId": serverId}),
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
