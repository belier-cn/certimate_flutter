import "package:certimate/api/http.dart";
import "package:certimate/database/servers_dao.dart";
import "package:dio/dio.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "server_api.freezed.dart";
part "server_api.g.dart";

@Riverpod(keepAlive: true)
ServerApi serverApi(Ref ref) {
  final dio = ref.read(dioProvider);
  return ServerApi(dio: dio);
}

class ServerApi {
  final Dio dio;

  ServerApi({required this.dio});

  Future<StatisticsResult> getStatistics(ServerModel server) async {
    final response = await dio.get(
      "${server.host}/api/statistics/get",
      options: server.getOptions(),
    );
    return ApiResult.fromJson(
      response.data,
      (json) => StatisticsResult.fromJson(json as Map<String, Object?>),
    ).data;
  }
}

@freezed
abstract class StatisticsResult with _$StatisticsResult {
  const factory StatisticsResult({
    int? workflowTotal,
    int? workflowEnabled,
    int? workflowDisabled,
    int? certificateTotal,
    int? certificateExpired,
    int? certificateExpiringSoon,
  }) = _StatisticsResult;

  factory StatisticsResult.fromJson(Map<String, Object?> json) =>
      _$StatisticsResultFromJson(json);
}
