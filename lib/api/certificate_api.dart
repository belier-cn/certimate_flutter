import "package:certimate/api/http.dart";
import "package:certimate/api/workflow_api.dart";
import "package:dio/dio.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "certificate_api.freezed.dart";
part "certificate_api.g.dart";

@Riverpod(keepAlive: true)
CertificateApi certificateApi(Ref ref, int serverId) {
  final dio = ref.read(dioProvider);
  return CertificateApi(dio: dio, serverId: serverId);
}

class CertificateApi {
  final Dio dio;

  final int serverId;

  CertificateApi({required this.dio, required this.serverId});

  Future<ApiPageResult<CertificateResult>> getRecords({
    int page = 1,
    int perPage = 15,
    String sort = "-created",
    String filter = "",
  }) async {
    final response = await dio.get(
      "/api/collections/certificate/records",
      queryParameters: {
        "page": page,
        "perPage": perPage,
        "expand": "workflowRef",
        "sort": sort,
        "fields":
            "id,source,subjectAltNames,isRevoked,issuerOrg,keyAlgorithm,validityNotBefore,validityNotAfter,workflowRef,created,expand.workflowRef.id,expand.workflowRef.name",
        "filter": filter,
      },
      options: Options(extra: {"serverId": serverId}),
    );
    return ApiPageResult.fromJson(
      response.data,
      (json) => CertificateResult.fromJson(json as Map<String, Object?>),
    );
  }

  Future<CertificateDetailResult> getDetail(String id) async {
    final response = await dio.get(
      "/api/collections/certificate/records/$id",
      queryParameters: {
        "fields":
            "id,issuerOrg,privateKey,certificate,serialNumber,keyAlgorithm,subjectAltNames,created,validityNotAfter,validityNotBefore",
      },
      options: Options(extra: {"serverId": serverId}),
    );
    return CertificateDetailResult.fromJson(response.data);
  }

  Future<ApiResult> revoke(String id) async {
    final response = await dio.post(
      "/api/certificates/$id/revoke",
      options: Options(extra: {"serverId": serverId}),
    );
    return ApiResult.fromJson(response.data, (json) => json);
  }

  Future<void> delete(String id) async {
    await dio.delete(
      "/api/certificates/$id",
      data: {"deleted": DateTime.now().toIso8601String()},
      options: Options(extra: {"serverId": serverId}),
    );
  }

  Future<ApiResult<CertificateArchiveResult>> archive(
    String id,
    String format,
  ) async {
    final response = await dio.post(
      "/api/certificates/$id/archive",
      data: {"format": format},
      options: Options(extra: {"serverId": serverId}),
    );
    return ApiResult.fromJson(
      response.data,
      (json) => CertificateArchiveResult.fromJson(json as Map<String, Object?>),
    );
  }
}

@freezed
abstract class CertificateResult with _$CertificateResult {
  const factory CertificateResult({
    String? id,
    String? source,
    bool? isRevoked,
    String? issuerOrg,
    String? keyAlgorithm,
    String? subjectAltNames,
    WorkflowRefExpand? expand,
    @dateTimeConverter DateTime? created,
    @dateTimeConverter DateTime? validityNotAfter,
    @dateTimeConverter DateTime? validityNotBefore,
    String? workflowRef,
  }) = _CertificateResult;

  factory CertificateResult.fromJson(Map<String, Object?> json) =>
      _$CertificateResultFromJson(json);
}

@freezed
abstract class CertificateDetailResult with _$CertificateDetailResult {
  const factory CertificateDetailResult({
    String? id,
    String? issuerOrg,
    String? privateKey,
    String? certificate,
    String? serialNumber,
    String? keyAlgorithm,
    String? subjectAltNames,
    @dateTimeConverter DateTime? created,
    @dateTimeConverter DateTime? validityNotAfter,
    @dateTimeConverter DateTime? validityNotBefore,
  }) = _CertificateDetailResult;

  factory CertificateDetailResult.fromJson(Map<String, Object?> json) =>
      _$CertificateDetailResultFromJson(json);
}

@freezed
abstract class CertificateArchiveResult with _$CertificateArchiveResult {
  const factory CertificateArchiveResult({
    String? fileFormat,
    String? fileBytes,
  }) = _CertificateArchiveResult;

  factory CertificateArchiveResult.fromJson(Map<String, Object?> json) =>
      _$CertificateArchiveResultFromJson(json);
}
