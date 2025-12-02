import "package:certimate/api/http.dart";
import "package:certimate/database/servers_dao.dart";
import "package:dio/dio.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "workflow_api.freezed.dart";
part "workflow_api.g.dart";

@Riverpod(keepAlive: true)
WorkflowApi workflowApi(Ref ref) {
  final dio = ref.read(dioProvider);
  return WorkflowApi(dio: dio);
}

class WorkflowApi {
  final Dio dio;

  WorkflowApi({required this.dio});

  Future<ApiPageResult<WorkflowResult>> getRecords(
    ServerModel server, {
    int page = 1,
    int perPage = 15,
    String sort = "",
    String filter = "",
  }) async {
    final response = await dio.get(
      "${server.host}/api/collections/workflow/records",
      queryParameters: {
        "page": page,
        "perPage": perPage,
        "sort": sort,
        "fields":
            "id,name,enabled,trigger,hasContent,triggerCron,description,created,lastRunTime",
        "filter": filter,
      },
      options: server.getOptions(),
    );
    return ApiPageResult.fromJson(
      response.data,
      (json) => WorkflowResult.fromJson(json as Map<String, Object?>),
    );
  }

  Future<void> copy(ServerModel server, String workflowId) async {
    final workflowRes = await dio.get<Map<String, dynamic>>(
      "${server.host}/api/collections/workflow/records/$workflowId",
      options: server.getOptions(),
    );
    final workflow = workflowRes.data ?? {};
    await dio.post<Map<String, dynamic>>(
      "${server.host}/api/collections/workflow/records",
      data: {
        "description": workflow["description"],
        "graphDraft": workflow["graphDraft"],
        "hasDraft": workflow["hasDraft"],
        "name": workflow["name"],
        "trigger": workflow["trigger"],
        "triggerCron": workflow["triggerCron"],
      },
      options: server.getOptions(),
    );
  }

  Future<void> delete(ServerModel server, String workflowId) async {
    await dio.delete(
      "${server.host}/api/collections/workflow/records/$workflowId",
      data: {"deleted": DateTime.now().toIso8601String()},
      options: server.getOptions(),
    );
  }

  Future<void> run(ServerModel server, String workflowId) async {
    await dio.post(
      "${server.host}/api/collections/workflow/records/$workflowId/runs",
      data: {"trigger": "manual"},
      options: server.getOptions(),
    );
  }

  Future<void> cancel(
    ServerModel server,
    String workflowId,
    String runId,
  ) async {
    await dio.post(
      "${server.host}/api/collections/workflow/records/$workflowId/runs/$runId/cancel",
      options: server.getOptions(),
    );
  }

  Future<ApiResult> enabled(
    ServerModel server,
    String workflowId,
    bool enabled,
  ) async {
    final response = await dio.patch(
      "${server.host}/api/collections/workflow/records/$workflowId",
      data: {"id": workflowId, "enabled": enabled},
      options: server.getOptions(),
    );
    return ApiResult.fromJson(response.data, (json) => json);
  }

  Future<ApiPageResult<WorkflowRunResult>> getRunRecords(
    ServerModel server, {
    int page = 1,
    int perPage = 15,
    String sort = "-created",
    String filter = "",
  }) async {
    final response = await dio.get(
      "${server.host}/api/collections/workflow_run/records",
      queryParameters: {
        "page": page,
        "perPage": perPage,
        "sort": sort,
        "expand": "workflowRef",
        "fields":
            "id,status,trigger,endedAt,startedAt,expand.workflowRef.id,expand.workflowRef.name,expand.workflowRef.description",
        "filter": filter,
      },
      options: server.getOptions(),
    );
    return ApiPageResult.fromJson(
      response.data,
      (json) => WorkflowRunResult.fromJson(json as Map<String, Object?>),
    );
  }

  Future<void> deleteRun(ServerModel server, String runId) async {
    await dio.delete(
      "${server.host}/api/collections/workflow_run/records/$runId",
      data: {"deleted": DateTime.now().toIso8601String()},
      options: server.getOptions(),
    );
  }

  Future<WorkflowRunDetailResult> getRunDetail(
    ServerModel server,
    String runId,
  ) async {
    final response = await dio.get(
      "${server.host}/api/collections/workflow_run/records/$runId",
      data: {"fields": "id,status,graph,trigger,startedAt,endedAt"},
      options: server.getOptions(),
    );
    return WorkflowRunDetailResult.fromJson(response.data);
  }

  Future<ApiPageResult<WorkflowLogResult>> getRunLogs(
    ServerModel server,
    String runId,
  ) async {
    final response = await dio.get(
      "${server.host}/api/collections/workflow_logs/records",
      queryParameters: {
        "page": 1,
        "perPage": 65535,
        "skipTotal": 1,
        "filter": "runRef='$runId'",
        "sort": "timestamp",
      },
      options: server.getOptions(),
    );
    return ApiPageResult.fromJson(
      response.data,
      (json) => WorkflowLogResult.fromJson(json as Map<String, Object?>),
    );
  }
}

@freezed
abstract class WorkflowRunResult with _$WorkflowRunResult {
  const factory WorkflowRunResult({
    String? id,
    String? status,
    String? trigger,
    WorkflowRefExpand? expand,
    @dateTimeConverter DateTime? endedAt,
    @dateTimeConverter DateTime? startedAt,
  }) = _WorkflowRunResult;

  factory WorkflowRunResult.fromJson(Map<String, Object?> json) =>
      _$WorkflowRunResultFromJson(json);
}

@freezed
abstract class WorkflowRefExpand with _$WorkflowRefExpand {
  const factory WorkflowRefExpand({WorkflowRef? workflowRef}) =
      _WorkflowRefExpand;

  factory WorkflowRefExpand.fromJson(Map<String, Object?> json) =>
      _$WorkflowRefExpandFromJson(json);
}

@freezed
abstract class WorkflowRef with _$WorkflowRef {
  const factory WorkflowRef({String? id, String? name, String? description}) =
      _WorkflowRef;

  factory WorkflowRef.fromJson(Map<String, Object?> json) =>
      _$WorkflowRefFromJson(json);
}

@freezed
abstract class WorkflowResult with _$WorkflowResult {
  const factory WorkflowResult({
    String? id,
    String? name,
    bool? enabled,
    String? trigger,
    bool? hasContent,
    String? triggerCron,
    String? description,
    @dateTimeConverter DateTime? created,
    @dateTimeConverter DateTime? lastRunTime,
  }) = _WorkflowResult;

  factory WorkflowResult.fromJson(Map<String, Object?> json) =>
      _$WorkflowResultFromJson(json);
}

@freezed
abstract class WorkflowRunDetailResult with _$WorkflowRunDetailResult {
  const factory WorkflowRunDetailResult({
    String? id,
    String? status,
    String? trigger,
    WorkflowGraph? graph,
    @dateTimeConverter DateTime? endedAt,
    @dateTimeConverter DateTime? startedAt,
  }) = _WorkflowRunDetailResult;

  factory WorkflowRunDetailResult.fromJson(Map<String, Object?> json) =>
      _$WorkflowRunDetailResultFromJson(json);
}

@freezed
abstract class WorkflowLogResult with _$WorkflowLogResult {
  const factory WorkflowLogResult({
    String? id,
    int? level,
    int? timestamp,
    String? nodeId,
    String? message,
    String? nodeName,
    Map<String, dynamic>? data,
    @dateTimeConverter DateTime? created,
  }) = _WorkflowLogResult;

  factory WorkflowLogResult.fromJson(Map<String, Object?> json) =>
      _$WorkflowLogResultFromJson(json);
}

@freezed
abstract class WorkflowGraph with _$WorkflowGraph {
  const factory WorkflowGraph({List<WorkflowNode>? nodes}) = _WorkflowGraph;

  factory WorkflowGraph.fromJson(Map<String, Object?> json) =>
      _$WorkflowGraphFromJson(json);
}

@freezed
abstract class WorkflowNode with _$WorkflowNode {
  const factory WorkflowNode({
    String? id,
    String? type,
    WorkflowNodeData? data,
    List<WorkflowNode>? blocks,
  }) = _WorkflowNode;

  factory WorkflowNode.fromJson(Map<String, Object?> json) =>
      _$WorkflowNodeFromJson(json);
}

@freezed
abstract class WorkflowNodeData with _$WorkflowNodeData {
  const factory WorkflowNodeData({String? name, Map<String, dynamic>? config}) =
      _WorkflowNodeData;

  factory WorkflowNodeData.fromJson(Map<String, Object?> json) =>
      _$WorkflowNodeDataFromJson(json);
}
